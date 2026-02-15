---
topic: historical-data-fallback
date: 2026-02-16
status: draft
confidence: high
related_solutions:
  - performance/2026-02-15-healthkit-query-parallelization.md
  - architecture/2026-02-15-domain-layer-purity.md
related_brainstorms:
  - 2026-02-15-health-app-foundation.md
---

# Implementation Plan: HealthKit 권한 확장 + 기존 데이터 Fallback 표시

## Context

실제 디바이스에 앱을 설치하면 HealthKit에 수년간의 건강 데이터가 쌓여 있지만, 두 가지 문제로 데이터를 제대로 보여주지 못한다:

1. **권한 부족**: 체중/체지방/근육량 등 Body 데이터 읽기 권한이 없음
2. **오늘 데이터만 조회**: 오늘 데이터가 없으면 빈 화면 표시

### 현재 HealthKit 권한 (`readTypes`)

```swift
// 현재 요청하는 권한
HKQuantityType(.heartRateVariabilitySDNN)  // HRV
HKQuantityType(.restingHeartRate)           // RHR
HKQuantityType(.stepCount)                  // Steps
HKCategoryType(.sleepAnalysis)              // Sleep
HKQuantityType(.activeEnergyBurned)         // Active Calories
HKQuantityType(.distanceWalkingRunning)     // Distance
HKObjectType.workoutType()                  // Workouts
```

### 누락된 권한

| 데이터 | HealthKit Type | 필요 이유 |
|--------|---------------|-----------|
| 체중 | `bodyMass` | Body 탭에서 HealthKit 체중 데이터 읽기 |
| 체지방률 | `bodyFatPercentage` | 인바디/스마트 체중계 데이터 읽기 |
| 근육량 | `leanBodyMass` | HealthKit 근육 데이터 읽기 |
| 키 | `height` | BMI 계산 가능성 대비 |
| 심박수 | `heartRate` | 운동 중 심박 등 추가 분석 |

### 핵심 문제

| 탭 | 현재 동작 | 기대 동작 |
|----|-----------|-----------|
| **Today** | 오늘 HRV/RHR 없으면 → "No Health Data" | 가장 최근 HRV/RHR 데이터 표시 + 날짜 명시 |
| **Today (Sleep)** | 오늘 수면 없으면 → 메트릭 미표시 | 어젯밤 수면 데이터 표시 |
| **Today (Steps)** | 오늘 걸음 없으면 → 메트릭 미표시 | 어제 걸음 수 표시 |
| **Today (Exercise)** | 오늘만 조회 (days:1) → 미표시 | 최근 운동 표시 |
| **Sleep 탭** | 오늘 수면 없으면 → score 0 | 가장 최근 수면 데이터로 score/stages 표시 |
| **Activity 탭** | 30일 워크아웃 (OK) | 유지 |
| **Body 탭** | SwiftData 수동 입력만 | HealthKit 체중/체지방/근육량도 가져와서 표시 |

## Requirements

### Functional

1. **HealthKit 권한 확장**: bodyMass, bodyFatPercentage, leanBodyMass, height 읽기 권한 추가
2. **Body 탭 HealthKit 연동**: HealthKit에서 체중/체지방/근육량 데이터 조회하여 수동 입력과 함께 표시
3. **Dashboard fallback**: 오늘 데이터 없는 메트릭은 최근 7일 내 데이터 표시
4. **Dashboard 날짜 표시**: 과거 데이터일 때 "어제", "2일 전" 등 상대 날짜 표시
5. **Sleep 탭 fallback**: todayStages 비어있으면 최근 수면 데이터 표시
6. **Activity 탭**: 이미 30일 데이터 → 변경 불필요 (Dashboard 메트릭만 fallback)

### Non-functional

- HealthKit 쿼리 수 최소화 (기존 쿼리 범위 확장)
- 기존 병렬화 패턴 유지 (async let, TaskGroup)
- 기존 UI 컴포넌트 재사용
- Body 탭: HealthKit 데이터와 수동 입력을 날짜순 merge

## Approach

**"권한 확장 + 쿼리 서비스 추가 + ViewModel fallback" 전략**

### 핵심 원칙

1. **HealthKitManager.readTypes 확장**: body composition 타입들 추가
2. **BodyCompositionQueryService 신규**: HealthKit에서 체중/체지방/근육량 조회
3. **기존 서비스에 fallback 메서드 추가**: 오늘 → 최근 N일 탐색
4. **ViewModel에서 fallback 로직**: 오늘 데이터 → 최근 데이터 순서로 시도
5. **UI에서 "최근 데이터" 표시**: HealthMetric에 `isHistorical` 플래그

### Alternative Approaches Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| A. 권한 확장 + 쿼리 서비스 추가 + VM fallback | 체계적, 기존 패턴 준수 | 파일 수 다소 증가 | **선택** |
| B. Body 탭은 수동 입력만 유지 | 변경 최소 | HealthKit 체중 데이터 활용 불가 | 기각 |
| C. 모든 데이터를 SwiftData에 캐싱 | 오프라인 지원 | 과잉 설계, 동기화 복잡 | 기각 |

## Affected Files

