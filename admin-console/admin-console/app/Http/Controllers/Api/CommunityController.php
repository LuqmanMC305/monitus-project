<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Community;

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

    public function index (Request $request)
    {
        // Display all communities list
        $user = $request->user();

        // We fetch all communities, but ONLY attach the pivot data for the logged-in user
        // This tells Flutter if the user is already 'pending' or 'approved'
        $communities = Community::with(['mobileUsers' => function ($query) use ($user) {
            $query->where('mobile_user_id', $user->id);
        }])->get();

        return response()->json([
            'success' => true,
            'data' => $communities
        ]);


    }
}


