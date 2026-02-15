# Input Validation

## createValidatedRecord 패턴

사용자 입력을 받는 모든 ViewModel은 다음 패턴을 따름:

```swift
func createValidatedRecord() -> SomeRecord? {
    guard let validated = validateInputs() else { return nil }
    return SomeRecord(...)
}

private func validateInputs() -> ValidatedInput? {
    // 범위 검증, 에러 메시지 설정
}
```

## 필수 검증 항목

- **숫자 입력**: min/max 범위 체크 (예: weight 0-500, bodyFat 0-100)
- **문자열 입력**: 길이 제한 (memo: 500자 — `String(input.prefix(500))`)
- **중복 저장 방지**: `isSaving` 플래그로 idempotency 보장
- **에러 표시**: `validationError: String?` 프로퍼티로 UI에 에러 전달

## 수학 함수 방어

- `log()` 호출 전: 입력값 > 0 확인 (`.filter { $0.value > 0 }`)
- `sqrt()` 호출 전: 입력값 >= 0 확인
- 나눗셈 전: 분모 != 0 확인
- 계산 결과: `.isNaN`, `.isInfinite` 체크 후 fallback

## CloudKit 고려사항

잘못된 데이터는 CloudKit을 통해 전 디바이스에 전파되므로 **입력 시점에서 차단**이 필수.
