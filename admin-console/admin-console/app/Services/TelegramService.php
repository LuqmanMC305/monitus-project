<?php

namespace App\Services;

use Telegram\Bot\Laravel\Facades\Telegram;
use Illuminate\Support\Facades\Log;

class TelegramService
{
    /**
     * Entry point for broadcasting to a community.
     */
    public function sendCommunityAlert($groupId, $alert)
    {
        //  Message Formatter
        $formattedMessage = $this->formatAlertMessage($alert);

        try {
            //  Dispatcher
            return Telegram::sendMessage([
                'chat_id' => $groupId, // Ensure this contains the -100 prefix
                'text' => $formattedMessage,
                'parse_mode' => 'HTML'
            ]);
        } catch (\Exception $e) {
            //  Error Guard (Retry Handler)
            Log::warning("Telegram Delivery Engine failed for Chat ID {$groupId}: " . $e->getMessage());
            return false; 
        }
    }

    /**
     * Message Formatter
     * Converts raw alert data into a professional Telegram layout.
     */
    private function formatAlertMessage($alert)
    {
        $severityIcons = [
            'HIGH' => '🚨',
            'MEDIUM' => '⚠️',
            'LOW' => 'ℹ️'
        ];

        $icon = $severityIcons[strtoupper($alert->severity)] ?? '📢';

        return "<b>{$icon} MONITUS ALERT: {$alert->title}</b>\n\n" .
               "<b>Instruction:</b>\n<i>{$alert->instruction}</i>\n\n" .
               "📍 <a href='https://monitus.app/view/{$alert->alert_id}'>View on Interactive Map</a>\n" .
               "<small>Stay safe and follow local authority guidance.</small>";
    }

    public function sendManualAnnouncement($groupId, $communityName, $message)
        {
            $formatted = "📢 <b>OFFICIAL COMMUNITY ANNOUNCEMENT</b>\n" .
                        "<b>Group:</b> {$communityName}\n\n" .
                        $message . "\n\n" .
                        "<small>Sent via Monitus Command Centre</small>";

            return $this->sendCommunityAlert($groupId, $formatted);
        }

    /* FUTURE FEATURE: Community-Verified Triggering (CROWDSOURCING) 
    public function sendWardenVerificationRequest($wardenChatId, $report)
    {
        // Logic to send a private message to a Warden to ask them to verify a report
    }
    */
}