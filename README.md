# Codyssey B1-2 — 시스템 장애 분석 & 기술 리포트 작성

> 실서버에서 발생하는 3대 장애(**OOM / CPU Spike / Deadlock**)를 관제 로그·실행 로그·시스템 도구의 객관적 증거를 근거로 추론하고, GitHub Issue 형태의 기술 리포트로 정리한다.
>
> 실행 환경: **macOS + OrbStack Ubuntu 24.04 머신** (B1-1과 동일 인프라 재사용)
>
> 본 저장소는 B1-1 에서 구축한 SSH/방화벽/계정/디렉토리/cron 인프라 위에 **B1-2 전용으로 `agent-leak-app` 을 얹어** 장애를 재현하는 구조다.

---

## 0. 과제 명세 (원본 미션 요구사항)

> 출처: `codyssey_assignments/B1-2.pdf` — 원문 요구사항을 그대로 옮기고, 해설은 💡 로 구분했다.

### 0.1 미션 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 분야 | AI/SW 기초 |
| 구분 | Linux와 OS |
| 학습시간 | 40시간 |
| 미션 제목 | **컴퓨터가 갑자기 느려지거나 멈췄을 때 원인 찾아 고치기** |
| 문제 유형 | 문제기술 / 기술적 설명 |
| 제공 데이터파일 | `agent-app-leak.zip`, 단위문제 PDF 파일 |
| 데이터파일 설명 | `agent-app-leak-x86` (Intel chip) / `agent-app-leak-arm64` (Apple chip) |

#### 1. 미션 소개 (원문)

> Memory Leak, CPU Spike, Deadlock. 이 세 가지 중 하나가 실서버에서 터지면 어떻게 해야 할까요? 로그 없이 재부팅부터 하면 원인이 묻히고, 같은 장애가 두 번, 세 번 반복됩니다. 관제 데이터를 근거로 원인을 추론하고, GitHub Issue 형태의 기술 리포트로 남기는 것까지 직접 해봅니다.
>
> 개발자가 작성한 코드는 운영체제 위에서 프로세스 형태로 실행됩니다. 이 미션에서는 빌드된 프로그램을 운영 환경에서 실행하며 발생하는 시스템 장애(Memory Leak/OOM, CPU Spike, Deadlock) 분석을 다룹니다.
>
> 단순히 "프로그램이 꺼졌다!"는 결과만 보는 것이 아니라, 관제 데이터와 로그를 통해 장애의 원인을 추론해야 합니다. 이를 바탕으로 현업 개발자처럼 GitHub Issue 형태의 기술 리포트를 작성하며 실전적인 트러블슈팅 및 협업 커뮤니케이션 역량을 기르는 것이 최종 목표입니다.

#### 💡 이 과제가 진짜로 묻는 것 (해설)

> 💡
> 1. **이 과제의 산출물은 "코드"가 아니라 "리포트 3건"이다.** 프로그램은 이미 빌드된 바이너리로 주어지고, 학습자가 만드는 것은 `monitor.sh` 관제 스크립트(B1-1 과제의 연장)와 **증거로 무장한 장애 분석 문서**다.
> 2. **"장애를 고치는 것"이 아니라 "장애를 증명하는 것"이 평가 대상이다.** 환경변수 조정은 어디까지나 임시 조치(Workaround)이며, 채점자는 *왜 그렇게 판단했는가*의 증거 사슬(관제 수치 → 로그 문자열 → OS 동작 원리)을 본다.
> 3. **세 장애는 각각 다른 진단 도구를 강요한다.** OOM은 시계열 메모리 증가(`ps`/`monitor.sh`), CPU Spike는 프로세스 단위 점유율(`top`/`ps`), Deadlock은 **스레드 단위** 관찰(`top -H`, `ps -L`)이다. 같은 도구로 세 개를 다 설명하면 감점 포인트가 된다.
> 4. **Deadlock은 "죽지 않는 장애"다.** 프로세스가 종료되지 않으므로 종료 로그가 없다. "아무 일도 일어나지 않는다"는 것 자체를 증거로 제시하는 훈련이다.
> 5. **육하원칙 커뮤니케이션이 명시적 목표다.** GitHub Issue 템플릿을 지키는 것은 형식이 아니라 "동료가 내 로그 없이도 재현할 수 있는가"를 묻는 역량 평가다.

---

### 0.2 최종 산출물 (제출물)

> **(원문)** 다음 과정의 산출물을 PDF 또는 GitHub Repository 링크 형태로 제출해야 한다.

#### D1. 시스템 장애 분석 및 이슈 리포트 (3건)

- [ ] **D1** 3가지 장애 유형(**OOM Crash, CPU Latency, Deadlock**) 각각에 대해 작성된 GitHub Issue 형태의 기술 보고서
- [ ] 각 리포트는 아래의 **필수 포함 항목**을 모두 갖추어야 한다.
  - [ ] **D1-1 발생 현상**: 장애가 어떻게 관측되었는지 서술
  - [ ] **D1-2 재현 경로 및 증거**: 로그/명령어 출력/스크린샷 등 객관적 증거 첨부
  - [ ] **D1-3 근본 원인**: 장애의 기술적 원인 분석
  - [ ] **D1-4 조치 내용**: 환경변수 조정 등 임시 조치와 그 결과
  - [ ] **D1-5 결과 확인**: 조치 후 Before & After 비교 결과

#### D2. 이슈 리포트 마크다운 템플릿

> **(원문)** 각 리포트는 아래 구조를 따르되, 세부 내용은 자유롭게 작성할 수 있다.

```markdown
[Bug] {장애 유형} - {한 줄 요약}

## 1. Description (현상 설명)
- 어떤 현상이 발생했는가?
- 언제, 어떤 조건에서 발생했는가?

## 2. Evidence & Logs (증거 자료)
- monitor.sh 관제 로그 데이터 (수치/그래프/스크린샷)
- 프로그램 실행 로그 중 핵심 구간 발췌
- 시스템 도구(ps, top 등) 출력 결과

## 3. Root Cause Analysis (원인 분석)
- 수집된 증거를 바탕으로 한 기술적 원인 분석
- 관련 OS 동작 원리 설명

## 4. Workaround & Verification (조치 및 검증)
- 어떤 환경변수를 어떻게 조정했는가?
- Before & After 비교 결과 (수치 또는 스크린샷)
- 근본적 해결을 위한 추가 제안 (선택)
```

#### E. 케이스별 필수 증거 최소 요건 (원문 "3. 케이스별 필수 증거 최소 요건")

**E1. OOM**

- [ ] **E1-1** `monitor.sh` 결과(메모리 상승 수치)
- [ ] **E1-2** 종료 직전/직후 실행 로그(`"Memory limit exceeded…"`, `"SELF-TERMINATED…"` 등)
- [ ] **E1-3** `MEMORY_LIMIT` 변경 전후 비교(**최소 2회 실행**)

**E2. CPU**

- [ ] **E2-1** CPU 사용률 급상승 구간(`top` / `ps` / 관제) 캡처
- [ ] **E2-2** 종료 로그(`"WATCHDOG… SIGTERM"` 등)
- [ ] **E2-3** `CPU_MAX_OCCUPY` 변경 전후 비교

**E3. Deadlock**

- [ ] **E3-1** PID 존재 증거(`ps -ef | grep …`)
- [ ] **E3-2** CPU/MEM 변화 정체 증거(`top -H` 또는 `ps -L`)
- [ ] **E3-3** 마지막 로그 지점(`"WAITING… BLOCKED"`)
- [ ] **E3-4** 스레드/락 대기 추론 근거

> 💡 (해설) `E1-3`의 "최소 2회 실행"은 이 명세에서 유일하게 **실행 횟수를 숫자로 못 박은 조건**이다. Before 1회 + After 1회를 각각 별도의 로그 파일/타임스탬프로 남겨야 요건을 만족한다.

---

### 0.3 과제 목표 — 수료 후 스스로 설명할 수 있어야 하는 것

> **(원문)** 해당 미션을 완료한 뒤, 학습자는 아래를 스스로 설명할 수 있어야 한다.

- [ ] **G1** 메모리 구조를 이해하고, 메모리 누수가 시스템 전체에 미치는 영향을 설명할 수 있다.
- [ ] **G2** 특정 프로세스의 CPU 과점유가 시스템 지연을 유발하는 원리를 설명할 수 있다.
- [ ] **G3** 자원 경쟁으로 인해 발생하는 교착상태(Deadlock)의 개념을 이해하고, 프로세스가 멈춘 상태를 시스템 도구로 식별하여 진단할 수 있다.
- [ ] **G4** 로그와 관제 데이터를 증거로 제시하여 **육하원칙에 맞게** 장애 상황을 기술하고, GitHub Issue를 통해 동료 개발자와 명확하게 소통할 수 있다.

---

### 0.4 기능 요구 사항 (필수)

> **(원문)** 다음 요구사항을 모두 만족해야 한다.

#### R1. 사전 준비 사항 (제공 어플리케이션)

> **(원문)** `agent-leak-app`을 실행하기 위해서는 아래 조건이 모두 충족되어야 한다.
> **조건이 충족되지 않으면 부트 시퀀스에서 자동으로 실패 처리된다.**

| 항목 | 조건 |
| --- | --- |
| 실행 계정 | root가 아닌 일반 사용자 |
| `AGENT_HOME` | 필수 환경변수 설정 |
| `AGENT_PORT` | **15034 (고정)** |
| `AGENT_UPLOAD_DIR` | `$AGENT_HOME/upload_files` (디렉터리 존재 필수) |
| `AGENT_KEY_PATH` | `$AGENT_HOME/api_keys` (경로 존재 필수) |
| `AGENT_LOG_DIR` | 로그 디렉터리 (존재 + 쓰기 권한) |
| `MEMORY_LIMIT` | 정수, **50~512** 범위 (단위: MB) |
| `CPU_MAX_OCCUPY` | 정수, **10~100** 범위 (단위: %) |
| `MULTI_THREAD_ENABLE` | `true` / `false` (`1` / `0`, `yes` / `no` 허용) |
| `secret.key` 파일 | `$AGENT_HOME/api_keys/secret.key` 존재, 내용: `agent_api_key_test` |
| 네트워크 | `0.0.0.0:15034` 바인딩 가능 |

체크리스트 형태로 다시 정리하면:

- [ ] **R1-1** root가 아닌 일반 사용자 계정으로 실행한다.
- [ ] **R1-2** `AGENT_HOME` 환경변수를 설정한다. (필수)
- [ ] **R1-3** `AGENT_PORT`를 `15034`로 고정 설정한다.
- [ ] **R1-4** `AGENT_UPLOAD_DIR`를 `$AGENT_HOME/upload_files`로 설정하고 **디렉터리를 실제로 생성**한다.
- [ ] **R1-5** `AGENT_KEY_PATH`를 `$AGENT_HOME/api_keys`로 설정하고 **경로가 존재**하게 한다.
- [ ] **R1-6** `AGENT_LOG_DIR`(로그 디렉터리)가 **존재하고 쓰기 권한**을 갖게 한다.
- [ ] **R1-7** `MEMORY_LIMIT`를 정수 **50~512**(MB) 범위로 설정한다.
- [ ] **R1-8** `CPU_MAX_OCCUPY`를 정수 **10~100**(%) 범위로 설정한다.
- [ ] **R1-9** `MULTI_THREAD_ENABLE`를 `true`/`false`(`1`/`0`, `yes`/`no` 허용)로 설정한다.
- [ ] **R1-10** `$AGENT_HOME/api_keys/secret.key` 파일을 만들고 내용을 정확히 `agent_api_key_test`로 채운다.
- [ ] **R1-11** `0.0.0.0:15034` 바인딩이 가능한 네트워크 상태를 확보한다.

