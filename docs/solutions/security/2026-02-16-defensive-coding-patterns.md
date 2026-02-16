---
tags: [force-unwrap, division-by-zero, nan, infinity, range-validation, healthkit, defensive-coding]
category: security
date: 2026-02-16
severity: critical
related_files:
  - Dailve/Presentation/Shared/Charts/ChartAccessibility.swift
  - Dailve/Domain/Models/ConditionScore.swift
  - Dailve/Domain/UseCases/CalculateConditionScoreUseCase.swift
  - Dailve/Presentation/Dashboard/DashboardViewModel.swift
  - Dailve/Data/HealthKit/BodyCompositionQueryService.swift
related_solutions:
  - security/2026-02-15-input-validation-swiftdata.md
---

# Solution: Defensive Coding — Force-Unwrap, Division Guard, NaN/Range Validation

## Problem

### Symptoms

- `ChartAccessibility`에서 `sorted.first!`/`sorted.last!` 6곳 — empty array 시 런타임 크래시
- `BaselineStatus.progress`에서 `daysRequired == 0` 시 division-by-zero
- `CalculateConditionScoreUseCase`에서 zScore 계산 결과가 NaN/Infinity일 수 있음
- Weight/BMI 데이터에 범위 검증 없이 HealthKit 값을 그대로 사용
- `fetchBMI(for:)` 메서드만 값 검증이 누락 (`fetchLatestBMI`에는 있음)

### Root Cause

1. **Force-unwrap 후 guard**: `guard !data.isEmpty` 이후 `sorted.first!` 사용 — guard 통과하면 안전하다고 가정했지만, 방어 코딩 원칙 위반
2. **산술 연산 입력 미검증**: HealthKit은 센서 오류, 수동 입력 오류 등으로 비정상 값 반환 가능
3. **검증 일관성 부재**: 동일 데이터의 다른 쿼리 경로에서 검증 수준이 다름

## Solution

### Changes Made

| File | Change | Reason |
|------|--------|--------|
| `ChartAccessibility.swift` | `sorted.first!` → `dateRange()` 헬퍼 (optional 접근 + fallback) | 6곳 force-unwrap 제거 |
| `ConditionScore.swift` | `guard daysRequired > 0 else { return 0 }` | Division-by-zero 방지 |
| `CalculateConditionScoreUseCase.swift` | zScore 계산 후 `isNaN && isInfinite` guard | 수학 함수 결과 검증 |
| `CalculateConditionScoreUseCase.swift` | `Int(rawScore)` → `Int(rawScore.rounded())` | 0.5+ 값 올림 처리 |
| `DashboardViewModel.swift` | Weight: `> 0 && < 500`, BMI: `> 0 && < 100` | HealthKit 값 범위 검증 |
| `BodyCompositionQueryService.swift` | `fetchBMI(for:)` 반환값 `> 0` guard | 검증 일관성 확보 |

### Key Code

```swift
// Pattern 1: Force-unwrap 제거 — 헬퍼로 안전 접근
private func dateRange<T>(from sorted: [T], dateKeyPath: KeyPath<T, Date>) -> (min: Double, max: Double) {
    let first = sorted.first?[keyPath: dateKeyPath].timeIntervalSince1970 ?? 0
    let last = sorted.last?[keyPath: dateKeyPath].timeIntervalSince1970 ?? 1
    return (first, last)
}

// Pattern 2: 나눗셈 guard
var progress: Double {
    guard daysRequired > 0 else { return 0 }
    return Double(daysCollected) / Double(daysRequired)
}

// Pattern 3: 수학 함수 결과 이중 검증
let zScore = (todayLn - baseline) / normalRange
guard !zScore.isNaN && !zScore.isInfinite else {
    return Output(score: nil, baselineStatus: baselineStatus, contributions: [])
}

// Pattern 4: HealthKit 값 범위 검증
if let latest = todaySamples.first, latest.value > 0, latest.value < 500 {
    effectiveWeight = latest.value
}
```

## Prevention

### Checklist Addition

- [ ] 모든 sorted/first/last 접근에 optional chaining 사용 (`?` + fallback)
- [ ] 나눗셈 연산 시 분모 guard + 결과 NaN/Infinity 검사
- [ ] HealthKit 값에 도메인별 범위 검증 (Weight: 0-500, BMI: 0-100, HR: 20-300 등)
- [ ] 동일 데이터의 모든 쿼리 경로에서 동일한 검증 수준 유지

### Rule Addition (if applicable)

기존 `.claude/rules/input-validation.md`에 HealthKit 범위 검증 표 추가 권장:

```markdown
| 데이터 | 범위 | 근거 |
|--------|------|------|
| Weight | 0-500 kg | 세계 기록 기반 |
| BMI | 0-100 | 의학적 범위 |
| Heart Rate | 20-300 bpm | 생리학적 범위 |
| HRV (SDNN) | 0-500 ms | 센서 범위 |
```

## Lessons Learned

1. **guard 이후에도 force-unwrap 금지**: guard로 empty 체크했더라도 `first!`가 아닌 `first?`를 사용. 코드 리팩토링 시 guard 순서가 바뀔 수 있음
2. **수학 연산 3단계 검증**: 입력 검증 → 연산 → 결과 검증. 중간 단계만 하면 불충분
3. **검증 일관성 = 동일 데이터의 모든 경로**: `fetchBMI(for:)`와 `fetchLatestBMI` 같은 동일 데이터의 다른 접근 경로에서 검증 수준이 달라 구멍 발생
4. **`.rounded()` vs `Int()` truncation**: `Int(49.7)` = 49, `Int(49.7.rounded())` = 50. 점수 시스템에서 truncation은 사용자 불만 유발
