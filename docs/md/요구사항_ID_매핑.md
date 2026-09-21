# 요구사항 ID 매핑표 — 저장소 자체 ID ↔ 명세 원문 ID

이 저장소의 리포트·증거·실험 스크립트는 `B1-2-A1`, `B1-2-P7`, `B1-2-E-DL3` 같은 **자체 ID** 로 근거를 단다.
과제 명세 원문(README 「0. 과제 명세」)이 쓰는 ID 는 `R1-1`, `R2-3`, `E3-2`, `B1-2` 계열이다.

두 체계 사이에 대조표가 없으면 **제3자가 "이 증거가 어느 요구사항을 충족하는가"를 추적할 수 없다.**
이 문서가 그 유일한 대조표다.

- 명세 원문 ID 의 정의: `README.md` → `## 0. 과제 명세` → `### 0.2 최종 산출물` / `### 0.4 기능 요구 사항` / `### 0.5 보너스 과제` / `### 0.6 개발 환경 · 제약 사항`
- **이 표는 기계가 검사한다**: `bash tools/check_req_ids.sh` — 저장소 어딘가에서 쓰이는 `B1-2-*` ID 중 이 표에 정의가 없는 것이 하나라도 있으면 **exit 1**.

---

## 0. 읽기 전 주의 — `B1-2` 라는 이름이 두 번 나온다

| 문맥 | 뜻 |
| --- | --- |
| `codyssey_B1-2`, `B1-2-A1` 의 앞부분 | **과제 코드** (Codyssey B1-2 미션) |
| 명세 0.5 절의 `B1-2` | **보너스 과제 B1 의 두 번째 항목** (알고리즘 역추론) |

그래서 저장소 ID `B1-2-B2` 와 명세 ID `B1-2` 는 **같은 것을 가리킨다**. 아래 2.4 절 참고.

---

## 1. 사전 준비 조건 — `B1-2-P1`~`P11` ↔ `R1-1`~`R1-11`

명세 0.4 절 R1 표의 11개 행과 **순서까지 1:1** 이다.

| 저장소 ID | 명세 ID | 조건 | 구현 | 실측 증거 |
| --- | --- | --- | --- | --- |
| `B1-2-P1` | `R1-1` | root 아닌 일반 사용자로 실행 | `src/03_users_and_groups.sh` | 모든 `evidence/*` 헤더의 `실행 계정: … root 아님 (B1-2-P1 충족)` 줄 |
| `B1-2-P2` | `R1-2` | `AGENT_HOME` 설정 | `src/05_env_and_keyfile.sh` | `evidence/oom_app.log` 부트 `[1/6]`~`[6/6]` 블록 |
| `B1-2-P3` | `R1-3` | `AGENT_PORT=15034` 고정 | `src/05_env_and_keyfile.sh`, `src/monitor.sh`, `src/02_firewall_allowlist.sh` | `evidence/oom_app.log` 의 `Port 15034 is available` |
| `B1-2-P4` | `R1-4` | `AGENT_UPLOAD_DIR` + 디렉터리 생성 | `src/05_env_and_keyfile.sh`, `src/04_directories_and_acl.sh` | 같은 부트 블록 |
| `B1-2-P5` | `R1-5` | `AGENT_KEY_PATH` 경로 존재 | `src/05_env_and_keyfile.sh`, `src/04_directories_and_acl.sh` | 같은 부트 블록 |
| `B1-2-P6` | `R1-6` | `AGENT_LOG_DIR` 존재 + 쓰기 권한 | `src/04_directories_and_acl.sh`, `src/monitor.sh` | `evidence/oom_app.log` 의 `Log directory is writable` |
| `B1-2-P7` | `R1-7` | `MEMORY_LIMIT` 정수 50~512 | `src/05_env_and_keyfile.sh`, `src/experiments/01_oom.sh` | `evidence/oom_monitor.log` §4 파라미터 스윕 |
| `B1-2-P8` | `R1-8` | `CPU_MAX_OCCUPY` 정수 10~100 | `src/05_env_and_keyfile.sh`, `src/experiments/02_cpu.sh` | `evidence/cpu_monitor.log` §4 파라미터 스윕 |
| `B1-2-P9` | `R1-9` | `MULTI_THREAD_ENABLE` true/false | `src/05_env_and_keyfile.sh`, `src/experiments/03_deadlock.sh` | `evidence/deadlock_monitor.log` §4 비교 요약 |
| `B1-2-P10` | `R1-10` | `secret.key` = `agent_api_key_test` | `src/05_env_and_keyfile.sh` | `evidence/oom_app.log` 의 `Verified 'secret.key' …` |
| `B1-2-P11` | `R1-11` | `0.0.0.0:15034` 바인딩 가능 | `src/experiments/lib_experiment.sh` 의 `_snapshot_bind_addr()` | **다음 실행부터** `evidence_live/*_ps_top.txt` 의 `(바인딩 주소 증거)` 블록 — 아래 3절 |

