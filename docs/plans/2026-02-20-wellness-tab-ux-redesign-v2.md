---
topic: wellness-tab-ux-redesign-v2
date: 2026-02-20
status: draft
confidence: high
related_solutions:
  - architecture/2026-02-17-wellness-tab-consolidation
  - general/2026-02-17-chart-ux-layout-stability
related_brainstorms:
  - 2026-02-20-wellness-tab-ux-redesign-v2
  - 2026-02-17-wellness-tab-app-ux-overhaul
---

# Implementation Plan: Wellness 탭 UX/UI 개편 v2

## Context

현재 Wellness 탭은 Sleep → Injuries → Body 3섹션이 세로로 나열된 단순 리스트.
정보 밀도가 낮고, 강조점이 없으며, Apple Watch가 수집하는 생체신호(SpO2, 호흡수, VO2 Max 등)를 전혀 활용하지 않음.

**목표**: 통합 Wellness Score 히어로 + 2칸 그리드 레이아웃으로 전면 개편.
Today 탭의 Condition Score를 Wellness Score로 통합하고, 5개 새 HealthKit 데이터 타입을 추가.

## Requirements

### Functional

1. **Wellness Score**: Sleep(40%) + Condition/HRV/RHR(35%) + Body Trend(25%) 통합 점수 (0-100)
2. **히어로 카드**: 점수 링 + 3개 서브스코어 + 상태 메시지
3. **2칸 그리드**: Sleep, SpO2, 호흡수, 체온, VO2 Max, HR Recovery, Weight, Body Fat, Muscle, BMI
4. **동적 배치**: 데이터 있는 카드가 상단으로
5. **조건부 Injury 배너**: 활성 부상 있을 때만 표시
6. **각 카드 탭 → MetricDetailView**: 상세 차트 navigation
7. **Today 탭에서 Condition Score 제거**: Wellness Score로 통합

### Non-functional

- 그린 계열 색상 체계 (스코어 그라디언트 + 카테고리별 고유색)
- 스크롤 깊이 50% 감소 (정보 밀도 2배)
- 데이터 없을 때 온보딩 가이드 empty state
- 미니 스파크라인 7일 트렌드 (각 카드)
- 오래된 데이터 "N days ago" 라벨 + opacity 감소

## Approach

**4-Phase 순차 구현**: 인프라 → 스코어 → 그리드 → 마무리

각 Phase가 독립적으로 빌드+테스트 가능하도록 설계.
Phase 1-2는 기존 WellnessView를 변경하지 않고 새 서비스/UseCase만 추가.
Phase 3에서 WellnessView를 전면 교체.
Phase 4에서 Today 탭 정리 + 마무리.

### Alternative Approaches Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| 새 WellnessView 처음부터 작성 | 기존 코드 제약 없음 | 기존 로직 재작성 비용 | **선택**: 기존 ViewModel 재활용, View만 교체 |
| 기존 View에 점진적 수정 | 리스크 낮음 | 그리드 전환이 점진적으로 불가능 | 거부: 구조 변경이 근본적 |
| SwiftUI Grid vs LazyVGrid | Grid는 더 유연 | LazyVGrid가 더 성숙, 동적 셀 수 쉬움 | **LazyVGrid** 사용 |

## Affected Files

### 신규 파일

| File | Description |
|------|-------------|
| `Data/HealthKit/VitalsQueryService.swift` | SpO2, 호흡수, VO2 Max, HR Recovery, 체온 쿼리 |
| `Domain/Models/VitalSign.swift` | 생체신호 도메인 모델 |
| `Domain/Models/WellnessScore.swift` | Wellness Score 도메인 모델 |
| `Domain/UseCases/CalculateWellnessScoreUseCase.swift` | 통합 스코어 산출 |
| `Presentation/Wellness/WellnessViewModel.swift` | 통합 ViewModel (기존 3개 VM 대체) |
| `Presentation/Wellness/Components/WellnessHeroCard.swift` | 히어로 카드 |
| `Presentation/Wellness/Components/VitalCard.swift` | 2칸 그리드 개별 카드 |
| `Presentation/Wellness/Components/InjuryBannerView.swift` | 조건부 부상 배너 |
| `Presentation/Wellness/Components/WellnessEmptyStateView.swift` | 온보딩 empty state |
| `Presentation/Shared/Components/MiniSparklineView.swift` | 이미 존재할 수 있음 — 확인 후 재활용 or 생성 |
| `Resources/Assets.xcassets/Colors/WellnessVitals.colorset/` | 새 카테고리 색상 |
| `Resources/Assets.xcassets/Colors/WellnessFitness.colorset/` | 새 카테고리 색상 |
| `DailveTests/VitalsQueryServiceTests.swift` | 쿼리 서비스 테스트 |
| `DailveTests/CalculateWellnessScoreUseCaseTests.swift` | 스코어 산출 테스트 |
| `DailveTests/WellnessViewModelTests.swift` | ViewModel 테스트 |

