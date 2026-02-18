---
topic: enhanced-workout-display
date: 2026-02-19
status: draft
confidence: high
related_solutions:
  - healthkit/healthkit-deduplication-best-practices
  - architecture/2026-02-18-healthkit-dedup-implementation
  - general/2026-02-17-chart-ux-layout-stability
  - performance/2026-02-15-healthkit-query-parallelization
related_brainstorms:
  - 2026-02-19-enhanced-workout-display
---

# Implementation Plan: Enhanced Workout Display & Training Intelligence

## Context

현재 HealthKit 외부 운동이 "Running, 32분, 245kcal" 수준으로만 표시되며, 상세뷰도 없고, 특별한 성취(마일스톤/PR)도 강조되지 않는다. HealthKit에는 심박수, 페이스, 고도, 날씨, Effort Score 등 풍부한 데이터가 있지만 활용되지 않고 있다.

4가지 기능을 MVP 범위로 구현한다:
1. **Rich Workout Display** — HealthKit 외부 운동의 리스트 강화 + 전용 상세뷰
2. **Milestone & PR Badges** — 5K/10K 마일스톤 + 개인기록 골드 하이라이트
3. **RPE + Effort Score** — 운동 강도 수동 입력 + Apple 자동 Effort 표시
4. **Training Load** — 자체 계산 기반 7일/28일 훈련량 차트

## Requirements

### Functional

- HKWorkoutActivityType 80+ 전체를 아이콘 + 한국어 이름 + 컬러로 매핑
- 외부 HealthKit 워크아웃 탭 시 전용 상세뷰로 이동 (HR 차트, 페이스, 고도, 날씨)
- 리스트 row에 운동별 아이콘/컬러 + 핵심 지표 1-2개 표시
- 5K/10K/하프마라톤/풀마라톤 완주 시 마일스톤 뱃지
- 역대 최고 기록 경신 시 PR 뱃지 + 골드 강조
- 운동 완료 후 RPE(1-10) 입력 UI
- Apple Estimated Workout Effort Score 자동 읽기 + 표시
- 7일/28일 Training Load 차트 (Effort Score 또는 TRIMP 기반)

### Non-functional

- Domain에 HealthKit/SwiftUI import 금지 (기존 레이어 규칙 준수)
- 리스트 표시용 데이터는 batch fetch, 상세 데이터는 lazy load
- PR 계산은 캐시 사용 (매번 전체 히스토리 스캔 X)
- 기존 `ExerciseView`, `ExerciseListSection` 의 시각 언어 유지

## Approach

**4단계 순차 구현**: F1 → F2 → F3 → F4

F1이 데이터 인프라(`WorkoutSummary` 확장, HKWorkoutActivityType 매핑)를 깔고, F2가 뱃지 시스템을 얹고, F3이 RPE/Effort 입력을 추가하고, F4가 전체를 종합해 Training Load를 계산한다.

### Alternative Approaches Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| `WorkoutSummary` 확장 | 기존 타입 재사용, 변경 최소 | 프로퍼티가 많아짐 | **채택** — lazy fetch로 상세 데이터는 nil 유지 가능 |
| 새 `WorkoutDetail` 타입 | 관심사 분리 | 기존 코드 대량 수정, 이중 fetch | 미채택 |
| PR을 SwiftData에 저장 | 쿼리 용이 | 스키마 추가, CloudKit 고려 | 미채택 — UserDefaults 캐시로 충분 |
| PR을 UserDefaults에 캐시 | 간단, 스키마 변경 없음 | 대량 데이터 부적합 | **채택** — PR은 운동 타입별 소수 |
| Training Load를 HealthKit 기반만 | 자동, 정확 | Effort Score iOS 18+, 일부 운동 누락 | 미채택 |
| Training Load 하이브리드 | Effort 우선, HR fallback, 수동 RPE 최후방 | 복잡 | **채택** — 데이터 가용성에 따라 최선 |

## Affected Files

### 신규 파일