> 💡 (해설) 이 표는 "환경 구성 숙제"가 아니라 **부트 시퀀스 실패를 통한 디버깅 훈련**이다. 11개 조건 중 하나라도 빠지면 프로그램이 시작조차 하지 않으므로, 실패 메시지를 읽고 어떤 조건이 어긋났는지 역추적하는 과정 자체가 학습 내용이다. 이 조건들은 `.bash_profile` 등에 영구 등록해두는 편이 재현에 유리하다(원문 예시 리포트에서 `.bash_profile` 내 환경변수를 조정했다고 서술한다).

#### R2. 메모리 누수 원인 규명 및 리포팅

- [ ] **R2-1** `monitor.sh` 를 활용하여, 대상 프로세스(`agent-leak-app`)의 **물리 메모리 사용량이 시간 경과에 따라 증가하는 패턴**을 관측한다.
- [ ] **R2-2** 프로세스가 예고 없이 중단되었을 때 **프로그램 실행 로그를 분석**하여, 메모리 임계치 초과로 인해 애플리케이션의 **메모리 보호 정책(MemoryGuard)** 에 따라 강제 종료되었음을 나타내는 **핵심 로그를 식별**한다.
- [ ] **R2-3** 환경변수(`MEMORY_LIMIT`)를 조정하여 프로그램이 **더 오래 생존**하는 것을 확인하고, 그 결과를 리포트에 **Before & After**로 기록한다.

#### R3. CPU 과점유 분석 및 리포팅

- [ ] **R3-1** 관제 툴과 로그를 통해 **시스템 전체 부하가 아닌 특정 프로세스(`agent-leak-app`)의 CPU 사용률**이 급격히 상승하는 구간을 식별한다.
- [ ] **R3-2** 프로그램 실행 로그 분석을 통해, 해당 종료가 **오류가 아닌 과점유 방지 정책(Watchdog)에 따른 시스템 보호 조치**였음을 입증한다.
- [ ] **R3-3** 환경변수(`CPU_MAX_OCCUPY`)를 조정하여 **프로세스 종료 여부 또는 생존 시간 변화**를 확인하고, 그 결과를 리포트에 **Before & After**로 기록한다.

#### R4. 교착상태(DeadLock) 진단 및 리포팅

- [ ] **R4-1** 프로세스가 **종료되지 않고 살아있으나(PID 존재)**, CPU/메모리 변화가 없고 로그 기록도 멈춘 **무응답 상태**임을 식별한다.
- [ ] **R4-2** 프로그램 로그의 **마지막 기록**을 분석하여, 서로 다른 스레드가 상대방의 자원을 무한히 기다리는 상태임을 **논리적으로 증명**한다.
- [ ] **R4-3** 환경변수(`MULTI_THREAD_ENABLE`)를 조정하여 **데드락 재현/회피 비교 결과**를 리포트에 기록한다.
- [ ] **R4-4** (권장) Deadlock(교착상태)의 개념이 생소한 학습자는 아래 키워드를 참고하여 기본 개념을 학습한 후 미션에 임하는 것을 **권장**한다.
  - **식사하는 철학자들 문제(Dining Philosophers Problem)**: 교착상태의 대표적인 비유 모델
  - **교착상태 4대 조건**: 상호 배제(Mutual Exclusion), 점유 대기(Hold and Wait), 비선점(No Preemption), 순환 대기(Circular Wait)

> 💡 (해설) R4-4는 원문에서 "권장"이라고 명시되어 있으므로 **필수 제출물은 아니다.** 다만 0.3의 목표 G3과 평가 체크리스트의 "핵심 개념 이해" 항목이 정확히 이 두 키워드를 겨냥하므로, 리포트 3절(Root Cause Analysis)에 4대 조건 중 어떤 조건이 어떻게 성립했는지를 적어두면 그대로 평가 답변이 된다.

---

### 0.5 보너스 과제 (선택)

> **(원문)** 5. 보너스 과제 (선택) — **스케줄링 알고리즘 추론**

- [ ] **B1** 스케줄링 알고리즘 추론
  - [ ] **B1-1 프로그램 로그 데이터 분석**: 로그의 **타임스탬프를 기반으로 프로세스 간 실행 순서와 교체 주기를 패턴화**한다.
  - [ ] **B1-2 알고리즘 역추론**: 도출된 패턴을 근거로, 현재 프로그램에 적용된 스케줄링 기법이 **Round-Robin, FCFS, Priority 중 무엇인지** 논리적으로 추론한다.
  - [ ] **B1-3 장단점 및 적합한 아키텍처 분석**: 추론한 스케줄링 알고리즘의 기술적 장단점을 서술하고 어떤 성격의 서비스(예: **실시간 응답이 중요한 웹 서버 vs 처리량이 중요한 배치 서버** 등)에 적합한지 분석하여 정리한다.

---

### 0.6 개발 환경 · 제약 사항

#### 6. 개발 환경 (원문)

- 제공된 바이너리(**Python 기반**)를 실행할 수 있는 **리눅스 환경**
- **로컬 또는 격리된 환경(Docker 컨테이너 등)에서 실행을 권장**
- **공유 네트워크 환경에서는 방화벽 설정에 유의**
- 🚫 **바이너리 디컴파일 및 리버스 엔지니어링 시도 금지**

#### 7. 제약 사항 (원문)

- `monitor.sh` , `ps` , `top` , `htop` , `pstree` , `kill` 등 **리눅스 표준 명령어 및 라이브러리 사용**

> 💡 (해설) 제약 사항의 핵심은 두 가지다.
> - **🚫 금지**: 바이너리를 뜯어보고 답을 알아내는 행위(디컴파일·리버스 엔지니어링). 즉 **소스가 아니라 "바깥에서 관찰한 증거"만으로 원인을 추론**해야 한다. 이 과제의 난이도와 학습 가치가 전부 여기서 나온다.
> - **✅ 허용/권장 도구**: 리눅스 표준 명령어. 별도의 APM·프로파일러를 설치해 우회하지 말고, `ps`/`top`/`htop`/`pstree`/`kill`과 직접 만든 `monitor.sh` 로 해결하라는 의미다.
> - **포트 15034 고정**은 방화벽/포트 충돌 시 "포트를 바꾸는" 회피가 불가능하다는 뜻이다. 격리 환경 권장의 실질적 이유이기도 하다.

---

### 0.7 결과/출력 예시

> **(원문)** 아래는 **정답이 아니라 참고 예시**다. 실제 문구와 디자인은 달라도 된다.

#### 0.7.1 장애 분석 리포트 예시 (GitHub Issue — OOM 분석 Case)

```markdown
[Bug] 프로세스 실행 10분 후 메모리 보호 정책에 의한 비정상 강제 종료

## 1. Description (현상 설명)
`agent-leak-app` 어플리케이션을 실행하고 약 10분이 경과하면, 터미널에
`SELF-TERMINATED` 메시지가 출력되며 프로세스가 예고 없이 종료됩니다. 애플리케이션
내부의 메모리 보호 정책(MemoryGuard)에 의해 프로세스가 강제 종료되는 현상이 반복됩니다.

## 2. Evidence & Logs (증거 자료)
`monitor.sh`를 통해 수집된 관제 로그를 분석한 결과, **메모리 점유율(MEM)**이
초기 5%대에서 시작하여 종료 직전 96%까지 **선형적으로 급격히 상승**하는 패턴이
확인되었습니다. 반면 CPU 사용률은 안정적이었습니다.
```

[ monitor.log 데이터 발췌 ]

```text
[2025-12-30 14:00:00] PROCESS:agent-leak-app CPU:1.2% MEM:5.1% DISK:954G FIREWALL:active
[2025-12-30 14:03:00] PROCESS:agent-leak-app CPU:1.5% MEM:35.4% DISK:954G FIREWALL:active
[2025-12-30 14:06:00] PROCESS:agent-leak-app CPU:1.4% MEM:68.2% DISK:954G FIREWALL:active
[2025-12-30 14:09:00] PROCESS:agent-leak-app CPU:1.3% MEM:89.5% DISK:954G FIREWALL:active
[2025-12-30 14:10:00] PROCESS:agent-leak-app CPU:1.5% MEM:96.8% DISK:954G FIREWALL:active
```

[ 프로그램 실행 로그 발췌 ]

```text
[CRITICAL] [MemoryGuard] Memory limit exceeded (256MB >= 256MB) / (Recommend Over 256MB)
[CRITICAL] [MemoryGuard] Self-terminating process 12345 to prevent system instability.
>>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<
```

```markdown
## 3. Root Cause Analysis (원인 분석)
현상 분석: 어플리케이션 로직 내부에서 생성한 데이터를 힙(Heap) 메모리에서 해제하지 않고
지속적으로 쌓는 메모리 누수(Memory Leak) 결함이 있는 것으로 판단됩니다.
시스템 동작: 물리 메모리 사용량이 MEMORY_LIMIT에 도달하자, 애플리케이션 내부의
**MemoryGuard 정책**이 시스템 전체 불안정을 방지하기 위해 해당 프로세스를 SIGKILL로
강제 종료시켰습니다.

## 4. Workaround & Verification (조치 및 검증)
조치 내용: .bash_profile 내의 환경변수 MEMORY_LIMIT 값을 기존 256MB에서 512MB로
상향 조정하여 임시적으로 가용 메모리를 확보했습니다.
검증 결과: 설정 변경 후 재실행 결과, 기존 종료 시점인 10분을 넘겨 30분 이상 프로세스가
생존함을 확인했습니다. 다만, 근본적인 해결을 위해서는 소스 코드 내 불필요한 데이터를
주기적으로 삭제(del or pop)하는 리팩토링이 필요합니다.
```

#### 0.7.2 장애 분석 리포트 구조 예시 (GitHub Issue — CPU 과점유 Case, 정답 아님)

```markdown
[Bug] CPU 과점유에 의한 Watchdog 보호 조치 프로세스 종료

## 1. Description (현상 설명)
`agent-leak-app` 실행 후 일정 시간이 경과하면, CPU 사용률이 급격히 상승하고
"[SYSTEM] WATCHDOG: INITIATING EMERGENCY ABORT (SIGTERM)" 메시지와 함께
프로세스가 종료됩니다.

## 2. Evidence & Logs (증거 자료)
- monitor.sh 관제 로그에서 CPU 사용률 변화 추이 (캡처/수치 첨부)
- 프로그램 실행 로그에서 Watchdog 관련 로그 발췌
- top 또는 ps 명령어를 통한 프로세스별 CPU 점유율 확인 결과

## 3. Root Cause Analysis (원인 분석)
- CPU 부하가 내부 Watchdog 임계치를 초과한 원인 분석
- 과점유 방지 정책의 동작 원리 서술

## 4. Workaround & Verification (조치 및 검증)
- CPU_MAX_OCCUPY 환경변수 조정 전후 비교 (Before & After)
- 조정 후 프로세스 생존 시간 또는 종료 여부 변화 기록
```

