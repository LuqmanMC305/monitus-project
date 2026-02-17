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
        $alerts = Alert::latest()->take($latestNum)->get();
        return view('admin.incident-map', compact('alerts'));
    }
}
