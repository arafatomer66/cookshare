<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Like extends Model
{
    public $incrementing = false;
    protected $primaryKey = null;

    protected $fillable = ['user_id', 'post_id'];
}
