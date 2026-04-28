<?php

namespace App\Services;

use Aws\S3\S3Client;

/**
 * Generates short-lived presigned GET URLs so the private S3 bucket
 * can be read by mobile clients without making the bucket public.
 */
class S3UrlService
{
    private static ?S3Client $client = null;

    public static function client(): S3Client
    {
        return self::$client ??= new S3Client([
            'version' => 'latest',
            'region' => config('filesystems.disks.s3.region'),
            'credentials' => [
                'key' => config('filesystems.disks.s3.key'),
                'secret' => config('filesystems.disks.s3.secret'),
            ],
        ]);
    }

    public static function presignedGet(string $key, int $minutes = 60): string
    {
        $bucket = config('filesystems.disks.s3.bucket');
        $cmd = self::client()->getCommand('GetObject', [
            'Bucket' => $bucket,
            'Key' => $key,
        ]);

        return (string) self::client()->createPresignedRequest($cmd, "+{$minutes} minutes")->getUri();
    }
}