#### 0.7.3 장애 분석 리포트 구조 예시 (GitHub Issue — Deadlock Case, 정답 아님)

```markdown
[Bug] 멀티스레드 환경에서 교착상태(Deadlock) 발생으로 프로세스 무응답

## 1. Description (현상 설명)
`agent-leak-app` 실행 후 프로세스가 종료되지 않고 PID가 유지되나,
CPU/메모리 변화가 없고 로그 출력도 완전히 멈춘 무응답 상태가 지속됩니다.

## 2. Evidence & Logs (증거 자료)
- ps -ef | grep agent 결과 (PID 존재 확인)
- top -H 또는 ps -L 결과 (스레드별 CPU/MEM 변화 없음 확인)
- 프로그램 실행 로그의 마지막 기록 발췌 (WAITING/BLOCKED 로그)

## 3. Root Cause Analysis (원인 분석)
- 마지막 로그를 근거로 스레드 간 순환 자원 대기 상태 추론
- 상호 배제와 순환 대기 원리 서술

## 4. Workaround & Verification (조치 및 검증)
- MULTI_THREAD_ENABLE 환경변수를 false로 변경하여 재실행
- 데드락 발생 여부 비교 (Before: true → Deadlock / After: false → 정상 동작)
```

#### 0.7.4 스케줄링 추론 리포트 예시 (보너스 B1)

```markdown
# [Analysis] 로그 패턴 분석을 통한 스케줄링 알고리즘 추론

## 1. 로그 관찰 개요
`agent-leak-app`의 정상 실행 상태에서 발생하는 워커(Worker) 스레드들의
작업 로그를 수집하여, OS 또는 런타임이 작업을 처리하는 스케줄링 기법을
역추적했습니다.

## 2. 증거 자료
로그의 타임스탬프와 작업 진행률(Progress)을 분석한 결과, 하나의 작업이
완료되기 전에 다른 작업이 끼어드는 현상이 관측되었습니다.
```

[ Application Log Snapshot ]

```text
[2025-12-30 14:00:00.100] [Thread-A] Task Started. Calculating... (10%)
[2025-12-30 14:00:00.150] [Thread-A] Calculating... (20%)
[2025-12-30 14:00:00.200] [Thread-B] Task Started. Calculating... (10%)  <-- A 중단, B 시작
[2025-12-30 14:00:00.250] [Thread-B] Calculating... (20%)
[2025-12-30 14:00:00.300] [Thread-C] Task Started. Calculating... (10%)  <-- B 중단, C 시작
[2025-12-30 14:00:00.350] [Thread-A] Resumed. Calculating... (30%)       <-- C 중단, A 재개
```

```markdown
## 3. 패턴 분석 및 결론
* 순차 처리 아님: Thread-A가 100% 완료되기 전에 Thread-B가 실행되었으므로,
  먼저 온 작업을 끝까지 처리하는 방식이 아닙니다.
* 우선순위 아님: 특정 스레드가 자원을 독점하거나, 긴급하게 처리되는 경향 없이
  A, B, C가 공평하게 나눠 가지는 모습을 보입니다.
* 최종 결론: 각 스레드가 정해진 시간 할당량만큼 CPU를 사용하고, 자원을 반납하는
  라운드 로빈 알고리즘으로 추론됩니다.
```

> 💡 (해설) 예시에서 반복적으로 등장하는 **핵심 로그 문자열**은 그대로 검색 키워드로 쓸 수 있다.
> - OOM: `Memory limit exceeded`, `MemoryGuard`, `SELF-TERMINATED`
> - CPU: `WATCHDOG`, `EMERGENCY ABORT`, `SIGTERM`
> - Deadlock: `WAITING`, `BLOCKED`
> `grep` 으로 이 문자열을 잡아 리포트에 발췌하면 E1-2 / E2-2 / E3-3 요건을 직접 충족한다.

---

### 0.8 📚 이 과제가 공부하길 원하는 것 (학습 지도)

| 요구사항 | 표면적으로 시키는 일 | 실제로 학습시키려는 개념 | 스스로 답해볼 질문 |
| --- | --- | --- | --- |
| **R1-1** (root 아닌 계정) | 일반 사용자로 실행 | 리눅스 **권한 모델과 최소 권한 원칙**, root로 돌리는 서비스가 왜 위험한가 | 이 앱이 root로 돌았다면 OOM이 발생했을 때 시스템 전체에 어떤 차이가 생기는가? |
| **R1-3 / R1-11** (`AGENT_PORT=15034` 고정, `0.0.0.0:15034` 바인딩) | 포트를 열어둔다 | **소켓 바인딩**, `0.0.0.0` vs `127.0.0.1`의 차이, `EADDRINUSE`(포트 충돌), 방화벽 | `0.0.0.0` 바인딩과 `127.0.0.1` 바인딩은 보안상 무엇이 다른가? 포트가 이미 쓰이고 있으면 어떻게 확인하는가? |
| **R1-2·R1-4~R1-10** (환경변수·디렉터리·secret.key) | 환경을 준비한다 | **환경변수의 프로세스 상속**, 12-Factor식 외부 설정 주입, 파일 퍼미션(존재 vs 쓰기 권한), **부트 시퀀스 사전 검증(fail-fast)** | 왜 설정을 코드가 아니라 환경변수로 받는가? "디렉터리가 존재한다"와 "쓸 수 있다"는 어떻게 다르게 검사하는가? |
| **R1-7 / R1-8** (`MEMORY_LIMIT` 50~512, `CPU_MAX_OCCUPY` 10~100) | 숫자를 범위 안에 넣는다 | **입력 검증(range validation)**, 리소스 쿼터·임계값 설계, cgroups/ulimit 같은 실제 OS 자원 제한과의 비교 | 실제 리눅스는 프로세스 메모리를 어떻게 제한하는가(cgroups, `ulimit -v`)? 앱 내부 제한과 OS 제한 중 무엇이 더 신뢰할 수 있는가? |
| **R2-1** (monitor.sh로 메모리 증가 관측) | 메모리를 주기적으로 찍는다 | **시계열 관제(polling)와 샘플링 주기**, `ps -o rss,vsz,%mem`의 의미 차이, **RSS/VSZ/힙**의 구분 | `%MEM`과 `RSS`는 무엇이 다른가? 3분 간격 샘플링으로 놓치는 장애는 무엇인가? |
| **R2-2** (MemoryGuard 로그 식별) | 종료 로그를 찾는다 | **메모리 누수의 메커니즘**(힙에 쌓고 해제 안 함), 가비지 컬렉션의 한계(참조가 남으면 GC도 못 지운다), 애플리케이션 레벨 보호 정책 vs 커널 **OOM Killer** | 파이썬처럼 GC가 있는 언어에서도 메모리 누수가 왜 발생하는가? 커널 OOM Killer는 무엇을 근거로 희생자를 고르는가(`oom_score`)? |
| **R2-3** (`MEMORY_LIMIT` Before & After) | 임계값을 올려본다 | **증상 완화와 근본 해결의 구분**, 통제 변인 하나만 바꾸는 **실험 설계**, 회귀 검증 | 한도를 512MB로 올리면 장애가 "해결"된 것인가, "지연"된 것인가? 누수율이 일정하다면 새 종료 시점을 계산할 수 있는가? |
| **R3-1** (전체 부하 vs 특정 프로세스) | CPU 그래프를 본다 | **load average와 %CPU의 차이**, 코어 수에 따른 100%↑ 해석, `top`의 Irix/Solaris 모드 | `top`에서 400%가 찍히는 것은 무슨 뜻인가? load average 4.0은 8코어와 2코어에서 각각 어떤 상태인가? |
| **R3-2** (Watchdog = 보호 조치임을 입증) | 종료 원인을 밝힌다 | **시그널 의미론**: `SIGTERM`(정상 종료 요청, 핸들링 가능) vs `SIGKILL`(무조건 종료), watchdog/서킷 브레이커 패턴 | 왜 OOM은 SIGKILL이고 Watchdog은 SIGTERM인가? SIGTERM을 받은 프로세스가 할 수 있는 마지막 일은 무엇인가? |
| **R3-3** (`CPU_MAX_OCCUPY` Before & After) | 임계값을 조정한다 | **CPU 과점유가 시스템 지연을 만드는 원리**(스케줄러 큐 대기, 컨텍스트 스위치 비용, starvation) | 한 프로세스가 CPU를 독점하면 다른 프로세스의 응답 지연은 왜 생기는가? 임계값을 100%로 올리면 무엇이 더 나빠지는가? |
| **R4-1** (PID 존재 + 변화 없음) | 멈춘 걸 확인한다 | **프로세스 상태 코드**: `R`/`S`/`D`(uninterruptible sleep)/`Z`/`T`, "살아있음"과 "일하고 있음"의 차이, 무응답 진단 절차 | `ps` STAT 열이 `S`와 `D`일 때 대응이 어떻게 달라지는가? 프로세스가 CPU 0%인데 정상인 경우와 데드락인 경우를 무엇으로 구분하는가? |
| **R4-2** (스레드 간 순환 대기 증명) | 마지막 로그를 읽는다 | **교착상태 4대 조건**(상호 배제·점유 대기·비선점·순환 대기), 뮤텍스/락 획득 순서, **스레드 단위 관찰**(`top -H`, `ps -L`, `/proc/<pid>/task`) | 로그에서 A→B, B→A 순환 의존을 어떻게 읽어내는가? 4대 조건 중 하나만 깨면 데드락이 사라지는 이유는? |
| **R4-3** (`MULTI_THREAD_ENABLE` 재현/회피) | 스위치를 끈다 | **재현 가능성(reproducibility)이 곧 진단의 증거**, 동시성 버그의 비결정성, 단일 스레드 전환이 "해결"이 아닌 이유 | 스레드를 끄면 데드락이 사라지는데, 왜 이것을 근본 해결이라 부르면 안 되는가? 코드를 고친다면 락 순서를 어떻게 정하겠는가? |
| **D1-D2 / E1-E3** (Issue 템플릿·증거 요건) | 문서를 형식에 맞춘다 | **기술 커뮤니케이션**: 현상→증거→원인→조치의 인과 사슬, 육하원칙, 재현 절차의 완결성, 주장과 증거의 분리 | 내 리포트만 읽은 동료가 내 환경 없이 같은 장애를 재현할 수 있는가? "~인 것 같다"를 "~라는 로그가 이를 뒷받침한다"로 바꿔 썼는가? |
| **B1-1~B1-3** (스케줄링 역추론) | 로그 타임스탬프를 본다 | **CPU 스케줄링 알고리즘**(Round-Robin / FCFS / Priority), 타임 슬라이스와 선점(preemption), 컨텍스트 스위치, 처리량 vs 응답시간 트레이드오프 | 50ms 간격 교체는 타임 퀀텀이 50ms라는 뜻인가? Round-Robin의 퀀텀을 늘리면 웹 서버와 배치 서버에 각각 어떤 영향이 있는가? |
| **제약: 리버스 엔지니어링 금지** | 바이너리를 안 뜯는다 | **블랙박스 관측 기반 추론**, 관측 가능성(observability), 가설-검증 사이클 | 소스를 못 볼 때 내가 쓸 수 있는 관측 창구는 무엇인가(`/proc`, 로그, 시스템 콜, 리소스 지표)? |
| **전체 (운영 관점)** | 3건 리포트를 낸다 | **사후 분석(Post-mortem)과 사고 대응 절차**, "재부팅 먼저"가 왜 최악인지, 선제 탐지(알림 임계치) 설계 | 장애 발생 *전에* 메모리 누수를 탐지하려면 `monitor.sh`를 어떻게 개선해야 하는가(증가 추세 기반 경보)? |

