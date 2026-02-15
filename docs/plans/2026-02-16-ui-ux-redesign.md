---
topic: UI/UX 전면 재설계
date: 2026-02-16
status: draft
confidence: high
related_solutions:
  - architecture/2026-02-16-agent-pipeline-integration.md
related_brainstorms:
  - 2026-02-15-health-app-foundation.md
---

# Implementation Plan: UI/UX 전면 재설계

## Context

현재 앱은 SwiftUI 기본 템플릿 수준의 UI로, 고유한 시각적 정체성이 없고 iPad를 전혀 지원하지 않습니다. 시뮬레이터에서도 전체 화면을 활용하지 못하며, Oura/Whoop 급 완성도와 비교하면 프로토타입 수준입니다.

### 현재 문제점
1. **iPhone 전용** — `horizontalSizeClass` 미사용, 고정 2열 그리드, iPad에서 탭바가 어색
2. **디자인 시스템 부재** — Ad-hoc 색상 (`.yellow`, `.green`, 커스텀 RGB 혼용), 타이포그래피 미통일
3. **단조로운 시각화** — 숫자+텍스트 위주, Progress Ring 없음, 평면적 카드
4. **Empty State 전무** — 데이터 없을 때 빈 화면 표시
5. **상호작용 빈약** — Haptic 미적용, 카드 stagger 애니메이션 없음

## Requirements

### Functional
- Universal App (iPhone + iPad) 지원
- 조건 점수 Progress Ring 시각화
- 카테고리별 테마 컬러 시스템
- Empty State 전체 화면 지원
- 수면 Stage Timeline 차트 (가로 막대)
- 적응형 Metric Card (iPad 3-4열, iPhone 2열)

### Non-functional
- 접근성: Dynamic Type 200%+, Reduced Motion 대응, VoiceOver 완전 지원
- 성능: 90일 차트 데이터 60fps 유지
- 일관성: 모든 컬러/스페이싱/애니메이션이 디자인 시스템에서 참조

## Approach

**점진적 리팩터링** — 기존 View 구조를 유지하면서 내부를 교체합니다. 새 파일(DesignSystem, 컴포넌트)을 먼저 생성하고, 기존 View를 하나씩 마이그레이션합니다.

### Alternative Approaches Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| 전면 재작성 (View 삭제 후 재구축) | 깔끔한 코드 | 높은 리스크, 긴 개발 기간 | **기각** |
| 점진적 리팩터링 (기존 구조 유지) | 낮은 리스크, 단계별 검증 가능 | 일부 레거시 잔존 가능 | **채택** |
| 디자인 시스템 패키지 분리 (SPM) | 재사용성 높음 | 현재 단일 앱, 과잉 설계 | **기각** |

## Affected Files

| File | Change Type | Description |
|------|-------------|-------------|
| **신규 파일** | | |
| `Presentation/Shared/DesignSystem.swift` | CREATE | DS enum (Color, Spacing, Radius, Animation, Typography) |
| `Presentation/Shared/Components/GlassCard.swift` | CREATE | Hero/Standard/Inline 카드 3종 |
| `Presentation/Shared/Components/ProgressRingView.swift` | CREATE | 원형 Progress Ring |
| `Presentation/Shared/Components/EmptyStateView.swift` | CREATE | 공통 Empty State |
| `App/AppSection.swift` | CREATE | iPad sidebar 섹션 모델 |
| `Resources/Assets.xcassets/Colors/` | CREATE | Named Color 16개 세트 (Light+Dark) |
| **수정 파일** | | |
| `App/ContentView.swift` | MODIFY | Universal layout (TabView + NavigationSplitView) |
| `Presentation/Dashboard/DashboardView.swift` | MODIFY | Hero Ring, 적응형 그리드, Empty State, 스크롤 효과 |
| `Presentation/Dashboard/Components/ConditionHeroView.swift` | MODIFY | Progress Ring, stagger 애니메이션 |
| `Presentation/Dashboard/Components/MetricCardView.swift` | MODIFY | 아이콘 + badge + Glass Material |
| `Presentation/Shared/Components/SmartCardGrid.swift` | MODIFY | 적응형 열 수 (2/3/4열) |
| `Presentation/Sleep/SleepView.swift` | MODIFY | Stage bar chart, Empty State |
| `Presentation/Exercise/ExerciseView.swift` | MODIFY | Empty State, iPad NavigationSplitView |
| `Presentation/BodyComposition/BodyCompositionView.swift` | MODIFY | Empty State, contextMenu 수정 |
| `Presentation/Shared/DesignConstants.swift` | DELETE | DS로 대체 |
| `Presentation/Shared/Extensions/ConditionScore+View.swift` | MODIFY | DS.Color 참조로 변경 |
| `Presentation/Shared/Extensions/HealthMetric+View.swift` | MODIFY | themeColor, iconName 추가 |
| `Presentation/Shared/Charts/DotLineChartView.swift` | MODIFY | Date 기반 ID, 기간별 최적화 |

## Implementation Steps

