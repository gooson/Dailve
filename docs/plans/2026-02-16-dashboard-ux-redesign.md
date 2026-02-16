---
tags: [ux, dashboard, redesign, accessibility, ipad, condition-score, detail-view]
date: 2026-02-16
category: plan
status: draft
depends_on: docs/brainstorms/2026-02-16-dashboard-ux-redesign.md
---

# Plan: Dashboard (첫 번째 탭) & 상세 화면 UX 재설계

## Overview

Dashboard 탭과 상세 화면(ConditionScoreDetailView, MetricDetailView)의 UX를 개선합니다.
Scope: Critical 6건 + Important 10건 = 총 16건의 이슈를 7단계로 나누어 구현합니다.

## Decisions Made

| 항목 | 결정 | 근거 |
|------|------|------|
| Score Contributors UI | 상태바 (Oura 스타일) | 한눈에 스캔 가능, 공간 효율적 |
| Mini Sparkline | 추가 | 경쟁사 전원 사용, 정보 밀도 향상 |
| iPad Detail | Inspector Panel | 대시보드 유지하며 상세 확인 가능 |
| Scope | Critical + Important 전체 | 사용자 요청 |

---

## Affected Files

### 신규 생성

| 파일 | 목적 |
|------|------|
| `Presentation/Dashboard/Components/ScoreContributorsView.swift` | Score 기여 요인 상태바 섹션 (I-1) |
| `Presentation/Dashboard/Components/DashboardSkeletonView.swift` | 로딩 스켈레톤 (I-8) |
| `Presentation/Shared/Charts/MiniSparklineView.swift` | 메트릭 카드용 7일 미니 스파크라인 (I-3) |
| `Domain/Models/ScoreContribution.swift` | Score 기여 요인 Domain 모델 |
| `DailveTests/CalculateConditionScoreUseCaseTests.swift` | Score 기여 요인 테스트 (신규 Output 필드) |

### 수정

| 파일 | 변경 내용 | 이슈 |
|------|----------|------|
| `Presentation/Shared/DesignSystem.swift` | Typography를 Dynamic Type 호환으로 변경 | C-1 |
| `Presentation/Dashboard/DashboardView.swift` | Empty/Error state 개선, 섹션 구분, 스켈레톤, 업데이트 시간 | C-2, C-3, I-1, I-2, I-8 |
| `Presentation/Shared/Components/EmptyStateView.swift` | tintColor 파라미터 추가 (선택적) | C-2 |
| `Presentation/Shared/Charts/DotLineChartView.swift` | AXChartDescriptor 구현 | C-4 |
| `Presentation/Shared/Charts/BarChartView.swift` | AXChartDescriptor 구현 | C-4 |
| `Presentation/Shared/Charts/RangeBarChartView.swift` | AXChartDescriptor 구현 | C-4 |
| `Presentation/Shared/Charts/AreaLineChartView.swift` | AXChartDescriptor 구현 | C-4 |
| `Presentation/Shared/Charts/SleepStageChartView.swift` | AXChartDescriptor 구현 | C-4 |
| `Presentation/Shared/Extensions/HealthMetric+View.swift` | 값/단위 분리, Unicode→SF Symbol | C-5, I-4 |
| `Presentation/Shared/Extensions/TimePeriod+View.swift` | locale-aware 날짜 포맷 | C-6 |
| `Presentation/Dashboard/Components/MetricCardView.swift` | Mini sparkline 추가, 값/단위 분리 | I-3, C-5 |
| `Presentation/Dashboard/Components/ConditionHeroView.swift` | Emoji→SF Symbol, 스파크라인 크기 확대 | I-9 |
| `Presentation/Dashboard/ConditionScoreDetailView.swift` | 인사이트 fold 위 이동, PeriodSwipe 적용 | I-5, I-6 |
| `Presentation/Shared/Detail/MetricDetailView.swift` | PeriodSwipe 적용 | I-6 |
| `Presentation/Shared/Detail/MetricSummaryHeader.swift` | 비교 문장 추가 | I-5 |
| `Presentation/Dashboard/DashboardViewModel.swift` | sparkline 데이터 + contributors 노출, auth 캐싱 | I-3, I-1, N-1 |
| `Domain/UseCases/CalculateConditionScoreUseCase.swift` | Output에 기여 요인 추가 | I-1 |
| `Domain/Models/ConditionScore.swift` | contributions 필드 추가 | I-1 |
| `Presentation/Shared/Components/SmartCardGrid.swift` | iPad 4열, reduceMotion 체크 | I-10 |
| `App/ContentView.swift` | iPad Inspector 패턴 | I-10 |
| `Presentation/Shared/Components/AdaptiveNavigation.swift` | iPad Inspector 지원 | I-10 |
| `Presentation/Shared/Detail/MetricDetailViewModel.swift` | scroll 디바운스 | N-3 |
| `Presentation/Dashboard/ConditionScoreDetailViewModel.swift` | contributors 연동 | I-1 |

