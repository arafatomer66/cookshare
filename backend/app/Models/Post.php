<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Post extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'caption',
        'photo_url',
        'photo_key',
        'dish_name',
        'cuisine',
        'cooking_minutes',
        'is_for_sale',
        'price',
        'portions_available',
        'lat',
        'lng',
    ];

    protected function casts(): array
    {
        return [
            'is_for_sale' => 'boolean',
            'price' => 'decimal:2',
            'lat' => 'float',
            'lng' => 'float',
            'cooking_minutes' => 'integer',
            'portions_available' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }

    public function likedBy(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'likes')->withTimestamps();
    }
}
