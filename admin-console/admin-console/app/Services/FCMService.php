<?php

namespace App\Services;

use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Laravel\Firebase\Facades\Firebase;
use Kreait\Firebase\Messaging\AndroidConfig;

class FCMService
{
    protected $messaging;

   public function sendEmergencyAlert($tokens, $title, $body)
    {
        // Accessing Messaging Instance Via Firebase Facades
        $messaging = Firebase::messaging();
        $sentCount = 0;

        foreach ($tokens as $token) {
            $message = CloudMessage::new()
                ->withNotification(Notification::create($title, $body)) //
                ->withAndroidConfig([
                    'priority' => 'high', 
                    'notification' => [
                         'channel_id' => 'high_importance_channel', // CRITICAL: Matches your test
                    ],       
                ])
                ->withData(['alert_type' => 'emergency']) //
                ->toToken($token);

            $messaging->send($message);
            $sentCount++;
        }
        return $sentCount;
    }
}