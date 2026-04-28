<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MapController;
use App\Http\Controllers\Api\PostController;
use App\Http\Controllers\Api\StoryController;
use App\Http\Controllers\Api\UploadController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Public auth
    Route::post('auth/register', [AuthController::class, 'register']);
    Route::post('auth/login', [AuthController::class, 'login']);

    // Public map tile proxy (flutter_map TileLayer fetches without auth headers).
    // Tile content is not sensitive and the only AWS action exposed is geo:GetMapTile.
    Route::get('map/tiles/{z}/{x}/{y}', [MapController::class, 'tile'])
        ->where(['z' => '[0-9]+', 'x' => '[0-9]+', 'y' => '[0-9]+']);

    // Public OSM raster tile proxy + allow-listed image proxy (handles emulator DNS quirks).
    Route::get('map/osm/{z}/{x}/{y}', [MapController::class, 'osmTile'])
        ->where(['z' => '[0-9]+', 'x' => '[0-9]+', 'y' => '[0-9]+']);
    Route::get('img-proxy', [MapController::class, 'imageProxy']);

    // Authenticated
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('auth/me', [AuthController::class, 'me']);

        // Feed + posts
        Route::get('feed', [PostController::class, 'index']);
        Route::post('posts', [PostController::class, 'store']);
        Route::get('posts/{post}', [PostController::class, 'show']);
        Route::delete('posts/{post}', [PostController::class, 'destroy']);
        Route::post('posts/{post}/like', [PostController::class, 'like']);
        Route::delete('posts/{post}/like', [PostController::class, 'unlike']);
        Route::get('posts/{post}/comments', [PostController::class, 'comments']);
        Route::post('posts/{post}/comments', [PostController::class, 'comment']);

        // Map
        Route::get('map/nearby', [MapController::class, 'nearby']);

        // Stories (24h ephemeral cooking posts)
        Route::get('stories/rings', [StoryController::class, 'rings']);
        Route::get('stories/users/{userId}', [StoryController::class, 'userStories'])->where('userId', '[0-9]+');
        Route::post('stories', [StoryController::class, 'store']);
        Route::post('stories/{story}/view', [StoryController::class, 'view']);
        Route::get('stories/{story}/viewers', [StoryController::class, 'viewers']);
        Route::delete('stories/{story}', [StoryController::class, 'destroy']);

        // Users
        Route::patch('users/me', [UserController::class, 'update']);
        Route::get('users/search', [UserController::class, 'search']);
        Route::get('users/nearby', [UserController::class, 'nearbyCooks']);
        Route::get('users/cooks', [UserController::class, 'allCooks']);
        Route::get('users/{user}', [UserController::class, 'show']);
        Route::get('users/{user}/posts', [UserController::class, 'posts']);
        Route::post('users/{user}/follow', [UserController::class, 'follow']);
        Route::delete('users/{user}/follow', [UserController::class, 'unfollow']);

        // Uploads
        Route::post('uploads/presign', [UploadController::class, 'presign']);
    });
});
