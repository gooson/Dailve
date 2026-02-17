---
topic: exercise-visual-guide
date: 2026-02-17
status: draft
confidence: high
related_solutions: []
related_brainstorms: [2026-02-17-exercise-visual-guide]
---

# Implementation Plan: 운동 시각 가이드 + 한글/영어 병기

## Context

운동 등록 시 "체스트 프레스 머신"이 정확히 어떤 동작/기구인지 이해하기 어려움.
텍스트 설명만으로는 부족하며, 머슬맵(어떤 근육을 쓰는지)과 기구 설명(뭘로 하는지),
그리고 한글/영어 이름 병기가 필요.

## Requirements

### Functional

1. **ExerciseDetailSheet에 머슬맵** — primaryMuscles(진한색)/secondaryMuscles(연한색) 하이라이트
2. **ExerciseDetailSheet에 기구 설명** — Equipment별 아이콘 + 한글 1-2줄 설명
3. **한글/영어 병기** — 한글 주(localizedName) + 영어 부제(name) 형태로 3곳 통일
4. **MuscleGroup/Equipment 한글 활성화** — 이미 정의된 `localizedDisplayName` 사용

### Non-functional

- 기존 MuscleMapView (주간 볼륨 기반) 재사용하되, 운동별 하이라이트 모드 추가
- 번들 크기 증가 없음 (벡터 기반 + SF Symbols)
- 다크 모드 호환

## Approach

기존 `MuscleMapView`의 body outline + muscle position 데이터를 재사용하여
`ExerciseMuscleMapView`(운동별 하이라이트 전용 컴팩트 뷰)를 새로 만듦.
기존 MuscleMapView는 @Query 기반 주간 볼륨 표시용이므로, 데이터만 공유하고 View는 분리.

### Alternative Approaches Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| 기존 MuscleMapView에 모드 파라미터 추가 | 코드 재사용 극대화 | @Query 의존성 + 복잡도 증가, 역할 혼재 | ❌ Rejected |
| **새 ExerciseMuscleMapView + 공유 데이터** | 단일 책임, 컴팩트 크기 최적화, @Query 불필요 | Shape 데이터 복사 | ✅ Selected |
| 외부 이미지 에셋 사용 | 미적 퀄리티 높음 | 번들 크기 증가, 유지보수 부담 | ❌ Rejected |

**데이터 공유 방식**: `MuscleMapData.swift`로 공유 데이터(bodyOutline, frontMuscles, backMuscles, MuscleMapItem)를 추출.
두 View 모두 이 파일을 참조.

## Affected Files

| File | Change Type | Description |
|------|-------------|-------------|
| `Presentation/Shared/Components/MuscleMapData.swift` | **New** | bodyOutline Path + MuscleMapItem + frontMuscles/backMuscles 데이터 |
| `Presentation/Shared/Components/ExerciseMuscleMapView.swift` | **New** | 운동별 primary/secondary 하이라이트 컴팩트 뷰 (front+back 나란히) |
| `Presentation/Exercise/Components/MuscleMapView.swift` | **Modify** | 공유 데이터를 MuscleMapData에서 import하도록 변경 |
| `Presentation/Exercise/Components/ExerciseDetailSheet.swift` | **Modify** | 머슬맵 + 기구 설명 섹션 추가, 한글/영어 병기 |
| `Presentation/Exercise/Components/ExercisePickerView.swift` | **Modify** | 행에 영어 부제 추가, muscle/equipment chip 한글화 |
| `Presentation/Shared/Extensions/Equipment+View.swift` | **Modify** | `equipmentDescription` (한글 설명) 프로퍼티 추가 |
| `Presentation/Exercise/ExerciseViewModel.swift` | **Modify** | ExerciseListItem에 `localizedType` 필드 추가 |
| `Presentation/Exercise/ExerciseView.swift` | **Modify** | ExerciseRowView에서 한글/영어 병기 |
| `Presentation/Exercise/ExerciseHistoryView.swift` | **Modify** | navigationTitle 한글명 사용 |

## Implementation Steps

### Step 1: MuscleMapData 추출 (공유 데이터 분리)

- **Files**: `Presentation/Shared/Components/MuscleMapData.swift` (new), `Presentation/Exercise/Components/MuscleMapView.swift` (modify)
- **Changes**:
  - `MuscleMapItem`, `frontMuscles`, `backMuscles`, `bodyOutline()` 함수를 `MuscleMapData.swift`로 이동
  - `MuscleMapItem`을 `internal`로 공개 (현재 `private`)
  - 기존 `MuscleMapView`가 `MuscleMapData`를 참조하도록 수정
- **Verification**: 기존 MuscleMapView 동작 변화 없음 확인

### Step 2: ExerciseMuscleMapView 생성 (운동별 하이라이트)

- **Files**: `Presentation/Shared/Components/ExerciseMuscleMapView.swift` (new)
- **Changes**:
  - Input: `primaryMuscles: [MuscleGroup]`, `secondaryMuscles: [MuscleGroup]`
  - Front + Back 나란히 표시 (HStack)
  - Primary → `DS.Color.activity.opacity(0.7)`, Secondary → `DS.Color.activity.opacity(0.25)`
  - 나머지 근육 → `Color.secondary.opacity(0.08)`
  - 컴팩트 크기: height 160pt (detail sheet용)
  - "Front" / "Back" 라벨 하단에 표시
- **Verification**: Preview에서 다양한 근육 조합 확인

### Step 3: Equipment 한글 설명 추가

