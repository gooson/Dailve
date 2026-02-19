---
tags: [muscle-fatigue, recovery, sleep, hrv, training-load, visualization]
date: 2026-02-19
category: brainstorm
status: draft
---

# Brainstorm: 근육 피로도 10단계 세분화 시스템

## Problem Statement

현재 근육 회복 시스템은 **3단계(Fatigued/Recovering/Ready)** + **순수 시간 기반 선형 감쇠**로 구성되어 있어:
- 5km 러닝과 20km 러닝이 동일한 피로도로 계산됨
- 2일 연속 vs 10일 연속 같은 부위 훈련의 누적 차이가 없음
- 수면 질, HRV가 근육 회복에 반영되지 않음
- 3색(빨/노/초)만으로는 "조금 피곤" vs "극도로 피곤"을 구분할 수 없음

## Target Users

- HRV/컨디션 분석에 관심 있는 일반 피트니스 사용자
- 주 3-6회 운동하는 중급자 이상
- Apple Watch 사용자 (수면/HRV/운동 데이터 자동 수집)

## Success Criteria

1. 근육맵에서 10단계 색상이 직관적으로 구분됨
2. 연속 훈련 일수가 누적 피로에 반영됨
3. 숙면 후 회복 속도가 체감적으로 빨라짐
4. 인포 버튼으로 계산 과정이 투명하게 설명됨
5. 기존 운동 추천 엔진이 세분화된 피로도를 활용

---

## Industry Research Summary

### 주요 앱 비교

| 앱 | 스케일 | 근육별? | 수면 반영 | HRV 반영 | 누적 피로 |
|---|---|---|---|---|---|
| **Fitbod** | 0-100% | O | X | X | 볼륨 기반 |
| **WHOOP** | 0-100% (3색) | X | O | O | 전신만 |
| **Garmin** | 0-100 Body Battery | X | O | O | Training Load |
| **Apple Watch** | 1-10 Effort | X | X | X | 7/28일 비교 |
| **TrainingPeaks** | CTL/ATL/TSB | X | X | X | EWMA |
| **HRV4Training** | HRV baseline | X | O (간접) | O (핵심) | X |
| **Strava** | Fitness/Freshness | X | X | X | Banister 모델 |

### 핵심 인사이트

1. **Fitbod**: 유일하게 근육별 피로 추적. 0-100% 스케일 + 바디맵 히트맵. 볼륨(세트×무게) 기반
2. **WHOOP**: 수면 중 HRV/RHR/호흡으로 전신 회복도 계산. 3색 존(Red/Yellow/Green)
3. **Garmin**: Body Battery + Training Readiness. EPOC 기반 Training Effect (0-5)
4. **TrainingPeaks**: Banister 모델의 표준 구현. CTL(42일)/ATL(7일)/TSB 수학 모델
5. **HRV4Training**: HRV만으로 회복 판단. "수면이 나빠도 HRV가 괜찮으면 몸이 감당한 것" 철학

### 차별화 기회

- **아무도 하지 않는 것**: 근육별 피로 + 수면/HRV 통합 + 10단계 세분화
- Fitbod는 근육별이지만 수면/HRV 미반영
- WHOOP/Garmin은 수면/HRV 반영하지만 근육별 아님
- **우리의 포지셔닝**: 둘의 결합 = 근육별 피로 × 전신 회복 modifier

---

## Proposed Algorithm: Compound Fatigue Score (CFS)

### 아키텍처 개요

```
[Raw Inputs]                    [Processing]                    [Output]

Exercise Records ──┐
HealthKit Workouts─┤─→ Volume Load ──→ Base Fatigue ──┐
                   │                   (per muscle)    │
Recovery Hours ────┘                                   ├─→ Compound Fatigue Score
                                                       │   (0.0 ~ 1.0, 10 levels)
Sleep Duration ────┐                                   │
Sleep Quality ─────┤─→ Recovery Modifier ──────────────┤
                   │   (0.6x ~ 1.2x)                  │
HRV (SDNN) ────────┤                                   │
Resting HR ────────┘─→ Readiness Modifier ─────────────┘
                       (0.7x ~ 1.15x)
```

### Step 1: Base Fatigue (볼륨 + 시간)

**현재 문제**: `recovery = hoursSince / recoveryHours` (선형, 볼륨 무시)

