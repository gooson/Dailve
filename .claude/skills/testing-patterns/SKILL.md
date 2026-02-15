---
name: testing-patterns
description: "테스트 작성 패턴과 커버리지 기대치. 테스트 관련 작업 시 자동으로 참조됩니다."
---

# Testing Patterns

> 이 파일은 프로젝트별로 커스터마이즈합니다.
> 프로젝트의 테스트 전략이 확정되면 아래 항목을 채웁니다.

## Test Structure

- Pattern: Arrange / Act / Assert (AAA)
- Test names: `should {expected behavior} when {condition}`
- Example: `should return 404 when user not found`

## Test Types

### Unit Tests
- Coverage target: [To be defined]
- Framework: [To be defined]
- Location: [To be defined - co-located / separate directory]
- File naming: [To be defined - *.test.ts / *.spec.ts / etc.]

### Integration Tests
- Coverage target: [To be defined]
- Framework: [To be defined]
- Database strategy: [To be defined - in-memory / test DB / mock]

### E2E Tests
- Framework: [To be defined]
- Critical paths: [To be defined]

## Mocking Strategy

- When to mock: [To be defined]
- Preferred mock library: [To be defined]
- External service mocking: [To be defined]

## Test Data

- Factory pattern: [To be defined]
- Seed data: [To be defined]
- Cleanup strategy: [To be defined]

## What to Test

### Always Test
- [To be defined, e.g., "Business logic"]
- [To be defined, e.g., "Edge cases"]
- [To be defined, e.g., "Error paths"]

### Don't Test
- [To be defined, e.g., "Framework internals"]
- [To be defined, e.g., "Simple getters/setters"]

## CI Integration

- Test command: [To be defined]
- Coverage report: [To be defined]
- Minimum coverage threshold: [To be defined]
