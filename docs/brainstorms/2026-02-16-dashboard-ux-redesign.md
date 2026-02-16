---
tags: [ux, dashboard, redesign, universal-app, ios26, condition-score, detail-view]
date: 2026-02-16
category: brainstorm
status: draft
---

# Brainstorm: Dashboard (첫 번째 탭) & 상세 화면 UX 재설계

## Problem Statement

현재 Dashboard 탭은 기능적으로 동작하지만, 20년차 iOS UX 디자이너 관점에서 다음 핵심 문제를 가짐:

1. **평면적 정보 구조**: Hero card 아래 모든 메트릭이 동일한 시각적 가중치로 나열됨 — HRV(핵심 건강 신호)와 Steps(일상 활동)가 구분 없이 나란히 배치
2. **점수의 블랙박스화**: Condition Score가 "왜" 그 수치인지 설명하지 않음 — 기여 요인(HRV 트렌드, RHR 변화, 수면 품질)이 보이지 않음
3. **상세 화면 인지 과부하**: ConditionScoreDetailView에 7개 섹션이 스크롤로 쌓여 핵심 인사이트가 fold 아래에 묻힘
4. **iPad 경험 미흡**: 3컬럼 그리드 + NavigationSplitView만으로 태블릿 최적화 부족
5. **경쟁사 대비 부족**: Oura Ring의 Score Attribution, WHOOP의 Recovery Gauge, Apple Health의 Highlights 대비 데이터만 보여주고 "의미"를 전달하지 않음

## Target Users

- **Primary**: Apple Watch 착용 30-50대 건강 관심자 — 아침에 오늘의 컨디션을 빠르게 확인하고 싶음
- **Secondary**: 운동인 — 훈련 강도 결정에 HRV 데이터 활용
- **Key need**: "숫자가 아니라 오늘 뭘 해야 하는지" 알고 싶음

## Success Criteria

- [ ] 첫 화면 3초 내 오늘의 컨디션 + 주요 원인 파악 가능
- [ ] Dynamic Type 전 단계 지원 (접근성)
- [ ] iPad에서 정보 밀도가 적절하고 빈 공간 없음
- [ ] 상세 화면 진입 후 핵심 인사이트가 fold 위에 노출
- [ ] VoiceOver로 차트 데이터 포인트 개별 탐색 가능

---

## 현재 상태 분석

### Dashboard (첫 번째 탭) 현재 구조

```
ScrollView
├── [Loading] ProgressView (스피너만, 스켈레톤 없음)
├── [Empty] EmptyStateView (액션 버튼 없음 — 복구 경로 없음)
├── [Baseline] BaselineProgressView (데이터 수집 중)
├── ConditionHeroView (88pt 링 + 상태 + 가이드 + 7일 스파크라인)
│   └── Tap → ConditionScoreDetailView
├── SmartCardGrid (2열/3열)
│   ├── MetricCardView (HRV)
│   ├── MetricCardView (RHR)
│   ├── MetricCardView (Sleep)
│   ├── MetricCardView (Steps)
│   ├── MetricCardView (Exercise)
│   └── MetricCardView (Weight)
│   └── 각각 Tap → MetricDetailView
└── Error text (캡션, 재시도 없음)
```

### ConditionScoreDetailView 현재 구조

```
ScrollView
├── ProgressRingView (120pt) + score + date
├── TimePeriod Picker (D/W/M/6M/Y)
├── Chart Header (범위 라벨 + 트렌드 토글)
├── DotLineChartView (StandardCard)
├── Summary Stats Card (Avg/Min/Max + 변화%)
├── ConditionInsightSection (상태별 인사이트)
├── Highlights Section (최고/최저/트렌드)
└── ConditionExplainerSection (점수 계산 설명, 접기 가능)
```

### MetricDetailView 현재 구조

