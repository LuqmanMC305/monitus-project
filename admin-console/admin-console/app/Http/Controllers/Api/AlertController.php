<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Alert;
use App\Models\MobileUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Services\FCMService;



class AlertController extends Controller
{
    public function store(Request $request)
    {
        // 1. Validate incoming map data
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'instruction' => 'required|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'radius' => 'required|integer',
            'severity' => 'required|string',
        ]);

        // 2. Save the Alert to DB
        $alert = Alert::create([
            'admin_id' => Auth::id(), // Get current Jetstream user ID
            'title' => $validated['title'],
            'instruction' => $validated['instruction'],
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'radius' => $validated['radius'],
            'severity' => $validated['severity'],
            'status' => 'active',
        ]);

        // 3. Trigger the Geo-Engine Logic 
        // (Find Users Within Radius of Recently Saved Alert)
        $affectedUsers = MobileUser::whereRaw(
            "ST_DWithin(last_location, ST_MakePoint(?, ?)::geography, ?)",
            [$alert->longitude, $alert->latitude, $alert->radius]
        )
        ->where('updated_at', '>=', now()->subMinutes(30))
        ->get();

        // Extract Tokers from Notifier Service
        $tokens = $affectedUsers->pluck('fcm_token')->filter()->toArray();

        // Call the Notifier Service (Pass the dynamic data)
        $fcmservice = app(FCMService::class); 
        $sentCount = $fcmservice->sendEmergencyAlert(
            $tokens, 
            $alert->title, 
            $alert->instruction
        );

        // 4. Return JSON response to Frontend (Axios Library)
        return response()->json([
            'message' => 'Alert broadcasted successfully!',
            'alert_id' => $alert->alert_id,
            'notified_count' => $affectedUsers->count(),
            'tokens_found' => $tokens, // Now you will see this in Edge!
            'debug_user_ids' => $affectedUsers->pluck('mobile_user_id'),
        ]);
    }
}
