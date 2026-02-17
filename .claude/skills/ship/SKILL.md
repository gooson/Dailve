---
name: ship
description: "현재 브랜치를 PR 생성 → GitHub 머지 → 브랜치 삭제까지 자동 수행합니다."
---

# Ship: PR 생성 → 머지 → 브랜치 삭제

현재 feature 브랜치를 GitHub PR을 통해 main에 머지하고 정리합니다.

## Process

### Step 1: 사전 검증

1. **브랜치 확인**: 현재 브랜치가 main이 아닌지 확인
   - main이면 중단하고 안내
2. **Uncommitted 변경 확인**: `git status`로 커밋되지 않은 변경 확인
   - 있으면 사용자에게 커밋 여부를 묻습니다
3. **리모트 동기화**: 현재 브랜치가 리모트에 push되었는지 확인
   - 안 되어 있으면 `git push -u origin {branch}` 실행

### Step 2: PR 생성

1. **기존 PR 확인**: `gh pr view` 로 이미 열린 PR이 있는지 확인
   - 있으면 해당 PR을 사용
2. **PR이 없으면 생성**:
   - `git log main..HEAD --oneline` 으로 커밋 목록 확인
   - `git diff main...HEAD --stat` 으로 변경 파일 확인
   - 커밋 메시지와 변경 내용을 분석하여 PR 제목과 본문 작성
   - `gh pr create --base main --title "..." --body "..."` 로 PR 생성
3. **PR URL을 사용자에게 표시**

### Step 3: PR 머지

GitHub의 PR 머지 API를 통해 머지합니다. **로컬 머지나 자체 스쿼시를 수행하지 않습니다.**

1. `gh pr merge {PR_NUMBER} --delete-branch` 실행
   - `--squash`, `--merge`, `--rebase` 플래그를 명시하지 않으면 GitHub 리포지토리의 기본 머지 전략을 따름
   - 사용자가 특정 전략을 원하면 해당 플래그 추가
2. 머지 완료 확인

### Step 4: 로컬 정리

1. `git checkout main` 으로 main 브랜치로 전환
2. `git pull` 으로 머지된 내용을 로컬에 반영
3. 로컬 feature 브랜치 삭제: `git branch -d {branch}`
4. 최종 상태를 사용자에게 표시

## 주의사항

- **절대 로컬에서 직접 머지하지 않습니다** — 반드시 `gh pr merge`를 통해 GitHub API로 머지
- PR 생성 시 `--base main` 명시
- 머지 실패 시 (충돌, CI 실패 등) 사용자에게 안내하고 중단
- `--delete-branch` 로 리모트 브랜치 자동 삭제