| File | Change Type | Description |
|------|-------------|-------------|
| `Data/HealthKit/HealthKitManager.swift` | **수정** | readTypes에 bodyMass, bodyFatPercentage, leanBodyMass, height 추가 |
| `Data/HealthKit/BodyCompositionQueryService.swift` | **신규** | HealthKit 체중/체지방/근육량 조회 서비스 |
| `Data/HealthKit/HRVQueryService.swift` | **수정** | fetchLatestRestingHeartRate(withinDays:) 추가 |
| `Data/HealthKit/StepsQueryService.swift` | **수정** | fetchLatestSteps(withinDays:) 추가 |
| `Data/HealthKit/SleepQueryService.swift` | **수정** | fetchLatestSleepStages(withinDays:) 추가 |
| `Domain/Models/HealthMetric.swift` | **수정** | isHistorical 프로퍼티 추가 |
| `Presentation/Dashboard/DashboardViewModel.swift` | **수정** | 각 fetch 함수에 fallback 로직 추가 |
| `Presentation/Dashboard/DashboardView.swift` | **수정** | 메트릭 카드에 상대 날짜 표시 |
| `Presentation/Sleep/SleepViewModel.swift` | **수정** | todayStages 비어있을 때 최근 데이터 fallback |
| `Presentation/Sleep/SleepView.swift` | **수정** | "최근 데이터" 안내 문구 표시 |
| `Presentation/BodyComposition/BodyCompositionViewModel.swift` | **수정** | HealthKit 데이터 로딩 + 수동 입력 merge |
| `Presentation/BodyComposition/BodyCompositionView.swift` | **수정** | HealthKit 데이터 표시 + 소스 구분 |
| `Presentation/Shared/Components/SmartCardGrid.swift` | **수정** | 메트릭 카드에 상대 날짜 라벨 |
| `DailveTests/DashboardViewModelTests.swift` | **신규** | ViewModel fallback 테스트 |

## Implementation Steps

### Step 1: HealthKit 권한 확장

- **Files**: `Data/HealthKit/HealthKitManager.swift`
- **Changes**:
  - `readTypes`에 추가:
    ```swift
    HKQuantityType(.bodyMass),
    HKQuantityType(.bodyFatPercentage),
    HKQuantityType(.leanBodyMass),
    HKQuantityType(.height),
    ```
  - 참고: 기존 사용자도 재요청 필요 (HealthKit은 새 타입 추가 시 자동으로 추가 권한 요청)
- **Verification**: 빌드 성공, 앱 실행 시 HealthKit 권한 팝업에 새 타입 포함 확인

### Step 2: BodyCompositionQueryService 생성

- **Files**: `Data/HealthKit/BodyCompositionQueryService.swift` (신규)
- **Changes**:
  - `BodyCompositionQuerying` 프로토콜 정의:
    ```swift
    protocol BodyCompositionQuerying: Sendable {
        func fetchWeight(days: Int) async throws -> [(value: Double, date: Date)]
        func fetchBodyFat(days: Int) async throws -> [(value: Double, date: Date)]
        func fetchLeanBodyMass(days: Int) async throws -> [(value: Double, date: Date)]
    }
    ```
  - `BodyCompositionQueryService` 구현: HealthKitManager 사용
  - 각 메서드: N일간 데이터를 날짜 역순으로 조회
- **Verification**: 프로토콜 구현 완전성, 빌드 성공

### Step 3: HealthMetric에 isHistorical 플래그 추가

- **Files**: `Domain/Models/HealthMetric.swift`
- **Changes**:
  - `let isHistorical: Bool` 추가 (default: `false` - 기존 init 호환)
- **Verification**: 빌드 성공

### Step 4: 기존 QueryService에 fallback 메서드 추가

- **Files**: `HRVQueryService.swift`, `StepsQueryService.swift`, `SleepQueryService.swift`
- **Changes**:
  - **HRVQuerying**: `fetchLatestRestingHeartRate(withinDays:) -> (value: Double, date: Date)?` 추가
    - 지정 기간 내 가장 최근 RHR 1건 (기존 fetchRestingHeartRate와 유사하지만 날짜 범위 확장)
  - **StepsQuerying**: `fetchLatestSteps(withinDays:) -> (value: Double, date: Date)?` 추가
    - 최근 N일 역순 탐색, 데이터 있는 첫 번째 날 반환
  - **SleepQuerying**: `fetchLatestSleepStages(withinDays:) -> (stages: [SleepStage], date: Date)?` 추가
    - 최근 N일 역순 탐색, 수면 데이터 있는 첫 번째 날 반환
- **Verification**: 프로토콜 구현 완전성 확인

### Step 5: DashboardViewModel fallback 로직

- **Files**: `Presentation/Dashboard/DashboardViewModel.swift`
- **Changes**:
  - `fetchHRVData()`:
    - HRV: 이미 7일치 samples → `samples.first`가 오늘이 아니면 `isHistorical = true`
    - RHR: todayRHR nil → `fetchLatestRestingHeartRate(withinDays: 7)` fallback
  - `fetchSleepData()`:
    - `stages.isEmpty` → `fetchLatestSleepStages(withinDays: 7)` fallback + `isHistorical = true`
  - `fetchExerciseData()`:
    - `fetchWorkouts(days: 7)` 확장 (현재 days: 1) → 최근 운동 합산
  - `fetchStepsData()`:
    - 오늘 steps nil → `fetchLatestSteps(withinDays: 7)` fallback + `isHistorical = true`