### 수정 파일

| File | Change Type | Description |
|------|-------------|-------------|
| `Data/HealthKit/HealthKitManager.swift` | Modify | readTypes에 5개 타입 추가 |
| `Domain/Models/HealthMetric.swift` | Modify | Category에 새 case 추가 (spo2, respiratoryRate, vo2Max, heartRateRecovery, wristTemperature) |
| `Presentation/Shared/Extensions/HealthMetric+View.swift` | Modify | 새 카테고리의 color/icon/name/unit 추가 |
| `Presentation/Shared/Detail/MetricDetailView.swift` | Modify | 새 metric 카테고리 chart 분기 추가 |
| `Presentation/Shared/Detail/MetricDetailViewModel.swift` | Modify | 새 metric 데이터 로드 분기 추가 |
| `Presentation/Shared/DesignSystem.swift` | Modify | 새 색상 토큰 추가 (vitals, fitness) |
| `Presentation/Wellness/WellnessView.swift` | **Rewrite** | 히어로 + 그리드 레이아웃으로 전면 교체 |
| `Presentation/Dashboard/DashboardView.swift` | Modify | Condition Score 섹션 제거 |
| `Presentation/Dashboard/DashboardViewModel.swift` | Modify | Condition Score 관련 코드 정리 |
| `App/ContentView.swift` | Minor | Wellness 탭 아이콘/색상 변경 가능 |

### 삭제 파일

| File | Reason |
|------|--------|
| `Presentation/Wellness/Components/SleepHeroCard.swift` | 그리드 카드로 대체 |
| `Presentation/Wellness/Components/BodySnapshotCard.swift` | 개별 카드로 분해 |

## Implementation Steps

### Step 1: HealthKit 인프라 확장

**목표**: 5개 새 HK 데이터 타입 쿼리 가능하게

- **Files**: `HealthKitManager.swift`, `VitalsQueryService.swift` (신규)
- **Changes**:
  1. `HealthKitManager.readTypes`에 추가:
     ```swift
     HKQuantityType(.oxygenSaturation),
     HKQuantityType(.respiratoryRate),
     HKQuantityType(.vo2Max),
     HKQuantityType(.heartRateRecoveryOneMinute),
     HKQuantityType(.appleSleepingWristTemperature),
     ```
  2. `VitalsQueryService` 생성 (protocol `VitalsQuerying` + struct):
     - `fetchLatestSpO2(withinDays:) -> (value: Double, date: Date)?`
     - `fetchLatestRespiratoryRate(withinDays:) -> (value: Double, date: Date)?`
     - `fetchLatestVO2Max(withinDays:) -> (value: Double, date: Date)?`
     - `fetchLatestHeartRateRecovery(withinDays:) -> (value: Double, date: Date)?`
     - `fetchLatestWristTemperature(withinDays:) -> (value: Double, date: Date)?`
     - `fetchWristTemperatureBaseline(days: 14) -> Double?`
     - 각 collection 쿼리 메서드 (스파크라인 + 상세뷰용)
  3. 값 범위 검증:
     | Data | Range | Unit |
     |------|-------|------|
     | SpO2 | 0.70-1.0 | percent (decimal) |
     | Resp Rate | 4-60 | breaths/min |
     | VO2 Max | 10-90 | ml/kg/min |
     | HR Recovery | 0-120 | bpm drop |
     | Wrist Temp | 30.0-42.0 | degC |
