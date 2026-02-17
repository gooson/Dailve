---
tags: [swiftui, chart, animation, layout-stability, overlay, transition, ux]
category: general
date: 2026-02-17
severity: important
related_files:
  - Dailve/Presentation/Shared/Charts/ChartSelectionOverlay.swift
  - Dailve/Presentation/Shared/Charts/DotLineChartView.swift
  - Dailve/Presentation/Shared/Charts/BarChartView.swift
  - Dailve/Presentation/Shared/Charts/AreaLineChartView.swift
  - Dailve/Presentation/Shared/Charts/RangeBarChartView.swift
  - Dailve/Presentation/Shared/Detail/MetricDetailView.swift
  - Dailve/Presentation/Shared/Detail/MetricSummaryHeader.swift
  - Dailve/Presentation/Dashboard/ConditionScoreDetailView.swift
related_solutions:
  - 2026-02-16-six-perspective-review-application.md
---

# Solution: Chart UX 레이아웃 안정성 및 전환 개선

## Problem

상세 화면의 차트 관련 UX에서 3가지 레이아웃 불안정 문제 발생.

### Symptoms

1. **Period 탭 전환 바운스**: D/W/M/6M/Y 탭 전환 시 `DS.Animation.snappy` (spring)가 차트 데이터 마크에 바운스 효과를 주어 부자연스러움
2. **Selection overlay 레이아웃 시프트**: 차트 long press/hover 시 선택 정보가 VStack 상단에 삽입되며 차트가 아래로 밀림 ("움찔")
3. **Summary stats 급격한 소멸**: Day 탭에 데이터가 없으면 Avg/Min/Max 영역이 갑자기 사라지며 레이아웃이 덜컹거림
4. **높이 불일치**: "—" 플레이스홀더와 실제 숫자의 높이 차이, comparison sentence 유무에 따른 높이 변동

### Root Cause

1. **Spring 애니메이션 + 뷰 내부 상태 충돌**: `.animation(DS.Animation.snappy)` 가 차트 전체에 적용되어 데이터 변경 시 spring bounce 발생. 또한 차트의 `@State selectedDate`가 period 변경 후에도 유지되어 stale selection 표시
2. **VStack 레이아웃**: selection info가 VStack의 첫 번째 자식으로 조건부 렌더링되어 삽입/제거 시 VStack 전체 높이 변경
3. **조건부 렌더링**: `if let summary { ... }` 가 summary가 nil일 때 전체 stats 블록을 제거하여 레이아웃 점프 발생
4. **텍스트 메트릭스 차이**: `Text(" ")` (공백)과 실제 comparison sentence의 높이가 다르며, "—" 문자와 숫자의 font metrics가 미세하게 다름

## Solution

### Changes Made

| File | Change | Reason |
|------|--------|--------|
| MetricDetailView | `.id(period)` + `.transition(.opacity)` + `.easeInOut(0.25)` | Period 전환 시 crossfade — spring 제거, @State 자동 리셋 |
| ConditionScoreDetailView | 동일 패턴 적용 | 일관성 유지 |
| 4 Chart Views | VStack header → `.overlay(alignment: .top)` | 선택 정보가 레이아웃에 영향 안 줌 |
| 4 Chart Views → ChartSelectionOverlay | 공통 컴포넌트 추출 (DRY) | 60줄 중복 제거 |
| MetricSummaryHeader (stats) | `if let summary` 제거 → 항상 렌더 + "—" 플레이스홀더 | 레이아웃 안정성 |
| MetricSummaryHeader (statItem) | `.frame(minHeight:)` 추가 | "—"과 숫자 높이 통일 |
| MetricSummaryHeader (comparison) | `Group` + `.frame(minHeight: 16)` | 문장 유무와 무관한 고정 높이 |
| MetricSummaryHeader (changeBadge) | `change == 0` 처리 추가 | "equal" 아이콘 + `.secondary` 색상 |

### Key Code

#### 1. Period 전환 — `.id()` + opacity crossfade