### Step 1: 디자인 시스템 기반 구축

- **Files**: `DesignSystem.swift` (신규), `Assets.xcassets/Colors/` (신규)
- **Changes**:
  - `DS` enum 생성: Color, Spacing, Radius, Animation, Typography 네임스페이스
  - Asset Catalog에 Named Color 16개 추가 (Score 5색 + Metric 6색 + Feedback 3색 + Surface 2색)
  - 각 색상 Light/Dark 변형 포함
- **Verification**: 빌드 성공, Xcode Preview에서 Light/Dark 색상 확인

### Step 2: 카드 컴포넌트 시스템

- **Files**: `GlassCard.swift` (신규), `ProgressRingView.swift` (신규), `EmptyStateView.swift` (신규)
- **Changes**:
  - `GlassCard<Content>`: `.ultraThinMaterial` + 그래디언트 보더 + 적응형 그림자
  - `ProgressRingView`: 원형 프로그레스 + `AngularGradient` + 애니메이션
  - `EmptyStateView`: 아이콘 + 타이틀 + 메시지 + 선택적 CTA 버튼
- **Verification**: Xcode Preview에서 3종 카드 + Ring + Empty State 렌더링 확인

### Step 3: ConditionHeroView 재설계

- **Files**: `ConditionHeroView.swift`
- **Changes**:
  - 숫자 표시 → Progress Ring + 중앙 숫자 레이아웃으로 변경
  - `GlassCard` 래퍼 적용, 배경 그래디언트
  - Stagger 애니메이션: Ring fill (1.2s spring) → Number count-up (1.0s, 0.2s delay)
  - `.sensoryFeedback(.impact(.light))` 로딩 완료 시
  - `@ScaledMetric` 기반 반응형 크기
  - Reduced Motion 대응
- **Verification**: Preview + 시뮬레이터에서 애니메이션 확인, Accessibility Inspector로 Reduced Motion 테스트

### Step 4: MetricCardView 리디자인

- **Files**: `MetricCardView.swift`, `HealthMetric+View.swift`
- **Changes**:
  - `HealthMetric.Category`에 `themeColor: Color`, `iconName: String` extension 추가
  - 카드에 카테고리 아이콘 추가 (SF Symbol, 테마 컬러 적용)
  - 변화 지시자: 텍스트 화살표 → Capsule badge (색상 배경)
  - `.ultraThinMaterial` 카드 배경 + `GlassCard` 래퍼
- **Verification**: 6개 메트릭 카테고리 각각 올바른 아이콘/컬러 표시 확인

### Step 5: 적응형 그리드 + Universal Layout

- **Files**: `ContentView.swift`, `AppSection.swift` (신규), `SmartCardGrid.swift`
- **Changes**:
  - `AppSection` enum: dashboard/exercise/sleep/body cases + title/icon
  - ContentView: `horizontalSizeClass`에 따라 iPhone TabView ↔ iPad NavigationSplitView 분기
  - TabView에 `.tabViewStyle(.sidebarAdaptable)` 적용 (또는 명시적 분기)
  - SmartCardGrid: 열 수 Compact=2, Regular=3-4로 동적 변경
- **Verification**: iPhone 시뮬레이터 탭바, iPad 시뮬레이터 사이드바 전환 확인

### Step 6: 색상 시스템 마이그레이션

- **Files**: `ConditionScore+View.swift`, `SleepStage+View.swift`, 모든 View 파일
- **Changes**:
  - `ConditionScore.Status.color` → `DS.Color.scoreXxx` 참조로 변경
  - 모든 하드코딩 `.padding(24)` → `DS.Spacing.xxl`, `.cornerRadius(16)` → `DS.Radius.lg` 등
  - 각 View 배경에 미세한 gradient 적용 (Material에 깊이감 부여)
- **Verification**: Light/Dark Mode 전환 시 모든 화면 가독성 확인

### Step 7: Empty State 적용

- **Files**: `DashboardView.swift`, `ExerciseView.swift`, `SleepView.swift`, `BodyCompositionView.swift`
- **Changes**:
  - 각 View에 `isLoading + isEmpty` 분기 추가
  - DashboardView: HealthKit 미승인 → 안내 Empty State
  - ExerciseView: 기록 없음 → "Add Exercise" CTA
  - SleepView: 수면 데이터 없음 → Apple Watch 안내
  - BodyCompositionView: 기록 없음 → "Add First Record" CTA
- **Verification**: HealthKit 권한 거부 상태에서 Empty State 표시 확인

### Step 8: Sleep Stage 시각화 개선

- **Files**: `SleepView.swift`
- **Changes**:
  - 텍스트 리스트 → 수평 Stacked Bar Chart (GeometryReader 기반)
  - Stage별 비율 시각화 + 하단 legend
  - `.gradient` modifier로 각 stage 색상 그래디언트
- **Verification**: 4개 stage 데이터에서 비율 바 정확히 렌더링 확인

### Step 9: 차트 시스템 개선

