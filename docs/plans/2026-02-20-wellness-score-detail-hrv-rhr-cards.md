---
topic: wellness-score-detail-hrv-rhr-cards
date: 2026-02-20
status: draft
confidence: high
related_solutions:
  - architecture/2026-02-17-wellness-tab-consolidation
  - general/2026-02-17-chart-ux-layout-stability
related_brainstorms:
  - 2026-02-20-wellness-tab-ux-redesign-v2
---

# Implementation Plan: 웰니스 점수 상세화면 + HRV/RHR 카드

## Context

Wellness Tab v2 리디자인이 완료되었으나 두 가지가 빠져있음:
1. **웰니스 점수 히어로카드**가 탭 불가 — 점수 breakdown, 가이드, sub-score 설명을 보여줄 상세화면이 없음
2. **HRV/RHR 개별 카드**가 grid에 없음 — Condition Score 계산에만 소비되고 raw 값이 카드로 표시되지 않음

`ConditionScoreDetailView`가 아키텍처 참조 대상. `MetricDetailView`에 `.hrv`, `.rhr` 차트가 이미 구현되어 있어 카드 추가만으로 navigation 작동.

## Requirements

### Functional

- 웰니스 히어로카드 탭 → WellnessScoreDetailView 진입
- 상세화면: 점수 링 + status + guide message
- 상세화면: Sleep/Condition/Body 3가지 sub-score breakdown (가중치 40/35/25% 표시)
- 상세화면: 각 sub-score의 의미 설명 (explainer)
- 상세화면: Condition Score의 contributions (HRV/RHR 기여도) 표시
- HRV 카드: 최신 SDNN 값 + 7일 sparkline
- RHR 카드: 최신 RHR 값 + 7일 sparkline
- 두 카드 탭 → 기존 MetricDetailView(.hrv / .rhr) 진입

### Non-functional

- ConditionScoreDetailView 패턴 재사용 (코드 일관성)
- 기존 fetchAllData() TaskGroup에 HRV/RHR raw 데이터 추가 — 별도 fetch 금지 (이미 condition task에서 데이터 사용 중)
- totalSources 카운트 업데이트

## Approach

**WellnessScoreDetailView를 새 파일로 생성**하되, ConditionScoreDetailView와 달리 차트가 없음 (Wellness Score는 일별 히스토리 개념이 아닌 composite score). 대신 sub-score breakdown 패널 + explainer 구성.

**HRV/RHR 카드**는 condition task에서 이미 가져오는 데이터를 FetchResults에 추가 저장하고, 별도 sparkline용 7일 히스토리를 TaskGroup에 2개 task 추가.

### Alternative Approaches Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| WellnessScoreDetailView에 일별 차트 포함 | 깊은 분석 가능 | Wellness Score 자체는 composite이라 일별 추적이 어색, 구현 복잡 | **Reject** — sub-score breakdown에 집중 |
| ConditionScoreDetailView 직접 재사용 | 구현 0 | Wellness Score ≠ Condition Score. 의미가 다름 | **Reject** |
| HRV/RHR fetch를 별도 task로 분리 | 격리성 | condition task와 중복 fetch, 네트워크 비용 | **Reject** — condition task에서 raw 값 추출 + sparkline만 별도 task |

## Affected Files

| File | Change Type | Description |
|------|-------------|-------------|
| `Presentation/Wellness/WellnessScoreDetailView.swift` | **New** | 웰니스 점수 상세화면 |
| `Presentation/Wellness/WellnessViewModel.swift` | Modify | HRV/RHR raw 값 저장, sparkline fetch 추가, conditionScoreFull 노출 |
| `Presentation/Wellness/WellnessView.swift` | Modify | NavigationLink 추가 (hero card → detail), navigationDestination 등록 |
| `Presentation/Wellness/Components/WellnessHeroCard.swift` | Modify | chevron 힌트 추가 (탭 가능 시각 표시) |
| `DailveTests/WellnessScoreDetailTests.swift` | **New** | 상세화면 ViewModel 테스트 (해당 시) |

## Implementation Steps

### Step 1: WellnessViewModel — HRV/RHR raw 데이터 노출

- **Files**: `WellnessViewModel.swift`
- **Changes**:
  1. `FetchResults`에 필드 추가:
     - `latestHRV: (value: Double, date: Date)?` — 오늘 마지막 HRV SDNN
     - `latestRHR: (value: Double, date: Date)?` — 오늘 RHR
     - `hrvWeekly: [(date: Date, average: Double)]` — 7일 일별 평균
     - `rhrWeekly: [(date: Date, min: Double, max: Double, average: Double)]` — 7일 RHR
  2. `FetchKey`에 `.hrvLatest`, `.rhrLatest`, `.hrvWeekly`, `.rhrWeekly` 추가
  3. `FetchValue`에 대응 case 추가
  4. `fetchAllData()`에서:
     - condition task에서 HRV 최신값/RHR 오늘값을 결과로 반환하도록 수정 (기존 conditionResult에 raw 값 포함하거나, 별도 FetchKey로 분리)
     - 간소화: condition task에서 latestHRV/latestRHR를 FetchValue에 포함
     - 별도 2개 task 추가: hrvWeekly (7일 일별 평균), rhrWeekly (7일 RHR)
  5. `performLoad()`에서 HRV/RHR buildCard() 호출 추가
  6. `totalSources` 8 → 10으로 업데이트 (HRV, RHR 추가)
  7. `conditionScoreFull: ConditionScore?` 프로퍼티 추가 — 기존 `conditionScore: Int?`와 별개로 full object 저장
