<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Services\S3UrlService;
use Aws\LocationService\LocationServiceClient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Http;

class MapController extends Controller
{
    /**
     * Returns recent posts within a radius as GeoJSON FeatureCollection — direct map render.
     */
    public function nearby(Request $request): JsonResponse
    {
        $data = $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'radius_km' => 'sometimes|numeric|min:0.1|max:100',
            'follow_only' => 'sometimes|boolean',
        ]);

        $radiusKm = (float) ($data['radius_km'] ?? config('cookshare.nearby_default_km', 5));
        $ttlHours = (int) config('cookshare.map_pin_ttl_hours', 24);
        $point = sprintf('ST_SetSRID(ST_MakePoint(%F, %F), 4326)::geography', $data['lng'], $data['lat']);

        $query = Post::with('user:id,name,avatar_url')
            ->where('created_at', '>=', now()->subHours($ttlHours))
            ->whereRaw("ST_DWithin(location, {$point}, ?)", [$radiusKm * 1000])
            ->orderByDesc('created_at')
            ->limit(500);

        if (! empty($data['follow_only'])) {
            $followedIds = $request->user()->following()->pluck('users.id');
            $query->whereIn('user_id', $followedIds);
        }

        $features = $query->get()->map(fn ($post) => [
            'type' => 'Feature',
            'geometry' => ['type' => 'Point', 'coordinates' => [(float) $post->lng, (float) $post->lat]],
            'properties' => [
                'id' => $post->id,
                'photo_url' => $this->resolvePhotoUrl($post),
                'dish_name' => $post->dish_name,
                'caption' => $post->caption,
                'is_for_sale' => $post->is_for_sale,
                'price' => $post->price,
                'created_at' => $post->created_at->toIso8601String(),
                'user' => [
                    'id' => $post->user->id,
                    'name' => $post->user->name,
                    'avatar_url' => $post->user->avatar_url,
                ],
            ],
        ]);

        return response()->json([
            'type' => 'FeatureCollection',
            'features' => $features,
        ]);
    }

    /**
     * Proxy AWS Location Service map tiles through the backend so the mobile client
     * doesn't need to ship signed AWS credentials or an API key.
     */
    public function tile(int $z, int $x, int $y): Response
    {
        $client = new LocationServiceClient([
            'version' => 'latest',
            'region' => config('filesystems.disks.s3.region'),
            'credentials' => [
                'key' => config('filesystems.disks.s3.key'),
                'secret' => config('filesystems.disks.s3.secret'),
            ],
        ]);

        $result = $client->getMapTile([
            'MapName' => config('cookshare.aws_location_map_name'),
            'X' => $x,
            'Y' => $y,
            'Z' => $z,
        ]);

        return response($result['Blob']->getContents(), 200, [
            'Content-Type' => $result['ContentType'] ?? 'application/octet-stream',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    private function resolvePhotoUrl(Post $post): ?string
    {
        if (! empty($post->photo_key)) {
            return S3UrlService::presignedGet($post->photo_key);
        }

        if (empty($post->photo_url)) {
            return null;
        }

        $host = parse_url($post->photo_url, PHP_URL_HOST);
        if (in_array($host, ['picsum.photos', 'fastly.picsum.photos', 'placehold.co'], true)) {
            return url('/api/v1/img-proxy?u=' . urlencode($post->photo_url));
        }

        return $post->photo_url;
    }

    /**
     * OSM raster tile proxy. The Android emulator has broken DNS for external hosts —
     * routing tiles through the backend keeps dev working, and is also a better OSM
     * citizen than thousands of clients hitting tile.openstreetmap.org directly.
     */
    public function osmTile(int $z, int $x, int $y): Response
    {
        $res = Http::withHeaders(['User-Agent' => 'CookShare/1.0 (dev)'])
            ->get("https://tile.openstreetmap.org/{$z}/{$x}/{$y}.png");

        return response($res->body(), $res->status(), [
            'Content-Type' => $res->header('Content-Type') ?: 'image/png',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    /**
     * Generic image proxy for seed/external photo URLs. Restricted to a small allow-list
     * (picsum, placehold) so it can't be turned into an open relay.
     */
    public function imageProxy(Request $request): Response
    {
        $url = (string) $request->query('u', '');
        $host = parse_url($url, PHP_URL_HOST);
        $allow = ['picsum.photos', 'fastly.picsum.photos', 'placehold.co'];

        if (! in_array($host, $allow, true)) {
            return response('forbidden', 403);
        }

        $res = Http::withHeaders(['User-Agent' => 'CookShare/1.0'])->get($url);

        return response($res->body(), $res->status(), [
            'Content-Type' => $res->header('Content-Type') ?: 'image/jpeg',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }
}
