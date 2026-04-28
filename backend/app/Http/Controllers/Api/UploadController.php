<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\S3UrlService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class UploadController extends Controller
{
    /**
     * Returns a presigned PUT URL so the mobile client can upload a photo directly to S3,
     * plus the S3 object key the client should later send to /posts.
     */
    public function presign(Request $request): JsonResponse
    {
        $data = $request->validate([
            'content_type' => 'required|string|in:image/jpeg,image/png,image/webp',
            'extension' => 'required|string|in:jpg,jpeg,png,webp',
        ]);

        $key = sprintf('posts/%s/%s.%s',
            $request->user()->id,
            Str::uuid()->toString(),
            $data['extension']
        );

        $bucket = config('filesystems.disks.s3.bucket');

        $cmd = S3UrlService::client()->getCommand('PutObject', [
            'Bucket' => $bucket,
            'Key' => $key,
            'ContentType' => $data['content_type'],
        ]);

        $uploadUrl = (string) S3UrlService::client()
            ->createPresignedRequest($cmd, '+15 minutes')
            ->getUri();

        return response()->json([
            'upload_url' => $uploadUrl,
            'photo_key' => $key,
            'expires_in' => 900,
        ]);
    }
}
