---
topic: dailve-mvp-implementation
date: 2026-02-15
status: approved
confidence: high
related_solutions: []
related_brainstorms: [2026-02-15-health-app-foundation]
---

# Implementation Plan: Dailve MVP

## Context

Dailve(Daily + Live)는 HRV/RHR 기반 컨디션 분석, 운동, 수면, 체성분을 하나의 미니멀 대시보드에서 관리하는 개인용 iOS 건강앱이다. brainstorm 단계에서 앱 이름, 기술 스택, 대시보드 디자인, MVP 범위가 모두 확정되었다.

이 계획서는 Xcode 프로젝트 초기화부터 MVP 기능 완성까지의 단계별 구현 계획을 정의한다.

## Requirements

### Functional

1. HealthKit에서 HRV(SDNN), RHR, 걸음 수, 수면 데이터 읽기
2. HRV 7일 평균 대비 오늘 수치로 컨디션 점수(0-100) 산출
3. 히어로 + 카드 레이아웃 대시보드 (스마트 정렬, 7일 트렌드)
4. 운동 기록 (수동 입력 + HealthKit 자동 연동)
5. 수면 기록 (HealthKit 자동 연동 + 수면 점수)
6. 체중/체성분 수동 기록
7. 주간/월간 트렌드 차트 (도트+라인, Swift Charts)
8. iCloud 동기화 (SwiftData + CloudKit)

### Non-functional

- iOS 26+ 최소 지원
- Swift 6 Strict Concurrency
- 60fps 대시보드 렌더링
- HealthKit 쿼리 < 500ms
- iCloud 동기화 < 3s
- 다크/라이트 모드 자동 전환
- 시스템 폰트 + Dynamic Type 지원

## Approach

**MVVM + Clean Architecture** (3-Layer)

```
Dailve/
├── App/                         # App entry point, DI
│   ├── DailveApp.swift
│   └── ContentView.swift
├── Presentation/                # SwiftUI Views + ViewModels
│   ├── Dashboard/
│   ├── Exercise/
│   ├── Sleep/
│   ├── BodyComposition/
│   └── Shared/                  # 공통 컴포넌트 (카드, 차트)
├── Domain/                      # 비즈니스 로직 (플랫폼 무관)
│   ├── Models/                  # Domain entities
│   ├── UseCases/                # 비즈니스 규칙
│   └── Repositories/            # Protocol 정의만
├── Data/                        # 구체적 구현
│   ├── HealthKit/               # HK 쿼리 서비스
│   ├── Persistence/             # SwiftData @Model + Repository 구현
│   └── Extensions/
└── Resources/                   # Assets, Localizable
```

### Alternative Approaches Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| TCA (The Composable Architecture) | 상태 관리 체계적, 테스트 용이 | 러닝커브, 개인 프로젝트에 과잉 | ❌ 불채택 |
| MVVM + @Observable (선택) | iOS 26 네이티브, 간결, 성능 우수 | 대규모 앱에서 상태 흐름 복잡 | ✅ 채택 |
| MV (View-Model only) | 최소 보일러플레이트 | HealthKit/SwiftData 로직이 View에 섞임 | ❌ 불채택 |

## Affected Files

### 신규 생성

