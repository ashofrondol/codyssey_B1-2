#!/usr/bin/env bash
# check_req_ids.sh — 저장소 자체 요구사항 ID(B1-2-*) 가 전부 매핑표에 정의돼 있는지 검사한다.
#
# 왜 필요한가:
#   리포트·증거·실험 스크립트는 B1-2-A1 / B1-2-E-DL3 같은 자체 ID 로 근거를 단다.
#   그 ID 가 명세 원문 ID(R1-1 / E3-3 …) 중 무엇을 가리키는지는
#   docs/md/요구사항_ID_매핑.md 한 곳에만 적혀 있다.
#   표를 갱신하지 않고 새 ID 를 쓰면 채점자는 근거를 추적할 수 없다 — 그걸 여기서 실패시킨다.
#
# 사용법:
#   bash tools/check_req_ids.sh          # 조용히 통과하면 exit 0
#   VERBOSE=1 bash tools/check_req_ids.sh  # 수집된 ID 를 전부 출력
#
# 종료 코드:
#   0 = 쓰이는 모든 ID 가 매핑표에 정의돼 있음
#   1 = 정의가 없는 ID 가 있음 (또는 매핑표 자체가 없음)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAP="${ROOT}/docs/md/요구사항_ID_매핑.md"
SELF="${ROOT}/tools/check_req_ids.sh"          # 자기 자신의 예시 ID 를 '사용처'로 세지 않는다
ID_RE='B1-2-(P[0-9]+|A[0-9]+|B[0-9]+|C[0-9]+|E-[A-Z]+[0-9]+)'

c_red=''; c_green=''; c_yellow=''; c_reset=''
if [[ -t 1 ]]; then
    c_red="$(printf '\033[1;31m')"; c_green="$(printf '\033[1;32m')"
    c_yellow="$(printf '\033[1;33m')"; c_reset="$(printf '\033[0m')"
fi

if [[ ! -f "$MAP" ]]; then
    printf '%s✗%s 매핑표가 없다: docs/md/요구사항_ID_매핑.md\n' "$c_red" "$c_reset"
    exit 1
fi

# ── 1) 저장소에서 "쓰이는" ID 수집 ───────────────────────────────────────────
# 제외: .git(히스토리), docs/html(build_docs.py 생성물), 매핑표 자신(정의처), 이 스크립트(예시 ID).
used="$(
    find "$ROOT" \
        \( -path "${ROOT}/.git" -o -path "${ROOT}/docs/html" \) -prune -o \
        -type f \( -name '*.md' -o -name '*.sh' -o -name '*.txt' -o -name '*.log' -o -name '*.py' \) -print \
    | grep -v -F -x -e "$MAP" -e "$SELF" \
    | xargs grep -hoE "$ID_RE" 2>/dev/null \
    | sort -u
)"

# ── 2) 매핑표가 "정의한" ID 수집 ─────────────────────────────────────────────
defined="$(grep -oE "$ID_RE" "$MAP" | sort -u)"

if [[ "${VERBOSE:-0}" == "1" ]]; then
    printf '%s사용 중(%s개)%s\n' "$c_yellow" "$(printf '%s\n' "$used" | grep -c .)" "$c_reset"
    printf '  %s\n' $used
    printf '%s매핑표 정의(%s개)%s\n' "$c_yellow" "$(printf '%s\n' "$defined" | grep -c .)" "$c_reset"
    printf '  %s\n' $defined
fi

# ── 3) 대조 ──────────────────────────────────────────────────────────────────
missing="$(comm -23 <(printf '%s\n' "$used") <(printf '%s\n' "$defined"))"

if [[ -n "$missing" ]]; then
    printf '%s✗ 매핑표에 정의가 없는 ID%s\n' "$c_red" "$c_reset"
    while read -r id; do
        [[ -z "$id" ]] && continue
        printf '  %s\n' "$id"
        grep -rlE "(^|[^A-Za-z0-9-])${id}([^A-Za-z0-9-]|$)" "$ROOT" \
            --exclude-dir=.git --exclude-dir=html 2>/dev/null \
            | grep -v -F -x -e "$MAP" -e "$SELF" | sed "s|^${ROOT}/|      ← |"
    done <<< "$missing"
    printf '\n  고치는 법: docs/md/요구사항_ID_매핑.md 에 행을 추가하고 명세 원문 ID 와 짝지어라.\n'
    exit 1
fi

printf '%s✓%s 요구사항 ID %s개 전부 매핑표에 정의돼 있다 (docs/md/요구사항_ID_매핑.md)\n' \
    "$c_green" "$c_reset" "$(printf '%s\n' "$used" | grep -c .)"
exit 0
