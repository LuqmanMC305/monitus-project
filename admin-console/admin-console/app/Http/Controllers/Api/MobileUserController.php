<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MobileUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;


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
            ['device_id' => $validated['device_id']], // Unique identifier 
            [
                'fcm_token'=> $validated['fcm_token'], 
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

    public function sendAlert(Request $request)
    {
        // 1. Validation for incoming incident data
        $validated = $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'radius' => 'required|numeric',
        ]);

        $latitude = $validated['latitude'];
        $longitude = $validated['longitude'];
        $radius = $validated['radius'];

        // 2. Prepare Well-Known Text (WKT) String First
        $pointWkt = "POINT($longitude $latitude)";

        // 3. Geo-Engine Logic (Query with Defined Parameters)
        $nearbyUsers = MobileUser::select('fcm_token', 'device_id')
        // Calculate distance of mobile client device from target 
        ->selectRaw("ST_Distance(last_location::geography, ST_GeomFromText(?, 4326)::geography) as distance_in_metres", [
        $pointWkt
        ])
        ->whereRaw("ST_DWithin(last_location, ST_GeomFromText(?, 4326), ?)", [
            $pointWkt, // PostGIS expects Longitude first
            $radius
        ])
        ->where('updated_at', '>=', now()->subMinutes(30))
        ->get();

        // Logging for Testing
        Log::info("Geo-Engine found " . $nearbyUsers->count() . " users nearby.");

        // 3. Return Success with JSON
        return response()->json([
        'status' => 'success',
        'count' => $nearbyUsers->count(),
        'tokens' => $nearbyUsers // Changed from pluck('fcm_token') to the whole collection
    ]);


    }
}