> 💡 (해설) 평가 체크리스트(`checklists_md/troubleshooting_oom_cpu_deadlock.md`)의 **"3. 핵심 개념 이해" / "4. 확장 사고 및 트러블슈팅"** 항목이 위 표의 "스스로 답해볼 질문" 열과 거의 1:1로 대응한다. 특히 다음 4개는 리포트 본문에 답이 없으면 구술로라도 반드시 답해야 한다.
> - OOM·CPU Spike·Deadlock 중 **실제 서비스에서 가장 치명적인 것**은 무엇이며 그 이유와 근본 예방책은?
> - **OOM과 Deadlock이 동시에 발생**했다면 어떤 순서로 트러블슈팅하고, 우선순위 판단 근거는?
> - 환경변수 조정은 임시 조치였다. **소스 코드를 고칠 수 있다면** 장애 유형별로 어떤 코드 레벨 개선을 하겠는가?
> - 이 미션을 **처음부터 다시** 한다면 어떤 점을 다르게 접근하겠는가?

---

### 0.9 자주 놓치는 함정

1. **"리포트 3건"은 3개의 독립 문서다.** 하나의 문서에 세 장애를 몰아 쓰면 D1의 "각각에 대해 작성된" 조건과 어긋난다. 그리고 각 리포트가 D1-1~D1-5(현상/증거/근본원인/조치/결과확인) **5개 항목을 전부** 가져야 한다 — 조치만 쓰고 "결과 확인(Before & After)"을 빠뜨리는 경우가 가장 흔하다.

2. **OOM은 "최소 2회 실행"이 명시되어 있다(E1-3).** `MEMORY_LIMIT` 변경 전 1회, 변경 후 1회의 **실행 로그가 각각 남아 있어야** 한다. 변경 후 한 번만 돌리고 "전에는 이랬다"고 서술만 하면 증거 요건 미달이다.

3. **CPU 케이스의 성공 조건은 "종료됨"이 아니다.** R3-3은 "프로세스 **종료 여부 또는 생존 시간 변화**"를 요구한다. 임계치를 올려서 아예 종료되지 않는 결과도 정당한 After 결과다. 반대로 "After에도 똑같이 죽었다"로 끝내면 비교가 성립하지 않는다.

4. **Deadlock에는 종료 로그가 없다.** OOM/CPU와 달리 프로세스가 살아 있으므로 `SELF-TERMINATED`류 문자열을 찾아 헤매면 안 된다. 증거는 **"PID는 있는데(E3-1) 수치가 멈췄고(E3-2) 로그가 그 지점에서 끊겼다(E3-3)"** 는 **부재(不在)의 증명**이다.

5. **Deadlock은 프로세스가 아니라 스레드 단위로 봐야 한다.** `ps -ef`나 기본 `top`만으로는 "CPU 0%"까지밖에 못 본다. E3-2가 굳이 **`top -H` 또는 `ps -L`** 을 지정한 이유가 여기 있다 — 스레드별로 각각 멈춰 있음을 보여야 순환 대기 추론(E3-4)의 근거가 된다.

6. **사전 준비 11개 조건은 "충족되지 않으면 부트 시퀀스에서 자동으로 실패 처리된다".** 즉 실행이 안 되는 것이 버그가 아니라 **명세대로의 동작**이다. `AGENT_PORT`는 15034 **고정**이라 포트를 바꿔 회피할 수 없고, `secret.key`는 파일 존재뿐 아니라 **내용이 정확히 `agent_api_key_test`** 여야 한다. `AGENT_LOG_DIR`는 존재만으로 부족하고 **쓰기 권한**까지 필요하다.

7. **`MEMORY_LIMIT`는 50~512, `CPU_MAX_OCCUPY`는 10~100 범위를 벗어날 수 없다.** 예시 리포트가 "256MB → 512MB"로 올리는 이유가 이것이다. 512를 넘기는 After 실험은 애초에 부트에서 막힌다.

8. **바이너리 디컴파일·리버스 엔지니어링은 명시적 금지다.** 코드를 열어 원인을 확인하고 그것을 "분석"으로 제출하면 제약 위반이다. 모든 근거는 관제 데이터·로그·표준 리눅스 명령어 출력에서 나와야 한다.

> 💡 (해설) 파일명 주의: 제공 데이터파일은 `agent-app-leak.zip` (바이너리 `agent-app-leak-x86` / `agent-app-leak-arm64`)이지만, 요구사항 본문과 예시 로그에서 프로세스는 `agent-leak-app` 으로 표기된다. 원문에 두 표기가 섞여 있으므로, 리포트에서는 **실제 실행 환경에서 `ps` 에 찍히는 이름**을 기준으로 쓰고 필요하면 각주로 밝혀두는 편이 안전하다. (이 불일치는 PDF 원문 그대로이며, 어느 쪽이 정답인지 PDF는 명시하지 않는다.)

### 0.10 ✅ 과제 수행 점검 (명세 대조)

> 점검 방식: 저장소의 실제 소스·증거 파일을 명세의 요구사항 ID 와 1:1 대조. 판정 근거는 저장소 루트 기준 상대경로로 명시. README 의 주장이 아니라 `evidence/` 원본과 `src/` 스크립트를 직접 열어 확인했다.

**종합 판정: 충족** — 필수 25개 중 충족 24 / 부분 1 / 미충족 0 / 로컬검증불가 0
(보너스 4개: 충족 4 / 부분 0 / 미충족 0)

특기 사항: `evidence/` 의 로그는 **실측 산출물**이다. `evidence/oom_monitor.log:8` 이 기록한 바이너리 해시 `md5 0fb02e12554328b32e6e1adac861630e` 가 저장소의 `bin/agent-leak-app` 실제 해시와 **일치**함을 확인했다(본 점검에서 `md5sum` 실행). 즉 리포트가 인용한 PID·타임스탬프·수치는 이 저장소에 들어 있는 바로 그 바이너리를 돌려 얻은 값이다.

---

#### 필수 요구 사항

