---
tags: [fatigue, muscle-recovery, exponential-decay, exercise-science, 10-level, compound-score, recovery-modifier]
category: architecture
date: 2026-02-19
severity: important
related_files:
  - Dailve/Domain/UseCases/FatigueCalculationService.swift
  - Dailve/Domain/UseCases/RecoveryModifierService.swift
  - Dailve/Domain/Models/FatigueLevel.swift
  - Dailve/Domain/Models/CompoundFatigueScore.swift
  - Dailve/Domain/Models/MuscleFatigueState.swift
  - Dailve/Presentation/Activity/ActivityViewModel.swift
related_solutions:
  - security/2026-02-16-defensive-coding-patterns.md
  - performance/2026-02-19-swiftui-color-static-caching.md
---

# Solution: Exponential Decay Muscle Fatigue Model (10-Level)

## Problem

### Symptoms

- Previous fatigue system was binary (fatigued/recovered) with no granularity
- Users couldn't distinguish "slightly sore" from "overtrained"
- No consideration of cumulative training load, sleep quality, or HRV readiness
- Muscle recovery map showed only 2 colors

### Root Cause

The original system lacked a mathematical model for fatigue decay over time. It needed a continuous score that accounts for: workout recency (exponential decay), volume/intensity (session load), cumulative multi-day training, muscle-specific recovery rates, and biometric recovery modifiers.

## Solution

### Architecture

```
ExerciseRecordSnapshot (DTO)
    ↓
FatigueCalculationService (Domain)
    - sessionLoad(from:) → Double
    - computeCompoundFatigue(for:from:sleepModifier:readinessModifier:) → [CompoundFatigueScore]
    ↓
CompoundFatigueScore → FatigueLevel (0..10)
    ↓
RecoveryModifierService (Domain)
    - calculateSleepModifier(totalSleep:deep:rem:) → 0.5...1.25
    - calculateReadinessModifier(hrvZScore:rhrDelta:) → 0.6...1.20
    ↓
ActivityViewModel (Presentation)
    - merges SwiftData + HealthKit snapshots
    - feeds to WorkoutRecommendationService
```

### Key Design Decisions

1. **Exponential decay**: `contribution = sessionLoad × engagement × e^(-hoursAgo/tau)`. Recent workouts dominate; old ones decay naturally. τ (tau) = base recovery hours × biometric modifiers.

2. **10-level enum (not continuous)**: Users need discrete labels ("가벼운 피로", "극심한 피로"), not floating-point scores. `FatigueLevel.from(normalizedScore:)` maps 0.0-1.0 to 11 cases (noData + 10 levels).

3. **Muscle-specific thresholds**: Large muscles (quads, lats) have higher saturation thresholds than small muscles (biceps, forearms). `saturationThreshold` varies by muscle group.

4. **ExerciseRecordSnapshot as Sendable DTO**: Bridges SwiftData `ExerciseRecord` (non-Sendable, @Model) and HealthKit `WorkoutSummary` into a single Sendable struct for the Domain layer.

5. **Recovery modifiers are multiplicative on tau**: Better sleep/HRV increases tau → faster decay → lower fatigue score. Sleep modifier 0.5-1.25, readiness modifier 0.6-1.20.

### Session Load Strategies

| Data Available | Formula | Example |
|---|---|---|
| Weight + Reps | `totalWeight × totalReps / bodyWeight / 100` | 100kg × 25 reps / 70kg / 100 = 0.357 |
| Distance + Duration | `distanceKm × sqrt(durationHours) / 10` | 5km × sqrt(0.5h) / 10 = 0.354 |
| Duration only | `durationMinutes / 60` | 30min / 60 = 0.50 |
| Sets only (fallback) | `setCount × 0.1` | 10 sets × 0.1 = 1.0 |

### Input Validation (Review Fixes)

| Parameter | Bound | Rationale |
|---|---|---|
| totalSleepMinutes | ≤ 1440 | 24 hours max |
| deepSleepRatio | ≤ 1.0 | Physical maximum |
| remSleepRatio | ≤ 1.0 | Physical maximum |
| HRV samples | ≤ 500ms | Sensor range |
| Snapshot totalWeight | ≤ 50,000 | Aggregate session cap |
| Snapshot totalReps | ≤ 10,000 | Aggregate session cap |
| Snapshot duration | ≤ 480min | 8 hours max |
| Snapshot distance | ≤ 500km | Correction #79 |

### Changes Made

| File | Change | Reason |
|------|--------|--------|
| `FatigueLevel.swift` | New 10-level enum with mapping | Granular fatigue representation |
| `CompoundFatigueScore.swift` | Score model with breakdown | Transparency for debugging/UI |
| `FatigueCalculationService.swift` | Exponential decay calculation | Core algorithm |
| `RecoveryModifierService.swift` | Sleep + HRV/RHR modifiers | Biometric recovery adjustment |
| `ActivityViewModel.swift` | Merge SwiftData + HK snapshots | Unified fatigue input |
| `SleepQueryService.swift` | Sleep summary for modifiers | Feed recovery data |
| `FatigueLevel+View.swift` | 10-color gradient with caching | Visual representation |
| `FatigueAlgorithmSheet.swift` | Algorithm explanation UI | User transparency |

## Prevention

### Checklist Addition

- [ ] New fatigue level added? → Update `FatigueLevel`, `FatigueLevel+View.swift` (ColorCache specs array), `FatigueLevelTests`, `FatigueAlgorithmSheet`
- [ ] New muscle group? → Add to `MuscleGroup.saturationThreshold`, muscle map SVG data
- [ ] Session load formula change? → Update `FatigueCalculationServiceTests` boundary values

## Lessons Learned

- **Sendable DTO bridges SwiftData and Domain**: `@Model` classes are non-Sendable. Creating a lightweight `ExerciseRecordSnapshot` struct lets Domain services work with pure data without importing SwiftData
- **Exponential decay is naturally forgiving**: Unlike linear models, exponential decay means a single intense workout fades quickly while sustained overtraining accumulates — matching actual physiology
- **10 levels is the sweet spot**: Fewer levels (3-5) can't distinguish moderate from high fatigue. More levels (20+) exceed human ability to act on distinctions. 10 levels map well to a green-red color spectrum
- **Recovery modifiers on tau (not score)**: Modifying the decay constant rather than the final score preserves the exponential shape. Modifying the score directly would create discontinuities