| File | Description |
|------|-------------|
| `Domain/Models/WorkoutActivityType.swift` | 80+ HKWorkoutActivityType에 대응하는 Domain enum |
| `Domain/Models/PersonalRecord.swift` | PR 데이터 모델 (타입, 값, 날짜, 운동ID) |
| `Domain/Models/TrainingLoad.swift` | Training Load 데이터 모델 |
| `Domain/Services/PersonalRecordService.swift` | PR 감지 로직 (히스토리 비교) |
| `Domain/Services/TrainingLoadService.swift` | Training Load 계산 로직 |
| `Data/HealthKit/WorkoutDetailQueryService.swift` | HKWorkout 상세 데이터 fetch (HR stats, pace, elevation, weather, effort) |
| `Data/HealthKit/EffortScoreService.swift` | Workout Effort Score 읽기/쓰기 |
| `Data/HealthKit/WorkoutActivityType+HealthKit.swift` | Domain enum ↔ HKWorkoutActivityType 매핑 |
| `Data/Persistence/PersonalRecordStore.swift` | PR 캐시 (UserDefaults) |
| `Presentation/Shared/Extensions/WorkoutActivityType+View.swift` | SF Symbol + 한국어 이름 + 컬러 |
| `Presentation/Exercise/HealthKitWorkoutDetailView.swift` | 외부 HK 운동 상세뷰 |
| `Presentation/Exercise/HealthKitWorkoutDetailViewModel.swift` | 상세뷰 데이터 로딩 |
| `Presentation/Exercise/Components/WorkoutBadgeView.swift` | 마일스톤/PR 뱃지 컴포넌트 |
| `Presentation/Exercise/Components/RPEInputView.swift` | RPE 입력 슬라이더/이모지 |
| `Presentation/Exercise/Components/TrainingLoadChartView.swift` | 7일/28일 Training Load 차트 |

### 수정 파일

| File | Change Type | Description |
|------|-------------|-------------|
| `Domain/Models/HealthMetric.swift` | Modify | `WorkoutSummary` 에 HR/pace/elevation/weather/effort/milestone/PR 필드 추가 |
| `Data/HealthKit/WorkoutQueryService.swift` | Modify | `toSummary()`에서 추가 statistics + metadata 추출, activity type 전체 매핑 |
| `Data/HealthKit/HealthKitManager.swift` | Modify | `typesToRead`에 effort score, speed 등 추가 |
| `Data/Persistence/Models/ExerciseRecord.swift` | Modify | `rpe: Int?` 필드 추가 |
| `Presentation/Exercise/ExerciseView.swift` | Modify | 외부 HK 운동 row에 NavigationLink + 뱃지 추가 |
| `Presentation/Exercise/ExerciseViewModel.swift` | Modify | PR/마일스톤 플래그 부여 로직 |
| `Presentation/Activity/Components/ExerciseListSection.swift` | Modify | 외부 HK row에 NavigationLink + 뱃지 추가 |
| `Presentation/Exercise/WorkoutSessionView.swift` | Modify | 운동 완료 시 RPE 입력 UI 추가 |
| `Presentation/Exercise/WorkoutSessionViewModel.swift` | Modify | RPE 저장 + Effort Score 쓰기 |
| `Presentation/Activity/ActivityView.swift` | Modify | Training Load 차트 섹션 추가 |
| `Presentation/Activity/ActivityViewModel.swift` | Modify | Training Load 데이터 fetch |

## Implementation Steps

### Step 1: Domain — WorkoutActivityType enum + WorkoutSummary 확장

- **Files**: `Domain/Models/WorkoutActivityType.swift`, `Domain/Models/HealthMetric.swift`
- **Changes**:
  - `WorkoutActivityType` enum: 80+ 케이스 (running, walking, cycling, swimming, hiking, yoga, strengthTraining, hiit, elliptical, rowing, coreTraining, flexibility, dance, pilates, boxing, climbing, skiing, snowboarding, surfing, martialArts, tennis, basketball, soccer, golf, other 등)
  - 각 케이스에 `isDistanceBased: Bool`, `category: ActivityCategory` computed property
  - `ActivityCategory` enum: cardio, strength, flexibility, sports, water, winter, combat, other
  - `WorkoutSummary` 확장:
    ```
    + activityType: WorkoutActivityType  (기존 type: String 대체)
    + heartRateAvg: Double?
    + heartRateMax: Double?
    + heartRateMin: Double?
    + averagePace: Double?        // sec/km
    + averageSpeed: Double?       // m/s
    + elevationAscended: Double?  // meters
    + weatherTemperature: Double? // celsius
    + weatherCondition: Int?
    + weatherHumidity: Double?
    + isIndoor: Bool?
    + effortScore: Double?
    + stepCount: Double?
    + milestoneDistance: MilestoneDistance?  // enum: fiveK, tenK, halfMarathon, marathon
    + isPersonalRecord: Bool
    + personalRecordTypes: [PersonalRecordType]
    ```
