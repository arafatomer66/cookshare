<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $me = $request->user();
        $isFollowing = false;
        if ($me && $me->id !== $this->id) {
            $isFollowing = $me->following()->where('users.id', $this->id)->exists();
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->when($me?->id === $this->id, $this->email),
            'bio' => $this->bio,
            'avatar_url' => $this->avatar_url,
            'whatsapp_number' => $this->whatsapp_number,
            'default_lat' => $this->default_lat,
            'default_lng' => $this->default_lng,
            'posts_count' => $this->whenCounted('posts'),
            'followers_count' => $this->whenCounted('followers'),
            'following_count' => $this->whenCounted('following'),
            'is_following' => $isFollowing,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
