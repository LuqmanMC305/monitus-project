<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Admin\IncidentMapController;
use App\Http\Controllers\Api\AlertController;

Route::get('/', function () {
    return view('welcome');
});

Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified',
])->group(function () {
    Route::get('/dashboard', function () {
        return view('dashboard');
    })->name('dashboard');
    // Incident Map Route
    Route::get('/incident-map', [IncidentMapController::class, 'index'])->name('incident.map');
    // Alert Controller
    Route::post('/api/send-alert', [AlertController::class, 'store']);
    // Resolve Alerts
    Route::patch('api/alerts/{id}/resolve', [IncidentMapController::class, 'resolve']);
    // Manage Alerts
    Route::get('/admin/manage-alerts', [IncidentMapController::class, 'manage'])->name('admin.manage-alerts');
});