- **Verification**: 빌드 성공 + 기존 `WorkoutSummary` 사용처 컴파일 에러 없음

### Step 2: Domain — PersonalRecord 모델 + 서비스

- **Files**: `Domain/Models/PersonalRecord.swift`, `Domain/Services/PersonalRecordService.swift`
- **Changes**:
  - `PersonalRecordType` enum: fastestPace(distance: MilestoneDistance), longestDistance, highestCalories, longestDuration, highestElevation
  - `PersonalRecord` struct: type, value, date, workoutID
  - `MilestoneDistance` enum: fiveK(5000), tenK(10000), halfMarathon(21097), marathon(42195) — meters
  - `PersonalRecordService`:
    - `checkMilestones(distance: Double?) -> MilestoneDistance?` — 거리 기반 마일스톤 체크
    - `checkPersonalRecords(workout: WorkoutSummary, history: [PersonalRecord]) -> [PersonalRecordType]` — PR 비교
    - 순수 Domain 로직, HealthKit/SwiftData 의존 없음
- **Verification**: Unit test — milestone 감지 (4999m=nil, 5000m=fiveK, 10500m=tenK), PR 감지 (기존보다 빠르면 PR, 같으면 아님)

### Step 3: Data — WorkoutActivityType ↔ HKWorkoutActivityType 매핑

- **Files**: `Data/HealthKit/WorkoutActivityType+HealthKit.swift`
- **Changes**:
  - `extension WorkoutActivityType` with `init(healthKit: HKWorkoutActivityType)` — 80+ 매핑
  - `var hkWorkoutActivityType: HKWorkoutActivityType` — 역매핑
  - 기존 `workoutTypeName(_:)` 함수 대체
- **Verification**: 빌드 성공 + 매핑 테스트 (running ↔ .running, unknown → .other)

### Step 4: Data — WorkoutQueryService 확장 (리스트용 batch fetch)

- **Files**: `Data/HealthKit/WorkoutQueryService.swift`, `Data/HealthKit/HealthKitManager.swift`
- **Changes**:
  - `HealthKitManager.typesToRead`에 추가:
    - `HKQuantityType(.runningSpeed)`, `HKQuantityType(.cyclingSpeed)`
    - `HKQuantityType(.workoutEffortScore)`, `HKQuantityType(.estimatedWorkoutEffortScore)`
  - `toSummary(_:)` 확장:
    - `activityType`: `WorkoutActivityType(healthKit: workout.workoutActivityType)`
    - HR stats: `workout.statistics(for: .heartRate)` → avg/max/min
    - Pace: `workout.statistics(for: .runningSpeed)` → averageQuantity → sec/km 변환
    - Elevation: `workout.metadata?[HKMetadataKeyElevationAscended]` as? HKQuantity
    - Weather: metadata keys (temperature, condition, humidity)
    - Indoor: `metadata?[HKMetadataKeyIndoorWorkout]` as? Bool
    - Step count: `workout.statistics(for: .stepCount)?.sumQuantity()`
  - 기존 `type: String` 프로퍼티 유지 (backward compat) + `activityType` 추가
  - 값 범위 검증: HR 20-300, pace > 0, elevation >= 0
- **Verification**: 빌드 + 시뮬레이터에서 외부 운동 데이터가 새 필드에 채워지는지 확인

### Step 5: Data — WorkoutDetailQueryService (상세뷰용 lazy fetch)