**개선안**: 지수 감쇠(exponential decay) + 볼륨 가중치 + 누적

```
// 각 운동 세션별 피로 기여도
sessionFatigue(workout) = volumeLoad × muscleEngagement

// volumeLoad 계산
- 근력 운동: sets × reps × weight / bodyWeight (normalized)
- 유산소: distance(km) × durationMinutes / 60
- HealthKit 외부: activityType의 기본 부하값 × durationMinutes

// muscleEngagement
- primary muscle: 1.0
- secondary muscle: 0.4

// 누적 피로 (최근 14일, 지수 감쇠)
totalFatigue(muscle) = Σ sessionFatigue(i) × e^(-hoursSince(i) / tau)

tau = muscle.recoveryHours × 2  // 시간 상수 (감쇠 속도)
```

### Step 2: Recovery Modifier (수면)

```
// HealthKit 수면 데이터
sleepHours = 지난 밤 총 수면 시간
sleepQuality = deepSleep비율 + REMSleep비율 (0.0~1.0)

// Recovery Modifier 계산
sleepModifier = baseSleepFactor × qualityFactor

baseSleepFactor:
  >= 8h: 1.15 (보너스 회복)
  7-8h: 1.0 (정상)
  6-7h: 0.85 (약간 감소)
  5-6h: 0.70 (크게 감소)
  < 5h: 0.55 (극심하게 감소)

qualityFactor:
  deepSleep >= 20%: +0.05
  REMSleep >= 20%: +0.05
  둘 다 부족: -0.10
```

### Step 3: Readiness Modifier (HRV/RHR)

```
// 기존 ConditionScore 로직 재활용
hrvBaseline = 7일 평균 HRV
hrvToday = 오늘 HRV
hrvZScore = (hrvToday - hrvBaseline) / stdDev

rhrDelta = rhrToday - rhrYesterday

// Readiness Modifier
readinessModifier:
  hrvZScore >= +1.0 AND rhrDelta <= -2: 1.15 (최상 회복)
  hrvZScore >= 0 AND rhrDelta <= 0: 1.05 (양호)
  hrvZScore in -0.5...0: 1.0 (보통)
  hrvZScore in -1.0...-0.5: 0.85 (회복 지연)
  hrvZScore < -1.0 OR rhrDelta >= +5: 0.70 (심각한 회복 지연)
```

### Step 4: Compound Fatigue Score (CFS) 최종 계산

```
// 누적 피로에서 회복을 빼는 것이 아니라,
// 회복 modifier가 피로 감쇠 속도를 조절

effectiveTau = baseTau × sleepModifier × readinessModifier

// tau가 클수록 느리게 감쇠 = 느린 회복
// sleepModifier 1.15 → tau 감소 → 빠른 회복
// readinessModifier 0.70 → tau 증가 → 느린 회복

adjustedFatigue(muscle) = Σ sessionFatigue(i) × e^(-hoursSince(i) / effectiveTau)

// 정규화 (0.0 = 완전 회복, 1.0 = 극도 피로)
normalizedFatigue = min(adjustedFatigue / saturationThreshold, 1.0)

saturationThreshold = 대략 주간 MEV (Minimum Effective Volume) × 2
```

### Step 5: 10단계 매핑

| Level | Range | 한국어 라벨 | 영어 라벨 | 색상 | 의미 |
|---|---|---|---|---|---|
| 0 | 데이터 없음 | 미측정 | No Data | Gray | 한 번도 훈련하지 않음 |
| 1 | 0.00-0.05 | 완전 회복 | Fully Recovered | Deep Green | 최적 훈련 타이밍 |
| 2 | 0.05-0.15 | 회복 완료 | Well Rested | Green | 훈련 가능, 최적에 가까움 |
| 3 | 0.15-0.25 | 경미한 피로 | Light Fatigue | Light Green | 가벼운 훈련 가능 |
| 4 | 0.25-0.35 | 약간 피로 | Mild Fatigue | Yellow-Green | 주의하며 훈련 가능 |
| 5 | 0.35-0.50 | 피로 중간 | Moderate Fatigue | Yellow | 충분한 워밍업 필요 |
| 6 | 0.50-0.65 | 상당한 피로 | Notable Fatigue | Orange-Yellow | 볼륨 줄이기 권장 |
| 7 | 0.65-0.75 | 높은 피로 | High Fatigue | Orange | 가벼운 운동만 권장 |
| 8 | 0.75-0.85 | 매우 높은 피로 | Very High Fatigue | Red-Orange | 적극적 휴식 권장 |
| 9 | 0.85-0.95 | 극심한 피로 | Extreme Fatigue | Red | 과훈련 위험, 휴식 필수 |
| 10 | 0.95-1.00 | 과훈련 | Overtrained | Deep Red | 부상 위험, 즉시 휴식 |

