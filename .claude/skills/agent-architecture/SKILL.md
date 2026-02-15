---
name: agent-architecture
description: "에이전트 시스템 아키텍처 패턴. 에이전트 설계, 프롬프트 엔지니어링, 컨텍스트 관리. AI/에이전트 코드 작성 시 자동으로 참조됩니다."
---

# Agent Architecture Patterns

## Agent Design Principles

1. **Single Responsibility**: 하나의 에이전트는 하나의 명확한 역할
2. **Explicit Context**: 필요한 컨텍스트를 명시적으로 제공
3. **Graceful Failure**: 에러 시 적절한 폴백과 사용자 안내
4. **Memory Management**: 컨텍스트 윈도우의 효율적 사용
5. **Composability**: 에이전트 간 조합이 가능한 설계

## Prompt Engineering

### Structure
1. Role definition (who the agent is)
2. Context (what it knows)
3. Task (what to do)
4. Constraints (what NOT to do)
5. Output format (how to respond)

### Best Practices
- Clear, unambiguous instructions
- Structured output format specification
- Few-shot examples when the task is novel
- Explicit constraints and boundaries
- Priority ordering when multiple objectives exist

## Context Management

- Minimize context size: only include relevant information
- Use summaries for large content
- Fork to subagents for heavy operations
- Persist learnings via agent memory or docs/solutions/

## Error Recovery

- Retry with modified approach (not same approach)
- Escalate to user when stuck after 2 attempts
- Log failures for future prevention
- Never silently fail - always inform

## Agent-Native Environment Checklist

### Level 1 (Basic)
- [ ] File read/write access
- [ ] Test execution
- [ ] Git commits

### Level 2 (Full Local)
- [ ] Browser access
- [ ] Local logs
- [ ] PR creation

### Level 3 (Production Visibility)
- [ ] Production logs (read-only)
- [ ] Error tracking (Sentry, etc.)
- [ ] Monitoring dashboards

### Level 4 (Full Integration)
- [ ] Ticket system (Jira, Linear, etc.)
- [ ] Deployment
- [ ] External service integration

## Inter-Agent Communication

- Use structured output formats for agent-to-agent data passing
- Define clear input/output contracts
- Document expected data shapes
- Handle missing or malformed data gracefully
