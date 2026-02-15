# TODO System Conventions

## File Naming

`NNN-STATUS-PRIORITY-description.md`

- NNN: 3-digit sequential number (001, 002, ...)
- STATUS: pending | ready | in-progress | done
- PRIORITY: p1 (critical) | p2 (important) | p3 (minor)
- description: kebab-case short description

## Examples

- `001-ready-p1-fix-auth-bypass.md`
- `002-pending-p2-add-unit-tests.md`
- `003-in-progress-p3-refactor-utils.md`

## Status Transitions

```
pending -> ready -> in-progress -> done
```

- **pending**: 아직 착수 조건이 갖춰지지 않음
- **ready**: 착수 가능, 필요한 정보와 계획이 있음
- **in-progress**: 현재 작업 중
- **done**: 완료됨 (파일은 기록으로 유지)

## TODO File Content

```yaml
---
source: manual | review/{reviewer} | brainstorm/{topic}
priority: p1 | p2 | p3
status: pending | ready | in-progress | done
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

## Numbering

새 TODO 생성 시:
1. todos/ 의 기존 파일에서 가장 높은 번호 확인
2. 그 다음 번호 사용
3. 충돌 방지를 위해 항상 순차적으로 증가

## Priority Definitions

- **P1 (Critical)**: 즉시 수정 필요. 보안 취약점, 데이터 손실 위험, 서비스 중단
- **P2 (Important)**: 빠른 수정 권장. 성능 문제, 아키텍처 개선, 중요 버그
- **P3 (Minor)**: 시간 될 때 처리. 코드 정리, 마이너 개선, 문서화
