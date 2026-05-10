<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class CommunityController extends Controller
{
    public function join(Request $request) {
        $user = $request->user(); // Get the authenticated mobile user
        $communityId = $request->community_id;

        // Attach the user to the community with a 'pending' status
        // syncWithoutDetaching prevents duplicate entries if they click twice
        $user->communities()->syncWithoutDetaching([
            $communityId => ['status' => 'pending', 'role' => 'resident']
        ]);

        return response()->json([
            'message' => 'Join request sent to Admin.',
            'status' => 'pending'
        ], 201);
    }
}