| File | Change Type | Description |
|------|-------------|-------------|
| `Dailve.xcodeproj` | Create | Xcode 프로젝트 |
| `DailveApp.swift` | Create | App entry point + ModelContainer 설정 |
| `ContentView.swift` | Create | TabView 루트 |
| **Domain Layer** | | |
| `Domain/Models/ConditionScore.swift` | Create | 컨디션 점수 도메인 모델 |
| `Domain/Models/HealthMetric.swift` | Create | 건강 지표 공통 모델 |
| `Domain/UseCases/CalculateConditionScoreUseCase.swift` | Create | HRV 기반 점수 산출 로직 |
| `Domain/Repositories/HealthDataRepository.swift` | Create | Protocol 정의 |
| `Domain/Repositories/BodyCompositionRepository.swift` | Create | Protocol 정의 |
| **Data Layer** | | |
| `Data/HealthKit/HealthKitManager.swift` | Create | HK 권한 + store 관리 |
| `Data/HealthKit/HRVQueryService.swift` | Create | HRV/RHR 쿼리 |
| `Data/HealthKit/SleepQueryService.swift` | Create | 수면 데이터 쿼리 |
| `Data/HealthKit/WorkoutQueryService.swift` | Create | 운동 데이터 쿼리 |
| `Data/HealthKit/StepsQueryService.swift` | Create | 걸음 수 쿼리 |
| `Data/Persistence/Models/BodyCompositionRecord.swift` | Create | @Model 체성분 기록 |
| `Data/Persistence/Models/ExerciseRecord.swift` | Create | @Model 운동 기록 |
| `Data/Persistence/HealthDataRepositoryImpl.swift` | Create | Repository 구현 |
| **Presentation Layer** | | |
| `Presentation/Dashboard/DashboardView.swift` | Create | 메인 대시보드 |
| `Presentation/Dashboard/DashboardViewModel.swift` | Create | 대시보드 VM |
| `Presentation/Dashboard/Components/ConditionHeroView.swift` | Create | 컨디션 점수 히어로 |
| `Presentation/Dashboard/Components/MetricCardView.swift` | Create | 지표 카드 |
| `Presentation/Dashboard/Components/TrendChartView.swift` | Create | 7일 트렌드 차트 |
| `Presentation/Exercise/ExerciseView.swift` | Create | 운동 기록 화면 |
| `Presentation/Exercise/ExerciseViewModel.swift` | Create | 운동 VM |
| `Presentation/Sleep/SleepView.swift` | Create | 수면 화면 |
| `Presentation/Sleep/SleepViewModel.swift` | Create | 수면 VM |
| `Presentation/BodyComposition/BodyCompositionView.swift` | Create | 체성분 화면 |
| `Presentation/BodyComposition/BodyCompositionViewModel.swift` | Create | 체성분 VM |
| `Presentation/Shared/Charts/DotLineChartView.swift` | Create | 공통 도트+라인 차트 |
| `Presentation/Shared/Components/SmartCardGrid.swift` | Create | 스마트 정렬 카드 그리드 |

## Implementation Steps

### Step 1: 프로젝트 셋업

- **Goal**: Xcode 프로젝트 생성 + 기본 인프라 구성
- **Files**: `Dailve.xcodeproj`, `DailveApp.swift`, `ContentView.swift`, `.gitignore`, `Info.plist`
- **Changes**:
  - Xcode에서 iOS App 프로젝트 생성 (SwiftUI, Swift, iOS 26+)
  - HealthKit capability 추가 + Usage Description
  - iCloud capability 추가 (CloudKit container: `iCloud.com.dailve.health`)
  - Background Modes (Remote Notifications) 추가
  - 폴더 구조 생성 (App/Domain/Data/Presentation/Resources)
  - git init + .gitignore
- **Verification**: 빌드 성공, 빈 앱이 시뮬레이터에서 실행됨

### Step 2: SwiftData 모델 + CloudKit

- **Goal**: 데이터 모델 정의 + iCloud 동기화 설정
- **Files**: `BodyCompositionRecord.swift`, `ExerciseRecord.swift`, `DailveApp.swift`
- **Changes**:
  - `@Model` 클래스 정의 (CloudKit 호환: 모든 프로퍼티 optional 또는 default)
  - `ModelContainer` 설정 (`ModelConfiguration(cloudKitDatabase: .private)`)
  - `BodyCompositionRecord`: date, weight, bodyFatPercentage, muscleMass, memo
  - `ExerciseRecord`: date, type, duration, calories, distance, memo
- **Verification**: 앱 실행 시 SwiftData 컨테이너 정상 생성, 실기기에서 iCloud 동기화 확인

### Step 3: HealthKit 연동

- **Goal**: HealthKit 권한 요청 + 데이터 읽기 서비스
- **Files**: `HealthKitManager.swift`, `HRVQueryService.swift`, `SleepQueryService.swift`, `WorkoutQueryService.swift`, `StepsQueryService.swift`
- **Changes**:
  - `HealthKitManager`: 권한 요청 (HRV, RHR, steps, sleep, workout)
  - 각 서비스: `HKSampleQueryDescriptor` + async/await 패턴
  - HRV: 7일간 `heartRateVariabilitySDNN` 샘플 조회
  - RHR: `restingHeartRate` 조회
  - 수면: `sleepAnalysis` 카테고리 (Core/Deep/REM/Awake 구분)
  - 운동: `HKWorkout` 조회 (타입, 시간, 칼로리)
  - 걸음 수: `HKStatisticsQuery`로 일별 합계
