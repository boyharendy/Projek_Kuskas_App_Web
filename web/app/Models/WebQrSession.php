<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WebQrSession extends Model
{
    protected $table = 'web_qr_sessions';

    protected $fillable = [
        'session_id',
        'token',
        'status',
        'kuskas_user_id',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
