<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Models\DeliveryLog;

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

    /*
      A MobileUser can have many delivery logs. WILL IMPLEMENT LATER
     
    public function deliveryLogs()
    {
        return $this->hasMany(DeliveryLog::class, 'mobile_user_id');
    }

    */

}
