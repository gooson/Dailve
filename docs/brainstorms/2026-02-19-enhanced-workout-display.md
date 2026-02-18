---
tags: [healthkit, workout, display, personal-records, training-load, effort, milestone]
date: 2026-02-19
category: brainstorm
status: draft
---

# Brainstorm: Enhanced Workout Display & Training Intelligence

## Problem Statement

현재 HealthKit 외부 운동이 "Running, 32분, 245kcal" 수준으로만 표시되어 사용자가 운동 내용을 파악하기 어렵다. HealthKit에는 심박수, 페이스, 고도, 날씨, Effort Score 등 풍부한 데이터가 있지만 활용되지 않고 있다.

또한 5K/10K 완주, 개인기록 경신 등 특별한 성취를 시각적으로 강조하지 않아 동기부여 기회를 놓치고 있으며, Apple Fitness의 Training Load(훈련량) 정보도 제공되지 않는다.

## Target Users

- 정기적으로 운동하며 Apple Watch로 운동을 기록하는 사용자
- 러닝/사이클링 등 거리 기반 운동을 하는 사용자
- 운동 강도와 훈련량 추세를 추적하고 싶은 사용자

## Success Criteria

1. HealthKit 외부 운동 탭 시 상세뷰에서 심박수, 페이스, 고도, 날씨 등 전체 데이터 확인 가능
2. 5K/10K 달성, 개인기록 경신 등 특별한 워크아웃이 리스트에서 시각적으로 구분됨
3. 7일/28일 Training Load 추세가 차트로 표시됨
4. 운동 완료 시 RPE(주관적 강도) 입력 + Apple Effort Score 자동 표시

## Proposed Approach

### Feature 1: Rich Workout Detail (HealthKit 외부 운동 상세 표시)

**리스트 강화:**
- 운동 타입별 아이콘 + 컬러 (80+ HKWorkoutActivityType 전체 매핑)
- 심박수 avg, 페이스(거리 기반), 고도 상승을 row에 요약 표시
- 실내/실외 인디케이터

**상세뷰 (새로운 `HealthKitWorkoutDetailView`):**
- 헤더: 운동 타입 아이콘 + 이름 + 날짜/시간 + 시간 + 칼로리
- 심박수 차트 (기존 `HeartRateQueryService` 활용)
- 페이스/속도 통계 (avg/min/max)
- 고도 상승 (metadata)
- 날씨 정보 (온도 + 상태 + 습도)
- 랩/세그먼트 리스트 (`workoutEvents`)
- Effort Score (수동 RPE + 자동)
- 루트 맵 (향후 — `HKWorkoutRoute` + MapKit)

**데이터 모델 확장:**
```
WorkoutSummary 확장 (또는 새로운 WorkoutDetail 타입):
  + heartRateAvg: Double?
  + heartRateMax: Double?
  + heartRateMin: Double?
  + averagePace: Double?        // sec/km (러닝/워킹)
  + averageSpeed: Double?       // m/s (사이클링 등)
  + elevationAscended: Double?  // meters
  + weatherTemperature: Double? // celsius
  + weatherCondition: Int?      // HKWeatherCondition rawValue
  + weatherHumidity: Double?    // percent
  + isIndoor: Bool?
  + effortScore: Double?        // 1-10 (user or estimated)
  + laps: [WorkoutLap]?
  + stepCount: Double?
```

**HKWorkoutActivityType 전체 매핑:**
- 현재 14개 → 80+ 전체 케이스 매핑
- 각 타입에 SF Symbol + 컬러 + 한국어 이름

### Feature 2: Milestone & Personal Record Badges

**마일스톤 (거리 달성):**
- 1K / 5K / 10K / 하프마라톤(21.1km) / 풀마라톤(42.2km) 완주 감지
- 리스트에서 뱃지 표시: 🏅 아이콘 + 거리 라벨
- 첫 달성 vs 반복 달성 구분

**개인기록 (Personal Records):**
- 추적 항목:
  - 특정 거리 최고 페이스 (5K PR, 10K PR 등)
  - 최장 거리 (러닝/사이클링별)
  - 최대 칼로리 소모
  - 최대 고도 상승
- PR 경신 시 리스트에서 특별 표시:
  - 골드 테두리 또는 그라데이션 배경
  - "PR" 뱃지
  - 이전 기록 대비 개선 폭 표시

**구현 접근:**
- `PersonalRecordService` (Domain): 역대 기록 비교 로직
- PR 데이터는 UserDefaults 또는 SwiftData에 캐시 (매번 전체 히스토리 스캔 불필요)
- 새 워크아웃 fetch 시 PR 체크 → badge 플래그 부여

**시각적 구분 (리스트):**
```
일반 워크아웃:     기본 row
마일스톤 달성:     🏅 뱃지 + subtle highlight
개인기록 경신:     ⭐ 뱃지 + gold accent border + "PR" 태그
마일스톤 + PR:     양쪽 모두 표시
```

### Feature 3: Training Load (자체 계산)

**Apple Training Load API가 비공개이므로 자체 계산:**

**계산 방식 (Simplified TRIMP):**
```
workoutLoad = duration(min) × avgHR_ratio × intensityFactor

avgHR_ratio = (avgHR - restingHR) / (maxHR - restingHR)
maxHR = 220 - age (또는 HealthKit에서 가져온 실측값)
intensityFactor = 가중치 (higher HR zone → exponentially higher load)
```

**대안: Effort Score 기반 (더 단순):**
```
workoutLoad = effortScore(1-10) × duration(min) / 60
```

**표시:**
- 7일 합산 Training Load 바 차트
- 28일 추세 라인 차트
- 증가/감소/안정 인디케이터
- 권장 범위 표시 (과훈련 경고)

