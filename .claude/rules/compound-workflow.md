# Compound Engineering Workflow

## The Compound Loop

1. **Plan** (40% of time): Research, design, validate
2. **Work** (10% of time): Implement according to plan
3. **Review** (40% of time): Multi-perspective analysis
4. **Compound** (10% of time): Document for future use

## Key Principles

- 계획에 전체 시간의 80%를 투자합니다 (Plan + Review)
- 모든 해결책은 docs/solutions/ 에 문서화합니다
- 교정 사항은 CLAUDE.md의 Correction Log에 추가합니다
- 리뷰 에이전트는 memory를 통해 프로젝트별 학습합니다

## Fidelity Levels

| Level | Description | Workflow |
|-------|-------------|----------|
| F1 | 단순 변경 (오타, 1줄 수정) | 직접 수정 |
| F2 | 중간 변경 (명확한 범위, 여러 파일) | /plan -> /work |
| F3 | 복잡한 변경 (불확실, 아키텍처) | /brainstorm -> /plan -> /work -> /review -> /compound |

## Before Starting Any Task

1. CLAUDE.md 읽기 (Correction Log 포함)
2. docs/solutions/ 에서 관련 과거 해결책 검색
3. Fidelity Level 판단 (F1/F2/F3)
4. 적절한 워크플로우 선택

## Compounding Mechanisms

1. **Agent Memory**: 리뷰 에이전트가 `memory: project`로 패턴 학습 -> 리뷰 정확도 향상
2. **Solution Docs**: 해결된 문제 축적 -> /plan이 자동 검색하여 재활용
3. **Correction Log**: 실수 기록 -> 매 세션 시작 시 로드되어 반복 방지
4. **Rules**: 반복 패턴 승격 -> 모든 세션에 자동 적용
5. **Domain Skills**: 프로젝트 지식 축적 -> 컨텍스트 자동 제공
