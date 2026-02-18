# Security Sentinel Memory

## Project: Dailve (iOS Health App)

### Architecture Notes
- Stack: Swift 6 / SwiftUI / HealthKit / SwiftData / CloudKit
- Data sync via CloudKit means bad data propagates to all devices
- WatchConnectivity used for iPhone <-> Watch communication
- HealthKit workout UUIDs stored as String in SwiftData models

### Confirmed Safe Patterns
- HealthKit BPM range validated (20-300 bpm) in HeartRateQueryService.validatedSample
- WorkoutDeleteService guards empty/invalid UUID before query
- ConfirmDeleteRecordModifier uses confirmation dialog before delete (correction #50)
- UUID parsing done via `UUID(uuidString:)` — safe, no string injection risk

### Recurring Patterns to Watch
- `errorMessage = error.localizedDescription` — can expose internal error details to UI (P3)
- `try? modelContext.save()` removed in this diff — was silently swallowing errors
- UserDefaults used for workout recovery state — low sensitivity data, acceptable
- `print()` debug calls in production code (WorkoutManager.swift lines 304, 316)

### Not Applicable to This Codebase
- SQL injection (no raw SQL, uses SwiftData/HealthKit)
- XSS (native iOS app, no WebView)
- CSRF (no web endpoints)
- Auth bypass (HealthKit permission model managed by OS)