```swift
StandardCard {
    Group {
        if viewModel.chartData.isEmpty && !viewModel.isLoading {
            chartEmptyState
        } else {
            chart.frame(height: chartHeight)
        }
    }
    .id(viewModel.selectedPeriod)    // 뷰 identity 교체 → @State 리셋
    .transition(.opacity)             // 이전/새 뷰 crossfade
}
.animation(.easeInOut(duration: 0.25), value: viewModel.selectedPeriod)
```

**핵심**: `.id()`는 SwiftUI에게 뷰를 새로 생성하라고 지시. 이전 뷰가 fade out + 새 뷰가 fade in되며, 차트 내부 `@State selectedDate` 등이 자동으로 초기화됨.

#### 2. Selection overlay — 레이아웃 비침투

```swift
Chart { ... }
    .overlay(alignment: .top) {
        if let selected = selectedPoint {
            ChartSelectionOverlay(
                date: selected.date,
                value: String(format: "%.1f", selected.value)
            )
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.15), value: selectedDate)
        }
    }
```

**핵심**: `.overlay()`는 기존 뷰의 bounds 위에 겹치므로 레이아웃에 영향 없음. `.ultraThinMaterial` 배경으로 가독성 확보.

#### 3. ChartSelectionOverlay 공통 컴포넌트

```swift
struct ChartSelectionOverlay: View {
    let date: Date
    let value: String
    var dateFormat: Date.FormatStyle = .dateTime.month(.abbreviated).day()

    var body: some View {
        HStack {
            Text(date, format: dateFormat)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .font(.caption)
        .foregroundStyle(.primary)
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .padding(.horizontal, DS.Spacing.xs)
    }
}
```

#### 4. 레이아웃 안정 stats — 항상 렌더 + minHeight

```swift
// 항상 렌더 — nil이면 "—" 표시
statItem(label: "Avg", value: summary.map { formatValue($0.average) } ?? "—")

// 값 높이 통일
Text(value)
    .contentTransition(.numericText())
    .frame(minHeight: sizeClass == .regular ? 20 : 16)

// Comparison sentence 고정 높이
Group {
    if let change { Text("...").transition(.opacity) }
}
.font(.caption)
.frame(minHeight: 16, alignment: .leading)
```

## Prevention

### Checklist Addition

- [ ] 차트/리스트에 조건부 header 추가 시 `.overlay()` 사용 검토 (VStack 삽입은 레이아웃 시프트 유발)
- [ ] 데이터 유무에 따라 사라지는 UI는 항상 placeholder 공간을 확보할 것
- [ ] Spring 애니메이션은 데이터 차트에 적용 금지 — easeInOut 또는 linear 사용
- [ ] `.id()`로 뷰 교체 시 내부 `@State` 리셋 의도를 주석으로 명시

### Rule Addition (if applicable)

향후 `.claude/rules/chart-ux-patterns.md`로 승격 검토:
- 차트 selection info는 반드시 `.overlay()` 패턴 사용
- Period 전환은 `.id()` + `.transition(.opacity)` 패턴 사용
- 데이터 종속 stats는 항상 렌더 + placeholder 패턴 사용

## Lessons Learned

1. **VStack 조건부 삽입 = 레이아웃 적**: 조건부로 VStack에 뷰를 추가/제거하면 항상 레이아웃 시프트 발생. `.overlay()`나 고정 높이 placeholder가 해결책
2. **`.id()` 는 강력한 전환 도구**: 복잡한 상태 관리 없이 뷰를 깨끗하게 교체. `@State` 자동 리셋이 핵심 이점
3. **Spring vs easeInOut**: Spring 애니메이션은 인터랙티브 요소(버튼, 제스처)에 적합. 데이터 시각화 전환에는 easeInOut이 더 자연스러움
4. **DRY는 리뷰에서 발견**: 구현 시점에는 "각 차트가 다를 수 있다"고 생각하지만, 리뷰 관점에서 보면 overlay 패턴이 동일. 6-관점 리뷰의 Simplicity Reviewer가 효과적으로 포착
5. **Text(" ")는 minHeight로 대체**: 빈 텍스트를 spacer로 사용하면 font metrics가 실제 콘텐츠와 달라 높이 불일치 발생. `Group` + `.frame(minHeight:)` 가 안정적
