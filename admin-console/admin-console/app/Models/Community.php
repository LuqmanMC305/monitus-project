<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Community extends Model
{
    public function members()
    {
        return $this->belongsToMany(MobileUser::class, 'community_user', 'community_id', 'mobile_user_id')
                ->withPivot('role')
                ->withTimestamps();
    }
}