```
ScrollView
├── MetricSummaryHeader (아이콘 + 이름 + 값 + 단위 + Avg/Min/Max + 변화 + 업데이트 시간)
├── TimePeriod Picker
├── Chart Header + Chart (카테고리별 다른 차트 타입)
├── ExerciseTotalsView (Exercise만)
├── MetricHighlightsView
└── "Show All Data" → AllDataView
```

---

## 발견된 문제점 (심각도순)

### Critical (즉시 수정 필요)

| # | 문제 | 파일 | 영향 |
|---|------|------|------|
| C-1 | **Dynamic Type 미지원**: `heroScore(56pt)`, `cardScore(28pt)` 하드코딩 | DesignSystem.swift | 접근성 위반 |
| C-2 | **Empty State 복구 경로 없음**: HealthKit 권한 거부 시 재요청 버튼 없음 | DashboardView.swift | 사용자 이탈 |
| C-3 | **Error State 재시도 없음**: `.caption` 텍스트만 표시 | DashboardView.swift | 사용자 무력감 |
| C-4 | **차트 VoiceOver 파괴**: `children: .combine`으로 모든 데이터 포인트 접근 불가 | DotLineChartView.swift 외 | 접근성 위반 |
| C-5 | **값+단위 붙임**: "72ms", "58bpm" — 읽기 어려움, VoiceOver "seventy two em ess" | HealthMetric+View.swift | 가독성/접근성 |
| C-6 | **한국어 날짜 하드코딩**: `"M월 d일 (E)"` — 다른 locale에서 깨짐 | TimePeriod+View.swift | 국제화 실패 |

### Important (개선 권장)

| # | 문제 | 설명 |
|---|------|------|
| I-1 | **평면적 정보 구조** | HRV와 Steps가 동일한 시각적 가중치 |
| I-2 | **Dashboard 업데이트 시간 없음** | 데이터 신선도 알 수 없음 |
| I-3 | **메트릭 카드에 트렌드 차트 없음** | 경쟁사 대비 정보 밀도 부족 |
| I-4 | **Unicode 삼각형 사용** | `▲▼` 대신 SF Symbol 사용해야 함 |
| I-5 | **상세 화면 인지 과부하** | 7개 섹션 일렬 나열, 인사이트 fold 아래 |
| I-6 | **PeriodSwipeModifier 미적용** | 구현됐으나 상세 화면에 미연결 |
| I-7 | **교차 메트릭 맥락 부재** | HRV 차트에 운동일 표시 없음 |
| I-8 | **로딩 스켈레톤 없음** | ProgressView 스피너만 표시 |
| I-9 | **Emoji 상태 표시** | SF Symbol로 교체 필요 |
| I-10 | **iPad 최소 대응** | 3열 그리드 + 기본 NavigationSplitView만 |

### Polish (완성도 향상)

| # | 문제 |
|---|------|
| P-1 | 배경 그라디언트가 점수 상태 반영 안 함 |
| P-2 | `.symbolEffect()` 미사용 |
| P-3 | Hero 스파크라인 32pt로 너무 작음 |
| P-4 | 메트릭 카드 탭 햅틱 없음 |
| P-5 | 카드 입장 애니메이션이 매 로드 재생 |
| P-6 | 탭바 탭 시 스크롤 투 탑 미구현 |
| P-7 | 상세 화면 요약 통계 시각적 가중치 부족 |
| P-8 | 기간 전환 시 차트 전환 애니메이션 없음 |

### Non-Functional / Architecture

| # | 문제 |
|---|------|
| N-1 | HealthKit 인증 매 로드 호출 (캐싱 필요) |
| N-2 | buildRecentScores 7일 매번 재계산 |
| N-3 | 스크롤 위치 변경 시 디바운스 없음 (프레임 드롭 위험) |
| N-4 | DotLineChartView에 Period/TimePeriod 이중 API |
| N-5 | 탭 전환 시 데이터 캐싱 없음 |
| N-6 | ConditionScore Hashable Date 취약성 |

---

## 제안: 개선된 Dashboard 구조

### 새로운 첫 번째 탭 Layout