| ID | 요구사항 (요약) | 판정 | 근거 / 비고 |
| --- | --- | --- | --- |
| **R1** | 사전 준비 11개 조건 충족 상태로 앱 부팅 | ✅ 충족 | `evidence/oom_app.log:34-49` — 부트 시퀀스 `[1/6]`~`[6/6]` 전부 `[OK]` + `All Boot Checks Passed! / Agent READY`. 동일 블록이 `evidence/cpu_app.log`·`evidence/deadlock_app.log` 에도 있음 |
| **R1-1** | root 아닌 일반 사용자로 실행 | ✅ 충족 | `evidence/oom_app.log:36` — `Running as service user 'ashofrondol' (uid=1000)`. 계정 생성은 `src/03_users_and_groups.sh` |
| **R1-2** | `AGENT_HOME` 설정 | ✅ 충족 | `src/05_env_and_keyfile.sh:34` / 수집 환경은 `evidence/oom_monitor.log:12` 헤더에 명시 |
| **R1-3** | `AGENT_PORT=15034` 고정 | ✅ 충족 | `src/05_env_and_keyfile.sh:35`, `src/monitor.sh:13`, 부트 로그 `evidence/oom_app.log:41-42` (`Port 15034 is available`) |
| **R1-4** | `AGENT_UPLOAD_DIR` 설정 + 디렉터리 생성 | ✅ 충족 | `src/05_env_and_keyfile.sh:36` + 실제 생성 `src/04_directories_and_acl.sh:29` |
| **R1-5** | `AGENT_KEY_PATH=$AGENT_HOME/api_keys` (경로 존재) | ✅ 충족 | `src/05_env_and_keyfile.sh:37` + `src/04_directories_and_acl.sh:30`. B1-1 의 "파일 경로" → B1-2 의 "디렉터리" 변경을 스크립트 주석(`src/05_env_and_keyfile.sh:7-9`)에서 명시적으로 처리 |
| **R1-6** | `AGENT_LOG_DIR` 존재 + 쓰기 권한 | ✅ 충족 | `src/04_directories_and_acl.sh:33,44,56-57` (770 + default ACL), 부트 로그 `evidence/oom_app.log:44-45` (`Log directory is writable: …`). `src/monitor.sh:145-152` 도 존재·쓰기 권한을 따로 검사 |
| **R1-7** | `MEMORY_LIMIT` 정수 50~512 | ✅ 충족 | `src/05_env_and_keyfile.sh:44` (512). 실험에 쓴 값 100 / 256 / 512 전부 범위 내 — `evidence/oom_monitor.log:311-315` |
| **R1-8** | `CPU_MAX_OCCUPY` 정수 10~100 | ✅ 충족 | `src/05_env_and_keyfile.sh:45` (10). 실험값 95/80/60/50/10 전부 범위 내 — `evidence/cpu_monitor.log:286-292` |
| **R1-9** | `MULTI_THREAD_ENABLE` true/false | ✅ 충족 | `src/05_env_and_keyfile.sh:46`, Before=`true` / After=`false` 양쪽 실측 — `evidence/deadlock_monitor.log:274-302` |
| **R1-10** | `secret.key` 내용 = `agent_api_key_test` | ✅ 충족 | `src/05_env_and_keyfile.sh:52-57` (생성·권한 640), 부트 로그 `evidence/oom_app.log:39-40` — `Verified 'secret.key' with correct key string.` |
| **R1-11** | `0.0.0.0:15034` 바인딩 가능 | 🟡 부분 충족 | 간접 근거는 충분하다 — 부트 `[4/6] Checking Port Availability [OK]`(`evidence/oom_app.log:41-42`), `Agent listening at port 15034`(`evidence/oom_app.log:51`), `monitor.sh` 의 LISTEN 검사 통과(`evidence/oom_monitor.log:45`, 구현은 `src/monitor.sh:57-67`), 방화벽 예외 `src/02_firewall_allowlist.sh:33`. 다만 **바인딩 주소가 `0.0.0.0` 인지 `127.0.0.1` 인지 구분해 주는 캡처(`ss -tlnp` 등)가 evidence 전체에 0건**이고, 남아 있는 접속 시도는 `curl http://127.0.0.1:15034` 뿐이다(`evidence/deadlock_ps_top.txt:81-90`) |
| **R2** | 메모리 누수 원인 규명 및 리포팅 | ✅ 충족 | `reports/01_oom_report.md` 361줄 — Description/Evidence/RCA/Workaround 4단 완비 |
| **R2-1** | `monitor.sh` 로 대상 프로세스 물리 메모리 증가 관측 | ✅ 충족 | `evidence/oom_monitor.log:155-164` — `monitor.sh` 가 직접 append 한 관제 라인 `PROC_RSS:42.7MB → 242.7MB`(27초). 고해상도 계열 `17.7 → 267.7MB` 는 `evidence/oom_monitor.log:227-236`. **`SYS_MEM`(37.4→37.8%) 이 아니라 `PROC_RSS` 가 근거임을 명시**(`reports/01_oom_report.md:33-43`) — 명세 해설이 경고한 함정을 정면으로 다룸. 수집 명령도 헤더에 보존(`evidence/oom_monitor.log:18-24`, `while :; do bash src/monitor.sh; sleep 3; done` — 스크립트 무수정) |
| **R2-2** | MemoryGuard 강제 종료 핵심 로그 식별 | ✅ 충족 | `evidence/oom_app.log:74-75` — `[CRITICAL] [MemoryGuard] Memory limit exceeded (275MB >= 256MB)` + `Self-terminating process 2738539`. 리포트는 PDF 예시의 `SELF-TERMINATED` 배너가 이 바이너리에 **없음을 실측으로 정정**(`reports/01_oom_report.md:27`) — 예시 문자열 베껴 쓰기를 하지 않았다 |
| **R2-3** | `MEMORY_LIMIT` 조정 → 더 오래 생존, Before & After | ✅ 충족 | Before 256 (09:02:36~, 0m34s 사망) / After 512 (09:03:11~, 3m00s 생존) 각각 **별도 PID·타임스탬프로 2회 실행** — `evidence/oom_monitor.log:227-237` vs `239-294`. 여기에 "512 는 더 늦게 죽는 값이 아니라 장애가 재현되지 않는 값"임을 스스로 간파하고, **100MB(13초) → 256MB(34초)** 대조로 "생존 연장"을 별도 입증(`evidence/oom_monitor.log:307-319`, 원본 종료 요약 `:337-356`). 명세가 요구한 것보다 한 단계 깊다 |
| **R3** | CPU 과점유 분석 및 리포팅 | ✅ 충족 | `reports/02_cpu_report.md` 352줄 — 4단 구조 완비 |
| **R3-1** | 시스템 전체가 아닌 **특정 프로세스**의 CPU 상승 구간 식별 | ✅ 충족 | `evidence/cpu_top_ps.txt:303-343` — `/proc/<pid>/stat` 의 `utime+stime` 1초 델타로 잰 `PROC_%CPU`(0→5%) 와 `HOST_%CPU`(무추세)를 같은 표에서 대조. 앱 자기보고 `Current Load 5.00→53.72%` 상승 구간은 `evidence/cpu_app.log:67-78`. 호스트 상위 프로세스 목록에 앱이 없음도 교차 확인(`evidence/cpu_top_ps.txt:349-379`). `ps %CPU` 가 누적 평균이라 스파이크를 못 잡는다는 한계를 짚고 별도 계측을 붙인 점이 정확하다(`reports/02_cpu_report.md:43`) |
| **R3-2** | 오류가 아닌 **보호 정책에 의한 종료**임을 입증 | ✅ 충족 | `evidence/cpu_app.log:78` — `[CRITICAL] [CpuWorker] CPU Threshold Violated! (53.72…%)`. 종료 코드 143(=128+15, SIGTERM) 의 raw 캡처는 형제 실행에 있음(`evidence/cpu_monitor.log:309`, `:325`). SIGTERM(정중한 종료) vs SIGKILL(OOM, 137) 대비로 "보호 조치"를 논증(`reports/02_cpu_report.md:256`). PDF 예시의 `WATCHDOG … EMERGENCY ABORT` 문자열이 이 바이너리에 없음을 실측 정정(`reports/02_cpu_report.md:27`) |
| **R3-3** | `CPU_MAX_OCCUPY` 조정 → 종료 여부/생존 시간 변화, Before & After | ✅ 충족 | Before 80 (0m30s 사망) / After 10 (3m00s 생존) — `evidence/cpu_monitor.log:205-214` vs `:216-271`. 나아가 5개 값 스윕(95/80/60/50/10)으로 **"상향은 효과 0, 하향이 유효"** 라는 반직관적 결론을 실측으로 뒤집고 실험 스크립트까지 고쳤다(`evidence/cpu_monitor.log:286-300`, `src/experiments/02_cpu.sh:29-41`). 명세 함정 3("After 에도 똑같이 죽었다로 끝내면 안 된다")을 회피 |
| **R4** | 교착상태 진단 및 리포팅 | ✅ 충족 | `reports/03_deadlock_report.md` 321줄 — 4단 구조 완비 |
| **R4-1** | PID 존재 + CPU/메모리·로그 정지 = 무응답 식별 | ✅ 충족 | `evidence/deadlock_ps_top.txt:56-61` (`ps -ef`/`ps -p` PID 생존, `STAT=SNl`, `ELAPSED 01:16`, `TIME 00:00:00`), 관제 `PROC_RSS` 17.7MB 76초 불변 + `PROC_CPU` 3.2→0.0% 감쇠(`evidence/deadlock_monitor.log:192-215`). 30s/120s/210s 반복 캡처에서 `VmRSS 18148kB`·`voluntary_ctxt_switches 14`·로그 파일 `1517 bytes`·mtime 이 **나노초까지 동일**(`evidence/deadlock_ps_top.txt:143-219`) — "느린 것"과 "멈춘 것"을 가르는 결정적 지표 |
| **R4-2** | 마지막 로그로 스레드 간 순환 대기를 논리적으로 증명 | ✅ 충족 | `evidence/deadlock_app.log:82-94` — `Worker-Thread-1 LOCK ACQUIRED [Shared_Memory_A]` / `Worker-Thread-2 LOCK ACQUIRED [Socket_Pool_B]` → 각각 상대 락에 `WAITING … (Status: BLOCKED)`. 의존 그래프와 4대 조건 대조표는 `reports/03_deadlock_report.md:193-218`. 커널 레벨 뒷받침으로 `ps -L -o wchan` 의 **전 스레드 `futex_wait_queue`**(`evidence/deadlock_ps_top.txt:61-66`) — 명세 함정 5(스레드 단위 관찰)를 정확히 충족 |
| **R4-3** | `MULTI_THREAD_ENABLE` 재현/회피 비교 | ✅ 충족 | Before(true)=부팅 9초 후 freeze / After(false)=3m00s 정상 — 비교표 `evidence/deadlock_monitor.log:274-302`, After 실측 스냅샷 `evidence/deadlock_ps_top.txt:102-122`(WCHAN 이 `futex_wait_queue`1 + `do_select`2 로 갈리고 `TIME+` 가 전진). "스레드 수는 같고 상태가 다르다"는 판별 기준을 명시(`reports/03_deadlock_report.md:292`) |
| **R4-4** | (권장) 데드락 4대 조건 · 식사하는 철학자 학습 | ✅ 충족 | `docs/md/이론_지식.md:737-866`(§5 동시성·락·데드락, `:797` 식사하는 철학자), `docs/md/용어집.md:697-699`, 리포트 본문의 4대 조건 성립 근거표 `reports/03_deadlock_report.md:209-218`. 권장 항목이지만 실제 리포트 논증에 녹아 있다 |

#### 제출물 · 증거 최소 요건 (D1·D2 / E1~E3 — 명세 0.2 절)

| ID | 요구사항 (요약) | 판정 | 근거 / 비고 |
| --- | --- | --- | --- |
| D1 | 3가지 장애 각각 **독립된** Issue 리포트 | ✅ 충족 | `reports/01_oom_report.md` / `reports/02_cpu_report.md` / `reports/03_deadlock_report.md` — 한 문서에 몰아쓰지 않음(명세 함정 1 회피) |
| D1-1~D1-5 | 현상 / 재현·증거 / 근본 원인 / 조치 / 결과 확인 | ✅ 충족 | 세 리포트 모두 `## 1. Description` `## 2. Evidence & Logs` `## 3. Root Cause Analysis` `## 4. Workaround & Verification` + Before/After 표를 가짐 (`reports/01_oom_report.md:275-300`, `reports/02_cpu_report.md:278-291`, `reports/03_deadlock_report.md:248-267`) |
| D2 | 마크다운 템플릿 구조 준수 | ✅ 충족 | 제목이 `[Bug] {장애 유형} - {한 줄 요약}` 형식(`reports/01_oom_report.md:1` 등), `.github/ISSUE_TEMPLATE/bug_report.md`·`analysis_report.md` 도 별도 제공 |
| E1-1 | `monitor.sh` 결과(메모리 상승 수치) | ✅ 충족 | `evidence/oom_monitor.log:155-164` |
| E1-2 | 종료 직전/직후 실행 로그 | ✅ 충족 | `evidence/oom_app.log:63-75` |
| E1-3 | `MEMORY_LIMIT` 변경 전후 **최소 2회 실행** | ✅ 충족 | 파이프라인 Before/After 2회(PID 2738539 / 2739609, `evidence/oom_monitor.log:226-294`) + 독립 probe 4회(`evidence/oom_monitor.log:337-367`). 명세에서 유일하게 횟수를 못 박은 조건인데 여유 있게 초과 |
| E2-1 | CPU 급상승 구간 `top`/`ps`/관제 캡처 | 🟡 부분 충족 | `top`/`ps` 캡처는 있으나(`evidence/cpu_top_ps.txt:43-55`, `:71-87`) 거기에 찍힌 값은 `%CPU 0.0` · `TIME+ 0:00.04→0:00.28` · load average 0.23→0.28 로 **"급상승"이 보이지 않는다**. 실제 상승은 `/proc/<pid>/stat` 델타표(최대 5%)와 앱 자기보고 `Current Load`(53.72%)에서만 관측된다. 리포트가 이 한계를 숨기지 않고 §2-3 에 그대로 적은 점은 높이 평가하나(`reports/02_cpu_report.md:148-154`), 요건 문구가 요구한 형태의 캡처는 아니다 |
| E2-2 | 종료 로그 | ✅ 충족 | `evidence/cpu_app.log:78` (`WATCHDOG` 문자열 대신 실제 출력인 `[CpuWorker] CPU Threshold Violated!`. 명세가 "…등"으로 열어 둔 범위) |
| E2-3 | `CPU_MAX_OCCUPY` 변경 전후 비교 | ✅ 충족 | `evidence/cpu_monitor.log:286-292` (5개 값 스윕) |
| E3-1 | PID 존재 증거 | ✅ 충족 | `evidence/deadlock_ps_top.txt:56-61`, 반복 캡처 `:144-146` 등 |
| E3-2 | `top -H` / `ps -L` 로 변화 정체 증명 | ✅ 충족 | `evidence/deadlock_ps_top.txt:63-79` |
| E3-3 | 마지막 로그 지점(`WAITING… BLOCKED`) | ✅ 충족 | `evidence/deadlock_app.log:93-94` |
| E3-4 | 스레드/락 대기 추론 근거 | ✅ 충족 | `reports/03_deadlock_report.md:193-207` (의존 그래프) + WCHAN·문맥교환 카운터 |

#### 제약 사항 점검

