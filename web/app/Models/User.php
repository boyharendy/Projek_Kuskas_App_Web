<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'users';

    /**
     * The primary key associated with the table.
     *
     * @var string
     */
    protected $primaryKey = 'id';

    /**
     * The "type" of the primary key ID.
     *
     * @var string
     */
    protected $keyType = 'string';

    /**
     * Indicates if the IDs are auto-incrementing.
     *
     * @var bool
     */
    public $incrementing = false;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'id',
        'full_name',
        'email',
        'avatar_url',
        'name',
    ];

    /**
     * Map default Laravel 'name' attribute to Supabase's 'full_name' for backwards compatibility.
     */
    public function getNameAttribute()
    {
        return $this->full_name;
    }

    public function setNameAttribute($value)
    {
        $this->full_name = $value;
    }

    /**
     * Map 'kuskas_user_id' to primary key 'id' for backwards compatibility.
     */
    public function getKuskasUserIdAttribute()
    {
        return $this->id;
    }

    public function setKuskasUserIdAttribute($value)
    {
        $this->id = $value;
    }

    /**
     * Disable password requirements by returning empty string.
     */
    public function getAuthPassword()
    {
        return '';
    }
}
