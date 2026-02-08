<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class IncidentMapController extends Controller
{
    // Index Method
    public function index()
    {
        return view('admin.incident-map');
    }
}