- **Verification**: `VitalsQueryServiceTests` — 범위 검증 로직, nil 처리, 빈 데이터 테스트

### Step 2: Domain 모델 + Wellness Score UseCase

**목표**: 통합 Wellness Score 산출 로직

- **Files**: `VitalSign.swift`, `WellnessScore.swift`, `CalculateWellnessScoreUseCase.swift` (모두 신규), `HealthMetric.swift` (수정)
- **Changes**:
  1. `VitalSign` 도메인 모델:
     ```swift
     struct VitalSign: Sendable {
         let type: VitalType
         let value: Double
         let date: Date
         let change: Double?      // vs 7일 전 or 개인 평균
         let sparklineData: [Double]  // 7일 트렌드

         enum VitalType: String, Sendable, CaseIterable {
             case spo2, respiratoryRate, vo2Max, heartRateRecovery, wristTemperature
         }
     }
     ```
  2. `WellnessScore` 도메인 모델:
     ```swift
     struct WellnessScore: Sendable {
         let score: Int           // 0-100
         let status: Status       // excellent/good/fair/tired/warning
         let sleepScore: Int?     // 서브스코어
         let conditionScore: Int? // 서브스코어 (HRV+RHR)
         let bodyScore: Int?      // 서브스코어
         let guideMessage: String // "Well recovered..."

         enum Status { case excellent, good, fair, tired, warning }
     }
     ```
  3. `CalculateWellnessScoreUseCase`:
     - Input: `sleepScore: Int?`, `conditionScore: ConditionScore?`, `bodyTrend: BodyTrend?`
     - `BodyTrend`: 7일 체중/체지방 변화 방향 → 0-100 점수로 변환
     - 가중치: Sleep 40% + Condition 35% + Body 25%
     - 구성 요소 중 2개 이상 없으면 `nil` 반환
     - 1개만 있으면 해당 점수를 100% 가중치로 사용
  4. `HealthMetric.Category`에 새 case 추가:
     ```swift
     case spo2, respiratoryRate, vo2Max, heartRateRecovery, wristTemperature
     ```
- **Verification**: `CalculateWellnessScoreUseCaseTests` — 정상 케이스, 부분 데이터, 경계값, nil 처리

### Step 3: 디자인 시스템 확장

**목표**: 그린 계열 색상 + 새 카테고리 토큰

- **Files**: `DesignSystem.swift`, `HealthMetric+View.swift`, Asset Catalog
- **Changes**:
  1. Asset Catalog에 새 colorset 추가:
     - `WellnessVitals` — Teal `#00C7BE` (light/dark variants)
     - `WellnessFitness` — Green `#34C759` (light/dark variants)
     - `WellnessScore` gradients (4단계)
  2. `DS.Color` 확장:
     ```swift
     static let vitals = Color("WellnessVitals")
     static let fitness = Color("WellnessFitness")
     static let wellnessExcellent = Color("WellnessScoreExcellent")  // green
     static let wellnessGood = Color("WellnessScoreGood")            // yellow-green
     static let wellnessFair = Color("WellnessScoreFair")            // orange
     static let wellnessWarning = Color("WellnessScoreWarning")      // red
     ```
  3. `HealthMetric+View.swift`에 새 카테고리별 `themeColor`, `iconName`, `displayName`, `unitLabel`:
     | Category | Color | Icon | Name | Unit |
     |----------|-------|------|------|------|
     | spo2 | vitals | lungs.fill | Blood Oxygen | % |
     | respiratoryRate | vitals | wind | Respiratory Rate | breaths/min |
     | vo2Max | fitness | figure.run | VO2 Max | ml/kg/min |
     | heartRateRecovery | fitness | heart.circle | HR Recovery | bpm |
     | wristTemperature | vitals | thermometer.medium | Wrist Temp | °C |
- **Verification**: 빌드 성공 확인. 기존 UI에 영향 없음 (새 case만 추가)

### Step 4: WellnessViewModel 통합

**목표**: 기존 3개 ViewModel을 1개로 통합

