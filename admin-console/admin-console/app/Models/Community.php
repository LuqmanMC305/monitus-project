<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Community extends Model
{
    protected $primaryKey = 'community_id';

    public function members()
    {
        // Arguments: Target Model, Pivot Table, Current Model FK, Target Model FK
        return $this->belongsToMany(MobileUser::class, 'community_user', 'mobile_user_id', 'community_user_id')
                ->withPivot('role')
                ->withTimestamps();
    }
}