### 색상 그라데이션 (10단계)

```swift
// SwiftUI Color interpolation
static func fatigueColor(level: Int) -> Color {
    switch level {
    case 0: return .secondary.opacity(0.2)       // Gray (no data)
    case 1: return Color(h: 140, s: 0.7, b: 0.5) // Deep Green
    case 2: return Color(h: 130, s: 0.6, b: 0.6) // Green
    case 3: return Color(h: 110, s: 0.5, b: 0.7) // Light Green
    case 4: return Color(h: 80, s: 0.5, b: 0.7)  // Yellow-Green
    case 5: return Color(h: 55, s: 0.6, b: 0.8)  // Yellow
    case 6: return Color(h: 40, s: 0.7, b: 0.8)  // Orange-Yellow
    case 7: return Color(h: 25, s: 0.8, b: 0.8)  // Orange
    case 8: return Color(h: 15, s: 0.8, b: 0.7)  // Red-Orange
    case 9: return Color(h: 5, s: 0.8, b: 0.65)  // Red
    case 10: return Color(h: 0, s: 0.9, b: 0.5)  // Deep Red
    default: return .secondary
    }
}
```

---

## 연속 훈련 누적 시나리오

### 예시: 매일 러닝 (다리 근육)

```
Day 1: 5km 러닝 → quads fatigue = 0.20 (Level 3)
Day 2: 5km 러닝 → quads fatigue = 0.20 + 0.17(어제 잔여) = 0.37 (Level 5)
Day 3: 5km 러닝 → quads fatigue = 0.20 + 0.14 + 0.12 = 0.46 (Level 5)
Day 5: 5km 러닝 → quads fatigue = 0.20 + ... 누적 = 0.55 (Level 6)
Day 10: 5km 러닝 → quads fatigue = 0.20 + ... 누적 = 0.72 (Level 7-8)
```

### 예시: 같은 근육 2일 연속 vs 10일 연속

```
2일 연속 chest:
  Day 1: bench press 5x5 → chest fatigue = 0.35 (Level 4)
  Day 2: bench press 5x5 → chest fatigue = 0.35 + 0.30 = 0.65 (Level 6)
  → 색상: Orange-Yellow → 볼륨 줄이기 권장

10일 연속 chest:
  Day 10 누적 → chest fatigue = 0.95+ (Level 10)
  → 색상: Deep Red → 과훈련 경고, 즉시 휴식
```

### 예시: 수면이 회복에 미치는 영향

```
Runner A (충분한 수면, HRV 양호):
  effectiveTau = 72h × 1.15 × 1.05 = 87h (빠른 회복)
  Day 3 잔여 피로: 0.08 (Level 2)

Runner B (수면 부족, HRV 저하):
  effectiveTau = 72h × 0.70 × 0.85 = 43h (느린 회복)
  Day 3 잔여 피로: 0.32 (Level 4)
```

---

## Info Button UI (계산 설명)

### 구조

인포 버튼 탭 시 `.sheet` 또는 `.popover`로 표시:

```
┌─────────────────────────────────────┐
│  ⓘ 피로도 계산 방법                    │
│                                     │
│  [대퇴사두근] Level 7 (0.68)         │
│                                     │
│  📊 누적 운동 부하                    │
│  ├ 2/17 스쿼트 5×5 (70kg) → 0.25    │
│  ├ 2/18 러닝 10km → 0.18            │
│  └ 2/19 레그프레스 4×10 → 0.22       │
│  소계: 0.65 → 감쇠 후: 0.52          │
│                                     │
│  😴 수면 회복 보정                    │
│  ├ 어젯밤 수면: 5.5h (부족)          │
│  ├ 깊은 수면: 12% (부족)             │
│  └ 보정 계수: ×0.75 (회복 지연)       │
│                                     │
│  ❤️ 생체 신호 보정                    │
│  ├ HRV: 42ms (기준선 55ms 대비 ↓)   │
│  ├ RHR: 62bpm (어제 58bpm 대비 ↑)   │
│  └ 보정 계수: ×0.85 (회복 지연)       │
│                                     │
│  ═══════════════════════════════     │
│  최종 피로도: 0.68 → Level 7         │
│  권장: 가벼운 운동만 권장              │
│                                     │
│  [10단계 색상 범례]                   │
│  ■■■■■■■■■■                         │
│  1  2  3  4  5  6  7  8  9  10      │
└─────────────────────────────────────┘
```

