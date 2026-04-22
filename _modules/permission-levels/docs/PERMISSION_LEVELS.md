# 권한 레벨 (L1 ~ L5)

> 프로젝트 단계·사용자 개입 선호에 따라 에이전트 자율성을 조정.
> 현재 레벨은 `.claude/LEVEL` 파일 한 줄로 관리.

---

## 빠른 전환

```bash
./docs/scripts/set-level.sh L3
```

현재 레벨 확인:
```bash
cat .claude/LEVEL
```

---

## 5단계 정의

### L1 — 관찰자 (Observer)
- **동작**: 모든 tool call 사용자 승인. 자동영역도 한번 확인.
- **butler 호출**: ≈ 0 (butler 통과 안 함, 바로 사용자)
- **사용자 개입 빈도**: 🔴 매우 높음
- **추천 상황**: 프로젝트 최초 셋업·보안 민감 초기·실수 영향 매우 큰 단계

### L2 — 검토자 (Reviewer)
- **동작**: 자동영역만 auto, 중간·큰 결정 모두 사용자
- **butler**: 낮음
- **빈도**: 🟠 높음
- **추천**: 아키텍처 확정 전·신입 프로젝트·코드베이스 생소할 때

### L3 — 협업자 (Collaborator) ⭐ **기본**
- **동작**: butler 가 중간지대 대리판단, 큰 결정(main push·외부 repo·비가역)만 사용자
- **butler**: 중간 (세션당 ≤ 5회 목표)
- **빈도**: 🟡 중
- **추천**: Phase 1~3 정상 개발·일반 팀 협업

### L4 — 자율 (Autonomous)
- **동작**: butler 가 main push 도 판단 (단 특정 조건: 테스트 통과·merge commit 아님·linear history). 외부 repo push·`rm -rf`·DROP·스키마 변경만 사용자.
- **butler**: 높음
- **빈도**: 🟢 낮음
- **추천**: 안정 운영·반복 작업이 많은 유지보수

### L5 — 전권 (Full Delegation)
- **동작**: 외부 repo push·비가역 데이터 삭제·새 외부 의존·비밀값 요청만 사용자. 나머지는 전부 에이전트 자율.
- **butler**: 매우 높음
- **빈도**: ⚪ 최소
- **추천**: 성숙한 유지보수 모드·사용자 장기 부재

---

## 프로젝트 단계별 권장 기본값

| 프로젝트 단계 | 권장 레벨 |
|---|---|
| Phase 0 — 환경 셋업·기반 공사 | **L2** |
| Phase 1 — 첫 모듈 개발 | **L3** (기본) |
| Phase 2~3 — 확장 | L3 → L4 점진 |
| Phase 4+ — 안정 운영 | **L4** |
| 유지보수·장기 부재 | **L5** |

---

## 각 레벨별 butler 분기 로직

butler 는 `.claude/LEVEL` 을 읽고 다음 매트릭스에 따라 판단:

| 요청 유형 | L1 | L2 | L3 | L4 | L5 |
|---|---|---|---|---|---|
| 자동영역 (permissions.allow 매칭) | ESC | APP | APP | APP | APP |
| 반복 관행·INIT 명시 산출물 | ESC | ESC | APP | APP | APP |
| 설계 선택(중간 지대) | ESC | ESC | butler 판단 | APP | APP |
| 모듈 내부 파일 편집 | ESC | ESC | APP | APP | APP |
| 새 파일·디렉토리 생성 | ESC | ESC | butler 판단 | APP | APP |
| `git commit` (conventional) | ESC | ESC | APP | APP | APP |
| `git push` → main (동일 repo) | ESC | ESC | ESC | butler 판단 | APP |
| `git push` → 외부 repo | ESC | ESC | ESC | ESC | ESC |
| PR 생성 (외부 repo) | ESC | ESC | ESC | ESC | ESC |
| `rm -rf`·DROP TABLE·데이터 삭제 | ESC | ESC | ESC | ESC | ESC |
| 새 외부 의존 추가 | ESC | ESC | ESC | butler 판단 | butler 판단 |
| 비밀값·API 키 | ESC | ESC | ESC | ESC | ESC |

**ESC** = ESCALATE (사용자), **APP** = APPROVE (자동), **butler 판단** = butler 가 맥락 보고 결정

---

## 레벨 변경 시점

- **상향** (L2 → L3 → L4): 에이전트가 프로젝트 맥락 이해도 높아지고 반복 실수 없을 때
- **하향** (L4 → L3): 중대한 실수 발생·새 멤버 합류·큰 리팩토링 앞

변경 후 각 워크트리 Claude 는 세션 재시작하거나 butler 호출 시 `.claude/LEVEL` 재확인.

---

## 파일 구조

```
.claude/LEVEL                       # 한 줄: "L3"
docs/PERMISSION_LEVELS.md           # 이 파일
docs/scripts/set-level.sh           # 변경 도구
.claude/AGENTS.md (butler 섹션)     # 레벨 분기 로직
```