> `B1-2-P1~P11` 은 리포트·로그에서 보통 **범위 표기**로 나온다
> (예: `evidence/oom_app.log:2` 헤더, `reports/01_oom_report.md` §2-3). 범위 안의 개별 번호는 이 표가 유일한 정의다.

---

## 2. 분석 요구 — `B1-2-A1`~`A9` ↔ `R2`~`R4`

| 저장소 ID | 명세 ID | 요구 내용 | 이 ID 로 태그된 곳 |
| --- | --- | --- | --- |
| `B1-2-A1` | `R2-1` | `monitor.sh` 로 **대상 프로세스** 물리 메모리 증가 관측 | `reports/01_oom_report.md` §2-1·§2-3, `evidence/oom_monitor.log` 헤더, `src/monitor.sh` §3-(b) |
| `B1-2-A2` | `R2-2` | MemoryGuard 강제 종료 **핵심 로그 식별** | `evidence/oom_app.log` 헤더 |
| `B1-2-A3` | `R2-3` | `MEMORY_LIMIT` 조정 → Before & After | `reports/01_oom_report.md` §4-2, `evidence/oom_monitor.log` §4 |
| `B1-2-A4` | `R3-1` | 시스템 전체가 아닌 **특정 프로세스** CPU 상승 구간 식별 | `reports/02_cpu_report.md` §2-4, `evidence/cpu_top_ps.txt` 헤더, `src/monitor.sh` §3-(b) |
| `B1-2-A5` | `R3-2` | 오류가 아닌 **보호 정책에 의한 종료**임을 입증 | `reports/02_cpu_report.md` §3 결론부, `evidence/cpu_app.log` 헤더 |
| `B1-2-A6` | `R3-3` | `CPU_MAX_OCCUPY` 조정 → Before & After | `reports/02_cpu_report.md` §4-2, `evidence/cpu_monitor.log` §4 |
| `B1-2-A7` | `R4-1` | PID 존재 + 지표·로그 정지 = 무응답 식별 | `reports/03_deadlock_report.md` §2-5, `evidence/deadlock_monitor.log` 헤더 |
| `B1-2-A8` | `R4-2` | 마지막 로그로 스레드 순환 대기 **논리적 증명** | `reports/03_deadlock_report.md` §3-1, `evidence/deadlock_app.log` 헤더 |
| `B1-2-A9` | `R4-3` | `MULTI_THREAD_ENABLE` 재현/회피 비교 | `reports/03_deadlock_report.md` §4-2, `evidence/deadlock_monitor.log` §4 |

> 명세 `R4-4`(데드락 개념 학습 — **권장**)에는 대응하는 `A` 번호가 없다. 권장 항목이라 증거 태그를 달지 않았고,
> 내용은 `docs/md/이론_지식.md` §5 와 `reports/03_deadlock_report.md` 의 4대 조건 성립표에 들어 있다.

---

## 3. 케이스별 증거 최소 요건 — `B1-2-E-*` ↔ `E1`~`E3`

