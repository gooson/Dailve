---
tags: [code-review, multi-perspective, compound-engineering, partial-failure, dry, accessibility]
category: general
date: 2026-02-16
severity: important
related_files:
  - Dailve/Presentation/Shared/Charts/ChartAccessibility.swift
  - Dailve/Presentation/Dashboard/DashboardViewModel.swift
  - Dailve/Presentation/Dashboard/Components/MetricCardView.swift
  - Dailve/Presentation/Dashboard/Components/ConditionHeroView.swift
  - Dailve/Presentation/Dashboard/Components/ScoreContributorsView.swift
  - Dailve/Presentation/Shared/Components/SmartCardGrid.swift
related_solutions:
  - security/2026-02-16-defensive-coding-patterns.md
  - architecture/2026-02-16-viewmodel-cached-filtering.md
---

# Solution: 6-관점 리뷰 결과의 체계적 적용

## Problem

### Symptoms

- 50파일 +2275줄 변경에 대한 6-관점 리뷰 결과 35건 (P1: 6, P2: 16, P3: 13)
- 관점별 중복 발견 다수 (ChartAccessibility force-unwrap이 Security, Architecture, Agent 3곳에서 동시 지적)
- 한 파일에 여러 관점의 수정이 중첩 (DashboardViewModel에 Security + Performance + Architecture 수정)

### Root Cause

대규모 변경 후 리뷰 → 적용 과정에서의 체계 부재:
1. 중복 발견사항 식별/병합 미흡
2. 파일별 수정 충돌 가능성
3. 우선순위별 적용 순서 미결정

## Solution

### Effective Process

1. **중복 제거 우선**: 6개 관점의 발견사항을 파일 단위로 병합 (35건 → 19건 작업 단위)
2. **P1 → P2 → P3 순차 적용**: 안전성 문제를 먼저 해결
3. **파일별 배치 편집**: 한 파일의 모든 수정을 한 번에 적용하여 충돌 방지
4. **빌드 + 테스트 1회**: 모든 수정 후 한 번에 검증 (중간 빌드 불필요)

### Changes Made (대표적 패턴)

| Pattern | Before | After | Impact |
|---------|--------|-------|--------|
| Dead code 제거 | `var sparklineData: [Double]?` 미사용 파라미터 | 파라미터 + 렌더링 코드 삭제 | -7줄 |
| DRY 헬퍼 추출 | 3개 struct에 동일 empty descriptor + DateFormatter | 3개 private 함수로 추출 | -40줄 중복 |
| Partial failure | 6개 fetch 중 일부 실패 시 무시 | 실패 카운트 + 사용자 안내 메시지 | UX 개선 |
| Magic number | `0.85`, `128`, `88` 등 인라인 | `Layout`/`BarFraction` enum 상수 | 가독성 |
| Accessibility | reduceMotion에서도 stagger delay 적용 | delay 제거 | 접근성 준수 |
| Hashable 계약 | `==` 비교에서 contributions 제외 | contributions 포함 | 정확한 동등성 |

### Key Code — Partial Failure Pattern

```swift
// Safe fetch with failure tracking
private func safeHRVFetch() async -> (metrics: [HealthMetric], failed: Bool) {
    do { return (try await fetchHRVData(), false) }
    catch {
        AppLogger.ui.error("HRV fetch failed: \(error.localizedDescription)")
        return ([], true)
    }
}

// Aggregate and report
let failureCount = [hrvResult.failed, sleepResult.failed, ...].filter { $0 }.count
if failureCount > 0 && !allMetrics.isEmpty {
    errorMessage = "Some data could not be loaded (\(failureCount) of 6 sources)"
}
```

## Prevention

### Checklist Addition

- [ ] 리뷰 결과 적용 전 반드시 파일별 중복 병합
- [ ] parallel fetch 패턴에는 항상 partial failure 보고 포함
- [ ] `Hashable` 구현 시 `==`에 사용하는 모든 프로퍼티를 `hash(into:)`에도 포함
- [ ] `reduceMotion` 사용 시 delay/stagger 관련 코드도 함께 조건 분기

## Lessons Learned

1. **리뷰 적용은 batch가 효율적**: 파일별로 모든 관점의 수정을 모아서 한 번에 적용 → 충돌 없음, 빌드 1회
2. **중복 발견 = 중요도 높음**: 3개 관점에서 동시 지적된 ChartAccessibility force-unwrap은 실제로 P1 수준
3. **Partial failure는 parallel fetch의 필수 동반자**: async let 6개를 쓸 때 일부 실패를 무시하면 사용자는 "왜 데이터가 없지?" 혼란
4. **dead code는 과감히 제거**: sparklineData가 "나중에 쓸 수도" 있었지만 현재 미사용이면 제거. 필요 시 git history에서 복원
5. **P3는 선별 적용 OK**: Typography API 통일 같은 미미한 차이는 스킵하여 불필요한 코드 변동 방지 (Surgical Scope 원칙)