**데이터 소스 우선순위:**
1. Apple Estimated Workout Effort Score (자동)
2. 사용자 입력 RPE (수동)
3. 심박수 기반 TRIMP 계산 (fallback)

### Feature 4: 운동 강도 입력 & 자동 측정

**수동 RPE 입력:**
- 운동 완료 후 RPE(1-10) 슬라이더 또는 이모지 기반 선택
- 1-2: 매우 쉬움, 3-4: 쉬움, 5-6: 보통, 7-8: 힘듦, 9-10: 최대
- `ExerciseRecord`에 `rpe: Int?` 필드 추가
- HealthKit에 `workoutEffortScore`로 저장 (양방향 sync)

**자동 Effort Score:**
- HealthKit `estimatedWorkoutEffortScore` 읽기
- 수동 RPE가 없을 때 자동 표시
- 수동 RPE 입력 시 자동 점수와 나란히 표시하여 비교

**입력 UI:**
- 운동 완료 sheet에 "How hard was it?" 섹션 추가
- 이모지 스케일: 😴 → 😐 → 😤 → 🔥 → 💀
- 선택 optional (스킵 가능)

**HealthKit 연동:**
```swift
// Read
HKQuantityType(.workoutEffortScore)
HKQuantityType(.estimatedWorkoutEffortScore)

// Write
HKUnit.appleEffortScore()
healthStore.relateWorkoutEffortSample(sample, with: workout, activity: nil)
```

## Constraints

### 기술적 제약
- **Training Load API 비공개**: Apple의 Training Load는 제3자 접근 불가 → 자체 계산 필수
- **Heart Rate Zones 비공개**: 심박수 존 계산도 자체 구현 필요
- **GPS 루트**: `HKWorkoutRoute` 읽기는 별도 권한 + 비동기 스트림 처리 필요
- **Effort Score**: iOS 18+ 한정 (older iOS 지원 시 조건부 사용)
- **전체 히스토리 스캔**: PR 계산에 전체 워크아웃 히스토리 필요 → 캐싱 전략 필수

### 아키텍처 제약
- Domain에 HealthKit import 금지 → 모든 HK 타입 변환은 Data 레이어에서
- ViewModel에 SwiftData import 금지 → PR 캐시 접근은 서비스 추상화 필요
- `WorkoutSummary` 확장 시 기존 API 호환성 유지

### 성능 제약
- 리스트 표시용 데이터는 batch fetch (상세 데이터는 lazy load)
- HR 샘플, 루트 데이터는 상세뷰 진입 시에만 fetch
- PR 비교는 캐시된 기록과만 비교 (매번 전체 스캔 X)

## Edge Cases

- HealthKit 권한 거부 시 → 기본 정보(타입/시간/칼로리)만 표시, 상세 데이터 영역에 "권한 필요" 안내
- 심박수 데이터 없는 워크아웃 → HR 섹션 숨김 (수동 입력 워크아웃 등)
- 거리 0인 워크아웃 → 마일스톤 체크 스킵
- 러닝 중 GPS 끊김 → 거리 데이터 부정확 가능, PR 판정에 최소 신뢰도 threshold
- 첫 번째 워크아웃 → 비교 대상 없으므로 "첫 기록!" 뱃지
- Effort Score 미지원 기기/OS → RPE 수동 입력으로 fallback
- 극단적 HR 값 (센서 오류) → 20-300 BPM 범위 필터 (기존 규칙)

## Scope

### MVP (Must-have)
- [ ] HKWorkoutActivityType 전체 매핑 (아이콘 + 한국어 이름 + 컬러)
- [ ] `WorkoutSummary` 확장: HR avg, 페이스, 고도, 날씨
- [ ] 리스트 row 강화: 운동별 아이콘/컬러 + 핵심 지표 1-2개
- [ ] `HealthKitWorkoutDetailView` 상세뷰: HR 차트, 페이스, 고도, 날씨
- [ ] 5K/10K/하프/풀 마일스톤 뱃지
- [ ] 개인기록(PR) 감지 + 리스트 골드 하이라이트
- [ ] RPE 입력 UI (운동 완료 시)
- [ ] Effort Score 읽기 + 표시

### Nice-to-have (Future)
- [ ] GPS 루트 맵 (MapKit)
- [ ] 랩/세그먼트 분석 뷰
- [ ] Training Load 7일/28일 차트
- [ ] TRIMP 기반 자체 Training Load 계산
- [ ] 심박수 존 계산 + 존별 시간 분포
- [ ] RPE → HealthKit workoutEffortScore 쓰기
- [ ] PR 히스토리 (기록 변천 차트)
- [ ] 마일스톤 달성 축하 애니메이션
- [ ] 주간/월간 운동 요약 리포트
- [ ] Watch에서 RPE 입력

## Open Questions

1. **마일스톤 기준**: 5K/10K/하프/풀 외에 추가할 거리 기준이 있는가? (예: 1마일, 100K 울트라 등)
2. **PR 범위**: 전체 기간 PR만? 또는 최근 90일/1년 PR도 별도 추적?
3. **Training Load 우선순위**: MVP에 포함할지, 상세 표시 + 뱃지 이후 별도 phase로?
4. **컬러 체계**: 운동 타입별 컬러를 어떻게 할 것인가? (카테고리별 그룹 컬러 vs 개별 컬러)
5. **Watch 연동**: RPE 입력을 Watch에서도 할 것인가? (운동 직후 Watch에서 입력이 더 자연스러움)

## Next Steps

- [ ] `/plan`으로 구현 계획 생성 (MVP 범위)
- [ ] Feature 1 (Rich Display) → Feature 2 (Badges) → Feature 4 (RPE) → Feature 3 (Training Load) 순서 권장
