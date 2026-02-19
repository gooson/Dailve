---
topic: muscle-fatigue-10-levels
date: 2026-02-19
status: draft
confidence: high
related_solutions:
  - general/2026-02-17-exercise-visual-guide.md
  - performance/2026-02-15-healthkit-query-parallelization.md
  - security/2026-02-15-input-validation-swiftdata.md
  - security/2026-02-16-defensive-coding-patterns.md
related_brainstorms:
  - 2026-02-19-muscle-fatigue-10-levels.md
---

# Implementation Plan: 근육 피로도 10단계 세분화 시스템

## Context

현재 근육 회복 시스템의 한계:
- **3단계(Fatigued/Recovering/Ready)** + 선형 시간 감쇠만 존재
- `recoveryPercent = hoursSince / muscle.recoveryHours` — 볼륨 무시, 누적 없음
- 5km 러닝과 20km 러닝이 동일한 피로도
- 2일 연속 vs 10일 연속 같은 부위 훈련의 차이 없음
- 수면/HRV가 근육 회복에 미반영

업계 분석 결과, **근육별 피로 + 수면/HRV 통합**을 동시에 제공하는 앱은 없음 (Fitbod은 근육별이나 수면/HRV 미반영, WHOOP은 수면/HRV 반영하나 근육별 아님). 이 둘의 결합이 차별화 포인트.

## Requirements

### Functional

- F1: 각 근육의 피로도를 0~10 레벨로 계산 (0=데이터 없음, 1=완전 회복, 10=과훈련)
- F2: 운동 볼륨(세트×무게) + 유산소(거리/시간)을 부하로 반영
- F3: 14일간 운동 이력의 지수 감쇠 누적 (최근 운동일수록 높은 비중)
- F4: 수면 시간/질을 회복 속도 modifier로 반영 (0.55x~1.15x)
- F5: HRV z-score + RHR 변화를 readiness modifier로 반영 (0.70x~1.15x)
- F6: 근육맵에 10단계 색상 그라데이션 (Deep Green → Deep Red)
- F7: 인포 버튼으로 계산 과정 투명하게 설명 (운동 부하 + 수면 보정 + 생체 보정)
- F8: 기존 운동 추천 엔진이 새 피로도 활용
- F9: primary muscle은 1.0, secondary muscle은 0.4 engagement

### Non-functional

