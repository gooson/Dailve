---
tags: [ux, wellness, redesign, healthkit, whoop, oura, grid-layout, wellness-score, vitals]
date: 2026-02-20
category: brainstorm
status: draft
---

# Brainstorm: Wellness 탭 UX/UI 개편 v2

## Problem Statement

현재 Wellness 탭은 Sleep → Injuries → Body 3섹션이 세로로 나열된 단순 리스트 구조.
**4가지 핵심 문제:**

1. **정보 밀도 낮음**: 스크롤이 많은데 데이터는 적음. 카드 간 여백이 크고 데이터가 희소
2. **강조점 부재**: 수면/부상/체성분이 동등하게 나열되어 탭을 열었을 때 "무엇을 봐야 하는지" 불명확
3. **미활용 HealthKit 데이터**: SpO2, 호흡수, 체온, VO2 Max, HR Recovery 등 Apple Watch가 수집하는 생체신호를 전혀 표시하지 않음
4. **트렌드 파악 어려움**: 주간 차트가 작고 데이터 포인트 적음. 장기 추세 확인 불가

## Target Users

- **Primary**: Apple Watch 착용 30-50대 건강 관심자
- **Secondary**: 운동인 (회복 상태 기반 트레이닝 강도 조절)
- **Key need**: "오늘 몸 상태가 어떤가?" → 단일 스코어 + 핵심 지표 한 눈에

## Design References

| 앱 | 차용할 점 | 차용하지 않을 점 |
|----|----------|-----------------|
| WHOOP | Recovery Score 중심 구조, 그린 그라디언트 색상 체계, 데이터 밀도 | 과도한 페이월, 복잡한 온보딩 |
| Oura Ring | Readiness Score 링 UI, 세부 지표 분해, 미니멀 고급감 | 3링 동시 표시의 복잡성 |
| Apple Health | 2칸 그리드 카드 레이아웃, 카테고리별 고유색, 정보 밀도 | 탐색 위주라 한 눈 파악 어려움 |
| Athlytic | HRV/Recovery→훈련 추천 연결, 운동선수 중심 UX | 과도한 숫자 나열 |

## Success Criteria

- [ ] 통합 Wellness Score가 탭 최상단 히어로에 표시
- [ ] 2칸 그리드로 정보 밀도 2배 향상 (스크롤 깊이 50% 감소)
- [ ] 6개 이상 HealthKit 생체신호 표시 (현재 3개 → 9개+)
- [ ] 데이터 없을 때 온보딩 가이드 empty state
- [ ] 그린 계열 통일 색상 체계
- [ ] 각 카드 탭 → 상세 트렌드 뷰 진입 가능

---

## Proposed Architecture

### 1. 히어로 카드: 통합 Wellness Score

```
┌─────────────────────────────────────┐
│         Today's Wellness            │
│                                     │
│          ┌───────┐                  │
│          │  82   │   Good           │
│          │  /100 │                  │
│          └───────┘                  │
│                                     │
│   Sleep 85   HRV 78   Body 84      │
│   ▪▪▪▪▪▪▪    ▪▪▪▪▪▪   ▪▪▪▪▪▪▪     │
│                                     │
│   "Well recovered. Ready for       │
│    high intensity training."        │
└─────────────────────────────────────┘
```

**구성 요소:**
- **중앙 링**: 0-100 통합 스코어 (Sleep 40% + HRV/RHR 35% + Body Trend 25%)
- **3개 서브 스코어**: 각각 미니 프로그레스 바
- **상태 텍스트**: 스코어 구간별 자연어 메시지
- **색상**: 스코어 기반 그라디언트 (Green 80+ / Yellow 50-79 / Red <50)
- **탭 액션**: 탭하면 스코어 산출 근거 상세 뷰

**스코어 산출 로직 (Domain):**
```
wellnessScore = sleepScore × 0.40
             + conditionScore × 0.35  (기존 HRV+RHR 기반)
             + bodyTrendScore × 0.25  (체중/체지방 목표 대비 방향)
```

