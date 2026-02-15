---
tags: [health-app, ios, swiftui, healthkit, hrv, mvp, brainstorm]
date: 2026-02-15
category: brainstorm
status: draft
---

# Brainstorm: Dailve - 나만의 건강앱 기반 작업

## Problem Statement

기존 건강앱(Apple Health, Training Today, MyFitnessPal, AutoSleep 등)은 각각의 강점이 있지만, 개인에게 최적화된 **통합 건강 대시보드**가 없다. HRV/RHR 기반 컨디션 분석, 운동 기록, 식단 관리, 수면 추적, 체성분 기록을 **하나의 미니멀한 인터페이스**에서 관리하는 개인용 iOS 네이티브 앱을 만든다.

## Target Users

- **주 사용자**: 본인 (개인용)
- **프로필**: iOS 고급 개발자, 건강 데이터에 관심이 높고 Apple Watch 사용자
- **핵심 니즈**: 매일 아침 "오늘 내 컨디션"을 한눈에 파악하고, 건강 데이터를 체계적으로 추적

## Success Criteria

1. HealthKit에서 HRV/RHR 데이터를 읽어 컨디션 점수를 산출할 수 있다
2. 운동, 식단, 수면, 체성분 데이터를 기록하고 트렌드를 볼 수 있다
3. 미니멀한 대시보드에서 핵심 지표를 한눈에 확인할 수 있다
4. iCloud를 통해 기기 간 데이터가 동기화된다

## 참고 앱 분석

| 앱 | 참고할 점 | 개선할 점 |
|---|---------|---------|
| Apple Health | 데이터 통합, HealthKit 연동 | UI가 복잡하고 핵심 정보 파악이 어려움 |
| Training Today | HRV 기반 컨디션 점수, 심플한 UI | 운동/식단/수면 통합 없음 |
| MyFitnessPal | 식단 기록 시스템, 칼로리 추적 | 건강 데이터 통합 부족 |
| AutoSleep | 수면 분석 깊이, Watch 연동 | 다른 건강 지표와 분리됨 |

## 앱 이름

**Dailve** (Daily + Live)

- 매일의 삶/건강을 추적하는 의미
- 짧고, 유니크하며, 직관적으로 건강/웰니스가 느껴짐
- App Store 기존 앱과 겹치지 않음 (2026-02-15 확인)

## 대시보드 구현 스타일

### 레이아웃: 히어로 + 카드 스크롤

```
┌─────────────────────────────┐
│  ┌───────────────────────┐  │
│  │   컨디션 점수 (히어로)    │  │  ← 숫자 + 색상 배경 + 이모지
│  │   87  😊  "좋음"       │  │
│  │   ▪─▪─▪─▪─●           │  │  ← 7일 트렌드 (도트+라인)
│  └───────────────────────┘  │
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │ HRV      │ │ RHR      │  │  ← 스마트 정렬
│  │ 45ms ▲3  │ │ 58bpm ▼2 │  │    (변화 큰 지표가 위로)
│  └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │ 수면      │ │ 운동      │  │
│  │ 7h 23m   │ │ 45min    │  │
│  └──────────┘ └──────────┘  │
│  ┌──────────┐               │
│  │ 체중      │               │
│  │ 72.5kg   │               │
│  └──────────┘               │
└─────────────────────────────┘
```

### 핵심 요소

| 요소 | 스타일 | 비고 |
|------|--------|------|
| **컨디션 점수** | 큰 숫자 + 색상 배경 + 이모지 | 😊좋음/😐보통/😴피로 등 직관적 표현 |
| **트렌드 그래프** | 도트 + 라인 결합 | 각 날짜에 도트, 라인으로 연결. 탭하면 상세 |
| **세부 지표 카드** | 스마트 정렬 | 변화가 큰 지표가 자동으로 위로 올라옴 |
| **테마** | 시스템 설정 따르기 | iOS 다크/라이트 모드 자동 전환 |
| **애니메이션** | 적극적 | 스크롤 패럴랙스, 카드 호버, 점수 전환 효과 등 |

### 인터랙션 상세

- **히어로 영역**: 점수가 바뀔 때 숫자 카운트업 애니메이션 + 배경색 그라데이션 전환
- **카드**: 탭 시 확장되며 상세 차트 표시, 스크롤 시 패럴랙스 효과
- **Pull-to-refresh**: 데이터 업데이트 시 각 카드가 순차적으로 갱신되는 애니메이션
- **스마트 정렬**: 카드 순서 변경 시 부드러운 재배치 애니메이션

