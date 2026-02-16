---
tags: [swiftui, viewmodel, caching, computed-property, performance, observable, didset]
category: architecture
date: 2026-02-16
severity: important
related_files:
  - Dailve/Presentation/Dashboard/DashboardViewModel.swift
  - Dailve/Presentation/Dashboard/DashboardView.swift
related_solutions:
  - architecture/2026-02-16-review-triage-dry-extraction-patterns.md
---

# Solution: View Body 필터/정렬 → ViewModel Cached Properties

## Problem

### Symptoms

- `DashboardView.body` 내에서 매번 `Set` 리터럴 생성 + `.filter()` 2회 실행
- SwiftUI body는 자주 재평가되므로 불필요한 반복 연산
- 동일 데이터를 2번 순회 (healthSignals + activityMetrics)

### Root Cause

필터링 로직이 View body에 인라인으로 작성됨:

```swift
// 매 body 평가마다 실행
let healthCategories: Set<HealthMetric.Category> = [.hrv, .rhr, .weight, .bmi]
let healthSignals = viewModel.sortedMetrics.filter { healthCategories.contains($0.category) }
let activityMetrics = viewModel.sortedMetrics.filter { !healthCategories.contains($0.category) }
```

## Solution

### Changes Made

| File | Change | Reason |
|------|--------|--------|
| `DashboardViewModel.swift` | `private(set) var healthSignals/activityMetrics` + `didSet` 캐싱 | 필터링 1회만 실행 |
| `DashboardViewModel.swift` | `static let healthCategories` Set 상수화 | 매번 Set 재생성 방지 |
| `DashboardView.swift` | `viewModel.healthSignals`/`viewModel.activityMetrics` 참조 | View body 단순화 |

### Key Code

```swift
// ViewModel
var sortedMetrics: [HealthMetric] = [] {
    didSet { invalidateFilteredMetrics() }
}

private(set) var healthSignals: [HealthMetric] = []
private(set) var activityMetrics: [HealthMetric] = []

private static let healthCategories: Set<HealthMetric.Category> = [.hrv, .rhr, .weight, .bmi]

private func invalidateFilteredMetrics() {
    healthSignals = sortedMetrics.filter { Self.healthCategories.contains($0.category) }
    activityMetrics = sortedMetrics.filter { !Self.healthCategories.contains($0.category) }
}

// View
if !viewModel.healthSignals.isEmpty {
    SmartCardGrid(metrics: viewModel.healthSignals)
}
```

### Pattern: `didSet` + `invalidateCache()`

```swift
// @Observable ViewModel에서 파생 데이터 캐싱 패턴
var sourceData: [T] = [] {
    didSet { invalidateCache() }
}
private(set) var derivedData: [U] = []

private func invalidateCache() {
    derivedData = sourceData.transformed()
}
```

## Prevention

### Checklist Addition

- [ ] View body 내에 `.filter()`, `.sorted()`, `.map()` 체이닝이 있으면 ViewModel 캐싱 검토
- [ ] Set/Dictionary 리터럴이 body에 있으면 `static let`으로 추출
- [ ] 동일 소스에서 2개 이상 파생 값이 나오면 `didSet` 일괄 계산

### Rule Addition (if applicable)

기존 CLAUDE.md Correction Log #8에 이미 언급됨:
> "Computed property 캐싱: 정렬/필터 포함 computed property가 SwiftUI body에서 반복 접근되면 `private(set) var` + `didSet { invalidateCache() }` 패턴으로 캐싱"

## Lessons Learned

1. **SwiftUI body는 "순수 함수"처럼 작성**: body에서 연산하지 말고, ViewModel이 이미 가공한 데이터만 읽기
2. **static Set은 의외로 비쌈**: `Set([.a, .b, .c, .d])` 리터럴이 body마다 새로 할당됨
3. **`didSet`은 `@Observable`과 잘 작동**: `@Observable` 매크로가 willSet/didSet을 올바르게 처리