---

## Implementation Steps

### Step 1: Design System — Dynamic Type (C-1)

**목표**: 하드코딩된 폰트 사이즈를 Dynamic Type 호환으로 변경

**변경 사항**:
```swift
// Before (DesignSystem.swift)
static let heroScore = Font.system(size: 56, weight: .bold, design: .rounded)
static let cardScore = Font.system(size: 28, weight: .bold, design: .rounded)

// After — text style 기반으로 전환
// heroScore: .largeTitle 기반 + .rounded design
// cardScore: .title 기반 + .rounded design
// 소비하는 View에서 @ScaledMetric으로 ring size 등 조정
```

- `DesignSystem.swift`: Typography를 text style 기반으로 변경
- `ProgressRingView.swift`: ring `size` 파라미터를 호출부에서 `@ScaledMetric`으로 관리
- `ConditionHeroView.swift`, `ConditionScoreDetailView.swift`, `MetricSummaryHeader.swift`: `@ScaledMetric` 적용

**테스트**: Accessibility Inspector로 전 Dynamic Type 단계 확인 (코드 테스트 불필요)

---

### Step 2: Empty/Error State 복구 경로 (C-2, C-3)

**목표**: 사용자가 문제를 해결할 수 있는 액션 제공

**DashboardView 변경**:
```swift
// Empty state — HealthKit 권한 재요청 버튼 추가
EmptyStateView(
    icon: "heart.text.clipboard",
    title: "No Health Data",
    message: "Grant HealthKit access to see your condition score.",
    actionTitle: "Open Settings",
    action: { /* UIApplication.open(openSettingsURLString) */ }
)

// Error state — 재시도 버튼 추가
// 현재: Text(error).font(.caption).foregroundStyle(.secondary)
// 변경: InlineCard with error message + "Try Again" button
```

**테스트**: EmptyStateView에 action 파라미터 전달 확인

---

### Step 3: 값/단위 분리 + SF Symbol 변경 (C-5, I-4, I-9)

**목표**: 가독성 개선 + VoiceOver 자연스러운 읽기 + iOS 디자인 언어 통일

**HealthMetric+View.swift 변경**:
```swift
// Before: formattedValue → "72ms"
// After: 2개 분리 프로퍼티
var formattedNumericValue: String  // "72"
var unitLabel: String              // "ms" (이미 Category extension에 존재)

// Before: formattedChange → "▲ 5.2%"
// After: changeDirection → Image(systemName: "arrow.up.right") / "arrow.down.right"
//        formattedChangeValue → "5.2%"
```

**MetricCardView.swift 변경**:
- 값과 단위를 별도 `Text`로 분리 (값: `.title2.bold.rounded`, 단위: `.caption.secondary`)
- 변화 뱃지: Unicode → SF Symbol `Image`

**ConditionHeroView.swift 변경**:
- `score.status.emoji` → SF Symbol (`checkmark.circle.fill` 등) + `score.status.color` 배경
- 스파크라인 높이 32pt → 44pt, area fill 추가

**ConditionScore.swift (Domain)**:
- `emoji` computed property 제거 (Presentation extension으로 이동)
- 새 extension `ConditionScore.Status+View.swift`에 `iconName: String` 추가

**테스트**: `HealthMetric` 포맷팅 테스트 (기존 테스트 수정)

---

### Step 4: 날짜 포맷 국제화 (C-6)

