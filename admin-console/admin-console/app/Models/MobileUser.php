<?php

namespace App\Models;

use App\Models\Alert;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Models\DeliveryLog;
use Illuminate\Database\Eloquent\Relations\HasMany;


class MobileUser extends Model
{
    use HasFactory;

    /**
     * The table associated with the model.
     * Use snake_case as per Laravel conventions.
     */
    protected $table = 'mobile_users';

    /**
     * Primary Key of this table.
     *  */    
    protected $primaryKey = 'mobile_user_id';

    /**
     * Mass assignable attributes 
     * Prevents MassAssignmentExceptions during registration
     */
    protected $fillable = [
        'device_id',
        'fcm_token',
        'last_location',
        'last_location_at'
        ];

    /**
     * The attributes that should be cast to native types.
     * 'last_location_at' is treated as a Carbon instance automatically.
     */
    protected $casts = [
        'last_location_at' => 'datetime',
    ];
  
    /*
    |--------------------------------------------------------------------------
    | Relationships
    |--------------------------------------------------------------------------
    */

    /**
     * One-to-many relationship ("One Mobile User can be found in many different rows of delivery logs.)
     */

    public function deliveryLogs()
    {
        return $this->hasMany(DeliveryLog::class, 'mobile_user_id', 'mobile_user_id');
    }


}