- **Files**: `Presentation/Shared/Extensions/Equipment+View.swift` (modify)
- **Changes**:
  - `equipmentDescription: String` computed property 추가 (한글 1-2줄 설명)
  - barbell: "긴 봉에 원판을 끼워 사용하는 프리웨이트 기구. 높은 중량 훈련에 적합"
  - dumbbell: "한 손에 하나씩 드는 프리웨이트. 좌우 균형 발달에 효과적"
  - machine: "가이드 레일이 있어 궤적이 고정된 기구. 초보자도 안전하게 사용 가능"
  - cable: "도르래와 케이블로 연결된 기구. 다양한 각도에서 저항 운동 가능"
  - bodyweight: "기구 없이 자기 체중만으로 수행하는 운동"
  - band: "탄성 밴드를 이용한 저항 운동. 강도 조절이 쉽고 휴대 가능"
  - kettlebell: "손잡이가 달린 구형 중량 기구. 스윙, 클린 등 동적 운동에 적합"
  - other: "기타 보조 기구"
- **Verification**: 빌드 성공

### Step 4: ExerciseDetailSheet 개선

- **Files**: `Presentation/Exercise/Components/ExerciseDetailSheet.swift` (modify)
- **Changes**:
  1. **Header 한글/영어 병기**:
     - Line 50: `exercise.name` → `exercise.localizedName` (주 이름)
     - 아래에 `exercise.name` caption 크기로 추가 (영어 부제)
     - Category/Equipment label도 `localizedDisplayName` 사용
  2. **머슬맵 섹션 추가** (muscleSection 위에):
     - `ExerciseMuscleMapView(primary:secondary:)` 삽입
     - 섹션 헤더: "타겟 근육"
  3. **기구 설명 섹션 추가** (infoSection 내 통합):
     - Equipment 아이콘 (`exercise.equipment.iconName`) + 한글명 + 설명
     - `exercise.equipment.localizedDisplayName` + `exercise.equipment.equipmentDescription`
  4. **Muscle 태그 한글화**:
     - `muscle.displayName` → `muscle.localizedDisplayName`
- **Verification**: Detail 시트에서 머슬맵 + 기구 설명 + 한글명 확인

### Step 5: ExercisePickerView 한글 개선

- **Files**: `Presentation/Exercise/Components/ExercisePickerView.swift` (modify)
- **Changes**:
  1. **exerciseRow 영어 부제 추가** (line 209 아래):
     - `exercise.name` caption 크기로 추가
  2. **Muscle 정보 한글화** (line 222):
     - `\.displayName` → `\.localizedDisplayName`
  3. **Equipment 정보 한글화** (line 227):
     - `.displayName` → `.localizedDisplayName`
  4. **필터 chip 한글화**:
     - `muscleChip`: `muscle.displayName` → `muscle.localizedDisplayName`
     - `equipmentChip`: `equipment.displayName` → `equipment.localizedDisplayName`
- **Verification**: Picker에서 한글/영어 병기 + 필터 chip 한글 확인

### Step 6: ExerciseView (기록 목록) 한글 병기

- **Files**: `Presentation/Exercise/ExerciseViewModel.swift`, `Presentation/Exercise/ExerciseView.swift` (modify)
- **Changes**:
  1. **ExerciseListItem에 `localizedType` 추가**:
     - `let localizedType: String?` 필드 추가
     - manual 레코드: `ExerciseLibraryService.shared.exercise(byID: record.exerciseDefinitionID)?.localizedName`
     - HealthKit 레코드: `nil` (HealthKit은 localized name 없음)
  2. **ExerciseRowView 병기**:
     - `localizedType`이 있고 `type`과 다르면: localizedType(주) + type(부제)
     - 없으면: type만 표시 (기존 동작 유지)
  3. **ExerciseHistoryView**:
     - `exerciseName` 파라미터 → localizedName 전달
- **Verification**: 운동 기록 목록에서 한글/영어 병기 확인

## Edge Cases

| Case | Handling |
|------|----------|
| 근육 데이터 없는 운동 (HealthKit import) | ExerciseMuscleMapView 숨김, 기존 UI 유지 |
| 커스텀 운동 (근육 미선택) | 빈 실루엣만 표시 (모든 근육 inactive) |
| Equipment가 .other인 경우 | 기본 아이콘 + "기타 보조 기구" 설명 |
| HealthKit 운동 (localizedType 없음) | 영어 type만 표시 (기존 동작) |
| 다크 모드 | body outline: `Color.secondary.opacity(0.3)`, 근육: DS.Color.activity 기반 — 양 모드 호환 |
| iPad 가로 모드 | ExerciseMuscleMapView front+back HStack이 자연스럽게 확장 |

## Testing Strategy

- **Unit tests**: 없음 (순수 UI 변경이므로 테스트 면제 대상)
- **Manual verification**:
  - ExerciseDetailSheet: 머슬맵 표시 + 기구 설명 + 한글/영어 병기
  - ExercisePickerView: 행 한글/영어 + 필터 chip 한글
  - ExerciseView: 기록 목록 한글/영어 병기
  - 다크 모드 전환
  - iPad multitasking

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| ExerciseListItem 변경이 기존 테스트 깨뜨림 | Medium | Low | 기본값 `localizedType: String? = nil`로 하위 호환 |
| MuscleMapData 추출 시 기존 MuscleMapView 깨짐 | Low | Medium | Step 1 완료 후 즉시 빌드 검증 |
| Detail 시트 높이 증가로 UX 변화 | Low | Low | .medium detent에서 스크롤 가능 |

## Confidence Assessment

- **Overall**: High
- **Reasoning**:
  - 대부분 기존 데이터/코드 재사용 (localizedName, localizedDisplayName, MuscleMapView 데이터)
  - 새 파일은 2개만 (MuscleMapData, ExerciseMuscleMapView)
  - Domain 레이어 변경 없음 (Presentation 레이어만)
  - 6단계 모두 독립적으로 검증 가능