### 점수 → 상태 매핑

| 점수 범위 | 상태 | 색상 | 아이콘 |
|----------|------|------|-------|
| 80-100 | 매우 좋음 | 초록 | 😊 |
| 60-79 | 좋음 | 연두 | 🙂 |
| 40-59 | 보통 | 노랑 | 😐 |
| 20-39 | 피로 | 주황 | 😴 |
| 0-19 | 주의 | 빨강 | ⚠️ |

## Proposed Architecture

```
┌─────────────────────────────────────────┐
│              Presentation               │
│  SwiftUI Views + ViewModels (MVVM)      │
├─────────────────────────────────────────┤
│              Domain                     │
│  Use Cases, Models, Protocols           │
├─────────────────────────────────────────┤
│              Data                       │
│  HealthKit + SwiftData + CloudKit       │
└─────────────────────────────────────────┘
```

### 기술 스택

- **Language**: Swift 6
- **UI**: SwiftUI
- **Architecture**: MVVM + Clean Architecture
- **Data**: SwiftData + CloudKit (iCloud 동기화)
- **Health Data**: HealthKit
- **Charts**: Swift Charts
- **Minimum Target**: iOS 26+

## Constraints

- **기술적**: HealthKit 접근 권한 필요 (Apple Watch 연동 시 watchOS 타겟도 필요)
- **개인정보**: 건강 데이터는 민감 정보 → iCloud 동기화 시 암호화 필수
- **Apple Review**: HealthKit 사용 앱은 App Store 심사가 까다로울 수 있음 (개인용이면 TestFlight 배포 가능)
- **데이터 정확도**: HRV 데이터는 Apple Watch 모델에 따라 측정 빈도/정확도 차이

## Edge Cases

- Apple Watch가 없을 경우 HRV/RHR 데이터를 수동 입력할 수 있어야 함
- HealthKit 권한을 거부했을 때의 fallback UI
- iCloud 동기화 충돌 시 최신 데이터 우선 전략
- 데이터가 없는 초기 상태의 빈 대시보드 UX

## Scope

### MVP (Must-have)
- [ ] 프로젝트 셋업 (Xcode, SwiftData, HealthKit 설정)
- [ ] HealthKit 연동 (HRV, RHR, 걸음 수, 수면 읽기)
- [ ] 컨디션 점수 산출 (HRV/RHR 기반 알고리즘)
- [ ] 메인 대시보드 (컨디션 점수 + 핵심 지표 카드)
- [ ] 운동 기록 (수동 입력 + HealthKit 자동 연동)
- [ ] 수면 기록 (HealthKit 자동 연동 + 점수)
- [ ] 체중/체성분 기록 (수동 입력)
- [ ] iCloud 동기화 (SwiftData + CloudKit)
- [ ] 주간/월간 트렌드 차트

### Nice-to-have (Future)
- [ ] 식단 기록 (수동 입력 → 음식 DB 검색 → AI 사진 분석 단계적 확장)
- [ ] Apple Watch 전용 앱 (watchOS)
- [ ] 위젯 (iOS Widget)
- [ ] 운동 강도 추천 (HRV 기반)
- [ ] 데이터 내보내기 (CSV/PDF)
- [ ] 알림/리마인더
- [ ] Siri Shortcut 연동
- [ ] 다크모드 테마 커스터마이징

## Open Questions (Resolved)

1. ~~**앱 이름 최종 결정**~~ → **Dailve** 로 결정 (2026-02-15)
2. ~~**컨디션 점수 알고리즘**~~ → **Training Today 방식 참고** — HRV 7일 평균 대비 오늘 수치로 점수 산출 (2026-02-15)
3. ~~**식단 기록 방식**~~ → **MVP에서 제외** — 운동/수면/컨디션에 집중, 식단은 Future로 이동 (2026-02-15)
4. ~~**watchOS 앱**~~ → **MVP에서 제외** — iPhone 앱에 집중, HealthKit으로 Watch 데이터는 읽기 가능 (2026-02-15)

## Next Steps

- [x] 앱 이름 최종 결정 → **Dailve**
- [x] Open Questions 정리 완료
- [x] `/plan` 으로 구현 계획 생성 → `docs/plans/2026-02-15-dailve-mvp-implementation.md`
- [ ] Xcode 프로젝트 초기 셋업