| 항목 | 판정 | 근거 |
| --- | --- | --- |
| 🚫 디컴파일·리버스 엔지니어링 금지 | ✅ 위반 없음 | `objdump\|readelf\|pyinstxtractor\|uncompyle\|decompil\|disassembl\|ghidra\|radare` 저장소 전체 grep **0건**. 오히려 `reports/02_cpu_report.md:250` 이 "바이너리 내부 구현은 리버스 엔지니어링 금지 대상이라 확인하지 않았다. 위 서술은 외부 관측만으로 세운 추론" 이라고 한계를 명시 |
| 리눅스 표준 명령어/라이브러리만 사용 | ✅ 위반 없음 | 사용 도구는 `ps` `top` `free` `df` `ss`/`netstat` `awk` `stat` `pgrep` `kill` `curl` + `/proc` 뿐(`src/monitor.sh`, `src/experiments/lib_experiment.sh`). 별도 APM·프로파일러 설치 없음 |
| 포트 15034 고정 | ✅ 위반 없음 | `src/05_env_and_keyfile.sh:35`, `src/02_firewall_allowlist.sh:33`, `src/07_cron_schedule.sh:27` 모두 15034 |
| 자동화 스크립트 Bash 전용(저장소 자체 선언) | 🟡 문서 불일치 | `README.md:836` 이 "자동화 스크립트는 **Bash 로만**"이라고 선언하지만 `tools/build_docs.py`(Python, `pip install markdown pygments` 필요)가 존재한다. 다만 이는 **문서 HTML 빌더**로 분석·관제 경로 밖이며, 명세의 제약(§7)을 위반하는 것은 아니다 |
| 격리 환경(Docker/VM) 권장 | 🟡 권장 미준수 | `README.md:730-746` 과 `demo.sh`/`verify_orbstack.sh` 는 OrbStack Ubuntu 머신 시나리오를 기술하지만, 제출 evidence 는 `AGENT_HOME=/home/ashofrondol/b12_sandbox/agent-app` 로 **개발 호스트에서 직접 실행**한 결과다(`evidence/oom_monitor.log:6,12`). 같은 호스트에서 `java`(RSS 19GB)·`grafana`·`loki` 가 돌고 있어(`evidence/oom_ps_top.txt:353-362`) 호스트 지표에 배경 부하가 섞인다. 리포트가 이를 스스로 밝히고 프로세스 단위 지표로 분리했으므로(`reports/02_cpu_report.md:207`) 결론에는 영향이 없다. 명세상 "권장"이라 감점 요소는 아니다 |

#### 보너스 과제

| ID | 요구사항 (요약) | 판정 | 근거 / 비고 |
| --- | --- | --- | --- |
| **B1** | 스케줄링 알고리즘 추론 | ✅ 충족 | `reports/04_scheduling_analysis.md` 240줄 + 수집 스크립트 `src/experiments/04_scheduling.sh` |
| **B1-1** | 타임스탬프 기반 실행 순서·교체 주기 패턴화 | ✅ 충족 | `evidence/scheduling_workers.log:38-62` 원문 21줄 + `:176-201` 경과/간격 계산표. 간격 표본 20개 전부 50~51ms(평균 50.8ms), 등장 순서 `A→B→C` 고정 회전까지 정량화 |
| **B1-2** | Round-Robin / FCFS / Priority 중 역추론 | ✅ 충족 | `reports/04_scheduling_analysis.md:158-191` — FCFS 기각(A 가 40%에서 `Preempted` 직후 B 시작), Priority 기각(턴 수 3/3/3, 턴당 진행폭 20%p 동일, 완료 시각 차 51ms 이내), RR 결론(고정 할당량·순환 교체·공평성·상태 보존 4근거). 게다가 `[Thread-A/B/C]` 가 OS 스레드가 아니라 앱 내부 논리 태스크임을 `top -H` 로 확인하고 **초판의 잘못된 근거를 스스로 폐기**(`:127-129`) |
| **B1-3** | 장단점 및 적합 아키텍처 분석 | ✅ 충족 | `reports/04_scheduling_analysis.md:195-223` — 장점 3 / 단점 3 + 적합(웹서버·인터랙티브·멀티테넌트) / 부적합(배치·ETL, RTOS, HPC) 표. 명세가 예시로 든 "실시간 응답 웹 서버 vs 처리량 배치 서버" 대비를 정확히 다룸 |

#### 과제 목표 (G1~G4) 대응

| ID | 판정 | 근거 |
| --- | --- | --- |
| G1 메모리 구조·누수 영향 | ✅ 충족 | `docs/md/이론_지식.md:92-233` (§2 가상 메모리~OOM), 리포트 `reports/01_oom_report.md:249-254` |
| G2 CPU 과점유 → 시스템 지연 원리 | ✅ 충족 | `docs/md/이론_지식.md:234-325` (§3 CPU·스케줄링), `reports/02_cpu_report.md:252-257` |
| G3 데드락 개념 + 시스템 도구 진단 | ✅ 충족 | `docs/md/이론_지식.md:737-866`, `reports/03_deadlock_report.md:220-225` |
| G4 육하원칙·Issue 소통 | ✅ 충족 | 리포트 3종의 머리말이 환경·계정·환경변수·측정 구간을 모두 적시(`reports/01_oom_report.md:3-7`), 모든 인용에 `원본: evidence/파일:줄번호` 역추적 링크. 구술 대비 문답은 `docs/md/평가_문항.md` 263줄 |

---

#### 🔍 발견된 격차와 보완 제안

1. **[경미 · R1-11] `0.0.0.0` 바인딩을 직접 보여 주는 캡처가 없다.**
   - 무엇이 부족한가: 포트가 LISTEN 이라는 사실은 부트 로그·`monitor.sh` 로 확인되지만, 바인딩 주소가 `0.0.0.0`(전 인터페이스)인지 `127.0.0.1`(루프백)인지 구분되는 출력이 evidence 전체에 없다. 명세 0.8 절의 학습 질문("`0.0.0.0` 과 `127.0.0.1` 바인딩은 보안상 무엇이 다른가")이 정조준하는 지점이다.
   - 어떻게 고치면 되는가: 앱 기동 상태에서 `ss -tlnp | grep 15034` (또는 `ss -tln 'sport = :15034'`) 한 줄을 캡처해 `evidence/oom_ps_top.txt` 상단 부트 검증 블록에 추가하고, 리포트 R1 체크리스트에서 이를 인용한다. `src/experiments/lib_experiment.sh` 의 preflight 에 이 한 줄을 넣어 두면 재실행 시 자동으로 남는다.

2. **[경미 · E2-1] `top`/`ps` 캡처만 보면 "CPU 급상승"이 보이지 않는다.**
   - 무엇이 부족한가: 요건은 "`top`/`ps`/관제로 급상승 구간을 캡처"인데, 실제 캡처값은 `%CPU 0.0` · `TIME+ 0.24초` · load average 무변화다. 상승은 `/proc` 델타표와 앱 자기보고 값에서만 보인다. 리포트가 이 불일치를 정직하게 서술한 것은 오히려 강점이지만, 채점자가 요건 문구만 대조하면 미비로 읽힐 수 있다.
   - 어떻게 고치면 되는가: `top -b -n 2 -d 1 -p <pid>` 의 **두 번째 샘플**(= 진짜 순간값)을 부하 상승 구간에서 3~4회 연속 캡처해 `%CPU` 가 실제로 오르는 표를 만들어 `evidence/cpu_top_ps.txt` §1 에 넣는다. 지금도 `:349-379` 에 `top -b -n 2` 사용 예가 있으므로 대상 PID 로 한 번 더 돌리면 된다. 그리고 리포트 §2-3 첫머리에 "이 앱의 부하는 OS 지표상 최대 5%이며, 그 이유는 앱 내부 회계가 종료를 결정하기 때문"이라는 한 줄 요약을 먼저 배치해 오독을 막는다.

3. **[경미 · R2-3 / R3-2] 파이프라인 Before 실행의 종료 코드가 raw 캡처로 남아 있지 않다.**
   - 무엇이 부족한가: 리포트는 Before 를 "exit 137"(OOM) / "exit 143"(CPU) 로 단언하지만, 그 **해당 실행 자체**의 종료 코드 출력은 evidence 에 없다. raw `exit_code=` 캡처는 형제 probe 에만 있다(`evidence/oom_monitor.log:340,348` / `evidence/cpu_monitor.log:309,325`). 파이프라인 구간에 남은 것은 After 의 `rc=2`(관측 종료)뿐이다(`evidence/oom_monitor.log:294`, `evidence/cpu_monitor.log:271`).
   - 어떻게 고치면 되는가: `src/experiments/lib_experiment.sh` 의 `_terminating_experiment` 가 워커 종료 후 `wait; echo "exit=$?"` 결과를 `*_monitor.log` 의 해당 구간 끝줄에 append 하도록 한 줄 추가한다. 그러면 Before 구간 자체에서 137/143 이 직접 증명된다.

4. **[경미 · 문서] `README.md` 와 저장소 실물이 두 군데에서 어긋난다.**
   - `README.md:605-606` 는 `bin/` 이 "비어 있음", "이 저장소에 바이너리는 포함되어 있지 않으니"라고 적었지만 실제로는 `bin/agent-leak-app`(6.5MB ELF)이 git 에 **추적되고 있다**(`git ls-files bin/` 확인). 해시가 evidence 헤더와 일치해 재현성 면에서는 오히려 큰 장점이므로, README 를 실물에 맞춰 "재현성을 위해 실험에 쓴 바이너리(md5 0fb02e…)를 포함한다"로 고치는 편이 낫다(운영 측 배포 정책상 재배포가 곤란하다면 반대로 파일을 제거하고 해시만 남긴다).
   - `README.md:836` 의 "자동화 스크립트는 Bash 로만" 선언과 `tools/build_docs.py` 의 공존. "분석·관제 자동화는 Bash 전용, 문서 빌드는 예외"로 문구를 한정하면 해소된다.

5. **[경미 · 추적성] 저장소가 쓰는 자체 요구사항 ID(`B1-2-A1`, `B1-2-P1~P11`, `B1-2-E-OOM1`, `B1-2-C2`, `B1-2-B1~B3`)의 정의표가 어디에도 없다.**
   - 무엇이 부족한가: 리포트·evidence·실험 스크립트 주석이 이 ID 로 근거를 달고 있는데(예: `reports/01_oom_report.md:107`, `evidence/oom_monitor.log:2`), ID → 원문 요구사항 매핑 문서가 없어 제3자가 추적할 수 없다.
   - 어떻게 고치면 되는가: 본 README 최상단 "0. 과제 명세" 절(R1~R4 / D1~D2 / E1~E3 / B1)을 그대로 기준 ID 로 삼고, 부록에 `B1-2-A1 = R2-1` 식의 대조표 한 장을 추가한다. 리포트 본문의 ID 를 새 체계로 치환하면 채점자가 요건표와 1:1 로 맞춰 볼 수 있다.

6. **[참고 · 결함 아님] 리포트가 스스로 밝힌 미확인 항목 3건** — ① `Worker-Thread-1/2` 와 LWP 의 1:1 대응 미확인(`reports/03_deadlock_report.md:70`), ② `Preempted` 가 진짜 선점인지 협조적 양보인지 미구분(`reports/04_scheduling_analysis.md:230`), ③ OOM 시 `dmesg` 미확인(`reports/01_oom_report.md:254`). 셋 다 명세가 요구하지 않은 범위이고, "확인하지 못했다"고 적은 태도 자체가 D1-2(객관적 증거) 기준에 부합한다. 더 깊이 가고 싶다면 ①은 `/proc/<pid>/task/<tid>/comm` 을, ③은 `dmesg -T | grep -i oom` 을 캡처하면 된다.

