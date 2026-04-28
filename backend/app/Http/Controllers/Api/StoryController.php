<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\StoryResource;
use App\Models\Story;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StoryController extends Controller
{
    /**
     * Story rings for the feed: groups of active (non-expired) stories per cook,
     * ordered to put followed cooks first then nearby cooks.
     */
    public function rings(Request $request): JsonResponse
    {
        $data = $request->validate([
            'lat' => 'sometimes|numeric|between:-90,90',
            'lng' => 'sometimes|numeric|between:-180,180',
            'radius_km' => 'sometimes|numeric|min:0.1|max:100',
        ]);

        $user = $request->user();
        $followedIds = $user->following()->pluck('users.id');

        $base = Story::with('user:id,name,avatar_url')
            ->where('expires_at', '>', now())
            ->orderByDesc('created_at');

        // My own ring (Instagram-style) first.
        $mine = (clone $base)->where('user_id', $user->id)->get();

        // Followed cooks next.
        $followed = (clone $base)->whereIn('user_id', $followedIds)->get();

        // Nearby cooks (excluding followed) if lat/lng provided.
        $nearby = collect();
        if (! empty($data['lat']) && ! empty($data['lng'])) {
            $radiusKm = (float) ($data['radius_km'] ?? config('cookshare.nearby_default_km', 5));
            $point = sprintf('ST_SetSRID(ST_MakePoint(%F, %F), 4326)::geography', $data['lng'], $data['lat']);
            $nearby = (clone $base)
                ->whereNotIn('user_id', $followedIds->push($user->id))
                ->whereRaw("ST_DWithin(location, {$point}, ?)", [$radiusKm * 1000])
                ->limit(50)
                ->get();
        }

        // Group by cook so the client renders one ring per user.
        $rings = $mine->concat($followed)->concat($nearby)
            ->groupBy('user_id')
            ->map(function ($stories) use ($user) {
                $first = $stories->first();
                $viewedIds = $user->id
                    ? \DB::table('story_views')->where('user_id', $user->id)
                        ->whereIn('story_id', $stories->pluck('id'))->pluck('story_id')->all()
                    : [];
                return [
                    'user' => [
                        'id' => $first->user->id,
                        'name' => $first->user->name,
                        'avatar_url' => $first->user->avatar_url,
                    ],
                    'story_count' => $stories->count(),
                    'has_unviewed' => count($viewedIds) < $stories->count(),
                    'preview_photo_url' => StoryResource::resolvePhotoUrl($first),
                    'latest_at' => $first->created_at->toIso8601String(),
                ];
            })->values();

        return response()->json(['rings' => $rings]);
    }

    /**
     * All active stories from a single cook, oldest first (viewer plays in order).
     */
    public function userStories(Request $request, int $userId): JsonResponse
    {
        $stories = Story::with('user:id,name,avatar_url,whatsapp_number')
            ->where('user_id', $userId)
            ->where('expires_at', '>', now())
            ->orderBy('created_at')
            ->get();

        return response()->json([
            'stories' => StoryResource::collection($stories),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'photo_key' => 'sometimes|string|max:255',
            'photo_url' => 'sometimes|url|max:500',
            'dish_name' => 'sometimes|nullable|string|max:120',
            'caption' => 'sometimes|nullable|string|max:500',
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'is_available' => 'sometimes|boolean',
            'portions_total' => 'required_if:is_available,true|nullable|integer|min:1|max:50',
            'price' => 'required_if:is_available,true|nullable|numeric|min:0',
            'pickup_area' => 'sometimes|nullable|string|max:80',
        ]);

        if (empty($data['photo_key']) && empty($data['photo_url'])) {
            return response()->json(['message' => 'photo_key or photo_url is required'], 422);
        }

        $ttlHours = (int) config('cookshare.story_ttl_hours', 24);

        $story = Story::create([
            ...$data,
            'user_id' => $request->user()->id,
            'whatsapp_at_post' => $request->user()->whatsapp_number,
            'expires_at' => now()->addHours($ttlHours),
        ]);

        $story->load('user:id,name,avatar_url,whatsapp_number');
        return response()->json(['story' => new StoryResource($story)], 201);
    }

    public function view(Request $request, Story $story): JsonResponse
    {
        // Idempotent — first view stamps timestamp, subsequent views are noops.
        \DB::table('story_views')->insertOrIgnore([
            'story_id' => $story->id,
            'user_id' => $request->user()->id,
            'viewed_at' => now(),
        ]);

        return response()->json(['ok' => true]);
    }

    public function destroy(Request $request, Story $story): JsonResponse
    {
        if ($story->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        $story->delete();
        return response()->json(['ok' => true]);
    }

    /**
     * Viewer list for one of my own stories — basic analytics for the cook.
     */
    public function viewers(Request $request, Story $story): JsonResponse
    {
        if ($story->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $viewers = $story->viewers()
            ->orderByPivot('viewed_at', 'desc')
            ->limit(200)
            ->get(['users.id', 'users.name', 'users.avatar_url']);

        return response()->json([
            'count' => $viewers->count(),
            'viewers' => $viewers,
        ]);
    }
}
