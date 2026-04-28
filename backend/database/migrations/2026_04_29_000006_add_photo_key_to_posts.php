<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            // S3 object key (private bucket — backend issues presigned GETs at read time).
            // Nullable so seed data using external photo_url URLs still works.
            $table->string('photo_key')->nullable()->after('photo_url');
            $table->string('photo_url')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->dropColumn('photo_key');
            $table->string('photo_url')->nullable(false)->change();
        });
    }
};
