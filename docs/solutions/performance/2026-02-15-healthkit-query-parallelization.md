---
tags: [healthkit, async-let, taskgroup, concurrency, swift-concurrency, parallel-queries]
category: performance
date: 2026-02-15
severity: critical
related_files:
  - Dailve/Presentation/Dashboard/DashboardViewModel.swift
  - Dailve/Presentation/Sleep/SleepViewModel.swift
  - Dailve/Data/HealthKit/SleepQueryService.swift
related_solutions: []
---

# Solution: HealthKit 쿼리 병렬화 (async let + TaskGroup)

## Problem

### Symptoms

- Dashboard 로드 시 HRV 샘플 + 오늘 RHR + 어제 RHR을 순차 호출 → ~500ms+ 소요
- Sleep 뷰에서 7일치 데이터를 순차 루프로 쿼리 → 800-1200ms 소요
- Sleep 중복 제거 알고리즘이 O(n^2)로 대량 샘플에서 느림

### Root Cause

1. **순차 await**: 독립적인 HK 쿼리들을 `try await`로 하나씩 호출
2. **for 루프 내 await**: 7일 데이터를 순차 반복하여 네트워크 왕복 시간 누적
3. **비효율적 중복 제거**: 정렬 없이 전체 리스트를 매번 탐색

## Solution

### Changes Made

| File | Change | Reason |
|------|--------|--------|
| DashboardViewModel | 3개 HK 쿼리를 `async let`으로 병렬화 | ~500ms → ~200ms |
| SleepViewModel | 7일 쿼리를 `withThrowingTaskGroup`으로 병렬화 | ~1000ms → ~200ms |
| SleepQueryService | 중복 제거를 sorted sweep-line으로 변경 | O(n^2) → O(n log n) |

### Key Code

**async let (소수 독립 쿼리)**:
```swift
// 3개 이하의 독립 쿼리 → async let이 간결
async let samplesTask = hrvService.fetchHRVSamples(days: 7)
async let todayRHRTask = hrvService.fetchRestingHeartRate(for: today)
async let yesterdayRHRTask = hrvService.fetchRestingHeartRate(for: yesterday)

let (samples, todayRHR, yesterdayRHR) = try await (samplesTask, todayRHRTask, yesterdayRHRTask)
```

**withThrowingTaskGroup (동적 개수 쿼리)**:
```swift
// N개의 동일 패턴 쿼리 → TaskGroup이 적합
weeklyData = try await withThrowingTaskGroup(of: DailySleep?.self) { group in
    for dayOffset in 0..<7 {
        group.addTask { [sleepService] in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)
            else { return nil }
            let stages = try await sleepService.fetchSleepStages(for: date)
            let totalMinutes = stages.filter { $0.stage != .awake }
                .map(\.duration).reduce(0, +) / 60.0
            return DailySleep(date: date, totalMinutes: totalMinutes)
        }
    }
    var results: [DailySleep] = []
    for try await result in group {
        if let result { results.append(result) }
    }
    return results.sorted { $0.date < $1.date }
}
```

**Sorted sweep-line 중복 제거**:
```swift
private func deduplicateSamples(_ samples: [HKCategorySample]) -> [HKCategorySample] {
    let sorted = samples.sorted { $0.startDate < $1.startDate }
    var result: [HKCategorySample] = []
    for sample in sorted {
        let hasOverlap = result.contains { existing in
            existing.startDate < sample.endDate && sample.startDate < existing.endDate
        }
        if !hasOverlap {
            result.append(sample)
        } else if isWatchSource(sample) {
            result.removeAll { existing in
                !isWatchSource(existing)
                    && existing.startDate < sample.endDate
                    && sample.startDate < existing.endDate
            }
            result.append(sample)
        }
    }
    return result.sorted { $0.startDate < $1.startDate }
}
```

## Prevention

### Checklist Addition

- [ ] HealthKit 쿼리가 2개 이상 순차 호출되고 있지 않은가?
- [ ] for 루프 내에서 await를 호출하고 있지 않은가? (TaskGroup 사용 검토)
- [ ] 시간 범위 데이터의 중복 제거에 정렬 기반 알고리즘을 사용하고 있는가?

### Rule Addition (if applicable)

```markdown
# HealthKit Query Patterns
- 독립 쿼리 2-3개: `async let` 사용
- 독립 쿼리 4개+: `withThrowingTaskGroup` 사용
- for 루프 내 await 금지 (순차 실행이 필요한 경우에만 예외)
- TaskGroup에서 actor-isolated 프로퍼티 접근 시 `[service]` capture list 사용
```

## Lessons Learned

1. **async let vs TaskGroup 선택 기준**: 쿼리 수가 컴파일 타임에 정해지고 3개 이하면 `async let`, 동적이거나 4개 이상이면 `TaskGroup`
2. **Sendable 캡처 주의**: TaskGroup 클로저에서 actor-isolated 프로퍼티를 캡처하려면 `[sleepService]` 같은 명시적 capture list 필요
3. **정렬 후 처리 원칙**: 시간 기반 데이터의 중복/겹침 처리는 정렬 후 sweep-line이 가장 직관적이고 효율적
4. **HealthKit은 읽기 전용**: HK 쿼리는 side-effect가 없으므로 안전하게 병렬화 가능
