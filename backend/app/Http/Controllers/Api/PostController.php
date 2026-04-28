<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommentResource;
use App\Http\Resources\PostResource;
use App\Models\Post;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class PostController extends Controller
{
    /**
     * Feed: posts from people the user follows, plus a nearby fallback to bootstrap discovery.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $user = $request->user();
        $followedIds = $user->following()->pluck('users.id')->push($user->id);

        $query = Post::with('user')
            ->withCount(['likedBy as likes_count', 'comments as comments_count'])
            ->orderByDesc('created_at');

        if ($request->filled('lat') && $request->filled('lng')) {
            $lat = (float) $request->input('lat');
            $lng = (float) $request->input('lng');
            $radiusKm = (float) $request->input('radius_km', config('cookshare.nearby_default_km', 5));
            $point = "ST_SetSRID(ST_MakePoint({$lng}, {$lat}), 4326)::geography";
            $query->whereRaw("(user_id IN (".$followedIds->implode(',').") OR ST_DWithin(location, {$point}, ?))", [$radiusKm * 1000]);
        } else {
            $query->whereIn('user_id', $followedIds);
        }

        return PostResource::collection($query->cursorPaginate(20));
    }

    public function store(Request $request): PostResource
    {
        $data = $request->validate([
            'caption' => 'nullable|string|max:1000',
            'photo_key' => 'required_without:photo_url|string|max:300',
            'photo_url' => 'required_without:photo_key|url|max:500',
            'dish_name' => 'nullable|string|max:120',
            'cuisine' => 'nullable|string|max:60',
            'cooking_minutes' => 'nullable|integer|min:1|max:1440',
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'is_for_sale' => 'sometimes|boolean',
            'price' => 'nullable|numeric|min:0',
            'portions_available' => 'nullable|integer|min:1',
        ]);

        $post = $request->user()->posts()->create($data);
        $post->load('user');
        $post->loadCount(['likedBy as likes_count', 'comments as comments_count']);

        return new PostResource($post);
    }

    public function show(Post $post): PostResource
    {
        $post->load('user');
        $post->loadCount(['likedBy as likes_count', 'comments as comments_count']);

        return new PostResource($post);
    }

    public function destroy(Request $request, Post $post): JsonResponse
    {
        abort_unless($post->user_id === $request->user()->id, 403);
        $post->delete();

        return response()->json(['message' => 'Deleted']);
    }

    public function like(Request $request, Post $post): JsonResponse
    {
        $post->likedBy()->syncWithoutDetaching([$request->user()->id]);

        return response()->json(['liked' => true, 'likes_count' => $post->likedBy()->count()]);
    }

    public function unlike(Request $request, Post $post): JsonResponse
    {
        $post->likedBy()->detach($request->user()->id);

        return response()->json(['liked' => false, 'likes_count' => $post->likedBy()->count()]);
    }

    public function comments(Post $post): AnonymousResourceCollection
    {
        return CommentResource::collection(
            $post->comments()->with('user')->latest()->cursorPaginate(30)
        );
    }

    public function comment(Request $request, Post $post): CommentResource
    {
        $data = $request->validate(['body' => 'required|string|max:500']);
        $comment = $post->comments()->create([
            'user_id' => $request->user()->id,
            'body' => $data['body'],
        ]);
        $comment->load('user');

        return new CommentResource($comment);
    }
}
