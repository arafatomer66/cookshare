<?php

namespace App\Http\Resources;

use App\Models\Story;
use App\Services\S3UrlService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'photo_url' => self::resolvePhotoUrl($this->resource),
            'dish_name' => $this->dish_name,
            'caption' => $this->caption,
            'lat' => (float) $this->lat,
            'lng' => (float) $this->lng,
            'is_available' => (bool) $this->is_available,
            'portions_total' => $this->portions_total,
            'price' => $this->price,
            'pickup_area' => $this->pickup_area,
            'whatsapp' => $this->whatsapp_at_post ?: $this->user?->whatsapp_number,
            'user' => $this->whenLoaded('user', fn () => [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'avatar_url' => $this->user->avatar_url,
            ]),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    public static function resolvePhotoUrl(Story $story): ?string
    {
        if (! empty($story->photo_key)) {
            return S3UrlService::presignedGet($story->photo_key);
        }
        if (empty($story->photo_url)) return null;

        $host = parse_url($story->photo_url, PHP_URL_HOST);
        if (in_array($host, ['picsum.photos', 'fastly.picsum.photos', 'placehold.co'], true)) {
            return url('/api/v1/img-proxy?u=' . urlencode($story->photo_url));
        }
        return $story->photo_url;
    }
}