### 2. 2칸 그리드 레이아웃: Vital Cards

히어로 카드 아래에 Apple Health 스타일 2칸 그리드로 핵심 지표 배치.

```
┌───────────────┬───────────────┐
│ 💤 Sleep      │ ❤️ SpO2       │
│ 7h 42m        │ 98%           │
│ Score: 85     │ ▲0.5%         │
│ ▪▪▪▪▪ stage   │ mini sparkline│
├───────────────┼───────────────┤
│ 🫁 Resp Rate  │ 🌡 Wrist Temp │
│ 14.2 /min     │ +0.2°C        │
│ ▼0.3 vs avg  │ baseline diff │
│ mini sparkline│ mini sparkline│
├───────────────┼───────────────┤
│ 🏃 VO2 Max    │ 💓 HR Recovery│
│ 45.2 ml/kg/m  │ 42 bpm/min   │
│ ▲1.2 vs 30d  │ Good          │
│ mini sparkline│ mini sparkline│
├───────────────┼───────────────┤
│ ⚖️ Weight     │ 📊 Body Fat   │
│ 75.2 kg       │ 18.5%         │
│ ▼0.3 vs 7d   │ ▼0.2% vs 7d  │
│ mini sparkline│ mini sparkline│
├───────────────┼───────────────┤
│ 💪 Muscle     │ 📏 BMI        │
│ 61.5 kg       │ 23.1          │
│ ▲0.2 vs 7d   │ Normal range  │
│ mini sparkline│ mini sparkline│
└───────────────┴───────────────┘
```

**각 카드 구성:**
- 아이콘 + 라벨
- 현재 값 (큰 폰트)
- 변화량 (vs 7일 전 or vs 개인 평균)
- 미니 스파크라인 (7일 트렌드)
- 탭 → 상세 차트 뷰 (MetricDetailView 재활용)

### 3. 조건부 섹션: Active Injuries

부상이 있을 때만 표시. 그리드 하단에 전체 너비 배너.

```
┌─────────────────────────────────────┐
│ ⚠️ Active Injuries (2)             │
│ ┌─────────┐  ┌─────────┐           │
│ │ 🦵 Left  │  │ 💪 Right│           │
│ │ Knee     │  │ Shoulder│           │
│ │ Moderate │  │ Mild    │           │
│ │ 12 days  │  │ 3 days  │           │
│ └─────────┘  └─────────┘           │
│                      View All →     │
└─────────────────────────────────────┘
```

### 4. Weekly Insights 섹션 (하단)

```
┌─────────────────────────────────────┐
│ 📈 This Week                        │
│                                     │
│ Wellness Score Trend (7d BarChart)  │
│ ▇ ▇ ▆ ▇ ▅ ▇ ▇                      │
│ M T W T F S S                       │
│                                     │
│ ▲ Avg Sleep: 7h 32m (+18min)       │
│ ▲ Avg VO2 Max: 45.2 (+0.8)        │
│ ▼ Avg Weight: 75.2 (-0.3kg)       │
└─────────────────────────────────────┘
```

---

## 새로 추가할 HealthKit 데이터

### 필수 추가 (MVP)

| 데이터 | HK Type | 단위 | 표시 위치 |
|--------|---------|------|----------|
| SpO2 | `oxygenSaturation` | % | 그리드 카드 |
| 호흡수 | `respiratoryRate` | /min | 그리드 카드 |
| 손목 체온 | `appleSleepingWristTemperature` | °C (baseline diff) | 그리드 카드 |
| VO2 Max | `vo2Max` | ml/kg/min | 그리드 카드 |
| HR Recovery | `heartRateRecoveryOneMinute` | bpm/min | 그리드 카드 |
| BMI | `bodyMassIndex` | count | 그리드 카드 (이미 서비스 존재) |

### Nice-to-have (Future)

