<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Alert;
use Illuminate\Http\Request;

class IncidentMapController extends Controller
{
    // Index Method
    public function index()
    {
        // Fetch the Latest Alerts
        $latestNum = 10; // 10 Latest Alerts
        $alerts = Alert::where('status','active')
                        ->latest()
                        ->take($latestNum)
                        ->get();

        return view('admin.incident-map', compact('alerts'));

        /*
        $alerts = Alert::latest()->take($latestNum)->get();
        
        */
    }

    /**
     * Update the alert status to 'resolved' from Axios PATCH request.
     */

    public function resolve($id)
    {
        $alert = Alert::findOrFail($id);
        $alert->status = 'resolved';
        $alert->save();

        return response()->json([
            'success' => true,
            'message' => 'Alert has been resolved and removed from the map.'
        ]);
    }

    public function manage()
    {
        // Fetch all active alerts for admin control
        $activeAlerts = Alert::where('status', 'active')
                            ->latest()
                            ->get();

        // Fetch recently resolved alerts for the history section
        define('RESOLVE_ALERT_NUM', 10);

        $resolvedAlerts = Alert::where('status', 'resolved')
                            ->latest()
                            ->take(RESOLVE_ALERT_NUM)
                            ->get();


        return view('admin.manage-alerts', compact('activeAlerts', 'resolvedAlerts'));
    }

    public function dashboard()
    {
        // 1. Get counts for metric cards
        $activeCount = Alert::where('status', 'active')->count();
        $resolvedCount = Alert::where('status', 'resolved')->count();
        $totalAlerts = Alert::count();

        // 2. Get Severity Breakdown for chart
        $highSeverity = Alert::where('status', 'active')->where('severity', 'HIGH')->count();

        // 3. Get Recent 5 Alerts
        define('RECENT_ALERT_NUM', 5);
        $recentAlerts = Alert::latest()->take(RECENT_ALERT_NUM)->get();

        return view('dashboard', compact(
            'activeCount',
            'resolvedCount', 
            'totalAlerts', 
            'highSeverity',
            'recentAlerts'
        ));
    }
}