| 저장소 ID | 명세 ID | 증거 | 파일 |
| --- | --- | --- | --- |
| `B1-2-E-OOM1` | `E1-1` | `monitor.sh` 결과(메모리 상승 수치) | `evidence/oom_monitor.log`, `evidence/oom_ps_top.txt` |
| `B1-2-E-OOM2` | `E1-2` | 종료 직전/직후 실행 로그 | `evidence/oom_app.log` |
| `B1-2-E-OOM3` | `E1-3` | `MEMORY_LIMIT` 변경 전후 **최소 2회 실행** | `evidence/oom_monitor.log` §4 |
| `B1-2-E-CPU1` | `E2-1` | CPU 급상승 구간 `top`/`ps`/관제 캡처 | `evidence/cpu_top_ps.txt`, `evidence/cpu_monitor.log` |
| `B1-2-E-CPU2` | `E2-2` | 종료 로그 | `evidence/cpu_app.log`, `evidence/cpu_top_ps.txt` |
| `B1-2-E-CPU3` | `E2-3` | `CPU_MAX_OCCUPY` 변경 전후 비교 | `evidence/cpu_monitor.log` §4 |
| `B1-2-E-DL1` | `E3-1` | PID 존재 증거 | `evidence/deadlock_ps_top.txt` |
| `B1-2-E-DL2` | `E3-2` | `top -H` / `ps -L` 변화 정체 증거 | `evidence/deadlock_ps_top.txt`, `evidence/deadlock_monitor.log` |
| `B1-2-E-DL3` | `E3-3` | 마지막 로그 지점(`WAITING… BLOCKED`) | `evidence/deadlock_app.log` |
| `B1-2-E-DL4` | `E3-4` | 스레드/락 대기 추론 근거 | `evidence/deadlock_app.log`, `evidence/deadlock_ps_top.txt` |

---

## 4. 보너스 — `B1-2-B1`~`B3` ↔ `B1-1`~`B1-3`

| 저장소 ID | 명세 ID | 요구 내용 | 파일 |
| --- | --- | --- | --- |
| `B1-2-B1` | `B1-1` | 타임스탬프 기반 실행 순서·교체 주기 패턴화 | `evidence/scheduling_workers.log`, `evidence/scheduling_top_h.txt` |
| `B1-2-B2` | `B1-2` | Round-Robin / FCFS / Priority 중 역추론 | `reports/04_scheduling_analysis.md` §3 |
| `B1-2-B3` | `B1-3` | 장단점 및 적합 아키텍처 분석 | `reports/04_scheduling_analysis.md` §4 |

수집 스크립트: `src/experiments/04_scheduling.sh` (주석에 `B1-2-B1~B3` 범위로 표기).

---

## 5. 제약 사항 — `B1-2-C1`~`C3` ↔ 명세 0.6 절

| 저장소 ID | 명세 원문(0.6) | 저장소가 지킨 방법 |
| --- | --- | --- |
| `B1-2-C1` | 리눅스 표준 명령어·라이브러리만 사용 | `ps`/`top`/`free`/`df`/`ss`/`awk`/`stat`/`pgrep`/`kill`/`curl` + `/proc` 만 사용. APM·프로파일러 설치 0건 |
| `B1-2-C2` | 🚫 바이너리 디컴파일·리버스 엔지니어링 금지 | `reports/02_cpu_report.md` §3 이 "내부 구현은 확인하지 않았다 — 외부 관측만으로 세운 추론"이라고 한계를 명시 |
| `B1-2-C3` | 포트 15034 고정 | `src/05_env_and_keyfile.sh` / `src/02_firewall_allowlist.sh` / `src/07_cron_schedule.sh` 모두 15034 |

> 저장소 본문에 실제로 인용된 것은 **`B1-2-C2` 하나뿐**이다(`reports/02_cpu_report.md`).
> `C1`·`C3` 은 계열을 완성하려고 이 표에서 번호를 부여했을 뿐, 인용처가 아직 없다.

---

## 6. 제출물 — `D1`·`D2` 는 자체 ID 가 없다

명세 0.2 절의 `D1`(리포트 3건) / `D2`(마크다운 템플릿)에 대응하는 `B1-2-D*` ID 는 **만들지 않았다.**
제출물은 파일 그 자체(`reports/01~04`, `.github/ISSUE_TEMPLATE/`)라 증거 태그가 필요 없기 때문이다.
새로 만들지도 말 것 — 없는 편이 표를 짧게 유지한다.

---

## 7. 이 표가 썩지 않게 하는 것

문서에만 적힌 규칙은 규칙이 아니라 희망이다. 그래서 검사를 붙였다:

```bash
bash tools/check_req_ids.sh
```

- 저장소(`README.md`, `reports/`, `src/`, `evidence/`, `docs/md/`, `실험_절차서.md` …)에서 쓰이는 모든 `B1-2-*` ID 를 모은다
- 이 문서에 정의가 없는 ID 가 하나라도 있으면 **exit 1** 로 끝난다
- 즉 새 ID 를 만들면서 이 표를 갱신하지 않으면 검사가 빨간 불을 켠다

`docs/html/` 는 `tools/build_docs.py` 가 생성한 산출물이라 검사 대상에서 제외한다.