**목표**: 하드코딩된 한국어 날짜를 locale-aware로 변경

**TimePeriod+View.swift 변경**:
```swift
// Before:
formatter.dateFormat = "M월 d일 (E)"

// After: locale-aware template
formatter.setLocalizedDateFormatFromTemplate("MMMdE")
// 한국어: "2월 16일 (월)", 영어: "Feb 16, Mon"
```

모든 `dateFormat =` 직접 할당을 `setLocalizedDateFormatFromTemplate()` 또는 `Date.FormatStyle`로 변경.

**테스트**: 한국어/영어 locale에서 날짜 포맷 확인 유닛 테스트

---

### Step 5: 차트 VoiceOver 접근성 (C-4)

**목표**: VoiceOver 사용자가 차트 데이터 포인트를 개별 탐색 가능하도록 함

**구현 방법**: 각 차트 뷰에 `AXChartDescriptorRepresentable` 프로토콜 구현

```swift
// Helper struct (Shared/Charts/ChartAccessibility.swift)
struct ChartAccessibilityDescriptor: AXChartDescriptorRepresentable {
    let title: String
    let data: [ChartDataPoint]
    let unitSuffix: String

    func makeChartDescriptor() -> AXChartDescriptor {
        // X axis: dates, Y axis: values with unit
        // Each data point: "{date}: {value} {unit}"
    }
}
```

5개 차트 뷰에 `.accessibilityChartDescriptor()` 적용:
- `DotLineChartView` — HRV ms, Condition Score 점
- `BarChartView` — Steps, Exercise min/km
- `RangeBarChartView` — RHR bpm (min-max-avg)
- `AreaLineChartView` — Weight kg
- `SleepStageChartView` — Sleep min

기존 `.accessibilityElement(children: .combine)` 제거.

**테스트**: VoiceOver로 실기기 확인 (자동 테스트 불가)

---

### Step 6: Score Contributors (I-1) — 핵심 신규 기능

**목표**: 점수에 영향을 준 요인(HRV 트렌드, RHR 변화)을 Oura 스타일 상태바로 표시

**6-1. Domain 모델 추가** (`Domain/Models/ScoreContribution.swift`):
```swift
struct ScoreContribution: Sendable {
    let factor: Factor
    let impact: Impact      // positive, neutral, negative
    let detail: String      // e.g. "Above baseline"

    enum Factor: String, Sendable, CaseIterable {
        case hrv, rhr
    }
    enum Impact: String, Sendable {
        case positive, neutral, negative
    }
}
```

**6-2. CalculateConditionScoreUseCase Output 확장**:
```swift
struct Output {
    let score: ConditionScore?
    let baselineStatus: BaselineStatus
    let contributions: [ScoreContribution]  // NEW
}
```

계산 로직에서 기여 요인 추출:
- HRV: z-score > 0.5 → positive, -0.5~0.5 → neutral, < -0.5 → negative
- RHR: rhrChange < -2 → positive, -2~2 → neutral, > 2 → negative

**6-3. ConditionScore에 contributions 추가**:
```swift
struct ConditionScore: Sendable, Hashable {
    let score: Int
    let status: Status
    let date: Date
    let contributions: [ScoreContribution]  // NEW (Hashable 제외 — id로 hash)
}
```

주의: `Hashable` 구현을 `score + date`로 제한 (contributions 제외)

**6-4. ScoreContributorsView 신규**:
```swift
// Presentation/Dashboard/Components/ScoreContributorsView.swift
struct ScoreContributorsView: View {
    let contributions: [ScoreContribution]
    // Oura 스타일: 각 factor별 가로 상태바 (녹색/노란색/빨간색)
    // + factor name + detail text
}
```

**6-5. DashboardView 배치**: Hero card 바로 아래, SmartCardGrid 위

**6-6. DashboardViewModel 연동**: `CalculateConditionScoreUseCase` Output에서 contributions 추출

**테스트**: `CalculateConditionScoreUseCaseTests`에 contributions 검증 추가
- z-score 양수 → HRV positive
- z-score 음수 → HRV negative
- RHR 상승 → RHR negative
- 데이터 없음 → contributions empty

---