- **Files**: `DotLineChartView.swift`, `TrendChartView.swift`
- **Changes**:
  - `ChartDataPoint.id`를 UUID → Date 기반으로 변경 (애니메이션 안정화)
  - 90일 뷰: PointMark 제거 (시각적 노이즈 방지)
  - 차트 선택 시 `RuleMark` 인디케이터 + 값 annotation
  - `.sensoryFeedback(.selection)` 차트 포인트 선택 시
  - Y축 도메인 명시적 설정 (레이아웃 안정화)
- **Verification**: 7/30/90일 기간 전환 시 부드러운 데이터 트랜지션 확인

### Step 10: 애니메이션 & Haptic 시스템 통합

- **Files**: 전체 View 파일
- **Changes**:
  - 모든 `withAnimation` 호출을 `DS.Animation.xxx` 프리셋으로 통일
  - MetricCard stagger 애니메이션: `ForEach(enumerated)` + delay
  - Haptic 포인트 추가:
    - Score 로딩 완료: `.impact(.light)`
    - 기록 저장 성공: `.notification(.success)`
    - 유효성 실패: `.notification(.error)`
    - 차트 포인트 선택: `.selection`
  - `@Environment(\.accessibilityReduceMotion)` 기반 Reduced Motion 분기
- **Verification**: Accessibility Inspector에서 Reduce Motion ON/OFF 테스트

### Step 11: DesignConstants 제거 + DesignSystem Skill 문서 업데이트

- **Files**: `DesignConstants.swift` (삭제), `DesignSystem.swift` (확인), `.claude/skills/design-system/SKILL.md`
- **Changes**:
  - `DesignConstants` 참조를 모두 `DS`로 변경한 후 파일 삭제
  - design-system SKILL.md에 실제 구현 내용 반영
- **Verification**: 빌드 성공, DesignConstants 참조 0건 확인

### Step 12: BodyCompositionView swipeActions 버그 수정

- **Files**: `BodyCompositionView.swift`
- **Changes**:
  - ScrollView 내 `.swipeActions`는 동작하지 않음
  - `.contextMenu`로 교체 (Delete + Edit)
  - 또는 History 섹션을 `List`로 분리
- **Verification**: 실기기/시뮬레이터에서 컨텍스트 메뉴 동작 확인

## Edge Cases

| Case | Handling |
|------|---------|
| HealthKit 권한 거부 | EmptyStateView + "Open Settings" CTA |
| 데이터 0건 (최초 실행) | 각 탭별 맞춤 EmptyState |
| iPad Split View (1/3 너비) | `horizontalSizeClass`가 `.compact`로 전환 → iPhone 레이아웃 |
| iPad 가로↔세로 회전 | 그리드 열 수 자동 반응 (sizeClass 변경) |
| Dynamic Type AX5 (최대 크기) | `@ScaledMetric` 상한 설정, 텍스트 잘림 방지 |
| Reduced Motion ON | 모든 spring/ease 애니메이션 → `.none` 또는 instant |
| 90일 차트 데이터 | PointMark 제거, 주간 평균 집계 (13포인트) |
| Dark Mode | Named Color Light/Dark 변형, Material 자동 적응 |
| Score 0 (데이터 부족) | Ring 빈 상태 표시, "Collecting data..." 메시지 |

## Testing Strategy

- **Unit tests**: DS.Color, DS.Spacing 상수값 검증, AppSection 모델 테스트
- **Preview tests**: 각 컴포넌트 Xcode Preview에서 Light/Dark, 다양한 데이터 상태
- **시뮬레이터 테스트**: iPhone 17 + iPad Pro에서 전체 흐름 확인
- **접근성 테스트**: Accessibility Inspector로 Dynamic Type, Reduced Motion, VoiceOver
- **성능 테스트**: Instruments Time Profiler로 90일 차트 스크롤 60fps 확인

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Asset Catalog 색상 불일치 (Light/Dark) | 중간 | 중간 | Preview에서 양 모드 동시 검증 |
| iPad NavigationSplitView + 기존 NavigationStack 충돌 | 낮음 | 높음 | Step 5에서 iPad 전용 테스트 |
| Progress Ring 성능 (AngularGradient 재렌더링) | 낮음 | 낮음 | 상수 그래디언트 사용, 불필요한 재렌더링 방지 |
| Dynamic Type 극단 크기에서 레이아웃 깨짐 | 중간 | 중간 | `@ScaledMetric` 상한 + `ViewThatFits` 폴백 |
| 12단계 변경의 범위가 큼 | 높음 | 중간 | 각 Step 독립 커밋, Step별 빌드/테스트 |

## Confidence Assessment

- **Overall**: High
- **Reasoning**: 기존 MVVM 아키텍처를 유지하면서 Presentation 레이어만 수정합니다. Domain/Data 레이어 변경이 없어 기능 회귀 위험이 낮습니다. iOS 26+ 전용이므로 하위 호환성 걱정 없이 최신 SwiftUI API를 활용할 수 있습니다. 각 Step이 독립적으로 빌드/테스트 가능하도록 설계되어 리스크 관리가 용이합니다.
