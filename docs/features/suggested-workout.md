---
tags: [activity, workout, recommendation, muscle-recovery]
date: 2026-02-17
category: feature-spec
status: reviewed
---

# Suggested Workout 기능 상세 설명

## 개요

Activity 탭의 Suggested Workout은 **회복 기반 운동 추천 엔진**이다. 사용자의 최근 운동 기록(SwiftData)을 분석하여 근육군별 피로/회복 상태를 계산하고, 충분히 회복된 근육을 타겟으로 하는 운동 목록을 추천한다.

## 데이터 흐름

```
SwiftData (@Query)
    └── ExerciseRecord[] (sets, primaryMusclesRaw, secondaryMusclesRaw)
            │
            ▼  ActivityView.task + onChange(of: recentRecords.count)
    ActivityViewModel.updateSuggestion(records:)
            │
            ├── ExerciseRecord → ExerciseRecordSnapshot[] 변환 (SwiftData 의존성 제거)
            │
            ▼
    WorkoutRecommendationService.recommend(from:library:)
            │
            ├── computeFatigueStates()  →  [MuscleFatigueState]
            │       └── records.weeklyMuscleVolume() (Collection extension)
            │
            ├── 후보 필터링/정렬 (isRecovered && !isOverworked)
            │
            ├── focusMuscle별 → ExerciseLibraryService.exercises(forMuscle:)
            │       └── exercises.json에서 로드된 in-memory 데이터 조회
            │
            └── WorkoutSuggestion { exercises, reasoning, focusMuscles } 반환
                        │
                        ▼
    ActivityViewModel.workoutSuggestion (@Observable 상태)
                        │
                        ▼
    ActivityView → SuggestedWorkoutCard(suggestion:onStartExercise:)
```

## 추천 알고리즘

### Step 1: 근육군별 피로 상태 계산 (`computeFatigueStates`)

13개 `MuscleGroup` 각각에 대해:

| 항목 | 계산 방식 |
|------|-----------|
| **마지막 훈련일** | 해당 근육을 타겟(primary/secondary)으로 한 가장 최근 `ExerciseRecord`의 날짜 |
| **회복률** | `hoursSinceLastTrained / 72.0`, 0.0~1.0으로 clamp. 훈련 기록 없으면 1.0(완전 회복) |
| **주간 볼륨** | `weeklyMuscleVolume()`: primary → 전체 세트 수, secondary → `max(setCount / 2, 1)` |

**핵심 상수**:
- 완전 회복 시간: **72시간 (3일)**
- Secondary 근육 피로 배율: **0.5x**

### Step 2: 후보 근육군 선별 및 정렬

**필터 조건**:
- `recoveryPercent >= 0.8` (80% 이상 회복됨)
- `weeklyVolume < 20` (주간 20세트 미만 — 과훈련 아님)

**정렬 기준**:
1. `recoveryPercent` 내림차순 (가장 회복된 근육 우선)
2. 동점 시 `weeklyVolume` 오름차순 (볼륨이 적은 근육 우선)

### Step 3: 운동 선택

- 상위 **3개 근육**을 `focusMuscles`로 선정
- 각 focus muscle에 대해 `ExerciseLibraryService.exercises(forMuscle:)` 호출
- `.strength` 또는 `.bodyweight` 카테고리만 필터링
- 매칭되는 **첫 번째** 운동을 선택 (결정론적 — 동일 근육이면 항상 같은 운동)

**추천 세트 수 계산**:
```swift
let remaining = max(20 - weeklyVolume, 0)
let suggestedSets = min(max(remaining / 2, 2), 5)  // 2~5 범위로 clamp
```

### Step 4: 복합 운동으로 보충

추천 운동이 4개 미만이면 **compound exercise** (primaryMuscles >= 2 또는 secondaryMuscles 있음)에서 보충. 각 3세트로 추천.

### Step 5: 추천 이유 텍스트 생성

운동별 reason:

| 조건 | 메시지 |
|------|--------|
| 마지막 훈련 >= 3일 | "N days since last trained, M sets this week" |
| 주간 볼륨 < 10세트 | "Low weekly volume (M sets), room for more" |
| 그 외 | "Recovered and ready for training" |

