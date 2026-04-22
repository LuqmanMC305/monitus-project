<?php

namespace App\Services;

use Telegram\Bot\Laravel\Facades\Telegram;

class TelegramService
{
    public function sendCommunityAlert($groupId, $message)
    {
        return Telegram::sendMessage([
            'chat_id' => $groupId,
            'text' => $message,
            'parse_mode' => 'HTML'
        ]);
    }
}