### Step 7: Dashboard Layout 개선 (I-2, I-8, I-10, I-3, I-5, I-6, I-7, N-1, N-3)

**이 Step은 여러 Important 이슈를 Dashboard 전체 리팩터링으로 묶어 처리합니다.**

**7-1. 로딩 스켈레톤 (I-8)**:
```swift
// DashboardSkeletonView.swift
// HeroCard 형태 + 4~6개 카드 형태의 .redacted(reason: .placeholder)
```

DashboardView에서 현재 `ProgressView()`를 `DashboardSkeletonView()`로 교체.

**7-2. 업데이트 시간 표시 (I-2)**:
- DashboardViewModel에 `lastUpdated: Date?` 추가
- DashboardView 하단에 `"Updated X min ago"` 텍스트 (`.secondary.caption2`)

**7-3. 섹션 분리 — Health Signals / Activity (I-1 연장)**:
```swift
// DashboardView body:
ScoreContributorsView(...)  // Step 6에서 추가

Section("Health Signals") {
    // HRV, RHR cards (2열)
}

Section("Activity") {
    // Sleep, Steps, Exercise, Weight cards (2열/4열)
}
```

DashboardViewModel에서 `sortedMetrics`를 2개 배열로 분리:
- `healthSignalMetrics`: `.hrv`, `.rhr` 필터
- `activityMetrics`: `.sleep`, `.steps`, `.exercise`, `.weight` 필터

**7-4. Mini Sparkline (I-3)**:
```swift
// MiniSparklineView.swift — 7-point Path, no axes, category color
struct MiniSparklineView: View {
    let dataPoints: [Double]  // 7일치 값
    let color: Color
    // Shape: simple Path with addLine, 28pt height
}
```

DashboardViewModel에 `metricSparklineData: [HealthMetric.Category: [Double]]` 추가.
각 카테고리별 7일 데이터를 대시보드 로딩 시 함께 fetch.

MetricCardView에 `sparklineData: [Double]?` optional 파라미터 추가. 있으면 하단에 MiniSparklineView 표시.

**7-5. HealthKit 인증 캐싱 (N-1)**:
```swift
// DashboardViewModel.loadData()
// Before: try await healthKitManager.requestAuthorization()
// After: if !authorizationChecked { try await ...; authorizationChecked = true }
```

**7-6. 상세 화면 개선 (I-5)**:
- ConditionScoreDetailView: ConditionInsightSection을 hero 바로 아래, chart 위로 이동
- MetricSummaryHeader: 비교 문장 추가 ("Your average is X% higher/lower than last {period}")

**7-7. PeriodSwipe 적용 (I-6)**:
- ConditionScoreDetailView와 MetricDetailView의 chart section에 `.periodSwipe()` modifier 적용
- 주의: `chartScrollableAxes(.horizontal)` 차트와의 제스처 충돌 → chart 외부 영역에만 적용하거나, 차트 스크롤 비활성화된 `.day` 기간에만 활성화

**7-8. SmartCardGrid reduceMotion 체크**:
```swift
// SmartCardGrid.swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
// 카드 transition에 reduceMotion 적용
.transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8)))
```

**7-9. iPad 개선 (I-10)**:

**SmartCardGrid**: iPad에서 4열
```swift
let count = sizeClass == .regular ? 4 : 2
```

**ContentView iPad Inspector 패턴**:
```swift
// iPad detail 영역에 .inspector(isPresented:) 사용
// 메트릭 카드 탭 시 inspector로 MetricDetailView 표시
// NavigationSplitView(.prominent) — sidebar 좁게
```

주의: `.inspector()` modifier는 iOS 17+에서 사용 가능. NavigationSplitView의 detail column에 적용.

**7-10. Scroll 디바운스 (N-3)**:
```swift
// MetricDetailViewModel.swift
var scrollPosition: Date = .now {
    didSet {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }
            invalidateScrollCache()
        }
    }
}
```

---

## Test Strategy