- **Files**: `WellnessViewModel.swift` (신규)
- **Changes**:
  1. `@Observable class WellnessViewModel` — `import Observation` only (SwiftUI 금지)
  2. 의존성 주입:
     ```swift
     init(
         sleepService: SleepQuerying,
         bodyService: BodyCompositionQuerying,
         hrvService: HRVQuerying,
         vitalsService: VitalsQuerying,
         wellnessScoreUseCase: CalculateWellnessScoreUseCase,
         sleepScoreUseCase: CalculateSleepScoreUseCase,
         conditionScoreUseCase: CalculateConditionScoreUseCase
     )
     ```
  3. Published state:
     - `wellnessScore: WellnessScore?`
     - `vitalCards: [VitalCardData]` — 동적 정렬된 카드 배열
     - `isLoading: Bool`
     - `errorMessage: String?`
  4. `VitalCardData` 내부 DTO:
     ```swift
     struct VitalCardData: Identifiable, Hashable {
         let id: String
         let category: HealthMetric.Category
         let title: String
         let value: String           // 포맷팅된 값
         let unit: String
         let change: String?         // "▲0.5%"
         let changeIsPositive: Bool?
         let sparklineData: [Double]
         let metric: HealthMetric    // navigation용
         let lastUpdated: Date
         let isStale: Bool           // 3일 이상 된 데이터
     }
     ```
  5. `loadData()`:
     - `withThrowingTaskGroup`로 10개+ 쿼리 병렬 실행 (Correction #5)
     - 각 Task 내부에서 `guard !Task.isCancelled` (Correction #17)
     - 결과를 `VitalCardData` 배열로 변환
     - 데이터 있는 카드를 상단으로 동적 정렬
     - Wellness Score 산출
     - Partial failure 카운트 추적 (Correction #25)
  6. `triggerReload()` — cancel-before-spawn (Correction #16)
- **Verification**: `WellnessViewModelTests` — 정상 로드, partial failure, cancellation, 동적 정렬

### Step 5: WellnessHeroCard

**목표**: 통합 Wellness Score 히어로 UI

- **Files**: `WellnessHeroCard.swift` (신규)
- **Changes**:
  1. `HeroCard` 래핑 (기존 DesignSystem 컴포넌트)
  2. 중앙 `ProgressRingView` — 스코어 기반 색상 그라디언트
  3. 3개 서브스코어 미니 바: Sleep / Condition / Body
  4. 상태 텍스트: `wellnessScore.guideMessage`
  5. 색상:
     - 링 stroke: `wellnessScore.status` 기반 그라디언트
     - 배경: subtle tint (10% opacity)
  6. 탭 액션: `NavigationLink(value: WellnessScoreDetail())` → 스코어 상세뷰 (향후)
  7. 데이터 없을 때: "Need more data" placeholder + 현재 수집 중인 데이터 표시
- **Verification**: Preview에서 각 스코어 구간별 색상 확인

### Step 6: VitalCard 공통 컴포넌트

**목표**: 2칸 그리드용 개별 카드

- **Files**: `VitalCard.swift` (신규), `MiniSparklineView.swift` (재활용 or 신규)
- **Changes**:
  1. `VitalCard(data: VitalCardData)`:
     - `StandardCard` 래핑
     - 카테고리 색상 아이콘 + 라벨 (상단)
     - 현재 값 (큰 폰트, `DS.Typography.cardScore`)
     - 변화량 + 방향 아이콘 (positive=green, negative=red)
     - 미니 스파크라인 (하단, 7 data points)
     - stale 데이터: "N days ago" 라벨 + 0.6 opacity
     - 탭: `NavigationLink(value: data.metric)`
  2. `MiniSparklineView` — 이미 Dashboard에 존재하면 재활용, 없으면:
     - `Path`로 7 data points 연결
     - 카테고리 색상 stroke
     - 높이 24pt 고정
     - 데이터 없으면 dashed line placeholder
- **Verification**: Preview에서 다양한 데이터 상태 (정상, stale, 없음) 확인

### Step 7: WellnessView 전면 교체

**목표**: 히어로 + 그리드 + 배너 레이아웃

- **Files**: `WellnessView.swift` (rewrite), `InjuryBannerView.swift` (신규), `WellnessEmptyStateView.swift` (신규)
- **Changes**:
  1. `WellnessView` 구조:
     ```
     NavigationStack
       ScrollView
         VStack(spacing: DS.Spacing.lg)
           WellnessHeroCard

           LazyVGrid(columns: 2, spacing: DS.Spacing.md)
             ForEach(viewModel.vitalCards) { card in
               VitalCard(data: card)
             }

           if hasActiveInjuries
             InjuryBannerView

       .navigationDestination(for: HealthMetric.self) → MetricDetailView
       .navigationDestination(for: BodyHistoryDestination.self) → BodyHistoryDetailView
       .navigationDestination(for: InjuryHistoryDestination.self) → InjuryHistoryView
     ```
  2. `InjuryBannerView`: 전체 너비, 활성 부상 최대 3개 표시, "View All" 링크
  3. `WellnessEmptyStateView`: 단계별 온보딩 가이드
     - Apple Watch 연결 상태
     - HealthKit 권한 상태
     - 데이터 수집 대기 안내
  4. `.task` 로딩: `viewModel.loadData()`
  5. `.onChange(of: records.count)`: body composition 캐시 무효화
  6. Toolbar `+` 메뉴 유지 (Body Record, Injury)
  7. 배경: 그린 계열 그라디언트 (`DS.Color.fitness.opacity(0.03)`)
- **Verification**: 빌드 + 시뮬레이터에서 전체 레이아웃 확인

### Step 8: MetricDetailView 확장

**목표**: 새 metric 카테고리의 상세 차트 지원

- **Files**: `MetricDetailView.swift`, `MetricDetailViewModel.swift`
- **Changes**:
  1. `MetricDetailViewModel.loadData()` switch에 5개 case 추가:
     - `.spo2`: `vitalsService.fetchSpO2Collection()` → `DotLineChartView`
     - `.respiratoryRate`: `vitalsService.fetchRespRateCollection()` → `AreaLineChartView`
     - `.vo2Max`: `vitalsService.fetchVO2MaxHistory()` → `DotLineChartView` (sparse data)
     - `.heartRateRecovery`: `vitalsService.fetchHRRecoveryHistory()` → `DotLineChartView`
     - `.wristTemperature`: `vitalsService.fetchWristTempCollection()` → `AreaLineChartView` (baseline overlay)
  2. VO2 Max / HR Recovery: sparse data이므로 `DotLineChartView`에 점만 표시 + 선 연결
  3. 기간 picker: VO2 Max는 기본 90일 (sparse), 나머지는 기본 7일
- **Verification**: 각 metric 카테고리별 상세뷰 진입 + 차트 표시 확인

### Step 9: Today 탭 Condition Score 정리

**목표**: Condition Score를 Wellness 탭으로 이전

- **Files**: `DashboardView.swift`, `DashboardViewModel.swift`
- **Changes**:
  1. `DashboardView`에서 Condition Score 히어로 카드 섹션 제거
  2. `DashboardViewModel`에서 `conditionScore` 프로퍼티 유지 (WellnessViewModel이 참조할 수 있도록)
     - 또는: `CalculateConditionScoreUseCase`를 WellnessViewModel에서 직접 호출
  3. Dashboard는 Health Signals (HRV, RHR 카드) + Activity Metrics로 단순화
  4. 기존 `ConditionScoreDetailView`는 Wellness 탭에서 접근 가능하도록 navigation 연결
- **Verification**: Today 탭에서 Condition Score 사라짐 확인. Wellness 탭에서 통합 스코어 표시 확인

### Step 10: 삭제 + 정리

**목표**: dead code 제거, xcodegen

- **Files**: `SleepHeroCard.swift` (삭제), `BodySnapshotCard.swift` (삭제), `project.yml`
- **Changes**:
  1. 기존 컴포넌트 삭제: `SleepHeroCard.swift`, `BodySnapshotCard.swift`
  2. `SleepViewModel` 유지 여부 결정:
     - WellnessViewModel이 수면 로직을 완전 흡수하면 삭제
     - MetricDetailView에서 아직 참조하면 유지
  3. `BodyCompositionViewModel`: 폼 로직(`createValidatedRecord`)은 유지 필요 (BodyCompositionFormSheet가 사용)
  4. `xcodegen generate` 실행
  5. 전체 빌드 + 테스트
- **Verification**: 빌드 성공, 테스트 통과, 사용하지 않는 파일 없음

## Edge Cases

| Case | Handling |
|------|----------|
| Apple Watch 미착용 | 대부분 카드 없음 → WellnessEmptyStateView 온보딩 가이드 |
| 일부 데이터만 존재 | 데이터 있는 카드만 표시 (동적 배치). 빈 카드는 그리드에서 제외 |
| HealthKit 개별 타입 권한 거부 | 해당 카드 숨김. "일부 데이터를 볼 수 없습니다" 배너 |
| 3일 이상 된 데이터 | "N days ago" 라벨 + 0.6 opacity (isStale flag) |
| 첫 사용 (24시간 미경과) | "Collecting data..." 로딩 placeholder |
| Wellness Score 계산 불가 (2개+ 없음) | 히어로 카드에 "Need more data" + 수집 중 표시 |
| HR Recovery — 운동 안 한 날 | 마지막 기록 유지 + "N days ago" 라벨 |
| VO2 Max — 자격 운동 없음 | 마지막 기록 유지 or "Complete an outdoor workout" 안내 |
| SpO2 — Series 5 이하 Watch | 카드 숨김 (데이터 자체가 없으므로 자연스러운 처리) |
| 체온 — Series 7 이하 Watch | 카드 숨김 (Nice-to-have이므로 Phase 1에서 제외 가능) |
| Body Composition 수동 입력만 | Weight/Fat/Muscle 카드는 수동 데이터로 표시. HK 배지 없음 |

## Testing Strategy

### Unit Tests

| Test File | Coverage |
|-----------|----------|
| `VitalsQueryServiceTests` | 각 쿼리 메서드 범위 검증, nil 처리, 빈 배열 |
| `CalculateWellnessScoreUseCaseTests` | 정상 산출, 부분 데이터 (1/2/3 구성요소), 경계값 (0, 100), nil 반환 조건, 가중치 계산 |
| `WellnessViewModelTests` | loadData 성공, partial failure, cancellation, 동적 정렬 순서, stale 데이터 판별, VitalCardData 변환 |

### Manual Verification

- 시뮬레이터에서 전체 레이아웃 확인 (iPhone 17 Pro Max)
- 데이터 없는 상태 → empty state 표시
- 각 그리드 카드 탭 → MetricDetailView 진입
- Today 탭에서 Condition Score 사라짐 확인
- Injury 배너 조건부 표시/숨김
- 다크 모드 색상 확인

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| HealthKit 권한 요청 항목 증가 (6개 추가) → 사용자 거부 | Medium | Medium | 단계적 권한 요청, 각 카드별 개별 처리 |
| 10+ 병렬 쿼리 성능 | Low | Medium | TaskGroup + 결과 캐싱, partial failure 허용 |
| Today 탭 Condition Score 제거 영향 | Low | High | DashboardViewModel 코드 유지, UseCase 공유 |
| 그리드 레이아웃 Dynamic Type 대응 | Medium | Low | 큰 텍스트에서 1칸 레이아웃 fallback |
| 체온 데이터 가용성 (Series 8+ 필요) | Medium | Low | Nice-to-have로 분류, 데이터 없으면 자동 숨김 |

## Confidence Assessment

- **Overall**: High
- **Reasoning**:
  - 기존 아키텍처 패턴(Query Service, UseCase, ViewModel, DesignSystem)이 잘 확립되어 있어 새 코드가 자연스럽게 맞음
  - MetricDetailView 재활용으로 상세뷰 구현 비용 최소화
  - CalculateConditionScoreUseCase가 이미 순수 Domain이라 Wellness Score에 쉽게 통합
  - 각 Phase가 독립적이라 중간에 문제 발생 시 롤백 가능
  - HealthKit API는 모두 iOS 16+이고 앱 타겟이 iOS 26+라 호환성 이슈 없음
