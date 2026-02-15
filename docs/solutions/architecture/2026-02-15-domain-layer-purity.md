---
tags: [clean-architecture, domain-layer, swiftui-import, layer-violation, extension-pattern]
category: architecture
date: 2026-02-15
severity: critical
related_files:
  - Dailve/Domain/Models/ConditionScore.swift
  - Dailve/Presentation/Shared/Extensions/ConditionScore+View.swift
related_solutions: []
---

# Solution: Domain 레이어 SwiftUI 의존성 제거

## Problem

### Symptoms

- `ConditionScore.swift` (Domain 레이어)가 `import SwiftUI`를 포함
- Domain 모델이 UI 프레임워크에 의존하여 레이어 경계 위반
- Domain 모듈을 독립 테스트하거나 재사용할 수 없음

### Root Cause

`ConditionScore.Status` enum에 `var color: Color` 프로퍼티가 있어서 SwiftUI import 필요. 초기 구현 시 편의를 위해 모델에 직접 Color를 넣었으나, Clean Architecture에서 Domain → Presentation 의존은 금지.

## Solution

### Changes Made

| File | Change | Reason |
|------|--------|--------|
| ConditionScore.swift | `import SwiftUI` → `import Foundation`, `color` 프로퍼티 삭제 | Domain 순수성 |
| ConditionScore+View.swift (신규) | `extension ConditionScore.Status { var color: Color }` | UI 매핑을 Presentation으로 이동 |

### Key Code

**Domain (순수)**:
```swift
import Foundation

struct ConditionScore: Sendable {
    let score: Int
    let status: Status
    // ...
    enum Status: String, Sendable, CaseIterable {
        case excellent, good, fair, tired, warning
        var label: String { ... }  // 순수 문자열 - OK
        var emoji: String { ... }  // 유니코드 문자열 - OK
        // color 없음
    }
}
```

**Presentation (Extension)**:
```swift
// Dailve/Presentation/Shared/Extensions/ConditionScore+View.swift
import SwiftUI

extension ConditionScore.Status {
    var color: Color {
        switch self {
        case .excellent: .green
        case .good: Color(red: 0.6, green: 0.8, blue: 0.2)
        case .fair: .yellow
        case .tired: .orange
        case .warning: .red
        }
    }
}
```

## Prevention

### Checklist Addition

- [ ] Domain 레이어 파일에 `import SwiftUI` 또는 `import UIKit`이 없는가?
- [ ] Domain 모델에 Color, Image, Font 등 UI 타입이 없는가?
- [ ] UI 매핑이 필요한 경우 `Presentation/Shared/Extensions/` 에 extension으로 분리되었는가?

### Rule Addition (if applicable)

```markdown
# Domain Layer Import Rules
- Domain 레이어: Foundation, HealthKit만 import 허용
- UI 타입(Color, Image, Font)은 Presentation extension으로 분리
- Extension 파일명: `{DomainType}+View.swift`
- 위치: `Presentation/Shared/Extensions/`
```

## Lessons Learned

1. **Extension으로 레이어 분리**: Swift의 extension은 다른 모듈/레이어에서 타입을 확장할 수 있어, Clean Architecture의 의존성 방향을 유지하면서 편의 프로퍼티를 제공하는 최적의 방법
2. **label/emoji vs color**: 문자열(label, emoji)은 Foundation 범위이므로 Domain에 둬도 되지만, Color는 SwiftUI 타입이므로 반드시 분리
3. **초기 구현 시 편의 vs 장기 유지보수**: 처음에는 모델에 Color를 넣는 것이 빠르지만, 테스트/재사용성을 위해 분리가 필수적