| 대상 | 테스트 유형 | 파일 |
|------|-----------|------|
| CalculateConditionScoreUseCase (contributions) | Unit test | `DailveTests/CalculateConditionScoreUseCaseTests.swift` |
| HealthMetric formatting (값/단위 분리) | Unit test | `DailveTests/HealthMetricTests.swift` |
| TimePeriod date formatting (locale) | Unit test | `DailveTests/TimePeriodFormattingTests.swift` |
| ScoreContribution model | Unit test | `DailveTests/ScoreContributionTests.swift` |
| Dynamic Type | Manual (Accessibility Inspector) | — |
| VoiceOver chart navigation | Manual (실기기) | — |
| iPad Inspector layout | Manual (시뮬레이터) | — |

---

## Edge Cases

| 상황 | 처리 |
|------|------|
| Score Contributors 데이터 없음 (baseline 미완료) | ScoreContributorsView 숨김 |
| Mini Sparkline 데이터 < 2일 | MiniSparklineView 숨김 |
| iPad multitasking 전환 (Split View → Slide Over) | `@State` 초기값 캡처 패턴 유지 (correction #10) |
| Dynamic Type AX5에서 ring 크기 | `@ScaledMetric` 최대값 clamping (ring: max 120pt) |
| PeriodSwipe + 차트 horizontal scroll 충돌 | `.day` 기간만 swipe 활성화 또는 차트 바깥 영역에 적용 |
| VoiceOver + chart selection 동시 사용 | `AXChartDescriptor`가 selection을 대체 |
| 한국어 외 locale에서 Contributors detail text | Contributors detail은 locale key로 관리 (미래 국제화 대비 enum rawValue 사용) |

---

## Risk Assessment

| 리스크 | 확률 | 영향 | 완화 |
|--------|------|------|------|
| iPad Inspector API 제한 | 중 | 중 | fallback: sheet 모달 |
| PeriodSwipe 제스처 충돌 | 높 | 낮 | `.day` 전용 활성화로 최소화 |
| Mini Sparkline 로딩 성능 | 중 | 중 | 기존 데이터 재활용, 추가 fetch 최소화 |
| ConditionScore Hashable 변경 | 낮 | 중 | contributions를 hash에서 제외 |
| 차트 AXChartDescriptor 호환성 | 낮 | 높 | iOS 16+ 지원, 대상 iOS 26+ |

---

## Implementation Order & Dependencies

```
Step 1 (C-1) ──────────────────────────┐
Step 2 (C-2, C-3) ────────────────────┤
Step 3 (C-5, I-4, I-9) ───────────────┤── 독립, 병렬 가능
Step 4 (C-6) ──────────────────────────┤
Step 5 (C-4) ──────────────────────────┘
              │
Step 6 (I-1) ─┤── Domain 모델 변경 필수 선행
              │
Step 7 (나머지 Important) ─── Step 6 결과물 사용
```

- Step 1~5: Critical 이슈, 서로 독립적 → 병렬 작업 가능
- Step 6: Score Contributors → Domain 모델 변경이 Step 7에 영향
- Step 7: 나머지 Important → Step 6 이후 순차 진행

**예상 파일 변경**: 신규 5개 + 수정 23개 = 총 28개 파일

---

## Alternatives Considered

| 결정 | 선택 | 대안 | 미선택 근거 |
|------|------|------|-----------|
| Score Contributors UI | 상태바 (Oura) | 게이지 (WHOOP) | 공간 효율, 스캔 속도 |
| Mini Sparkline 구현 | 커스텀 Path | Swift Charts LineMark | 카드 내 28pt에서 Charts 오버헤드 불필요 |
| iPad Detail | Inspector | Sheet / Push | 대시보드 유지하며 상세 확인 가능 |
| 날짜 포맷 | setLocalizedDateFormatFromTemplate | Date.FormatStyle | DateFormatter가 기존 코드와 일관적 |
| Chart 접근성 | AXChartDescriptorRepresentable | 커스텀 rotor | Apple 공식 권장 API |

---

## Next Steps

1. 이 plan 승인 후 `/work dashboard-ux-redesign` 실행
2. Step 1~5 (Critical) 병렬 구현 → 빌드 확인
3. Step 6 (Score Contributors) 구현 → 테스트
4. Step 7 (Important 나머지) 구현 → 빌드+테스트
5. `/review` 실행
6. `/compound` 로 학습 문서화
