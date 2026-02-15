---
tags: [swiftdata, validation, input-sanitization, body-composition, exercise, cloudkit]
category: security
date: 2026-02-15
severity: critical
related_files:
  - Dailve/Presentation/BodyComposition/BodyCompositionViewModel.swift
  - Dailve/Presentation/Exercise/ExerciseViewModel.swift
  - Dailve/Domain/UseCases/CalculateConditionScoreUseCase.swift
related_solutions: []
---

# Solution: SwiftData 입력 유효성 검증 + ViewModel-View 역할 분리

## Problem

### Symptoms

- 사용자가 비정상적 값(음수 체중, 100% 초과 체지방 등)을 입력해도 그대로 SwiftData에 저장됨
- ViewModel이 ModelContext를 직접 조작하여 테스트 불가능하고 레이어 경계 위반
- `log(0)` 입력 시 CalculateConditionScoreUseCase가 `-inf` 또는 crash 발생 가능
- Exercise 저장 시 동시 탭으로 중복 레코드 생성 가능

### Root Cause

1. **입력 검증 부재**: TextField → Double 변환만 하고 범위 검증 없음
2. **ViewModel-ModelContext 결합**: ViewModel이 `context.insert()`를 직접 호출하여 Presentation이 Data 레이어에 의존
3. **수학적 엣지 케이스 무시**: HRV SDNN 값이 0인 경우 `log(0)` 호출 가능
4. **idempotency 미보장**: `isSaving` 플래그 없이 연속 저장 가능

## Solution

### Changes Made

| File | Change | Reason |
|------|--------|--------|
| BodyCompositionViewModel | `createValidatedRecord()` + `validateInputs()` | 범위 검증 + ModelContext 분리 |
| ExerciseViewModel | `createValidatedRecord()` + `isSaving` guard | 범위 검증 + 중복 방지 |
| BodyCompositionView | `modelContext.insert(record)` 직접 호출 | View가 persistence 담당 |
| ExerciseView | `modelContext.insert(record)` 직접 호출 | View가 persistence 담당 |
| CalculateConditionScoreUseCase | `filter { $0.value > 0 }` + NaN 체크 | log(0) 방어 |

### Key Code

**createValidatedRecord 패턴 (ViewModel)**:
```swift
// ViewModel: 검증 + 레코드 생성만 담당
func createValidatedRecord() -> BodyCompositionRecord? {
    guard let validated = validateInputs() else { return nil }
    return BodyCompositionRecord(
        date: Date(),
        weight: validated.weight,
        bodyFatPercentage: validated.bodyFat,
        muscleMass: validated.muscleMass,
        memo: String(newMemo.prefix(500))
    )
}

private func validateInputs() -> (weight: Double?, bodyFat: Double?, muscleMass: Double?)? {
    // weight: 0-500kg, bodyFat: 0-100%, muscleMass: 0-300kg
}
```

**View에서 persistence 처리**:
```swift
// View: ModelContext 조작 담당
if let record = viewModel.createValidatedRecord() {
    modelContext.insert(record)
    viewModel.resetForm()
    viewModel.isShowingAddSheet = false
}
```

**log(0) 방어**:
```swift
let validAverages = dailyAverages.filter { $0.value > 0 }
guard !validAverages.isEmpty, todayAverage.value > 0 else {
    return Output(score: nil, baselineStatus: baselineStatus)
}
// ...
guard !variance.isNaN && !variance.isInfinite else {
    return Output(score: nil, baselineStatus: baselineStatus)
}
```

## Prevention

### Checklist Addition

- [ ] 사용자 입력을 받는 모든 ViewModel에 `validateInputs()` private 메서드가 있는가?
- [ ] ViewModel이 `ModelContext`를 import하지 않는가?
- [ ] 수학 함수(log, sqrt, division) 입력에 0/음수 방어가 있는가?
- [ ] 저장 버튼에 `isSaving` idempotency guard가 있는가?
- [ ] 문자열 입력에 길이 제한이 있는가? (memo: 500자)

### Rule Addition (if applicable)

`.claude/rules/` 에 추가 권장:

```markdown
# Input Validation Pattern
- ViewModel은 `createValidatedRecord() -> Record?` 패턴 사용
- ViewModel은 SwiftData를 import하지 않음
- View의 @Environment(\.modelContext)가 insert/delete 담당
- 수학 함수 입력은 항상 양수/유효 범위 확인
```

## Lessons Learned

1. **ViewModel은 순수 검증기**: ModelContext 의존을 제거하면 유닛 테스트가 가능해지고, SwiftUI Preview에서도 안전하게 동작한다
2. **Optional 반환으로 실패 표현**: `createValidatedRecord() -> Record?`는 성공/실패를 명확히 전달하며, View는 nil 체크만 하면 된다
3. **수학 함수는 항상 도메인 검증**: `log()`, `sqrt()`, `/` 등은 입력 도메인이 제한적이므로 사전 필터링 필수
4. **CloudKit 동기화 고려**: 잘못된 데이터가 CloudKit에 올라가면 모든 디바이스에 전파되므로 입력 시점에서 차단해야 한다
