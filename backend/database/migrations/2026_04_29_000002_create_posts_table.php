<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->text('caption')->nullable();
            $table->string('photo_url');
            $table->string('dish_name')->nullable();
            $table->string('cuisine')->nullable();
            $table->unsignedSmallInteger('cooking_minutes')->nullable();
            $table->boolean('is_for_sale')->default(false);
            $table->decimal('price', 10, 2)->nullable();
            $table->unsignedSmallInteger('portions_available')->nullable();
            $table->decimal('lat', 10, 7);
            $table->decimal('lng', 10, 7);
            $table->timestamps();
            $table->index('created_at');
        });

        // Generated PostGIS geography column + GIST index for fast nearby queries.
        DB::statement('ALTER TABLE posts ADD COLUMN location geography(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography) STORED');
        DB::statement('CREATE INDEX posts_location_gist ON posts USING GIST (location)');
    }

    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
