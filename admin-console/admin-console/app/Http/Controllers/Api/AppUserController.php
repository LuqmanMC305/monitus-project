<?php

namespace App\Http\Controllers\Api;


use App\Http\Controllers\Controller;
use App\Models\AppUser;
use Illuminate\Http\Request;
use  Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;


class AppUserController extends Controller
{
    public function register(Request $request) 
    {
        // Validate the input
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:app_users,app_user_email',
            'password' => 'required|string|min:8',
        ]);

        if ($validator->fails()) return response()->json($validator->errors(), 422);

        // Create the AppUser (Hash the password!)
        // Get the validated data as an array
        $data = $validator->validated();
    
        $user = AppUser::create([
            'app_user_name' => $data['name'],
            'app_user_email' =>  $data['email'],
            'app_user_password' => Hash::make($data['password']), // Password Encryption
        ]);

        // 3. Return the app_user_id to Flutter 
        return response()->json([
            'message' => 'Registration successful',
            'app_user_id' => $user->app_user_id
        ], 201);
    }
   
    public function login(Request $request)
    {
        // Verify credentials
        $request->validate
        ([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        // Verify the user exists and the hashed password matches
        $user = AppUser::where('app_user_email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->app_user_password)) 
        {
            return response()->json
            ([
                'message' => 'Invalid login credentials'
            ], 401);
        }

        // Return the app_user_id so the phone can save it
        return response()->json
        ([
            'message' => 'Login successful',
            'app_user_id' => $user->app_user_id,
            'name' => $user->app_user_name
        ], 200);

    }
}
