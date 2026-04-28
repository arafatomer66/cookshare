<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PostResource;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class UserController extends Controller
{
    public function show(User $user): UserResource
    {
        $user->loadCount(['posts', 'followers', 'following']);

        return new UserResource($user);
    }

    public function update(Request $request): UserResource
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:80',
            'bio' => 'nullable|string|max:280',
            'avatar_url' => 'nullable|url|max:500',
            'whatsapp_number' => 'nullable|string|max:32',
            'default_lat' => 'nullable|numeric|between:-90,90',
            'default_lng' => 'nullable|numeric|between:-180,180',
        ]);

        $user = $request->user();
        $user->update($data);

        return new UserResource($user);
    }

    public function follow(Request $request, User $user): JsonResponse
    {
        abort_if($user->id === $request->user()->id, 422, 'Cannot follow yourself');
        $request->user()->following()->syncWithoutDetaching([$user->id]);

        return response()->json(['following' => true]);
    }

    public function unfollow(Request $request, User $user): JsonResponse
    {
        $request->user()->following()->detach($user->id);

        return response()->json(['following' => false]);
    }

    public function posts(User $user): AnonymousResourceCollection
    {
        return PostResource::collection(
            $user->posts()
                ->with('user')
                ->withCount(['likedBy as likes_count', 'comments as comments_count'])
                ->latest()
                ->cursorPaginate(20)
        );
    }

    public function nearbyCooks(Request $request): AnonymousResourceCollection
    {
        $data = $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'radius_km' => 'sometimes|numeric|min:0.1|max:100',
        ]);

        $radiusKm = (float) ($data['radius_km'] ?? config('cookshare.nearby_default_km', 5));
        $ttlHours = (int) config('cookshare.map_pin_ttl_hours', 24);
        $point = sprintf('ST_SetSRID(ST_MakePoint(%F, %F), 4326)::geography', $data['lng'], $data['lat']);

        $cooks = User::whereExists(function ($q) use ($point, $radiusKm, $ttlHours) {
            $q->select('id')
                ->from('posts')
                ->whereColumn('posts.user_id', 'users.id')
                ->where('posts.created_at', '>=', now()->subHours($ttlHours))
                ->whereRaw("ST_DWithin(posts.location, {$point}, ?)", [$radiusKm * 1000]);
        })
            ->where('id', '!=', $request->user()->id)
            ->withCount('posts')
            ->limit(50)
            ->get();

        return UserResource::collection($cooks);
    }

    /**
     * Roster of any cook with at least one post — used as the "find people"
     * fallback when the user denies location or there's nobody nearby.
     */
    public function allCooks(Request $request): AnonymousResourceCollection
    {
        $cooks = User::has('posts')
            ->where('id', '!=', $request->user()->id)
            ->withCount('posts')
            ->orderByDesc('posts_count')
            ->limit(100)
            ->get();

        return UserResource::collection($cooks);
    }

    public function search(Request $request): AnonymousResourceCollection
    {
        $q = trim((string) $request->input('q'));
        abort_if($q === '', 422, 'q is required');

        $users = User::where('name', 'ilike', "%{$q}%")
            ->orWhere('email', 'ilike', "%{$q}%")
            ->limit(30)
            ->get();

        return UserResource::collection($users);
    }
}