```
ScrollView
├── [Loading] DashboardSkeletonView (.redacted)
├── [Empty] EmptyStateView + "설정에서 권한 허용" 버튼
│
├── ConditionHeroView (개선)
│   ├── Progress Ring (88pt) + Score
│   ├── Status SF Symbol + Label (emoji 제거)
│   ├── Guide Message (데이터 기반)
│   └── 7일 Sparkline (44pt로 확대, area fill 추가)
│
├── ── NEW ── Score Contributors Section
│   ├── "What affected your score"
│   ├── HRV: ● above baseline (+) / ● below baseline (-)
│   ├── RHR: ● stable / ● elevated
│   └── Sleep: ● sufficient / ● insufficient
│
├── Section Header: "Health Signals"
│   ├── MetricCardView (HRV) — 미니 스파크라인 추가
│   └── MetricCardView (RHR) — 미니 스파크라인 추가
│
├── Section Header: "Activity"
│   ├── MetricCardView (Sleep)
│   ├── MetricCardView (Steps)
│   ├── MetricCardView (Exercise)
│   └── MetricCardView (Weight)
│
├── ── NEW ── Recovery Trend Indicator
│   └── "3일 추세: 회복 중 ↑" / "안정 →" / "하락 중 ↓"
│
└── "Updated 5 min ago" (subtle footer)
```

### 개선된 ConditionScoreDetailView 구조

```
ScrollView
├── ProgressRingView (120pt) + Score + Date
│
├── ── 순서 변경 ── ConditionInsightSection (fold 위로 이동)
│   └── "오늘의 인사이트" — 먼저 "의미"를 전달
│
├── TimePeriod Picker (D/W/M/6M/Y)
│   └── PeriodSwipeModifier 적용
│
├── Chart Header + DotLineChartView
│   └── 운동일 표시 annotation marks 추가
│
├── Summary Stats Card (Avg 크기 확대: .title3)
│   └── "Your average is X% higher than last {period}" 문장 추가
│
├── Highlights Section
│
└── ConditionExplainerSection (유지, 접기)
```

### iPad 전용 개선

```
NavigationSplitView (.balanced → .prominent)
├── Sidebar (4 tabs as List)
└── Detail
    ├── Dashboard: 4열 그리드, 더 높은 정보 밀도
    ├── Metric Tap → Inspector panel (push 대신)
    └── Toolbar: Refresh, Date Navigation, Share
```

---

## 새로 추가할 정보/기능

### MVP (Must-have)

| 기능 | 설명 | 데이터 소스 |
|------|------|------------|
| **Score Contributors** | 점수에 영향을 준 요인 (HRV 트렌드, RHR 변화, 수면) | 이미 fetch 중인 데이터 |
| **Recovery Trend** | 3일 롤링 방향 (회복/안정/하락) | recentScores 기존 데이터 |
| **Mini Sparklines** | 메트릭 카드 하단 7일 트렌드 | 추가 fetch 필요 |
| **Dynamic Type** | 모든 텍스트 스케일링 | 코드 수정 |
| **Loading Skeleton** | 레이아웃 형태 유지하며 로딩 | 코드 수정 |
| **Error/Empty 복구** | 액션 버튼 추가 | 코드 수정 |
| **Chart Accessibility** | AXChartDescriptorRepresentable | 코드 수정 |

### Nice-to-have (Future)

| 기능 | 설명 |
|------|------|
| **Training Readiness** | 운동 강도 추천 ("고강도 가능" / "휴식 권장") |
| **Sleep Debt** | 7-14일 누적 수면 부족 시각화 |
| **Personal Range** | 전체 기간 대비 백분위 ("상위 30%") |
| **Interactive Widget** | Medium 위젯: 점수 링 + HRV + 수면 + 걸음 |
| **Morning Briefing** | 아침 알림: 오늘의 요약 + 가이드 |
| **Journal / Input** | 주관적 요인 기록 (카페인, 스트레스, 음주) |
| **Cross-metric Annotations** | 차트에 다른 메트릭 이벤트 표시 |
| **Live Activity** | 운동 중 Lock Screen에 실시간 표시 |