- **Verification**: 실기기에서 HealthKit 데이터 읽기 성공 (Simulator 불가)

### Step 4: 컨디션 점수 알고리즘

- **Goal**: HRV/RHR 기반 컨디션 점수 산출
- **Files**: `CalculateConditionScoreUseCase.swift`, `ConditionScore.swift`, `HealthMetric.swift`
- **Changes**:
  - `ConditionScore`: score(0-100), status(enum), color, emoji
  - 알고리즘:
    1. 7일간 ln(SDNN) 수집
    2. 7일 롤링 평균(baseline) 산출
    3. CV(변동계수) 산출 → normal range 결정
    4. 오늘 ln(SDNN)과 baseline 비교 → 0-100 점수 매핑
    5. RHR 트렌드 보정 (RHR 상승 + HRV 하락 = 더 강한 피로 신호)
  - 7일 미만 데이터: "기준선 설정 중" 상태 표시
  - 점수 → 상태 매핑 (80-100 매우좋음, 60-79 좋음, 40-59 보통, 20-39 피로, 0-19 주의)
- **Verification**: Unit test — 다양한 HRV 패턴에 대해 예상 점수 범위 검증

### Step 5: 메인 대시보드

- **Goal**: 히어로 + 카드 레이아웃 대시보드 구현
- **Files**: `DashboardView.swift`, `DashboardViewModel.swift`, `ConditionHeroView.swift`, `MetricCardView.swift`, `TrendChartView.swift`, `SmartCardGrid.swift`
- **Changes**:
  - `DashboardViewModel` (@Observable, @MainActor): HealthKit 데이터 fetch + 점수 산출
  - `ConditionHeroView`: 큰 숫자 + 색상 배경 + 이모지 + 7일 도트+라인 미니 트렌드
  - `MetricCardView`: 지표명, 현재값, 변화량(▲▼), 탭 시 확장
  - `SmartCardGrid`: 변화량 절대값 기준 정렬 + 재배치 애니메이션
  - 애니메이션: 점수 카운트업, 배경색 그라데이션 전환, 카드 패럴랙스
  - Pull-to-refresh: 순차적 카드 갱신 애니메이션
  - 시스템 다크/라이트 자동 전환
- **Verification**: 시뮬레이터에서 UI 렌더링 확인, 실기기에서 HealthKit 데이터 반영 확인

### Step 6: 운동 기록

- **Goal**: 수동 입력 + HealthKit 연동 운동 기록
- **Files**: `ExerciseView.swift`, `ExerciseViewModel.swift`, `ExerciseRecord.swift`
- **Changes**:
  - 운동 목록 화면 (HealthKit 자동 데이터 + 수동 입력 데이터 통합)
  - 수동 입력 폼: 운동 종류, 시간, 칼로리, 거리, 메모
  - SwiftData 저장 (수동 입력만)
  - 주간/월간 운동 요약 차트
- **Verification**: 수동 입력 → 저장 → 목록 표시 흐름 확인

### Step 7: 수면 기록

- **Goal**: HealthKit 수면 데이터 시각화 + 수면 점수
- **Files**: `SleepView.swift`, `SleepViewModel.swift`
- **Changes**:
  - HealthKit 수면 단계별 시각화 (Core/Deep/REM/Awake 바 차트)
  - 수면 시간 합계 + 수면 효율(%) 산출
  - 수면 점수 산출 (총 시간 + 깊은 수면 비율 + 일관성)
  - 주간 수면 트렌드 차트
- **Verification**: 실기기에서 수면 데이터 표시 확인

### Step 8: 체중/체성분 기록

- **Goal**: 수동 입력 체중/체성분 추적
- **Files**: `BodyCompositionView.swift`, `BodyCompositionViewModel.swift`
- **Changes**:
  - 입력 폼: 체중, 체지방률, 근육량, 메모
  - 히스토리 목록 + 수정/삭제
  - 체중 변화 트렌드 차트 (도트+라인)
  - SwiftData 저장 + iCloud 동기화
- **Verification**: 입력 → 저장 → 차트 반영 → 다른 기기에서 iCloud 동기화 확인

### Step 9: 트렌드 차트 통합

