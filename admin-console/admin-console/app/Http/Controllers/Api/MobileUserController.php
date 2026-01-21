<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MobileUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MobileUserController extends Controller
{
    /**
     * Handle the registration and location update for mobile users.
     */
    public function register(Request $request)
    {
        // 1. Request Validation
        $validated = $request->validate([
            'device_id'=> 'required|string',
            'fcm_token' => 'required|string',
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        // 2. Data Transformation & Persistence
        // We use updateOrCreate to prevent duplicate entries for the same device.
        $user = MobileUser::updateOrCreate(
            ['fcm_token' => $validated['fcm_token']], // Unique identifier
            [
                'device_id'=> $validated['device_id'],
                // Convert Lat/Long to PostGIS Geography Point
                'last_location' => DB::raw("ST_GeogFromText('SRID=4326;POINT({$validated['longitude']} {$validated['latitude']})')"),
                'last_location_at' => now(), // The "Timestamp" context
            ]
        );

        // 3. API Response
        return response()->json([
            'status' => 'success',
            'message' => 'User location synchronized successfully.',
            'data' => [
                'user_id' => $user->mobile_user_id,
                'updated_at' => $user->last_location_at->toDateTimeString()
            ]
        ], 201);
    }
}