| 데이터 | HK Type | 근거 |
|--------|---------|------|
| Mindful Sessions | `mindfulSession` | 스트레스/회복 맥락 |
| Walking HR Avg | `walkingHeartRateAverage` | 유산소 체력 프록시 |
| Stand Time | `appleStandTime` | 좌식 행동 추적 |
| Walking Steadiness | `appleWalkingSteadiness` | 부상 위험 지표 |

---

## 색상 체계: 그린 중심

### Wellness Score 색상

| 구간 | 색상 | 의미 |
|------|------|------|
| 80-100 | `#34C759` → `#00C7BE` (Green gradient) | Optimal / Well recovered |
| 60-79 | `#FFD60A` → `#FF9F0A` (Yellow-Orange) | Moderate / Some recovery needed |
| 40-59 | `#FF9F0A` → `#FF6B6B` (Orange-Red) | Low / Significant recovery needed |
| 0-39 | `#FF3B30` (Red) | Critical / Rest recommended |

### 카테고리 색상 (그리드 카드 악센트)

| 카테고리 | 색상 | Asset Name |
|---------|------|-----------|
| Sleep | Indigo `#5856D6` | `wellnessSleep` |
| Vitals (SpO2, Resp, Temp) | Teal `#00C7BE` | `wellnessVitals` |
| Fitness (VO2, HR Recovery) | Green `#34C759` | `wellnessFitness` |
| Body (Weight, Fat, Muscle, BMI) | Cyan `#32ADE6` | `wellnessBody` |
| Injury | Red `#FF3B30` | `wellnessInjury` |

### 히어로 카드 배경

- 다크 모드: `#1C1C1E` → 스코어 색상 그라디언트 (subtle, 10% opacity)
- 라이트 모드: White → 스코어 색상 tint (5% opacity)

---

## 기존 UI 개선사항

### 1. Sleep Section → 그리드 카드 압축

**Before**: SleepHeroCard (큰 링 + 단계별 바) + 주간 트렌드 차트 = 화면 60%
**After**: 2칸 그리드의 1칸 (Sleep 카드) + 탭하면 기존 상세뷰

개선:
- 수면 스코어 링 → 숫자 + 미니 프로그레스 바
- 단계별 바 → 카드 하단 1줄 컬러바 (터치하면 상세)
- 주간 트렌드 → 미니 스파크라인 (7 data points)

### 2. Body Section → 그리드 4칸 분해

**Before**: BodySnapshotCard (Weight + Fat + Muscle 한 카드) + 체중 트렌드 차트
**After**: Weight / Body Fat / Muscle / BMI 각각 독립 그리드 카드

개선:
- 각 지표가 독립 트렌드를 보여줌 (현재는 체중만 차트)
- 체지방/근육량도 미니 스파크라인으로 변화 확인 가능
- 탭하면 MetricDetailView로 30/90일 차트

### 3. Injury Section → 조건부 배너

**Before**: 항상 표시, 부상 없으면 빈 섹션 영역
**After**: 활성 부상 있을 때만 표시. 그리드 하단 전체 너비

개선:
- 부상 없는 사용자(대부분)에게 불필요한 공간 제거
- 있을 때는 눈에 띄는 배너로 경고성 표시

### 4. Empty State → 온보딩 가이드

**Before**: "Wear Apple Watch to bed..." 텍스트만
**After**: 단계별 온보딩 카드

```
┌─────────────────────────────────────┐
│         Set Up Wellness             │
│                                     │
│  ✅ Step 1: Connect Apple Watch     │
│  ✅ Step 2: Enable HealthKit        │
│  ⬜ Step 3: Wear Watch to sleep     │
│  ⬜ Step 4: Record a workout        │
│                                     │
│  Your wellness data will appear     │
│  within 24 hours of wearing your    │
│  Apple Watch.                       │
└─────────────────────────────────────┘
```

### 5. 트렌드 강화

