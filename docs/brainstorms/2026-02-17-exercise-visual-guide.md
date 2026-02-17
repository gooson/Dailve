---
tags: [exercise, ux, muscle-map, localization, visual-guide]
date: 2026-02-17
category: brainstorm
status: draft
---

# Brainstorm: 운동 시각적 가이드 및 한글/영어 병기

## Problem Statement

운동 등록 시 "체스트 프레스 머신" 같은 운동이 정확히 어떤 동작인지 이해하기 어려움.
텍스트 설명만으로는 부족하며, 시각적 안내(이미지/다이어그램)와 함께 한글/영어 이름 병기가 필요.

## Target Users

- 헬스 초/중급자: 운동 이름만으로 동작을 파악하기 어려움
- 한국어 사용자: 영어 운동명에 익숙하지 않은 사용자
- 다양한 기구 경험이 없는 사용자: 머신/프리웨이트 구분이 필요

## Success Criteria

1. 운동 선택 시 어떤 근육을 사용하는지 시각적으로 즉시 파악 가능
2. 한글 이름으로 운동을 이해하고, 영어 이름으로 검색/참고 가능
3. Picker, Info 시트, 운동 기록 화면 모든 곳에서 일관된 경험

## Decisions

| 항목 | 결정 | 근거 |
|------|------|------|
| 이미지 형태 | 일러스트/다이어그램 (머슬맵) | 직관적 + 앱 번들 포함 가능 |
| 표시 위치 | Info 시트 + Picker 목록 + 운동 기록 화면 | 모든 접점에서 시각적 안내 |
| 이름 표기 | 한글 주 + 영어 부제 | 한국어 앱이므로 한글 우선 |
| 이미지 소스 | SF Symbols + 커스텀 머슬맵 | 무료, 오프라인, 즉시 구현 |

## Proposed Approach

### 1. 머슬맵 다이어그램 (MuscleMapView)

SwiftUI `Shape`/`Path` 기반 인체 실루엣 커스텀 View:
- `primaryMuscles` → 진한 accent 색
- `secondaryMuscles` → 연한 secondary 색
- 전면(front) + 후면(back) 나란히 표시
- 크기 옵션: `.compact` (Picker 행), `.regular` (Detail 시트), `.large` (운동 기록)

### 2. 한글/영어 병기

기존 데이터 활용 (`name` + `localizedName`):
```
바벨 벤치프레스          ← localizedName (주)
Barbell Bench Press    ← name (부제, caption 크기)
```

적용 범위:
- ExercisePickerView 행
- ExerciseDetailSheet 헤더
- ExerciseView (운동 기록 목록)
- ExerciseHistoryView 네비게이션 타이틀
- MuscleGroup / Equipment 도 localizedDisplayName 활성화

### 3. Equipment 시각 가이드

각 Equipment 타입별 **일러스트 이미지 + 1-2줄 한글 설명**을 ExerciseDetailSheet에 통합 표시.

SF Symbols 매핑 (Picker 행/아이콘용):
- barbell → `figure.strengthtraining.traditional`
- dumbbell → `dumbbell.fill`
- machine → `gearshape.fill`
- cable → `cable.connector`
- bodyweight → `figure.stand`
- band → `circle.dotted`
- kettlebell → `figure.strengthtraining.functional`
- other → `ellipsis.circle`

Equipment 설명 데이터 (ExerciseDetailSheet 표시용):
- barbell: "긴 봉에 원판을 끼워 사용하는 프리웨이트 기구. 높은 중량 훈련에 적합"
- dumbbell: "한 손에 하나씩 드는 프리웨이트. 좌우 균형 발달에 효과적"
- machine: "가이드 레일이 있어 궤적이 고정된 기구. 초보자도 안전하게 사용 가능"
- cable: "도르래와 케이블로 연결된 기구. 다양한 각도에서 저항 운동 가능"
- bodyweight: "기구 없이 자기 체중만으로 수행하는 운동"
- band: "탄성 밴드를 이용한 저항 운동. 강도 조절이 쉽고 휴대 가능"
- kettlebell: "손잡이가 달린 구형 중량 기구. 스윙, 클린 등 동적 운동에 적합"
- other: "기타 보조 기구"

## Constraints

- **번들 크기**: 벡터 기반 머슬맵이므로 증가 미미
- **13개 근육 그룹**: 각각에 대한 Path 데이터 필요 (front/back)
- **~100개 운동**: 개별 이미지가 아닌 근육 기반이므로 스케일 가능
- **커스텀 운동**: 사용자가 선택한 근육 그룹으로 동일 머슬맵 표시

## Edge Cases

- **근육 데이터 없는 운동**: 빈 머슬맵 대신 카테고리 아이콘 표시
- **커스텀 운동**: 사용자가 근육 그룹을 선택하지 않으면 "전체" 실루엣만
- **다크 모드**: 실루엣/하이라이트 색상이 양 모드에서 가독성 유지

## Scope

### MVP (Must-have)
- [ ] MuscleMapView 커스텀 View (front/back, 13 muscle groups)
- [ ] 한글/영어 병기 — ExercisePickerView, ExerciseDetailSheet, ExerciseView
- [ ] ExerciseDetailSheet에 머슬맵 추가
- [ ] ExerciseDetailSheet에 기구 일러스트 + 한글 설명 통합
- [ ] ExercisePickerView 행에 컴팩트 머슬맵 또는 Equipment 아이콘
- [ ] MuscleGroup/Equipment localizedDisplayName UI 활성화
- [ ] Equipment 한글 설명 데이터 추가

### Nice-to-have (Future)
- [ ] 운동 동작 GIF/애니메이션
- [ ] 외부 API 연동으로 실제 사진 표시
- [ ] 3D 인체 모델 (회전 가능)
- [ ] 운동별 Form Cues 한국어 번역
- [ ] 커스텀 운동 이미지 업로드

## Open Questions

1. 머슬맵의 미적 수준 — 단순 실루엣 vs 해부학적 디테일?
2. Picker 행에 머슬맵이 들어가면 행 높이가 커지는데, 컴팩트 모드 크기는?
3. ExerciseDescriptions의 설명/Form Cues도 한국어로 번역할 것인지?

## Next Steps

- [ ] `/plan exercise-visual-guide` 로 구현 계획 생성