---

#### 🧪 실행 검증 기록

저장소를 변경하지 않고 네트워크·설치 없이 가능한 범위만 수행했다.

| 검증 | 명령 | 결과 |
| --- | --- | --- |
| 셸 문법 검사 (전 스크립트) | `for f in $(find . -name '*.sh' -not -path './.git/*'); do bash -n "$f"; done` | **19개 전부 OK** (`demo.sh`, `verify_orbstack.sh`, `src/*.sh` 11개, `src/experiments/*.sh` 6개) — 구문 오류 0건 |
| 바이너리 동일성 | `md5sum bin/agent-leak-app` | `0fb02e12554328b32e6e1adac861630e` — `evidence/oom_monitor.log:8` 이 기록한 해시와 **일치**. evidence 가 이 저장소의 바이너리에서 나왔음이 확인됨 |
| 리버스 엔지니어링 흔적 | `grep -rniE "objdump\|readelf\|pyinstxtractor\|uncompyle\|decompil\|disassembl\|ghidra\|radare" --include='*.sh' --include='*.md' --include='*.py' --include='*.txt' --include='*.log' .` | **0건** (용어집의 용어 설명 제외) |
| 바인딩 주소 근거 | `grep -rn "0\.0\.0\.0:15034\|ss -tln\|netstat -tln\|LISTEN" evidence/` | 주석 1줄뿐, 실제 `ss` 출력 캡처 **0건** → R1-11 부분 충족 판정의 근거 |
| 리포트↔evidence 줄번호 대조 | `sed -n` 으로 인용 구간 직접 열람 (`oom_app.log:34-58,63-78` / `oom_monitor.log:150-170,225-240,300-370` / `oom_ps_top.txt:290-372` / `cpu_monitor.log:280-340` / `cpu_top_ps.txt:300-350` / `deadlock_ps_top.txt:78-95,140-226` / `deadlock_monitor.log:274-302` / `scheduling_workers.log:30-70,170-206`) | 표본으로 확인한 인용 **전부 일치**. 리포트 본문에 붙은 `원본: …:Lxx-yy` 링크가 실제 줄 내용과 맞다 |

**미실행 항목과 이유**

- `bin/agent-leak-app` 실행 / `src/monitor.sh` 실행 / `src/experiments/*.sh` 실행 — **미실행**. 앱 실행은 `$AGENT_HOME`·`$AGENT_LOG_DIR` 디렉터리 생성과 로그 파일 쓰기를 동반해 "저장소·시스템 무변경" 규칙에 어긋나고, `monitor.sh` 는 앱이 떠 있어야만 Health Check 를 통과하며 `$AGENT_LOG_DIR` 에 append 한다.
- `src/0X_*.sh` setup 스크립트 — **미실행**. `apt-get install`(acl·ufw·cron), 계정 생성, `sudo` 시스템 변경을 수행한다.
- `tools/build_docs.py` — **미실행**. `markdown`·`pygments` 설치가 필요하고(`README.md:857`) 설치는 금지 범위다. 단, `docs/html/index.html` 산출물이 이미 존재함은 확인했다.

---

## 0-A. 미션이 진짜로 묻는 것 (저장소 저자 해설)

쉘 명령어를 외워서 푸는 게 아니라, **외부에서 보이는 데이터(로그·관제·시스템 도구) 만으로 프로세스 안과 OS 안에서 무슨 일이 벌어졌는지 역추론**할 수 있는지를 묻는다.

```
[관측] monitor.log 의 PROC_RSS 가 17.7MB→267.7MB 로 올랐고 [MemoryGuard] Self-terminating 이 찍혔다
   ↓
[추론] 어떤 자료구조 위에서, 어떤 정책이, 누구를, 어떤 시그널로 죽였는가?
   ↓
[증명] /proc, ps, top 으로 그 추론을 뒷받침할 수 있는가?
   ↓
[소통] 위 3단계를 동료 개발자가 30초만에 따라올 수 있는 Issue 로 정리했는가?
```

따라서 미션의 산출물은 **리포트(.md)** 다. 하지만 진짜 측정 대상은 학습자가 **운영체제 동작 원리** 를 자기 언어로 설명할 수 있게 됐는가이다. 그래서 본 저장소는 리포트와 함께 **이론 지식 문서**를 핵심 산출물로 포함한다.

---

## 1. 학습 목표

수료 후 학습자는 다음을 자기 말로 설명할 수 있어야 한다:

- 가상 메모리·Heap·RSS·OOM Killer·앱 자체 MemoryGuard 의 관계
- 특정 프로세스의 CPU 과점유가 시스템 지연을 유발하는 원리, CFS 스케줄러의 기본 직관
- 데드락 4대 조건(상호배제·점유대기·비선점·순환대기), 외부 도구로 데드락을 증명하는 6가지 증거
- 로그·관제 데이터를 근거로 GitHub Issue 형태로 동료와 소통하는 방법

이론적 배경은 [docs/md/이론_지식.md](docs/md/이론_지식.md) 에 깊이 정리돼 있다 — 리포트를 쓰기 전에 한 번 통독할 것.

---

## 2. 디렉토리 구조

```
codyssey_B1-2/
├── README.md                       ← 이 파일 (미션 개요 + 수행 방법)
├── 실험_절차서.md                  ← 3개 장애 재현·검증 절차
├── demo.sh                         ← (macOS) OrbStack 자동 시연 래퍼 — 한 줄로 전체 실행
├── verify_orbstack.sh              ← (macOS) 머신 생성→setup→부트→실험→증거 수집 드라이버
│
├── docs/
│   ├── md/
│   │   └── 이론_지식.md            ← 컴퓨터 구조 · 메모리 · CPU · 동시성 (필독)
│   └── html/
│       └── index.html              ← tools/build_docs.py 가 생성하는 정적 사이트
│
├── reports/                        ← GitHub Issue 형식 분석 리포트 (제출 산출물)
│   ├── 01_oom_report.md
│   ├── 02_cpu_report.md
│   ├── 03_deadlock_report.md
│   └── 04_scheduling_analysis.md   ← 보너스 (스케줄링 추론)
│
├── evidence/                       ← 리포트가 인용한 로그·명령어 출력 원본
│   ├── oom_monitor.log / oom_app.log / oom_ps_top.txt
│   ├── cpu_monitor.log / cpu_app.log / cpu_top_ps.txt
│   ├── deadlock_monitor.log / deadlock_app.log / deadlock_ps_top.txt
│   └── scheduling_workers.log / scheduling_top_h.txt
│
├── bin/                            ← 운영 측 제공 agent-leak-app 을 두는 자리 (비어 있음)
│   └── (agent-leak-app)            ← 학습자가 직접 배치 — 이 저장소에는 포함 안 됨
│
├── src/                            ← B1-1 에서 가져온 인프라 자동화 스크립트
│   ├── monitor.sh                  ← 시스템 상태 수집·로깅 (cron 매분)
│   ├── report.sh                   ← monitor.log 통계 출력
│   ├── archive_logs.sh             ← 시간 기반 로그 보존 정책
│   ├── 00_run_all.sh               ← 01~07 setup 단계를 한 번에 실행
│   ├── 01_ssh_hardening.sh         ← SSH 포트 20022 + Root 차단
│   ├── 02_firewall_allowlist.sh    ← UFW 화이트리스트 (20022/15034)
│   ├── 03_users_and_groups.sh      ← 계정 3종 + 그룹 2종
│   ├── 04_directories_and_acl.sh   ← 디렉토리 + ACL
│   ├── 05_env_and_keyfile.sh       ← B1-2 사양 env 5종 + 실험용 3종 + secret.key
│   ├── 06_deploy_app_and_scripts.sh ← agent-leak-app + *.sh 배포 (B1-2 버전)
│   ├── 07_cron_schedule.sh         ← cron 매분/매일 등록
│   └── experiments/                ← 실험_절차서.md 를 자동 수행하는 검증 파이프라인
│       ├── 00_run_experiments.sh   ← 4개 실험 일괄/개별 실행 오케스트레이터
│       ├── lib_experiment.sh       ← 공통 도구 (설정·관측 루프·증거 스냅샷·요약) — 직접 실행 안 함
│       ├── 01_oom.sh               ← OOM 재현·검증 (MEMORY_LIMIT 256→512)
│       ├── 02_cpu.sh               ← CPU 과점유 재현·검증 (CPU_MAX_OCCUPY 80→10)
│       ├── 03_deadlock.sh          ← Deadlock(freeze) 재현·검증 (MULTI_THREAD_ENABLE true→false)
│       └── 04_scheduling.sh        ← 스케줄링 추론 데이터 수집 (보너스)
│
└── tools/
    └── build_docs.py               ← .md → docs/html/index.html 빌더
```

> B1-1 과 가장 큰 차이는 두 가지다:
> 1. `src/05_env_and_keyfile.sh` 가 B1-2 사양으로 바뀌었다 (key 파일명, key 경로 의미, 실험용 ENV 3종 추가).
> 2. `src/06_deploy_app_and_scripts.sh` 의 바이너리 이름이 `agent-leak-app` 으로 바뀌었다. **이 저장소에 바이너리는 포함되어 있지 않으니** 운영 측이 제공한 파일을 `bin/agent-leak-app` 에 배치해야 한다.

---

## 3. 사전 준비 (agent-leak-app 실행 조건)

운영 측에서 제공한 `agent-leak-app` 은 부트 시퀀스에서 아래 항목을 모두 검사하고, 하나라도 실패하면 자동 부팅 실패 처리된다.

| 항목 | 조건 |
| ---- | ---- |
| 실행 계정 | root **금지**, 일반 사용자 (예: `agent-admin`) |
| `AGENT_HOME` | 필수 환경변수 |
| `AGENT_PORT` | `15034` 고정 |
| `AGENT_UPLOAD_DIR` | `$AGENT_HOME/upload_files` (디렉토리 존재) |
| `AGENT_KEY_PATH` | `$AGENT_HOME/api_keys` (경로 존재) — **B1-1 과 달리 디렉토리** |
| `AGENT_LOG_DIR` | 디렉토리 존재 + 쓰기 권한 |
| `MEMORY_LIMIT` | 정수, **50~512** (MB) |
| `CPU_MAX_OCCUPY` | 정수, **10~100** (%) |
| `MULTI_THREAD_ENABLE` | `true/false`, `1/0`, `yes/no` 허용 |
| `secret.key` 파일 | `$AGENT_HOME/api_keys/secret.key`, 내용 = `agent_api_key_test` |
| 네트워크 | `0.0.0.0:15034` 바인딩 가능 |

`.bashrc` 예시 (`src/05_env_and_keyfile.sh` 가 자동 등록):

