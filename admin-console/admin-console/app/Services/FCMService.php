<?php

namespace App\Services;

use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class FCMService
{
    protected $messaging;

    public function __construct()
    {
        // This automatically uses the FIREBASE_CREDENTIALS from your .env
        $this->messaging = app('firebase.messaging');
    }

    public function sendEmergencyAlert($tokens, $title, $body)
    {
        if (empty($tokens)) return 0;

        // Create the notification payload
        $notification = Notification::create($title, $body);
        
        $message = CloudMessage::new()
            ->withNotification($notification)
            ->withData(['type' => 'emergency_alert']); // Extra data for Flutter logic

        // Send to multiple tokens at once (Multicast)
        $report = $this->messaging->sendMulticast($message, $tokens);

        return $report->successes()->count();
    }
}