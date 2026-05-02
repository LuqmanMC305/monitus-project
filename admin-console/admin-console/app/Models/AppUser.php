<?php

/**
 * @property int $app_user_id
 * @property string $app_user_name
 * @property string $app_user_email
 * @property string $app_user_password
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 */

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppUser extends Model
{
    protected $table = 'app_users';
    protected $primaryKey = 'app_user_id';

    protected $fillable = [
    
        'app_user_name',
        'app_user_email',
        'app_user_password'
    ];
}