---

## iOS 17-26 트렌드 적용 현황

| Feature | 현재 | 권장 |
|---------|------|------|
| Dynamic Type | hardcoded sizes | `@ScaledMetric` 필수 |
| Interactive Widget | 미구현 | MVP 후 F3 |
| Live Activity | 미구현 | Future |
| TipKit | 미구현 | 점수 설명에 활용 가능 |
| `.symbolEffect()` | 미사용 | 아이콘 애니메이션에 적용 |
| `.containerRelativeFrame()` | 미사용 | iPad 카드 사이징 |
| `.contentTransition(.numericText())` | 사용 중 | OK |
| `.sensoryFeedback()` | 부분 사용 | 카드 탭에도 적용 |
| `@Observable` | 사용 중 | OK |
| Translucent materials | 3단계 사용 | OK |
| `NavigationSplitView` | 기본 구현 | Inspector 패턴 추가 |
| `AXChartDescriptor` | 미사용 | 필수 |

---

## 경쟁사 대비 Gap 분석

| 기능 | Oura | WHOOP | Apple Health | Athlytic | **Dailve** |
|------|------|-------|-------------|----------|-----------|
| Score Attribution | O (Contributors) | O (Recovery factors) | - | O | **X (최우선)** |
| Contextual Intelligence | O (AI insights) | O | O (Highlights) | Partial | **X (정적 메시지만)** |
| Mini Trend in Cards | O | O | O | O | **X** |
| Widget | O | O | O | O | **X** |
| Journal / Input | O | O | - | - | **X** |
| Training Readiness | O | O | - | O | **X** |
| Sleep Debt | O | O | - | - | **X** |
| Chart Annotations | O (activity markers) | - | O | - | **X** |

---

## Micro-interactions 개선 제안

| 항목 | 현재 | 개선 |
|------|------|------|
| Score Ring | 1초 spring fill | Overshoot 2-3% 후 settle back (Apple Watch 스타일) |
| Score Haptic | `.impact(weight: .light)` | 점수 비례 weight (excellent: heavy, tired: light) |
| Card Press | 없음 | `.scaleEffect(0.97)` on press (Weather 앱 패턴) |
| Period Switch | 즉시 전환 | 방향 슬라이드 + 크로스페이드 |
| Refresh Complete | 없음 | Hero card scale pulse (1.0 → 1.01 → 1.0) + 햅틱 |
| Tab Scroll-to-Top | 미구현 | ScrollViewReader 또는 iOS 17 scroll position API |

---

## Open Questions

1. Score Contributors UI: 상태바 (Oura 스타일) vs 텍스트 설명 (간결) vs 게이지 (WHOOP 스타일)?
2. Mini Sparkline: 7일 데이터 추가 fetch 비용 vs UX 가치 — 대시보드 로딩 시간 영향?
3. iPad Inspector: metric 상세를 trailing column inspector로 할지 sheet으로 할지?
4. 다국어: 현재 한국어 하드코딩 — 영어 지원 시점과 우선순위?
5. Training Readiness: 운동 부하 데이터(TRIMP 등) 추가 계산 필요 — MVP scope에 포함?

---

## Constraints

- **기술적**: iOS 26+, Swift 6, HealthKit 시뮬레이터 제한 (실기기 테스트 필수)
- **아키텍처**: Domain 레이어 SwiftUI import 금지 규칙 유지
- **데이터**: Score Contributors는 이미 fetch 중인 데이터로 구현 가능 (추가 쿼리 최소화)
- **성능**: 스크롤 위치 변경 디바운스 필수, 7일 sparkline은 대시보드 로딩 시간에 영향

---

## Next Steps

- [ ] Open Questions에 대한 의사결정
- [ ] `/plan dashboard-ux-redesign` 으로 구현 계획 생성
- [ ] Critical (C-1 ~ C-6) 먼저 수정 → Important (I-1 ~ I-10) → Polish