```bash
export AGENT_HOME="/home/agent-admin/agent-app"
export AGENT_PORT="15034"
export AGENT_UPLOAD_DIR="$AGENT_HOME/upload_files"
export AGENT_KEY_PATH="$AGENT_HOME/api_keys"
export AGENT_LOG_DIR="/var/log/agent-app"

# 베이스라인 (정상 가동) — 실험 시 실험_절차서.md 조합표대로 바꿔서 재실행
#   CPU_MAX_OCCUPY 는 10 이어야 [Healthy System Monitoring] 이 선택된다.
#   95 로 두면 CPU 과점유 시나리오가 골라져 34초 만에 죽는다(exit 143). 실험_절차서.md §조합표 참고.
export MEMORY_LIMIT="512"
export CPU_MAX_OCCUPY="10"
export MULTI_THREAD_ENABLE="false"
```

---

## 4. 분석 흐름 (모든 장애 공통)

```
[1] 정상 가동 (Baseline 수집)
        │  monitor.sh 가 1분 단위로 CPU/MEM/DISK 로그
        ▼
[2] 장애 관측 (Symptom)
        │  - OOM: 메모리 선형 증가 → 종료
        │  - CPU: CPU% 급상승 → SIGTERM
        │  - Deadlock: PID 살아있지만 로그/리소스 정지
        ▼
[3] 증거 수집 (Evidence)
        │  monitor.log + agent-leak-app 실행 로그 + ps/top
        ▼
[4] 원인 추론 (Root Cause)
        │  OS 동작 원리 + 앱 정책 매핑
        │  → 막히면 docs/md/이론_지식.md 재참조
        ▼
[5] 임시 조치 & 재검증 (Workaround)
        │  환경변수 조정 → 재실행 → Before/After 비교
        ▼
[6] GitHub Issue 작성 (reports/*.md)
```

---

## 5. 빠른 실행 가이드

### 5.1 환경 구축 (OrbStack)

#### (A) 한 줄 자동 실행 — 권장 (macOS)

운영 측 제공 `agent-leak-app` 을 `bin/` 에 둔 뒤, 머신 생성 → §1~§7 setup → agent-leak-app
부트 검증 → monitor/cron 확인 → 3대 장애 실험 → 증거 수집까지 한 번에 돌린다.
증거는 `./.verify-artifacts/` 에 모인다.

```bash
cp ~/Downloads/agent-leak-app bin/agent-leak-app   # 운영 측 제공 바이너리 배치

./demo.sh                 # 시연 모드(섹션마다 엔터) + 실험 전체(실측)
./demo.sh --quick         # 장애 실험 대기시간 단축 (라이브 시연 권장)
./demo.sh --no-exp        # setup + 부트 검증까지만 (실험 생략)
./demo.sh --fast          # 일시정지 없이 끝까지 (CI 처럼)

# demo.sh 없이 드라이버만 직접:
./verify_orbstack.sh                  # 실험 전체(실측 — OOM ≤25분 등 매우 김)
QUICK=1 ./verify_orbstack.sh          # 실험 단축
RUN_EXPERIMENTS=0 ./verify_orbstack.sh # setup+부트만
FRESH=1 ./verify_orbstack.sh          # 머신 깨끗이 재생성
```

> ⚠ 실험 '전체(실측)' 는 의도적으로 장애를 재현하므로 매우 오래 걸린다
> (OOM ≤25분 / CPU ≤15분 / Deadlock ≤10분). 빠른 확인은 `--quick` 또는 `--no-exp`.

#### (B) 수동 단계 실행 (머신 안에서 직접)

```bash
# macOS 호스트
brew install orbstack
orb create ubuntu:24.04 codyssey-b1-2

cp ~/Downloads/agent-leak-app bin/agent-leak-app
orb push -m codyssey-b1-2 src/*.sh bin/agent-leak-app /tmp/

orb shell -m codyssey-b1-2

# 머신 안에서 (CRLF 정리 후 setup)
sudo apt-get install -y dos2unix
dos2unix /tmp/*.sh && chmod +x /tmp/*.sh
bash /tmp/00_run_all.sh           # 7단계 setup 한 번에
```

### 5.2 부트 시퀀스 확인

```bash
sudo -iu agent-admin
cd $AGENT_HOME
./agent-leak-app             # 모든 [OK] 가 떠야 정상
```

### 5.3 장애 실험

세 가지 장애를 순서대로 재현하는 환경변수 조합과 검증 명령은 [실험_절차서.md](실험_절차서.md) 에 정리돼 있다.

```bash
# 한 줄 요약
# (아래 시간·시그니처는 2026-08-26 실측값. 나머지 두 변수는 안전값 MEMORY_LIMIT=512 / CPU_MAX_OCCUPY=10 고정)
# OOM     : MEMORY_LIMIT=256        → 0m34s 후 exit 137, [MemoryGuard] Memory limit exceeded + Self-terminating
# CPU     : CPU_MAX_OCCUPY=80       → 0m30s 후 exit 143, [CpuWorker] CPU Threshold Violated!
# Deadlock: MULTI_THREAD_ENABLE=true → 부팅 약 9초 후 무응답 (PID 생존, 자가 종료 없음)
```

위 절차를 **사람 손 없이 자동 수행**하려면 [src/experiments/](src/experiments/) 의 파이프라인을 쓴다
(환경변수 설정 → 앱 실행 → 자원 샘플링 → ps/top/curl 증거 캡처 → 종료/freeze 판정 → Before/After 비교 → PASS/FAIL 요약):

```bash
cd $AGENT_HOME/experiments        # 또는 src/experiments 를 머신에 푸시한 경로
bash 00_run_experiments.sh selftest   # 앱 안 띄우고 환경/권한만 점검
bash 00_run_experiments.sh all        # 4개 파이프라인 일괄 (oom→cpu→deadlock→scheduling)
bash 01_oom.sh                        # 파이프라인 하나만 단독 실행
QUICK=1 bash 00_run_experiments.sh all   # 대기시간 단축 (배선 확인·데모용)
```

### 5.4 관제 모니터링

```bash
# 다른 터미널
tail -f /var/log/agent-app/monitor.log              # cron 매분 누적
tail -f $AGENT_LOG_DIR/agent_app.log               # 앱 자체 로그 (앱이 직접 append)
tail -f $AGENT_LOG_DIR/agent_app.out               # nohup stdout (부트 시퀀스 [1/6]~[6/6])
```

라이브 관찰만으로는 리포트에 넣을 **수치**가 안 나온다. `monitor.log` 에서 추세를 뽑거나(`grep`/`awk`), `src/report.sh` 로 구간 통계(Max/Min·도달 시각·평균)를 산출한다:

```bash
# 특정 PID 의 PROC_RSS(MB) 시계열만 추출 (Evidence 표/그래프 재료)
# monitor.log 포맷: [TS] PID:n SYS_CPU:x% SYS_MEM:y% PROC_CPU:z% PROC_RSS:wMB DISK_USED:d%
#   SYS_* = 호스트 전체 / PROC_* = 대상 프로세스. 프로세스 메모리 증가의 근거는 PROC_RSS 다.
grep "PID:<pid>" /var/log/agent-app/monitor.log | awk -F'PROC_RSS:' '{print $2}' | awk -F'MB' '{print $1}'

# 구간 통계 — ====== STATISTICS REPORT ====== ([Process RSS] Maximum … MB at … )
bash src/report.sh                                          # 전체
bash src/report.sh "2026-08-26 09:02:37" "2026-08-26 09:03:11"   # 구간 지정 (OOM Before 실측 구간)
```

---

## 6. 리포트 작성 가이드

세 리포트 모두 동일한 4단 구조로 쓴다:

```markdown
[Bug] {장애 유형} - {한 줄 요약}

## 1. Description (현상 설명)
- 무엇이, 언제, 어떤 조건에서 발생했나

## 2. Evidence & Logs (증거 자료)
- monitor.log 발췌 (수치)
- 앱 로그 핵심 라인 발췌
- ps/top 출력

## 3. Root Cause Analysis (원인 분석)
- 위 증거가 OS 동작 원리로 어떻게 설명되는가
- (이론_지식.md 의 어느 부분을 끌어왔는지 자기 언어로 적기)

## 4. Workaround & Verification (조치 및 검증)
- 어떤 환경변수를 어떻게 바꿨고
- Before / After 결과가 어떻게 달라졌는가
- 근본 해결은 무엇인가 (선택)
```

> 🔑 **리포트의 합격선은 "동료가 30초 안에 따라올 수 있는가"** 다. 4단 구조의 각 섹션을 한 번에 한 가지 사실만 적되, 그 사실의 근거를 evidence/ 파일과 1:1 로 연결되게 인용한다.

---

## 7. 제약 사항

- 사용 가능 도구: `monitor.sh`, `ps`, `top`, `htop`, `pstree`, `kill`, `vmstat`, `/proc` 등 리눅스 표준 도구
- **바이너리 디컴파일/리버스 엔지니어링 금지** — 외부 관측 정보(로그/관제)만으로 추론
- 일반 계정으로만 실행 (root 금지)
- 자동화 스크립트는 **Bash 로만**

---

## 8. 필수 증거 체크리스트

| 장애 | 증거 |
| ---- | ---- |
| **OOM** | monitor.log **`PROC_RSS`** 선형 증가 구간(`SYS_MEM` 아님) + `[MemoryGuard] Memory limit exceeded` / `Self-terminating process …` 로그 + 종료 코드 137 + `MEMORY_LIMIT` 변경 전/후 생존시간 비교 |
| **CPU** | `[CpuWorker] Current Load` 상승 계열 + `/proc/<pid>/stat` 델타로 잰 프로세스 CPU(호스트 전체와 대조) + `[CpuWorker] CPU Threshold Violated!` 로그 + 종료 코드 143 + `CPU_MAX_OCCUPY` 변경 전/후 비교 |
| **Deadlock** | `ps -ef \| grep agent` PID 존재 + `top -H` 스레드 `TIME+` 정지 + `ps -L -o wchan` 의 `futex_wait_queue`(전 스레드) + 앱 로그 mtime 정지 + 마지막 `WAITING/BLOCKED` 로그 + `MULTI_THREAD_ENABLE=false` 회피 확인 |
| **(보너스) 스케줄링** | 워커 스레드 로그의 타임스탬프 + 진행률 패턴 → RR / FCFS / Priority / CFS 중 어느 시그니처인지 |

---

## 9. 문서 빌드 (선택)

세 개의 .md (이 파일, 실험_절차서, 이론_지식) 와 4개 리포트를 묶어 보기 좋은 정적 HTML 로 빌드:

```bash
# 의존성 (Python 3 + markdown + pygments)
pip install markdown pygments

python3 tools/build_docs.py            # docs/html/index.html 생성
# Windows: 더블클릭으로 열기 / macOS: open docs/html/index.html
```

생성된 `docs/html/index.html` 은 **단일 파일·외부 파일 없음** 으로 만들어져 어디로 옮겨도 그대로 열린다. 좌측 사이드바에서 문서 간 이동 + 우측에 현재 문서 목차가 같이 보인다.

---

## 10. 다음 단계 — 학습 체크리스트

리포트를 다 쓴 뒤, [이론_지식.md 의 §8 학습 체크리스트](docs/md/이론_지식.md) 의 질문들에 자기 언어로 답할 수 있는지 확인해보자. 답이 막히는 항목이 있다면 그 부분이 이번 미션에서 더 채워야 할 이론의 빈 곳이다.
