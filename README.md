# proyetomobile2

A Flutter project for route navigation using GPS and local SQLite storage.

## Project Structure (MVVM)

```
lib/
├── core/
│   └── database/          # DB infrastructure (AppDatabase, bootstrap, constants)
│       └── migrations/    # Schema migrations
├── models/                # Data classes (AppRoutingSettings, …)
├── repositories/          # Data-access layer (AppSettingsRepository, …)
├── services/              # External services (GpsService, RouteCostCalculator)
├── viewmodels/            # Business logic / state management
├── views/                 # UI screens and widgets
│   ├── app.dart           # Root MaterialApp widget
│   └── home/
│       └── home_screen.dart  # Home screen
└── main.dart              # Entry point
```

## Features (initial commit `27e0224`)

- **GPS service** via `geolocator` plugin (`lib/services/gps_service.dart`)
- **Local SQLite database** with migrations, bootstrap, and settings repository (`lib/core/database/`)
- **Route cost calculator** (`lib/services/route_cost_calculator.dart`)
- **Full Flutter multi-platform scaffold** (Android, iOS, Web, Linux, macOS, Windows) with geolocator permissions wired into `AndroidManifest.xml`