---

## Constraints

### 기술적 제약
- HealthKit 수면 데이터: Apple Watch 착용 시에만 자동 수집. 미착용 시 수면 modifier = 1.0 (기본값)
- HRV: 하루 1회 이상 측정값 필요. 없으면 readiness modifier = 1.0
- HealthKit 외부 운동: 정확한 세트/무게 없음 → 활동 유형별 기본 부하값 사용
- 14일 히스토리 필요: 데이터 부족 시 단순 시간 기반으로 fallback

### 성능 제약
- 14일 × 13 근육 × 여러 세션 = 계산량 많음 → 캐싱 필수
- 수면/HRV modifier는 하루 1회 계산 → 캐시 가능

### UX 제약
- 10단계가 시각적으로 구분되어야 함 → 색상 테스트 필수
- Dark mode에서도 명확한 구분 필요
- 접근성: 색각 이상 사용자를 위한 숫자/라벨 병행 표시

---

## Edge Cases

1. **첫 사용자 (데이터 없음)**: Level 0 (Gray) + "운동을 시작하면 피로도가 추적됩니다" 안내
2. **수면 데이터 없음**: sleepModifier = 1.0, 인포에 "수면 데이터 미수집" 표시
3. **HRV 없음**: readinessModifier = 1.0, 인포에 "HRV 미측정" 표시
4. **극단적 운동량**: saturationThreshold로 1.0 상한. Level 10 이상은 없음
5. **시간대 변경 (해외여행)**: UTC 기준 계산으로 일관성 유지
6. **오래된 데이터만 있음 (14일+ 이전)**: 지수 감쇠가 자연스럽게 0에 수렴 → Level 1

---

## Scope

### MVP (Must-have)
- [ ] Domain: `CompoundFatigueScore` 모델 (10단계 + 계산 상세)
- [ ] Domain: `FatigueCalculationService` (볼륨 기반 지수 감쇠 + 누적)
- [ ] Domain: `RecoveryModifierService` (수면 + HRV/RHR modifier)
- [ ] Data: HealthKit 수면 데이터 쿼리 (`SleepQueryService` 확장)
- [ ] Presentation: 10단계 색상 매핑 (`MuscleRecoveryMapView` 업데이트)
- [ ] Presentation: 인포 버튼 + 계산 설명 시트
- [ ] Presentation: 10단계 범례 업데이트
- [ ] 기존 `WorkoutRecommendationService` 연동 (세분화된 점수 활용)
- [ ] 유산소 운동 거리/시간 기반 부하 계산
- [ ] 단위 테스트 (모든 경계값, 수학 함수 방어)

### Nice-to-have (Future)
- [ ] ACWR (Acute:Chronic Workload Ratio) 부상 위험 경고
- [ ] 근육별 회복 시간 학습 (사용자별 개인화)
- [ ] 연속 훈련 일수 기반 추가 경고 배지
- [ ] Widget으로 오늘의 피로도 요약
- [ ] Watch complication으로 핵심 근육 피로도

## Open Questions

1. 10단계 색상이 근육맵 SVG에서 시각적으로 충분히 구분되는가? → 프로토타이핑 필요
2. `saturationThreshold`를 사용자별로 다르게 해야 하는가? (초보 vs 상급자)
3. 유산소 운동의 부하 기본값을 어떻게 정할 것인가? (활동 유형별 테이블)
4. 수면 modifier에 "수면 일관성" (일정한 취침/기상 시간)도 반영할 것인가?

## Next Steps

- [ ] `/plan` 으로 구현 계획 생성
- [ ] 10단계 색상 프로토타입 (dark/light mode)
- [ ] HealthKit 수면 데이터 쿼리 가능 범위 확인
