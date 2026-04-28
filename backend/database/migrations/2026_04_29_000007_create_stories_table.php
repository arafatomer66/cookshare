<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('whatsapp_number', 32)->nullable()->after('avatar_url');
        });

        Schema::create('stories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('photo_key')->nullable();
            $table->string('photo_url')->nullable();
            $table->string('dish_name')->nullable();
            $table->text('caption')->nullable();
            $table->double('lat');
            $table->double('lng');

            // Optional sell fields — story is "available" if these are set.
            $table->boolean('is_available')->default(false);
            $table->unsignedInteger('portions_total')->nullable();
            $table->decimal('price', 10, 2)->nullable();
            $table->string('pickup_area', 80)->nullable();
            $table->string('whatsapp_at_post', 32)->nullable(); // snapshot, in case user changes later

            $table->timestamp('expires_at')->index();
            $table->timestamps();

            $table->index(['user_id', 'expires_at']);
        });

        // PostGIS geography column for radius queries (matches posts table pattern).
        DB::statement('ALTER TABLE stories ADD COLUMN location geography(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography) STORED');
        DB::statement('CREATE INDEX stories_location_gix ON stories USING GIST (location)');

        Schema::create('story_views', function (Blueprint $table) {
            $table->foreignId('story_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamp('viewed_at')->useCurrent();
            $table->primary(['story_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('story_views');
        Schema::dropIfExists('stories');
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('whatsapp_number');
        });
    }
};