- **Files**: `Data/HealthKit/WorkoutDetailQueryService.swift`, `Data/HealthKit/EffortScoreService.swift`
- **Changes**:
  - `WorkoutDetailQueryService`:
    - `fetchDetail(for workoutID: String) async throws -> WorkoutDetail` — 개별 운동의 상세 데이터
    - HR 샘플 배열 (기존 `HeartRateQueryService` 재사용)
    - Effort Score: `HKQuery.predicateForWorkoutEffortSamplesRelated(workout:)` 사용
    - 랩/세그먼트: `workout.workoutEvents` 파싱
  - `EffortScoreService`:
    - `fetchEffortScore(for workoutID: String) async throws -> Double?`
    - `saveEffortScore(_ score: Double, for workout: HKWorkout) async throws`
    - `HKUnit.appleEffortScore()` 사용
    - `healthStore.relateWorkoutEffortSample(_:with:activity:)` 연동
- **Verification**: Unit test (mock) + 시뮬레이터에서 Effort Score 읽기 확인

### Step 6: Data — PersonalRecordStore (UserDefaults 캐시)

- **Files**: `Data/Persistence/PersonalRecordStore.swift`
- **Changes**:
  - UserDefaults에 `[WorkoutActivityType: [PersonalRecordType: PersonalRecord]]` Codable 저장
  - Key prefix: `Bundle.main.bundleIdentifier` (correction #76)
  - `func currentRecords(for type: WorkoutActivityType) -> [PersonalRecord]`
  - `func updateIfNewRecord(_ workout: WorkoutSummary) -> [PersonalRecordType]` — 비교 + 갱신
  - Garbage collection: 120개 초과 시 oldest 정리
- **Verification**: Unit test — 저장/읽기/갱신/GC

### Step 7: Presentation — WorkoutActivityType+View (아이콘/이름/컬러)

- **Files**: `Presentation/Shared/Extensions/WorkoutActivityType+View.swift`
- **Changes**:
  - `displayName: String` — 한국어 이름 (러닝, 걷기, 사이클링, ...)
  - `iconName: String` — SF Symbol (figure.run, figure.walk, figure.outdoor.cycle, ...)
  - `color: Color` — 카테고리별 DS.Color 또는 커스텀
    - Cardio: DS.Color.activity
    - Strength: .orange
    - Flexibility: .purple
    - Sports: .blue
    - Water: .cyan
    - Winter: .indigo
    - Combat: .red
    - Other: .gray
  - `abbreviation: String` — 축약명 (PR 뱃지용)
- **Verification**: 빌드 성공 + 기존 `WorkoutSummary.iconName(for:)` 사용처 마이그레이션

### Step 8: Presentation — HealthKitWorkoutDetailView

- **Files**: `Presentation/Exercise/HealthKitWorkoutDetailView.swift`, `Presentation/Exercise/HealthKitWorkoutDetailViewModel.swift`
- **Changes**:
  - ViewModel: `loadDetail(workoutID:)` → `WorkoutDetailQueryService` + `EffortScoreService` 호출
  - View 구조 (ScrollView > VStack):
    - **헤더**: 아이콘 + 타입명 + 날짜/시간 + duration + calories
    - **핵심 지표 그리드** (2열 `statCard` 패턴): 페이스, 거리, 고도, 걸음수, Effort
    - **심박수 차트**: `HeartRateChartView` 재사용
    - **날씨 섹션**: 온도 + 상태 아이콘 + 습도 (있을 때만)
    - **마일스톤/PR 뱃지**: 해당 시 표시
    - **랩 리스트**: workoutEvents 있을 때만
  - 기존 `ExerciseSessionDetailView`의 card/material 패턴 동일 적용
  - `.ultraThinMaterial` + `RoundedRectangle(cornerRadius: DS.Radius.md)` 카드
- **Verification**: 시뮬레이터에서 외부 러닝 운동 탭 → 상세뷰 표시 확인

### Step 9: Presentation — WorkoutBadgeView (마일스톤/PR)

- **Files**: `Presentation/Exercise/Components/WorkoutBadgeView.swift`
- **Changes**:
  - `MilestoneBadge`: 5K/10K/하프/풀 아이콘 + 거리 라벨, 캡슐 배경
  - `PRBadge`: "PR" 텍스트 + 골드 accent, 캡슐 배경
  - 리스트 row용 inline 스타일 (compact) + 상세뷰용 expanded 스타일
  - Colors: milestone=DS.Color.activity, PR=.orange(gold)
  - `PRHighlightModifier`: row에 골드 테두리 ViewModifier
    ```swift
    .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
        .stroke(Color.orange.opacity(0.4), lineWidth: 1.5))
    ```
- **Verification**: Preview에서 뱃지 렌더링 확인

### Step 10: Presentation — ExerciseView/ExerciseListSection 수정

- **Files**: `Presentation/Exercise/ExerciseView.swift`, `Presentation/Exercise/ExerciseViewModel.swift`, `Presentation/Activity/Components/ExerciseListSection.swift`
- **Changes**:
  - `ExerciseView`:
    - HealthKit-only row에 `NavigationLink` 추가 → `HealthKitWorkoutDetailView(workout:)`
    - Row에 `WorkoutActivityType` 기반 아이콘/컬러 적용
    - PR row에 `PRHighlightModifier` 적용
    - 마일스톤 있으면 `MilestoneBadge` inline 표시
  - `ExerciseViewModel`:
    - `invalidateCache()`에서 PR/마일스톤 체크 추가
    - `ExerciseListItem`에 `milestoneDistance: MilestoneDistance?`, `isPersonalRecord: Bool`, `personalRecordTypes: [PersonalRecordType]` 추가
  - `ExerciseListSection`:
    - `workoutRow()` 에 `NavigationLink` 추가
    - 아이콘/컬러 + 뱃지 동일 패턴 적용
- **Verification**: 시뮬레이터에서 리스트 확인 — 아이콘 컬러, 뱃지, 탭 네비게이션

### Step 11: RPE 입력 + ExerciseRecord 확장

- **Files**: `Data/Persistence/Models/ExerciseRecord.swift`, `Presentation/Exercise/Components/RPEInputView.swift`, `Presentation/Exercise/WorkoutSessionView.swift`, `Presentation/Exercise/WorkoutSessionViewModel.swift`
- **Changes**:
  - `ExerciseRecord`에 `rpe: Int?` 필드 추가 (1-10)
  - `RPEInputView`:
    - 1-10 숫자 + 이모지 스케일: 😴(1-2) 😐(3-4) 💪(5-6) 😤(7-8) 🔥(9-10)
    - 슬라이더 또는 가로 스크롤 선택
    - Optional — "건너뛰기" 가능
  - `WorkoutSessionView`: 운동 완료 sheet에 RPE 섹션 추가
  - `WorkoutSessionViewModel`: `rpe: Int?` 상태 + `createValidatedRecord()`에 rpe 포함
  - `EffortScoreService.saveEffortScore()` 호출하여 HealthKit에도 저장
- **Verification**: 시뮬레이터에서 운동 완료 → RPE 입력 → 저장 확인

### Step 12: Training Load 계산 + 차트

- **Files**: `Domain/Models/TrainingLoad.swift`, `Domain/Services/TrainingLoadService.swift`, `Presentation/Exercise/Components/TrainingLoadChartView.swift`, `Presentation/Activity/ActivityView.swift`, `Presentation/Activity/ActivityViewModel.swift`
- **Changes**:
  - `TrainingLoad` model: date, load(Double), source(effort/trimp/rpe)
  - `TrainingLoadService`:
    - 데이터 소스 우선순위: Effort Score > RPE > HR-based TRIMP
    - `calculateDailyLoad(workouts: [WorkoutSummary]) -> [TrainingLoad]`
    - 7일/28일 합산
    - HR-based TRIMP: `duration(min) × ((avgHR - restHR) / (maxHR - restHR))²`
  - `TrainingLoadChartView`:
    - 7일 `BarChartView` 재사용 (DS.Color.activity)
    - 28일 `DotLineChartView` 재사용
    - 증감 인디케이터 (changeBadge 패턴)
  - `ActivityView`에 Training Load 섹션 추가 (WeeklySummary 아래)
  - `ActivityViewModel`에 trainingLoad fetch 추가
- **Verification**: Unit test (TRIMP 계산 정확성) + 시뮬레이터 차트 표시

### Step 13: 테스트 + xcodegen + 빌드 검증

- **Files**: `DailveTests/` 하위 테스트 파일들, `Dailve/project.yml`
- **Changes**:
  - `WorkoutActivityTypeTests.swift` — 매핑 테스트
  - `PersonalRecordServiceTests.swift` — 마일스톤/PR 감지 테스트
  - `TrainingLoadServiceTests.swift` — TRIMP 계산 테스트
  - `PersonalRecordStoreTests.swift` — 캐시 저장/읽기/GC 테스트
  - `xcodegen generate` 실행
  - 전체 빌드 + 테스트 실행
- **Verification**: `xcodebuild test` 전체 통과

## Edge Cases

| Case | Handling |
|------|----------|
| HealthKit 권한 거부 | 기본 정보(타입/시간/칼로리)만 표시, 상세뷰에서 "HealthKit 접근 필요" 안내 |
| 심박수 데이터 없음 | HR 섹션 숨김 (`if let heartRateSummary`) |
| 거리 0 또는 nil | 마일스톤 체크 스킵, 페이스 계산 스킵 |
| GPS 끊김으로 거리 부정확 | 마일스톤은 HK 제공 distance 그대로 사용 (루트 분석은 Future) |
| 첫 번째 워크아웃 | 비교 대상 없으므로 PR 아닌 "첫 기록" 표시 |
| Effort Score 미지원 | `nil`이면 RPE만 표시, 둘 다 없으면 강도 섹션 숨김 |
| 극단적 HR 값 | 20-300 BPM 범위 필터 (기존 규칙) |
| 극단적 페이스 | 1:00/km 미만 또는 60:00/km 초과 시 표시하지 않음 |
| 날씨 데이터 없음 | 날씨 섹션 숨김 |
| 운동 타입 unknown | `.other` 매핑 + "운동" 이름 + 기본 아이콘 |
| PR 캐시 corruption | Codable 실패 시 빈 상태로 리셋 (데이터 유실은 재계산으로 복구) |
| RPE 스킵 | nil 저장, 강제하지 않음 |
| Training Load 데이터 부족 | 최소 3일 이상 운동 데이터 있을 때만 차트 표시, 아니면 EmptyStateView |

## Testing Strategy

- **Unit tests**:
  - `WorkoutActivityType` ↔ `HKWorkoutActivityType` 매핑 (모든 케이스)
  - `PersonalRecordService`: 마일스톤 감지 (경계값 4999/5000/5001), PR 감지 (동일값/개선/후퇴)
  - `TrainingLoadService`: TRIMP 계산 (정상, HR=0, duration=0, NaN 방어)
  - `PersonalRecordStore`: 저장/읽기/갱신/GC
  - `WorkoutSummary` 새 필드 기본값 검증
- **Integration tests**: N/A (HealthKit 시뮬레이터 제한)
- **Manual verification**:
  - 시뮬레이터에서 Apple Health에 다양한 운동 수동 추가 → 리스트 표시 확인
  - 외부 운동 탭 → 상세뷰 전환 확인
  - 5K 이상 러닝 → 마일스톤 뱃지 확인
  - 운동 완료 → RPE 입력 → 저장 확인
  - Activity 탭 → Training Load 차트 확인

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| HKWorkoutActivityType 새 케이스 누락 | Low | Low | `default` → `.other` fallback + @unknown default |
| WorkoutSummary 필드 증가로 메모리 | Low | Low | 리스트용은 nil, 상세뷰 진입 시만 fetch |
| Effort Score API 동작 불확실 | Medium | Medium | Optional 처리, nil이면 숨김 |
| PR 캐시 UserDefaults 용량 | Low | Low | 운동 타입별 최대 5개 PR만 저장 (~10KB) |
| ExerciseRecord 스키마 변경 (rpe 추가) | Low | Medium | Optional 필드이므로 CloudKit 호환 |
| Training Load 계산 부정확 | Medium | Low | "예상 훈련량" 명시, 참고용임을 안내 |

## Confidence Assessment

- **Overall**: High
- **Reasoning**:
  - F1 (Rich Display): HealthKit API가 명확하고 기존 패턴 확장이므로 높은 확신
  - F2 (Badges): 순수 Domain 로직이므로 테스트 용이, 높은 확신
  - F3 (RPE/Effort): Effort Score API가 iOS 18+에서 안정적, RPE는 단순 UI 추가
  - F4 (Training Load): 자체 계산이므로 정확도는 보통이지만 구현 자체는 단순
  - 기존 코드베이스 패턴(card, chart, dedup)을 그대로 따르므로 아키텍처 리스크 낮음