**Before**: 7일 바 차트 (작고 데이터 적음)
**After**:
- 미니 스파크라인: 각 카드에 7일 인라인
- Weekly Insights: 주간 Wellness Score 트렌드 + 핵심 변화 요약
- 상세뷰: 7/30/90일 기간 선택 + 풀사이즈 차트

---

## Scope

### MVP (Must-have)

1. 통합 Wellness Score 히어로 카드
2. 2칸 그리드 레이아웃 전환
3. 기존 데이터(Sleep, Weight, Body Fat, Muscle) 그리드 카드화
4. 새 HealthKit 데이터 추가: SpO2, 호흡수, VO2 Max, HR Recovery
5. 그린 계열 색상 체계 적용
6. 조건부 Injury 배너
7. 데이터 없을 때 empty state 개선
8. 각 카드 탭 → 상세뷰 navigation

### Nice-to-have (Future)

- 손목 체온 (데이터 가용성 확인 필요)
- Mindful Sessions, Stand Time 카드
- Weekly Insights 섹션 (주간 요약)
- Wellness Score 산출 가중치 사용자 커스텀
- 카드 순서 사용자 커스텀 (드래그)
- 위젯 (iOS Widget)으로 Wellness Score 표시
- 30일/90일 장기 트렌드 상세뷰
- AI 기반 인사이트 ("수면 시간이 줄어들고 있습니다")

## Constraints

- iOS 26+ only
- Apple Watch 필수 (대부분의 HealthKit 데이터)
- HealthKit 권한 요청 항목 증가 (6개 추가) → 권한 요청 UX 고려
- 기존 SleepViewModel, BodyCompositionViewModel 재활용/리팩터
- MetricDetailView 패턴 재활용 가능
- SwiftData 모델 변경 없음 (HealthKit read-only 데이터)

## Edge Cases

- **Apple Watch 미착용**: 대부분 카드가 빈 상태 → 온보딩 가이드
- **일부 데이터만 존재**: SpO2 없고 수면만 있는 경우 → 카드 숨김 or "No data" placeholder
- **HealthKit 권한 거부**: 개별 타입별 거부 가능 → 거부된 카드 숨김 + 설정 안내
- **오래된 데이터**: 3일 이상 된 데이터는 "N days ago" 표시 + 연한 opacity
- **첫 사용**: 아직 24시간 미경과 → "Collecting data..." 로딩 상태
- **Wellness Score 계산 불가**: 구성 요소 중 2개 이상 없으면 스코어 대신 "Need more data"

## Decisions (Resolved)

1. **Body Trend 가중치**: 목표 체중 설정 불필요. 최근 7일 체중/체지방 변화 방향성만으로 산출
2. **그리드 카드 순서**: 데이터 가용성 기반 동적 배치. 데이터 있는 카드가 상단으로
3. **Condition Score**: Today 탭의 Condition Score를 Wellness Score로 통합. Today 탭에서 제거
4. **HR Recovery**: 운동 안 한 날은 마지막 기록 유지 + "N days ago" 라벨 표시

## Implementation Phases

### Phase 1: 인프라 (1-2일)
- 새 HealthKit 쿼리 서비스 추가 (SpO2, Resp, VO2, HR Recovery)
- Domain 모델 정의
- HealthKitManager readTypes 확장

### Phase 2: Wellness Score (2-3일)
- 스코어 산출 UseCase
- 히어로 카드 UI
- 색상 시스템

### Phase 3: 그리드 레이아웃 (2-3일)
- VitalCard 공통 컴포넌트
- 2칸 LazyVGrid
- 기존 데이터 카드 마이그레이션
- 새 Vitals 카드

### Phase 4: 상세뷰 + 마무리 (1-2일)
- MetricDetailView 연결
- Empty state 개선
- Injury 배너 조건부 표시
- 애니메이션/트랜지션

## Next Steps

- [ ] `/plan wellness-tab-redesign-v2` 으로 상세 구현 계획 생성
- [ ] Phase 1부터 순차 구현