- **Verification**: 빌드 성공, 기존 카드 + HRV/RHR 카드 2개 추가 확인

### Step 2: WellnessScoreDetailView 생성

- **Files**: `Presentation/Wellness/WellnessScoreDetailView.swift` (new)
- **Changes**:
  1. Props: `let wellnessScore: WellnessScore`, `let conditionScore: ConditionScore?`
  2. Layout (ConditionScoreDetailView 구조 참조):
     - **Hero 영역**: ProgressRingView + 점수 + status label + guide message
     - **Sub-Score Breakdown**: 3개 항목 (Sleep/Condition/Body), 각각 가중치%, 점수, mini progress bar, 1줄 설명
     - **Condition Contributors**: `ScoreContributorsView(contributions:)` 재사용 (conditionScore가 있을 때만)
     - **Explainer Section**: Wellness Score 계산 방법 설명 (Sleep 40% + Condition 35% + Body 25%, 각 sub-score 의미)
  3. iPad 대응: `sizeClass == .regular`로 hero + breakdown 2-column
  4. `.navigationTitle("Wellness Score")`, `.navigationBarTitleDisplayMode(.large)`
- **Verification**: Preview에서 렌더링 확인

### Step 3: Navigation 연결

- **Files**: `WellnessView.swift`, `WellnessHeroCard.swift`
- **Changes**:
  1. `WellnessView.swift`:
     - `WellnessScoreDestination` struct 추가 (Hashable)
     - hero card를 `NavigationLink(value: WellnessScoreDestination())` 으로 래핑
     - `.navigationDestination(for: WellnessScoreDestination.self)` 등록 → `WellnessScoreDetailView` 연결
     - WellnessScoreDetailView에 `viewModel.wellnessScore!`, `viewModel.conditionScoreFull` 전달
  2. `WellnessHeroCard.swift`:
     - chevron.right 아이콘을 hero card 우상단에 추가 (탭 가능 시각 힌트)
- **Verification**: 히어로카드 탭 → 상세화면 push navigation 동작 확인

### Step 4: 테스트 + 빌드 검증

- **Files**: xcodegen, build, test
- **Changes**:
  1. `cd Dailve && xcodegen generate`
  2. 빌드 확인
  3. 기존 481 테스트 통과 확인
  4. WellnessScore 관련 edge case가 이미 `CalculateWellnessScoreUseCaseTests`에 13개 있으므로 추가 테스트는 최소화
- **Verification**: 빌드 성공, 481+ 테스트 통과

## Edge Cases

| Case | Handling |
|------|----------|
| HRV 데이터 없음 (baseline 미완성) | 카드 미표시 (nil guard). Condition Score도 nil이면 상세화면에서 "Condition: No data" |
| RHR 데이터 없음 | 카드 미표시. 상세화면 sub-score에 "--" 표시 |
| Wellness Score nil (모든 sub-score 없음) | 히어로카드가 emptyCard 렌더 → NavigationLink 미적용 (기존 동작 유지) |
| HRV 값 범위 초과 | HRVQueryService에서 0-500ms 범위 검증 이미 존재 (Correction #22) |
| RHR 값 범위 초과 | HRVQueryService에서 20-300bpm 범위 검증 이미 존재 |
| iPad multitasking 전환 | sizeClass 기반 adaptive layout |

## Testing Strategy

- Unit tests: 기존 `CalculateWellnessScoreUseCaseTests` 13개가 score 로직 커버. 추가 필요 없음
- Integration: 빌드 + 기존 테스트 suite 통과로 regression 검증
- Manual verification: 시뮬레이터에서 hero card 탭 → 상세화면, HRV/RHR 카드 표시 + 탭 → MetricDetailView 확인

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| condition task refactoring으로 기존 score 로직 깨짐 | Low | High | conditionResult FetchValue를 확장하되 기존 flow 유지. 테스트로 regression 검증 |
| HRV sparkline fetch 추가로 HealthKit 쿼리 과다 | Low | Medium | HRVQueryService.fetchHRVCollection은 이미 최적화됨. 7일 범위는 경량 |
| NavigationLink 중첩 시 WelinessHeroCard accessibility 깨짐 | Medium | Low | .accessibilityElement(children: .combine) 유지, NavigationLink는 View 레벨에서 적용 |

## Confidence Assessment

- **Overall**: High
- **Reasoning**: ConditionScoreDetailView가 완벽한 참조 아키텍처. HRV/RHR 데이터 경로가 이미 존재하고 MetricDetailView도 대응 완료. 주요 작업은 데이터 노출 + 새 View 1개 생성.