- **Verification**: 각 메트릭이 fallback으로 채워지는지 확인

### Step 6: SleepViewModel fallback 로직

- **Files**: `Presentation/Sleep/SleepViewModel.swift`
- **Changes**:
  - `loadData()`에서 todayStages가 비어있으면:
    - `fetchLatestSleepStages(withinDays: 7)` 호출
    - `todayStages`에 할당 + `latestSleepDate: Date?` 프로퍼티 추가
  - weeklyData는 이미 7일치 → 변경 없음
- **Verification**: 오늘 수면 없어도 score/stages 표시 확인

### Step 7: Body 탭 HealthKit 데이터 연동

- **Files**: `Presentation/BodyComposition/BodyCompositionViewModel.swift`, `BodyCompositionView.swift`
- **Changes**:
  - ViewModel에 `bodyCompositionService: BodyCompositionQuerying` 의존성 추가
  - `loadHealthKitData() async` 메서드 추가: HealthKit에서 체중/체지방/근육량 조회 (90일)
  - `healthKitRecords: [BodyCompositionListItem]` 프로퍼티 추가
  - View에서 SwiftData records + HealthKit records를 날짜순 merge하여 표시
  - 소스 구분: HealthKit 데이터에 하트 아이콘 표시 (Exercise 탭 패턴 참조)
  - Latest values: HealthKit 최신 + 수동 입력 최신 중 더 최근 것 표시
- **Verification**: HealthKit 체중 데이터가 Body 탭에 표시되는지 확인

### Step 8: UI에서 "최근 데이터" 시각적 구분

- **Files**: `DashboardView.swift`, `SmartCardGrid.swift` (또는 카드 컴포넌트), `SleepView.swift`
- **Changes**:
  - Dashboard: `isHistorical` true → 상대 날짜 라벨 ("어제", "2일 전")
  - Sleep 탭: latestSleepDate가 오늘이 아닐 때 안내 문구
  - Body 탭: HealthKit 소스 아이콘 구분
- **Verification**: 시각적 구분 확인

### Step 9: 유닛 테스트

- **Files**: `DailveTests/DashboardViewModelTests.swift` (신규), 기존 테스트 Mock 업데이트
- **Changes**:
  - Mock services로 fallback 시나리오 테스트
  - BodyCompositionQueryService Mock 테스트
  - 오늘 데이터 있을 때 / 없을 때 / 7일간 전무할 때 케이스
- **Verification**: `xcodebuild test` 통과

## Edge Cases

| Case | Handling |
|------|---------|
| 7일간 모든 데이터 전무 | 기존 EmptyState 유지 (변경 없음) |
| HealthKit 권한 거부 | 기존 에러 처리 유지 |
| Body 탭: HealthKit + 수동 입력 같은 날짜 | 양쪽 모두 표시, 소스 아이콘으로 구분 |
| Body 탭: HealthKit 권한만 거부 | 수동 입력만 표시 (기존 동작) |
| 아침 일찍 (오늘 데이터 미생성) | 어제/최근 데이터 fallback |
| Condition Score 7일 미달 | BaselineProgressView 유지 (HRV samples 7일 조회는 이미 함) |
| HealthKit 새 권한 타입 추가 후 기존 사용자 | requestAuthorization() 재호출 시 새 타입만 추가 요청됨 |
| RHR fallback 사용 시 condition score | fallback RHR도 동일 input으로 전달 |

## Testing Strategy

- **Unit tests**: Mock service로 ViewModel fallback + BodyCompositionQueryService 테스트
- **Manual verification**:
  - 실제 디바이스: 아침에 앱 열어 기존 데이터 표시 확인
  - 실제 디바이스: Body 탭에서 HealthKit 체중 데이터 표시 확인
  - 권한 거부 시 graceful degradation 확인
  - 모든 데이터 없을 때 EmptyState 정상 표시 확인

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Protocol 변경으로 기존 Mock 깨짐 | 높음 | 낮음 | 새 메서드 default extension 또는 Mock 업데이트 |
| Body HealthKit + SwiftData merge 복잡성 | 중간 | 중간 | 날짜순 정렬 + 소스 구분 enum으로 단순화 |
| 추가 HealthKit 쿼리 성능 | 낮음 | 중간 | fallback은 조건부 실행, Body는 90일 제한 |
| 기존 사용자 권한 재요청 UX | 낮음 | 낮음 | HealthKit이 자동으로 새 타입만 추가 요청 |

## Confidence Assessment

- **Overall**: High
- **Reasoning**: 기존 코드 구조가 Protocol 기반으로 잘 분리되어 독립적 변경 가능. BodyCompositionQueryService는 기존 QueryService 패턴을 그대로 따름. HealthKit 권한 확장은 readTypes 추가만으로 완료.
