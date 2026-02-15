# Swift Layer Boundaries

## Domain Layer Import Rules

- **허용**: `Foundation`, `HealthKit`
- **금지**: `SwiftUI`, `UIKit`, `SwiftData`
- UI 타입(Color, Image, Font)이 필요한 경우 Presentation extension으로 분리
- Extension 파일명: `{DomainType}+View.swift`
- 위치: `Presentation/Shared/Extensions/`

## ViewModel Rules

- ViewModel은 `SwiftData`를 import하지 않음
- ViewModel은 `ModelContext`를 받지 않음
- ViewModel은 `createValidatedRecord() -> Record?` 패턴으로 검증+생성만 담당
- View의 `@Environment(\.modelContext)`가 insert/delete 수행

## Layer Dependencies

```
App → Presentation → Domain ← Data
         ↓
      SwiftUI, SwiftData (View only)
```

- Domain은 다른 레이어를 의존하지 않음
- Presentation은 Domain만 의존
- Data는 Domain만 의존
- SwiftData 조작은 View에서만 수행