전체 reasoning: `"Focus on X, Y, Z — these muscles are well-recovered and could use more volume this week."`

## 관련 파일

| 파일 | 레이어 | 역할 |
|------|--------|------|
| `Domain/UseCases/WorkoutRecommendationService.swift` | Domain | 핵심 추천 엔진 + 도메인 모델 (`WorkoutSuggestion`, `SuggestedExercise`, `MuscleFatigueState`, `ExerciseRecordSnapshot`, `WorkoutRecommending` protocol) |
| `Domain/Models/ExerciseDefinition.swift` | Domain | 운동 정의 엔티티 (Codable, Identifiable, Sendable) |
| `Domain/Models/MuscleGroup.swift` | Domain | `enum MuscleGroup: String, CaseIterable` (13개 근육군) |
| `Domain/Protocols/ExerciseLibraryQuerying.swift` | Domain | 운동 라이브러리 프로토콜 |
| `Data/ExerciseLibraryService.swift` | Data | `exercises.json` 로드, `static let shared` 싱글턴 |
| `Data/Resources/exercises.json` | Data | 번들 JSON (1,135줄, 전체 운동 정의) |
| `Data/Persistence/Models/ExerciseRecord.swift` | Data | SwiftData `@Model`, `primaryMusclesRaw`/`secondaryMusclesRaw` 저장 |
| `Presentation/Shared/Extensions/ExerciseRecord+WeeklyVolume.swift` | Shared | `weeklyMuscleVolume(from:days:)` Collection extension |
| `Presentation/Activity/ActivityViewModel.swift` | Presentation | `@Observable` ViewModel, `updateSuggestion(records:)` 호출 |
| `Presentation/Activity/ActivityView.swift` | Presentation | `.task`와 `.onChange(of: recentRecords.count)`에서 트리거 |
| `Presentation/Exercise/Components/SuggestedWorkoutCard.swift` | Presentation | 추천 카드 UI 컴포넌트 |

## UI 구성 (SuggestedWorkoutCard)

1. **헤더**: `sparkles` 아이콘 + "Suggested Workout" 레이블
2. **Focus 근육 칩**: `HStack` — 각 `focusMuscle.displayName`을 `Capsule` 형태로 표시, `DS.Color.activity` 색상
3. **운동 행**: `ForEach`로 각 운동 표시
   - 운동 이름 (`definition.localizedName`)
   - 추천 세트 수 ("4 sets")
   - 탭 → `onStartExercise(exercise.definition)` → `WorkoutSessionView`로 네비게이션
4. **Rest day 메시지**: 추천 운동이 없으면 reasoning 텍스트만 표시

## 트리거 시점

| 시점 | 방식 |
|------|------|
| 화면 최초 로드 | `.task` modifier |
| 운동 기록 추가/삭제 | `.onChange(of: recentRecords.count)` |

## 핵심 상수 정리

| 상수 | 값 | 의미 |
|------|---|------|
| 완전 회복 시간 | 72시간 | 이 시간 이후 recoveryPercent = 1.0 |
| 회복 임계값 | 0.8 (80%) | 이 이상이면 "회복됨" 판정 |
| 주간 최대 볼륨 | 20세트 | 이 이상이면 "과훈련" 판정 |
| Secondary 배율 | 0.5x | 보조 근육은 절반만 볼륨 계산 |
| 목표 추천 수 | 4개 | 부족하면 compound로 보충 |
| 추천 세트 범위 | 2~5 | suggestedSets clamp 범위 |

## 알려진 제한 사항

1. **결정론적 운동 선택**: 항상 라이브러리의 `.first`를 선택하여 같은 근육이면 항상 같은 운동이 추천됨. 랜덤화 미구현
2. **정적 운동 데이터**: `exercises.json` 기반 싱글턴. 서버/동적 데이터 미지원
3. **일 단위 회복 계산**: `Calendar.dateComponents([.day], ...)`로 계산하여, 밤 11시 운동 → 새벽 1시 체크 시 "1일" 경과로 처리됨 (실제 2시간)
4. **reasoning에 rawValue 사용**: focusMuscles 이유 텍스트에서 `muscle.rawValue` ("quadriceps") 사용 — `displayName` 미적용
