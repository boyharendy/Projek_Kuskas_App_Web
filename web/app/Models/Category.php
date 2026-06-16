<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Category extends Model
{
    use HasFactory;

    protected $table = 'categories';

    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';

    // The categories table has created_at but no updated_at
    const UPDATED_AT = null;

    protected $fillable = [
        'id',
        'user_id',
        'name',
        'icon',
        'type',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];
}
