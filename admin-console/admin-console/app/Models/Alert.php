<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Alert extends Model
{
    protected $primaryKey = 'alert_id';

    // Acts as a security guard to protect its attributes
    protected $fillable = [
        'admin_id', 'title', 'instruction', 'status', 
        'severity', 'latitude', 'longitude', 'radius'
    ];

    /**
     * Get the Admin that send the alert.
     */
    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_id');
    }
}
