<?php

namespace App\Http\Resources;

use App\Services\S3UrlService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'caption' => $this->caption,
            'photo_url' => $this->resolvePhotoUrl(),
            'dish_name' => $this->dish_name,
            'cuisine' => $this->cuisine,
            'cooking_minutes' => $this->cooking_minutes,
            'is_for_sale' => $this->is_for_sale,
            'price' => $this->price,
            'portions_available' => $this->portions_available,
            'lat' => (float) $this->lat,
            'lng' => (float) $this->lng,
            'likes_count' => $this->whenCounted('likedBy', $this->likes_count ?? 0),
            'comments_count' => $this->whenCounted('comments', $this->comments_count ?? 0),
            'liked_by_me' => $request->user()
                ? $this->likedBy()->where('users.id', $request->user()->id)->exists()
                : false,
            'user' => new UserResource($this->whenLoaded('user')),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    /**
     * Prefer the S3 key (issuing a fresh presigned GET) so the bucket can stay private.
     * Fall back to photo_url for seed/external images, wrapped in the backend image
     * proxy so they reach clients on networks with restricted DNS (e.g. Android emulator).
     */
    private function resolvePhotoUrl(): ?string
    {
        if (! empty($this->photo_key)) {
            return S3UrlService::presignedGet($this->photo_key);
        }

        if (empty($this->photo_url)) {
            return null;
        }

        $host = parse_url($this->photo_url, PHP_URL_HOST);
        $proxied = ['picsum.photos', 'fastly.picsum.photos', 'placehold.co'];

        if (in_array($host, $proxied, true)) {
            return url('/api/v1/img-proxy?u=' . urlencode($this->photo_url));
        }

        return $this->photo_url;
    }
}