- **Goal**: 주간/월간 통합 트렌드 뷰
- **Files**: `DotLineChartView.swift`, 각 ViewModel 트렌드 데이터 추가
- **Changes**:
  - 공통 `DotLineChartView`: Swift Charts, LineMark + PointMark, 탭 선택, 스크롤
  - 기간 토글 (7일/30일/90일)
  - `.chartScrollableAxes(.horizontal)` + `.chartXVisibleDomain(length:)`
  - 각 지표별 트렌드 차트를 대시보드 카드 확장 시 표시
  - 기준선(baseline) RuleMark 표시
- **Verification**: 다양한 기간의 차트 렌더링 + 인터랙션 확인

## Edge Cases

| Case | Handling |
|------|----------|
| Apple Watch 없음 | HRV/RHR 데이터 없음 → "Apple Watch를 연결하세요" 안내 + 수동 입력 UI |
| HealthKit 권한 거부 | 빈 데이터 → 수동 입력 모드로 전환, 설정 앱 이동 버튼 제공 |
| 7일 미만 HRV 데이터 | "기준선 설정 중 (N/7일)" 프로그레스 표시, 점수 미산출 |
| iCloud 동기화 충돌 | CloudKit 기본 정책(last-writer-wins) 사용 |
| HRV 0 또는 비정상값 | ln(0) 방지: SDNN < 1ms 필터링, 이상치 제외 |
| 수면 데이터 소스 중복 | sourceRevision 기반 중복 제거, 우선순위: Apple Watch > iPhone |
| 빈 대시보드 (첫 실행) | 온보딩 → HealthKit 권한 → 빈 카드에 "데이터 없음" placeholder |
| 오프라인 상태 | 로컬 SwiftData 정상 작동, 온라인 복귀 시 자동 동기화 |

## Testing Strategy

- **Unit tests**:
  - `CalculateConditionScoreUseCase`: 다양한 HRV 패턴 → 예상 점수 범위
  - ln(SDNN) 변환 정확도
  - 7일 미만 데이터 핸들링
  - 스마트 정렬 로직 (변화량 기준 정렬)
  - 수면 점수 산출 로직

- **Integration tests**:
  - SwiftData CRUD + CloudKit 동기화
  - HealthKit 쿼리 (실기기 필수)

- **Manual verification**:
  - 실기기에서 전체 사용자 플로우 (첫 실행 → 권한 → 대시보드 → 기록)
  - 다크/라이트 모드 전환
  - Dynamic Type 크기 변경
  - iCloud 동기화 (두 대 이상 기기)
  - 애니메이션 60fps 확인 (Instruments)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| HealthKit 시뮬레이터 불가 | 확실 | 높음 | 실기기 테스트 필수, Mock 서비스로 UI 개발 |
| CloudKit 동기화 지연/실패 | 중간 | 중간 | 로컬 우선 동작, 동기화 상태 표시 UI |
| HRV 데이터 희소 (1일 0-3회) | 높음 | 중간 | 빈 데이터 UI, 전날 데이터 fallback |
| SwiftData + CloudKit unique 제약 불가 | 확실 | 낮음 | 앱 레벨에서 중복 방지 로직 |
| 컨디션 점수 정확도 | 중간 | 중간 | 초기에는 단순 알고리즘, 사용하며 점진적 보정 |

## Confidence Assessment

- **Overall**: **High**
- **Reasoning**:
  - 기술 스택(SwiftUI, HealthKit, SwiftData)이 모두 iOS 26 네이티브로 잘 문서화됨
  - 개인 프로젝트로 외부 의존성/조율 비용 없음
  - brainstorm에서 모든 핵심 결정이 완료됨
  - 각 단계가 독립적으로 구현/테스트 가능
  - iOS 고급 개발 경험 보유

## Implementation Timeline (권장 순서)

```
Step 1: 프로젝트 셋업           ← 시작점
Step 2: SwiftData + CloudKit    ← 데이터 기반
Step 3: HealthKit 연동          ← 데이터 소스
Step 4: 컨디션 점수 알고리즘      ← 핵심 로직
Step 5: 메인 대시보드            ← 핵심 UI
Step 6: 운동 기록               ← 기능 확장
Step 7: 수면 기록               ← 기능 확장
Step 8: 체성분 기록              ← 기능 확장
Step 9: 트렌드 차트 통합          ← 마무리
```

## Next Steps

- [ ] 이 계획 승인
- [ ] `/work` 으로 Step 1부터 구현 시작
