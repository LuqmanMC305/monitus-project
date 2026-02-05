<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\MobileUserController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/hello', function (Request $request) {
    return response()->json([
        'message' => 'Hello from Laravel',
        'value' => '55'
    ]);
});

// This maps the URL 'your-domain.com/api/register-mobile' to your controller method
Route::post('/register-mobile', [MobileUserController::class, 'register']);

// Send Alert 
Route::post('/send-alert', [MobileUserController::class, 'sendAlert']);

/*
Route::post('/hello', function (Request $request) {
    return response()->json([
        'message'=> 'You sent: ' . $request->input('text'),
        'author' => 'The Author: ' . $request->input('author')
        ]);
        
});

//Other Post Method Example

Route::post('/hello/create', function (Request $request) {
    return response()->json([
        'id' => rand(1, 100000),
        'message'=> 'You sent: ' . $request->input('text'),
        'author' => 'The Author: ' . $request->input('author')
        ]);
        
});

Route::put('/hello/{id}', function ($id, Request $request) {
    return response()->json([
        'id'=> $id,
        'updated' => $request->all()
        ]);
        
});

Route::patch('/hello/{id}', function ($id, Request $request) {
    return response()->json([
        'id'=> $id,
        'patched' => $request->all()
        ]);
        
});

Route::delete('/hello/{id}', function ($id, Request $request) {
    return response()->json([
        'message' => "Deleted resource with id of $id"
        ]);
        
});

*/
