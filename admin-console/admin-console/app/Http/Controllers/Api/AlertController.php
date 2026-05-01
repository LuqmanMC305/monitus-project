<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Alert;
use App\Models\MobileUser;
use App\Models\Community;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Services\FCMService;
use App\Services\TelegramService as ServicesTelegramService;

use function Laravel\Prompts\error;

class AlertController extends Controller
{
    protected $telegramService;

    public function __construct(ServicesTelegramService $telegramService)
    {
        $this->telegramService = $telegramService;
    }

    // For Manual Targeting
    public function broadcastToCommunity($communityId, $alertMessage)
    {
        // Find community
        $community = Community::findOrFail($communityId);

        // Send broadcast
        try
        {
            $this->telegramService->sendCommunityAlert(
                $community->telegram_group_id,
                "📢 <b>OFFICIAL COMMUNITY ANNOUNCEMENT:</b>\n" .
                "<b>Group:</b> " . $community->community_name . "\n\n" .
                $alertMessage
            );

            return back()->with('success', 'Alert sent to ' . $community->community_name);

        } catch (\Exception $e){
            return back()->with('error', 'Failed to reach Telegram: ' . $e->getMessage());
        }
           
    }
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
        $sql = "ST_DWithin(last_location, ST_MakePoint(?, ?)::geography, ?)";
        $bindings = [$alert->longitude, $alert->latitude, $alert->radius];
        
        $affectedUsers = MobileUser::whereRaw($sql, $bindings)
            ->where('last_location_at', '>=', now()->subMinutes(30))
            ->get();

        foreach ($affectedUsers as $user)
        {
            // Attach user to the alert
            $alert->mobileUsers()->attach($user->mobile_user_id, [
                'is_success' => true,
                'delivered_at' => now(),
            ]);

            // Telegram Direct Broadcast
            // Only send if user has linked to Telegram
            if($user->is_telegram_verified && $user->telegram_chat_id)
                {
                    try{
                        $this->telegramService->sendCommunityAlert(
                            $user->telegram_chat_id,
                            "🚨 <b>" . strtoupper($alert->severity) . " ALERT: " . $alert->title . "</b>\n\n" .
                            $alert->instruction
                        );
                    } catch(\Exception $e){
                        info("Telegram broadcast fail for User:" . $user->mobile_user_id);
                    }
                }
        }

        // Alert relevant communities (Community Group Sweep)
        $affectedCommunities = Community::whereRaw(
            "ST_DWithin(location, ST_SetSRID(ST_Point(?, ?), 4326)::geography, ?)",
            [$alert->longitude, $alert->latitude, $alert->radius]
        )->get();

        foreach($affectedCommunities as $community)
        {
            if ($community->telegram_group_id)
                {
                    try
                    {
                        $this->telegramService->sendCommunityAlert(
                            $community->telegram_group_id,
                            "📢 <b>COMMUNITY NOTIFICATION</b>\n" .
                            "<b>Location:</b> " . $community->community_name . "\n".
                            "<b>Incident:</b> " . $alert->title . "\n\n" .
                            $alert->instruction
                        );
                    } catch (\Exception $e){
                        error("Community Telegram failed: " . $community->community_name);
                    }
                }
        }
            
        

        // Extract Tokers from Notifier Service
        $tokens = $affectedUsers->pluck('fcm_token')->filter()->toArray();

        // Call the Notifier Service (Pass the dynamic data)
        $fcmservice = app(FCMService::class);

        // Prepare the data payload (READY TO FOLLOW CAP PROTOCOL)
        $extraData = [
            'latitude'   => (string)$alert->latitude,  // Matches Flutter key
            'longitude'  => (string)$alert->longitude, // Matches Flutter key
            'radius'     => (string)$alert->radius,
            'alert_type' => $alert->severity,          // Or 'emergency'
        ]; 

        
        $sentCount = $fcmservice->sendEmergencyAlert(
            $tokens, 
            $alert->title, 
            $alert->instruction,
            $extraData
        );

        // Print raw alert data on laravel log
        info('Raw Alert Data:', $extraData);

        // 4. Return JSON response to Frontend (Axios Library)
        return response()->json([
            'message' => 'Alert broadcasted successfully!',
            'alert_id' => $alert->alert_id,
            'notified_count' => $affectedUsers->count(),
            'tokens_found' => $tokens, // Now you will see this in Edge!
            'debug_user_ids' => $affectedUsers->pluck('mobile_user_id'),
            'search_radius' => $alert->radius,
            'latitude' => $alert->latitude,
            'longitude' => $alert->longitude,
        ]);
    }
}
