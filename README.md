# Monitus

Monitus is a community-based emergency alert and response system developed to improve public awareness and safety during local emergencies. The project combines a Flutter mobile application for residents and a Laravel admin console for managing alerts, coordinating communities, and sending notifications to affected users.

The system is designed to deliver timely hazard alerts based on location, support community communication, and provide an administrative dashboard for monitoring active and resolved incidents.

## Project Overview

Monitus aims to solve the problem of delayed emergency communication by enabling:

- residents to receive alerts relevant to their area,
- communities to request and manage local memberships,
- admins to broadcast incidents and hazard warnings,
- users to report or view active danger zones on a map,
- local authorities or administrators to monitor and resolve alerts centrally.

This project was developed as a full-stack solution with:
- a mobile client for end users,
- a Laravel backend for alert logic and administration,
- Firebase Cloud Messaging for mobile notifications,
- Telegram integration for community communication and alerts.

## Objectives

The key goals of the project are to:

- provide real-time emergency alerts in affected areas,
- support location-aware notification delivery,
- allow local communities to stay informed and connected,
- give administrators tools to view, manage, and resolve alerts,
- improve response coordination for emergency situations.

## System Features

### Mobile Features
- User registration and login
- Device and location synchronization
- Alert history and notification viewing
- Community discovery and join requests
- Community membership status tracking
- Map view of active alerts and danger zones
- Reporting of incidents from the app
- Firebase push notifications
- Telegram channel access for approved communities

### Admin Features
- Admin dashboard with alert statistics
- Active and resolved alert management
- Alert creation and broadcasting
- Location-based alert targeting
- Community approval workflow
- Telegram community broadcasting
- Incident map management
- Alert resolution tracking

## Architecture

The project is divided into two main components:

1. Admin Console
   - Laravel backend
   - web dashboard
   - API endpoints
   - alert and community management logic

2. Mobile Client
   - Flutter application
   - user-facing interfaces
   - map-based alert display
   - local notification and session management

### High-Level Flow

```text
Mobile User
   |
   v
Flutter App
   |
   v
Laravel API
   |-- validates user and alert data
   |-- stores alerts and community memberships
   |-- checks proximity of users to alert locations
   |
   +--> Firebase Push Notification
   +--> Telegram Direct/Community Alerts
   +--> Admin Dashboard Monitoring
```

## Tech Stack

### Backend
- PHP 8.2
- Laravel 12
- Jetstream
- Livewire
- Sanctum
- Firebase Admin SDK
- Telegram Bot SDK

### Mobile Frontend
- Flutter
- Dart
- Provider for state management
- Firebase Cloud Messaging
- Geolocator
- Flutter Map
- Shared Preferences
- URL Launcher
- Image Picker

### Supporting Tools
- MySQL/PostgreSQL-compatible database layer
- OpenStreetMap map tiles
- REST API communication
- Geo-aware queries for alert radius matching

## Project Structure

```text
monitus-project/
├── admin-console/
│   └── admin-console/
│       ├── app/
│       │   ├── Http/
│       │   │   ├── Controllers/
│       │   │   │   ├── Admin/
│       │   │   │   └── Api/
│       │   ├── Models/
│       │   ├── Providers/
│       │   ├── Services/
│       │   └── View/
│       ├── config/
│       ├── database/
│       ├── public/
│       ├── resources/
│       ├── routes/
│       ├── storage/
│       ├── tests/
│       ├── artisan
│       ├── composer.json
│       ├── package.json
│       ├── phpunit.xml
│       └── vite.config.js
│
├── mobile-client/
│   └── monitus_mobile_client/
│       ├── android/
│       ├── ios/
│       ├── lib/
│       │   ├── config/
│       │   ├── providers/
│       │   ├── screens/
│       │   ├── services/
│       │   ├── firebase_options.dart
│       │   └── main.dart
│       ├── test/
│       ├── pubspec.yaml
│       └── README.md
│
└── README.md
```

## Core Modules

### Admin Console
The admin portion contains the main logic for alert management and community oversight.

Key modules include:
- `IncidentMapController` for map and alert dashboards
- `CommunityApprovalController` for managing community membership requests
- `AlertController` for creating and broadcasting alerts
- `FCMService` for Firebase notification delivery
- `TelegramService` for Telegram community and direct alerts

### Mobile Client
The mobile app handles the resident experience.

Main screens and logic include:
- registration and login
- community list and join flow
- warning/alert map view
- alert history
- session persistence and user state management

## Main Functional Workflow

1. A resident registers and syncs their device information with the backend.
2. The user joins or requests membership in a local community.
3. An admin creates an emergency alert through the admin dashboard.
4. The backend identifies users within the alert radius.
5. Matching users receive relevant push notifications.
6. Community Telegram groups may also receive warnings.
7. The admin can review, manage, and resolve active incidents.

## API Overview

Key backend routes include:
- mobile registration
- app registration and login
- community join requests
- community listing
- alert broadcast to affected users
- admin alert resolution
- community approvals and rejections

The project routes are defined in:
- `api.php`
- `web.php`

## Setup Instructions

### 1. Backend Setup
Open the Laravel admin project:

```bash
cd admin-console/admin-console
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
npm install
npm run build
php artisan serve
```

### 2. Mobile App Setup
Open the Flutter app:

```bash
cd mobile-client/monitus_mobile_client
flutter pub get
flutter run
```

### 3. Firebase Setup
Ensure Firebase is configured for the mobile app and that the app is initialized correctly in:
- `lib/firebase_options.dart`
- `lib/main.dart`

### 4. Environment Notes
- The Flutter app is configured with a staging environment at startup.
- Laravel handles backend logic, database access, and webhook/notification tasks.
- Firebase and Telegram are used for real-time communication.

## Future Improvements

Possible enhancements include:

- improved real-time dashboard analytics,
- polygon-based geofencing for complex danger zones,
- better user role management,
- automated escalation workflows,
- stronger API security and validation,
- improved offline notification handling,
- support for additional emergency categories and reporting modules.

## License
This project is intended for academic, research, and collaborative development use within the scope of the FYP project.