- NF1: 피로도 계산은 메인 스레드 차단 없이 async 수행
- NF2: 14일 × 13 근육 계산 결과 캐싱 (하루 1회 수면/HRV modifier 재계산)
- NF3: Dark/Light mode 모두에서 10단계 색상 명확히 구분
- NF4: 접근성: 색상 외에 숫자 레벨 + 텍스트 라벨 병행
- NF5: 데이터 부족 시 graceful degradation (수면 없으면 modifier=1.0)
- NF6: 모든 수학 함수에 NaN/Infinity 방어 (Correction #4, #18)

## Approach

**Compound Fatigue Score (CFS)** — 지수 감쇠 누적 피로 + modifier 기반 회복 조절

핵심 수식:
```
effectiveTau = baseTau × sleepModifier × readinessModifier
adjustedFatigue(muscle) = Σ sessionLoad(i) × e^(-hoursSince(i) / effectiveTau)
fatigueLevel = mapToLevel(normalizedFatigue)  // 0-10
```

선형 감쇠 대신 **지수 감쇠**를 선택한 이유:
- 초반 회복이 빠르고 후반이 느린 생리학적 현실 반영
- Banister 모델, TrainingPeaks CTL/ATL, WHOOP 등 업계 표준
- 누적이 자연스러움 (여러 세션의 잔여 피로가 합산)

modifier가 **감쇠 속도(tau)**를 조절하는 설계:
- 잘 자면 tau 감소 → 빠른 회복 (피로가 빨리 줄어듦)
- 못 자면 tau 증가 → 느린 회복 (피로가 오래 지속)
- HRV 높으면 tau 감소 → 신체가 잘 회복 중
- 직접 피로값을 가감하는 것보다 물리적으로 정확

### Alternative Approaches Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| 선형 감쇠 + 볼륨 (현재 확장) | 단순, 기존 코드 최소 변경 | 누적 피로 미반영, 비생리학적 | 기각 |
| TRIMP 기반 CTL/ATL/TSB | 업계 표준, 검증됨 | 전신 지표만 (근육별 X), HR 필수 | 부분 채택 (부하 계산에 참고) |
| Fitbod 스타일 볼륨 기반 | 근육별, 직관적 | 수면/HRV 미반영, 시간 가중 없음 | 부분 채택 (볼륨 개념) |
| **지수 감쇠 + modifier (채택)** | 근육별+전신 통합, 누적, 수면/HRV 반영 | 구현 복잡도, 파라미터 튜닝 필요 | **채택** |

## Affected Files

### Domain Layer (New)

| File | Change Type | Description |
|------|-------------|-------------|
| `Domain/Models/FatigueLevel.swift` | **New** | 10단계 enum + 라벨 + 범위 정의 |
| `Domain/Models/CompoundFatigueScore.swift` | **New** | 근육별 CFS 모델 (level, rawScore, breakdown) |
| `Domain/Models/FatigueBreakdown.swift` | **New** | 인포 버튼용 계산 상세 (workoutContributions, sleepModifier, readinessModifier) |
| `Domain/UseCases/FatigueCalculationService.swift` | **New** | CFS 계산 엔진 (지수 감쇠 + 정규화) |
| `Domain/UseCases/RecoveryModifierService.swift` | **New** | 수면 + HRV/RHR → modifier 계산 |

### Domain Layer (Modified)

| File | Change Type | Description |
|------|-------------|-------------|
| `Domain/Models/MuscleFatigueState.swift` | **Modify** | `fatigueLevel: FatigueLevel`, `compoundScore: CompoundFatigueScore?` 추가 |
| `Domain/UseCases/WorkoutRecommendationService.swift` | **Modify** | `computeFatigueStates()` → CFS 기반으로 교체, 추천 threshold 조정 |
| `Domain/UseCases/WorkoutRecommendationService.swift` | **Modify** | `ExerciseRecordSnapshot`에 `weight`, `reps`, `duration`, `distance` 필드 추가 |

### Data Layer (Modified)

| File | Change Type | Description |
|------|-------------|-------------|
| `Data/HealthKit/SleepQueryService.swift` | **Modify** | `fetchLastNightSleepSummary()` 메서드 추가 (시간+질 요약) |

### Presentation Layer (New)

| File | Change Type | Description |
|------|-------------|-------------|
| `Presentation/Shared/Extensions/FatigueLevel+View.swift` | **New** | 10단계 색상, 아이콘, displayName 매핑 |
| `Presentation/Activity/Components/FatigueInfoSheet.swift` | **New** | 인포 버튼 계산 설명 시트 |
| `Presentation/Activity/Components/FatigueLegendView.swift` | **New** | 10단계 범례 뷰 |

### Presentation Layer (Modified)

| File | Change Type | Description |
|------|-------------|-------------|
| `Presentation/Activity/Components/MuscleRecoveryMapView.swift` | **Modify** | `recoveryColor()` → 10단계 색상, 범례 교체 |
| `Presentation/Activity/Components/MuscleDetailPopover.swift` | **Modify** | 배지 10단계 + 인포 버튼 추가 |
| `Presentation/Activity/ActivityViewModel.swift` | **Modify** | SleepQuerying + HRVQuerying 주입, modifier 계산 통합 |

### Tests (New)

| File | Change Type | Description |
|------|-------------|-------------|
| `DailveTests/FatigueCalculationServiceTests.swift` | **New** | 지수 감쇠, 누적, 정규화, 경계값 |
| `DailveTests/RecoveryModifierServiceTests.swift` | **New** | 수면/HRV modifier 계산, fallback |
| `DailveTests/FatigueLevelTests.swift` | **New** | 레벨 매핑, 색상, 라벨 |

## Implementation Steps

### Step 1: Domain 모델 정의

- **Files**: `FatigueLevel.swift`, `CompoundFatigueScore.swift`, `FatigueBreakdown.swift`
- **Changes**:

```swift
// FatigueLevel.swift
enum FatigueLevel: Int, Sendable, CaseIterable, Comparable {
    case noData = 0
    case fullyRecovered = 1   // 0.00-0.05
    case wellRested = 2       // 0.05-0.15
    case lightFatigue = 3     // 0.15-0.25
    case mildFatigue = 4      // 0.25-0.35
    case moderateFatigue = 5  // 0.35-0.50
    case notableFatigue = 6   // 0.50-0.65
    case highFatigue = 7      // 0.65-0.75
    case veryHighFatigue = 8  // 0.75-0.85
    case extremeFatigue = 9   // 0.85-0.95
    case overtrained = 10     // 0.95-1.00

    static func from(normalizedScore: Double) -> FatigueLevel { ... }
    var recommendation: String { ... } // 영어 (Domain)
}

// CompoundFatigueScore.swift
struct CompoundFatigueScore: Sendable {
    let muscle: MuscleGroup
    let normalizedScore: Double   // 0.0 (fully recovered) ~ 1.0 (overtrained)
    let level: FatigueLevel
    let breakdown: FatigueBreakdown
}

// FatigueBreakdown.swift
struct FatigueBreakdown: Sendable {
    let workoutContributions: [WorkoutContribution]  // 각 세션의 기여도
    let baseFatigue: Double          // modifier 적용 전 누적 피로
    let sleepModifier: Double        // 0.55~1.15
    let readinessModifier: Double    // 0.70~1.15
    let effectiveTau: Double         // 최종 감쇠 시간 상수

    struct WorkoutContribution: Sendable {
        let date: Date
        let exerciseName: String?
        let rawLoad: Double          // 원본 부하
        let decayedLoad: Double      // 감쇠 후 잔여 부하
    }
}
```

- **Verification**: `FatigueLevelTests.swift` — 모든 경계값에서 올바른 레벨 매핑 확인

### Step 2: ExerciseRecordSnapshot 확장

- **Files**: `WorkoutRecommendationService.swift` (ExerciseRecordSnapshot 정의)
- **Changes**:

```swift
struct ExerciseRecordSnapshot: Sendable {
    let date: Date
    let exerciseDefinitionID: String?
    let exerciseName: String?        // NEW: 인포 시트 표시용
    let primaryMuscles: [MuscleGroup]
    let secondaryMuscles: [MuscleGroup]
    let completedSetCount: Int
    let totalWeight: Double?         // NEW: kg, nil이면 bodyweight
    let totalReps: Int?              // NEW: 전체 rep 수
    let durationMinutes: Double?     // NEW: 유산소 시간
    let distanceKm: Double?          // NEW: 유산소 거리
}
```

- **Verification**: 기존 snapshot 생성 코드가 새 필드를 올바르게 채우는지 확인. HealthKit 외부 운동은 `durationMinutes`만 제공.

### Step 3: FatigueCalculationService 구현

- **Files**: `Domain/UseCases/FatigueCalculationService.swift`
- **Changes**:

```swift
protocol FatigueCalculating: Sendable {
    func computeCompoundFatigue(
        for muscles: [MuscleGroup],
        from records: [ExerciseRecordSnapshot],
        sleepModifier: Double,
        readinessModifier: Double,
        referenceDate: Date
    ) -> [CompoundFatigueScore]
}

final class FatigueCalculationService: FatigueCalculating, Sendable {
    private let lookbackDays: Int = 14

    func computeCompoundFatigue(...) -> [CompoundFatigueScore] {
        // 1. 각 근육에 대해
        // 2. lookbackDays 이내의 records 필터
        // 3. 각 record의 sessionLoad 계산:
        //    - 근력: (sets × reps × weight) / referenceWeight(80kg 기본) × engagement
        //    - 유산소: (distanceKm × durationMinutes / 60) × engagement
        //    - fallback: sets × engagement
        // 4. effectiveTau = muscle.recoveryHours × 2.0 / (sleepModifier × readinessModifier)
        //    (modifier가 높을수록 tau 감소 = 빠른 회복)
        // 5. decayedLoad = sessionLoad × exp(-hoursSince / effectiveTau)
        //    guard decayedLoad.isFinite else { continue }
        // 6. totalFatigue = Σ decayedLoad
        // 7. normalize: min(totalFatigue / saturationThreshold, 1.0)
        //    saturationThreshold = muscle별 상수 (large=15, medium=12, small=10)
        // 8. FatigueLevel.from(normalizedScore:)
    }

    // sessionLoad 계산 - 순수 함수
    func calculateSessionLoad(
        record: ExerciseRecordSnapshot,
        muscle: MuscleGroup,
        referenceBodyWeight: Double
    ) -> Double { ... }
}
```

핵심 수학:
- `exp(-h / tau)`: h=0이면 1.0(방금), h=tau이면 ~0.37, h=2tau이면 ~0.14
- `tau = recoveryHours × 2 / combinedModifier`: modifier 1.15×1.15=1.32 → tau 66% → 빠른 회복
- `saturationThreshold`: 14일 동안 매일 운동해도 Level 10에 도달하기 위한 누적량

- **Verification**: `FatigueCalculationServiceTests.swift`
  - 단일 운동 후 시간별 감쇠 곡선
  - 2일 연속 vs 10일 연속 누적 차이
  - 수면 modifier가 감쇠 속도에 미치는 영향
  - 유산소 vs 근력 부하 차이
  - 경계값: 0시간, 14일 초과, weight=0, distance=0
  - NaN/Infinity 방어: tau=0, sessionLoad=극대값

### Step 4: RecoveryModifierService 구현

- **Files**: `Domain/UseCases/RecoveryModifierService.swift`
- **Changes**:

```swift
protocol RecoveryModifying: Sendable {
    func calculateSleepModifier(
        totalSleepMinutes: Double?,
        deepSleepRatio: Double?,
        remSleepRatio: Double?
    ) -> Double

    func calculateReadinessModifier(
        hrvZScore: Double?,
        rhrDelta: Double?
    ) -> Double
}

final class RecoveryModifierService: RecoveryModifying, Sendable {
    func calculateSleepModifier(...) -> Double {
        guard let minutes = totalSleepMinutes else { return 1.0 }
        let hours = minutes / 60.0
        guard hours.isFinite, hours >= 0 else { return 1.0 }

        let baseFactor: Double
        switch hours {
        case 8...: baseFactor = 1.15
        case 7..<8: baseFactor = 1.0
        case 6..<7: baseFactor = 0.85
        case 5..<6: baseFactor = 0.70
        default: baseFactor = 0.55
        }

        var qualityBonus = 0.0
        if let deep = deepSleepRatio, deep.isFinite {
            qualityBonus += deep >= 0.20 ? 0.05 : (deep < 0.10 ? -0.05 : 0)
        }
        if let rem = remSleepRatio, rem.isFinite {
            qualityBonus += rem >= 0.20 ? 0.05 : (rem < 0.10 ? -0.05 : 0)
        }

        return max(0.5, min(baseFactor + qualityBonus, 1.25))
    }

    func calculateReadinessModifier(...) -> Double {
        // HRV z-score 없으면 1.0
        // RHR delta 없으면 1.0
        // 둘 다 있으면 조합
        guard let z = hrvZScore, z.isFinite else { return 1.0 }

        var modifier: Double
        switch z {
        case 1.0...: modifier = 1.15
        case 0..<1.0: modifier = 1.05
        case -0.5..<0: modifier = 1.0
        case -1.0..<(-0.5): modifier = 0.85
        default: modifier = 0.70
        }

        if let delta = rhrDelta, delta.isFinite {
            if delta >= 5 { modifier = min(modifier, 0.75) }
            else if delta <= -2 { modifier = min(modifier + 0.05, 1.20) }
        }

        return max(0.6, min(modifier, 1.20))
    }
}
```

- **Verification**: `RecoveryModifierServiceTests.swift`
  - 수면 nil → 1.0
  - 수면 8h + 양호한 질 → ~1.20
  - 수면 4h + 나쁜 질 → ~0.50
  - HRV z=+2, RHR delta=-3 → ~1.20
  - HRV z=-2, RHR delta=+8 → ~0.65
  - NaN/Infinity 입력 → 1.0 fallback

### Step 5: SleepQueryService 확장

- **Files**: `Data/HealthKit/SleepQueryService.swift`
- **Changes**: `SleepQuerying` 프로토콜에 메서드 추가

```swift
// Protocol
func fetchLastNightSleepSummary(
    for date: Date
) async throws -> SleepSummary?

// Model (HealthMetric.swift에 추가)
struct SleepSummary: Sendable {
    let totalSleepMinutes: Double
    let deepSleepRatio: Double   // 0.0~1.0
    let remSleepRatio: Double    // 0.0~1.0
    let date: Date
}
```

기존 `fetchDailySleepDurations(start:end:)`의 결과를 단일 날짜용으로 래핑. 새 쿼리 로직 불필요.

- **Verification**: 기존 `SleepQueryService` 테스트에 `fetchLastNightSleepSummary` 추가

### Step 6: MuscleFatigueState 확장 + WorkoutRecommendationService 교체

- **Files**: `MuscleFatigueState.swift`, `WorkoutRecommendationService.swift`
- **Changes**:

`MuscleFatigueState` 확장:
```swift
struct MuscleFatigueState: Sendable {
    let muscle: MuscleGroup
    let lastTrainedDate: Date?
    let hoursSinceLastTrained: Double?
    let weeklyVolume: Int
    let recoveryPercent: Double           // 기존 유지 (하위 호환)
    let compoundScore: CompoundFatigueScore?  // NEW

    // 새 피로도 기반 computed properties
    var fatigueLevel: FatigueLevel {
        compoundScore?.level ?? (lastTrainedDate == nil ? .noData : FatigueLevel.from(normalizedScore: 1.0 - recoveryPercent))
    }
    var isRecovered: Bool { fatigueLevel.rawValue <= 3 }         // Level 1-3
    var isOverworked: Bool { fatigueLevel.rawValue >= 8 }        // Level 8-10
}
```

`WorkoutRecommendationService.computeFatigueStates()` 교체:
- `FatigueCalculationService` + `RecoveryModifierService` 주입
- 기존 선형 `recoveryPercent`도 유지 (하위 호환, 점진 마이그레이션)
- 추천 threshold를 `fatigueLevel` 기반으로 조정: `isRecovered`=Level 1-3, 추천 가능

- **Verification**: 기존 `WorkoutRecommendationServiceTests` 업데이트 + 새 CFS 기반 추천 검증

### Step 7: ActivityViewModel 통합

- **Files**: `Presentation/Activity/ActivityViewModel.swift`
- **Changes**:
  - `SleepQuerying` 주입 추가
  - `recomputeFatigueAndSuggestion()`에서:
    1. `async let` 으로 수면 데이터 + HRV z-score + RHR delta 병렬 fetch
    2. `RecoveryModifierService`로 sleepModifier + readinessModifier 계산
    3. `FatigueCalculationService`에 modifier 전달
  - `fatigueStates: [MuscleFatigueState]`는 기존 타입 유지 (내부에 `compoundScore` 추가)

- **Verification**: 빌드 + 기존 Activity 탭 동작 확인

### Step 8: Presentation — 10단계 색상 + 범례

- **Files**: `FatigueLevel+View.swift`, `MuscleRecoveryMapView.swift`, `FatigueLegendView.swift`
- **Changes**:

`FatigueLevel+View.swift` (Presentation/Shared/Extensions/):
```swift
extension FatigueLevel {
    var displayName: String { ... }  // 한국어 라벨
    var shortLabel: String { ... }   // "L1"~"L10"

    func color(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .noData: return .secondary.opacity(0.2)
        case .fullyRecovered: return Color(hue: 0.39, saturation: 0.70, brightness: colorScheme == .dark ? 0.90 : 0.50)
        case .wellRested: return Color(hue: 0.36, saturation: 0.60, brightness: colorScheme == .dark ? 0.90 : 0.60)
        case .lightFatigue: return Color(hue: 0.31, saturation: 0.55, brightness: colorScheme == .dark ? 0.90 : 0.70)
        case .mildFatigue: return Color(hue: 0.22, saturation: 0.55, brightness: colorScheme == .dark ? 0.90 : 0.75)
        case .moderateFatigue: return Color(hue: 0.15, saturation: 0.65, brightness: colorScheme == .dark ? 0.90 : 0.80)
        case .notableFatigue: return Color(hue: 0.11, saturation: 0.70, brightness: colorScheme == .dark ? 0.88 : 0.80)
        case .highFatigue: return Color(hue: 0.07, saturation: 0.75, brightness: colorScheme == .dark ? 0.85 : 0.78)
        case .veryHighFatigue: return Color(hue: 0.04, saturation: 0.80, brightness: colorScheme == .dark ? 0.82 : 0.72)
        case .extremeFatigue: return Color(hue: 0.01, saturation: 0.82, brightness: colorScheme == .dark ? 0.78 : 0.65)
        case .overtrained: return Color(hue: 0.00, saturation: 0.90, brightness: colorScheme == .dark ? 0.70 : 0.50)
        }
    }
}
```

`MuscleRecoveryMapView` — `recoveryColor(for:)` 교체:
```swift
private func recoveryColor(for state: MuscleFatigueState?) -> Color {
    guard let state else { return FatigueLevel.noData.color(for: colorScheme) }
    return state.fatigueLevel.color(for: colorScheme)
}
```

`FatigueLegendView` — 10단계 가로 그라데이션 바 + 주요 라벨:
```
■■■■■■■■■■
1        10
회복  →  과훈련
```

- **Verification**: Preview에서 10색상 Dark/Light mode 시각 확인

### Step 9: MuscleDetailPopover 업데이트

- **Files**: `MuscleDetailPopover.swift`
- **Changes**:
  - 배지: `fatigueLevel.displayName` + `fatigueLevel.color(for:)`
  - 인포 버튼 (ⓘ) 추가 → `FatigueInfoSheet` 표시
  - Stats grid에 "피로 레벨" 행 추가

- **Verification**: 팝오버에서 10단계 배지 + 인포 버튼 동작 확인

### Step 10: FatigueInfoSheet 구현

- **Files**: `Presentation/Activity/Components/FatigueInfoSheet.swift`
- **Changes**:

```
┌─────────────────────────────────────┐
│  ⓘ 피로도 계산 방법                    │
│                                     │
│  [근육 이름] Level N (점수)            │
│                                     │
│  📊 운동 부하 (14일)                   │
│  ├ 날짜 운동명 → 원본부하 → 잔여부하    │
│  └ ...                              │
│  소계: X.XX                          │
│                                     │
│  😴 수면 보정: ×modifier              │
│  ├ 수면 시간: Xh (양호/부족)           │
│  └ 깊은수면/REM: XX%                  │
│                                     │
│  ❤️ 생체 보정: ×modifier              │
│  ├ HRV: Xms (기준선 대비 ↑/↓)        │
│  └ RHR: Xbpm (어제 대비 ↑/↓)         │
│                                     │
│  ═══════════════════════════════     │
│  최종: X.XX → Level N                │
│                                     │
│  [10단계 범례 바]                      │
└─────────────────────────────────────┘
```

`FatigueBreakdown` 데이터를 그대로 렌더링. 데이터 없는 섹션은 "미수집" 표시.

- **Verification**: 다양한 시나리오의 인포 시트 렌더링 확인

### Step 11: 테스트 작성

- **Files**: 3개 테스트 파일
- **Changes**:

`FatigueCalculationServiceTests.swift`:
- 단일 운동 후 0h, 24h, 48h, 72h, 168h 감쇠
- 2일 연속 / 5일 연속 / 10일 연속 동일 부위 누적
- primary(1.0) vs secondary(0.4) engagement 차이
- 유산소(거리 기반) vs 근력(볼륨 기반) 부하
- sleepModifier 1.15 vs 0.55에 따른 회복 속도 차이
- readinessModifier 1.15 vs 0.70에 따른 차이
- 경계값: weight=0, reps=0, distance=0, duration=0
- NaN/Infinity 방어: exp() 입력 극값, tau=0 방어
- saturationThreshold 도달 (Level 10)
- 14일 초과 데이터 무시 확인

`RecoveryModifierServiceTests.swift`:
- 수면 nil → 1.0
- 수면 8h+양호질 → ~1.20
- 수면 4h+나쁜질 → ~0.50
- HRV z=+2 → ~1.15
- HRV z=-2 → ~0.70
- RHR delta=+8 → 하한 제약
- 모든 nil → 1.0
- NaN/Infinity → 1.0

`FatigueLevelTests.swift`:
- 0.0 → Level 1
- 0.05 경계 → Level 1 vs 2
- 0.95 → Level 10
- 1.0 → Level 10
- -0.1 → Level 1 (clamp)
- 1.5 → Level 10 (clamp)

- **Verification**: `xcodebuild test -project Dailve/Dailve.xcodeproj -scheme DailveTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.2' -only-testing DailveTests`

### Step 12: xcodegen + 빌드 검증

- **Files**: `Dailve/project.yml`
- **Changes**: 없음 (xcodegen이 자동으로 새 파일 감지)
- **Verification**: `cd Dailve && xcodegen generate && xcodebuild build ...`

## Edge Cases

| Case | Handling |
|------|----------|
| 첫 사용자 (운동 이력 없음) | Level 0 (noData), 모든 근육 Gray |
| 수면 데이터 없음 (Watch 미착용) | sleepModifier = 1.0, 인포에 "수면 미수집" 표시 |
| HRV 없음 (측정 안 됨) | readinessModifier = 1.0, 인포에 "HRV 미측정" 표시 |
| 14일+ 전 운동만 있음 | 지수 감쇠 → 0에 수렴 → Level 1 (완전 회복) |
| 극단적 운동량 (하루 50세트) | saturationThreshold로 1.0 상한 → Level 10 |
| HealthKit 외부 운동 (세트/무게 없음) | duration 기반 fallback 부하, 활동 유형별 기본 engagement |
| weight=0 (bodyweight 운동) | `max(weight, defaultBodyWeight)` fallback |
| 수면 0분 (데이터 오류) | `max(minutes, 0)`, modifier 최하한 0.50 |
| exp() 결과 NaN/Infinity | `guard result.isFinite else { continue }` |
| tau=0 (modifier 극값) | `max(effectiveTau, 1.0)` clamp |
| 시간대 변경 (해외여행) | UTC 기반 `hoursSince` 계산 |

## Testing Strategy

- **Unit tests**: `FatigueCalculationServiceTests`, `RecoveryModifierServiceTests`, `FatigueLevelTests` — 모든 경계값, 수학 방어, 시나리오 커버
- **Integration tests**: `WorkoutRecommendationServiceTests` 업데이트 — CFS 기반 추천이 기존 동작과 호환
- **Manual verification**:
  1. 운동 기록 → 근육맵 색상 변화 확인
  2. 연속 훈련 시 누적 피로 증가 시각 확인
  3. 인포 버튼 → 계산 상세 표시 확인
  4. Dark/Light mode에서 10색상 구분 확인
  5. 수면 데이터 유무에 따른 modifier 변화 확인

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| saturationThreshold 파라미터 튜닝 부정확 | Medium | Medium | 실제 운동 데이터로 A/B 테스트, 조정 가능한 상수로 분리 |
| 10단계 색상이 시각적으로 구분 안 됨 | Low | High | HSB 기반 그라데이션 + Preview 테스트, 숫자 라벨 병행 |
| 지수 감쇠 계산 성능 (14일 × 13근육 × N세션) | Low | Low | 캐싱 + 하루 1회 modifier 재계산으로 해결 |
| ExerciseRecordSnapshot 확장의 하위 호환 | Medium | Medium | 새 필드 모두 Optional, 기존 생성 코드에 nil 기본값 |
| 수면/HRV 데이터 불일치 (다른 시간대) | Low | Low | UTC 기준 통일, `lastNight` 쿼리로 정확한 수면 윈도우 사용 |

## Confidence Assessment

- **Overall**: High
- **Reasoning**:
  - 기존 `SleepQueryService`, `CalculateConditionScoreUseCase`, `TrainingLoadService`의 인프라가 이미 존재
  - 지수 감쇠 모델은 업계 표준 (Banister, TrainingPeaks)으로 검증됨
  - `MuscleRecoveryMapView`의 색상 매핑만 교체하면 시각적 변화 즉시 반영
  - 새 필드는 모두 Optional → 하위 호환 보장
  - 수면/HRV 없을 때 modifier=1.0 fallback → 기존 동작과 동일
