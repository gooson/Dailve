---
name: lfg
description: "전체 파이프라인 자동화. Plan -> Work -> Review -> Resolve -> Compound -> Ship. 기능 전체를 처음부터 끝까지 구현합니다."
---

# LFG: Full Pipeline Execution

$ARGUMENTS 에 대해 전체 Compound Engineering 파이프라인을 실행합니다.

## Pipeline Overview

```
Phase 1: Plan ──> Phase 2: Work ──> Phase 3: Review ──> Phase 4: Resolve ──> Phase 5: Compound ──> Phase 6: Ship
     │                 │                  │                   │                    │                    │
  [승인 필요]      [테스트 통과]       [결과 생성]          [P1 해결]           [문서화]            [PR 생성]
```

## Phase 1: Plan (계획)

/plan 과 동일한 프로세스를 따릅니다:
1. 코드베이스 리서치
2. docs/solutions/ 검색
3. 구현 계획 생성
4. docs/plans/ 에 저장

**Quality Gate**: 사용자에게 계획을 제시하고 승인을 받아야 다음 단계로 진행합니다.

## Phase 2: Work (구현)

/work 의 4단계를 따릅니다:
1. Setup: 브랜치 생성, 환경 준비
2. Implement: 계획에 따라 구현
3. Quality Check: 테스트, 린트, 타입 체크
4. Commit: 변경사항 커밋

**Quality Gate**: 모든 자동 검증이 통과해야 다음 단계로 진행합니다.

## Phase 3: Review (리뷰)

/review 의 6개 관점을 모두 실행합니다:
1. Security Sentinel
2. Performance Oracle
3. Architecture Strategist
4. Data Integrity Guardian
5. Code Simplicity Reviewer
6. Agent-Native Reviewer

결과를 P1/P2/P3로 정리합니다.

## Phase 4: Resolve (해결)

리뷰 결과를 처리합니다:
- **P1 (Critical)**: 즉시 자동 수정합니다
- **P2 (Important)**: 사용자에게 수정 여부를 확인합니다
- **P3 (Minor)**: TODO로 기록합니다

수정 후 Phase 3 (Review)를 다시 실행하여 P1이 0건인지 확인합니다.

**Quality Gate**: P1이 모두 해결되어야 다음 단계로 진행합니다.

## Phase 5: Compound (문서화)

/compound 프로세스를 따릅니다:
- 해결책을 docs/solutions/ 에 문서화
- CLAUDE.md Correction Log 업데이트 (필요시)
- 새 규칙 추가 제안 (필요시)

## Phase 6: Ship (배포)

1. 최종 커밋 정리
2. PR 생성:
   ```
   gh pr create --title "{title}" --body "{body}"
   ```
3. PR 링크를 사용자에게 전달

## Pipeline Control

각 Phase 완료 시 진행 상황을 보고합니다:

```
━━━ Phase {N}: {Name} Complete ━━━
{summary}

Next: Phase {N+1} - {Name}
Continue? [Y/n/back]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

사용자가 언제든 파이프라인을 중단하거나 이전 Phase로 돌아갈 수 있습니다.
