# iTerm 세션 모니터링

다른 iTerm 탭에서 실행 중인 AI 에이전트 세션(주로 Claude Code)을 모니터링하고 자동 관리합니다.

이 커맨드는 iTerm2 + Claude Code 스타일 프롬프트(`❯`)에 최적화된 선택 워크플로우입니다.
해당 환경이 아니면 실행하지 말고, 사용 중인 도구의 기본 세션 모니터링 방식을 사용하세요.

## 사전 요구사항

- `pip3 install iterm2`
- iTerm2 > Settings > General > Magic > **Enable Python API**

## 실행 절차

### 1단계: 세션 탐색

iTerm Python API로 현재 윈도우의 모든 세션을 탐색합니다:

```python
import iterm2, asyncio

async def main(connection):
    app = await iterm2.async_get_app(connection)
    for w in app.windows:
        for tab in w.tabs:
            for s in tab.sessions:
                screen = await s.async_get_screen_contents()
                last_line = screen.line(screen.number_of_lines - 1).string.replace("\x00", " ")
                print(f"ID: {s.session_id} | Name: {s.name} | Last: {last_line.strip()}")

iterm2.run_until_complete(main)
```

사용자에게 모니터링할 세션을 확인받습니다 (session_id + 라벨).

### 2단계: 모니터 스크립트 생성

`/tmp/iterm-monitor-v6.py`에 모니터 스크립트를 생성합니다.

**상태 감지 패턴** (화면 마지막 20줄 기준):

| 패턴 | 상태 | 조치 |
|------|------|------|
| `Do you want to proceed` | NEEDS_PERMISSION | `\r` 전송 + Tink 사운드 |
| `Esc to cancel` | NEEDS_ACCEPT | `\r` 전송 + Tink 사운드 |
| `❯` 없음 (프롬프트 없음) | ACTIVE | 대기 |
| `\d+s · ` 타이밍 패턴 | ACTIVE | 대기 |
| `❯ [텍스트]` | IDLE_WITH_INPUT | 로그만 |
| `❯ ` (빈 프롬프트) | IDLE | 로그만 |

**핵심 주의사항**:
- `⏵⏵ accept edits on` 은 **상태줄 설정 표시**이므로 감지에 사용하지 않음
- 세션 이름의 스피너(✳ ✻ ✽)는 IDLE 후에도 남아있으므로 감지에 사용하지 않음
- 화면 텍스트의 `\x00` null byte → `.replace("\x00", " ")` 필수
- `\n` = 프롬프트 텍스트 제출, `\r` = 메뉴/다이얼로그 수락 (구분 필수)

**모니터 스크립트 구조**:

```python
#!/usr/bin/env python3
"""iTerm2 Claude Code Session Monitor - Python API based"""
import iterm2
import asyncio
import time
import re
import subprocess

# 사용자가 지정한 세션 ID와 라벨로 교체
SESSIONS = {
    "라벨1": "세션ID-1",
    "라벨2": "세션ID-2",
}
LOG = "/tmp/iterm-monitor.log"
prev_states = {label: "unknown" for label in SESSIONS}

def log(msg):
    ts = time.strftime("%H:%M:%S")
    line = f"{ts} {msg}"
    with open(LOG, "a") as f:
        f.write(line + "\n")
    print(line)

def detect_state(screen_text):
    lines = screen_text.strip().split("\n") if screen_text else []
    last20 = "\n".join(lines[-20:]) if len(lines) > 20 else "\n".join(lines)
    if "Do you want to proceed" in last20:
        return "NEEDS_PERMISSION"
    if "Esc to cancel" in last20:
        return "NEEDS_ACCEPT"
    prompt_lines = [l for l in lines[-15:] if "❯" in l]
    if not prompt_lines:
        return "ACTIVE"
    prompt = prompt_lines[-1]
    after_prompt = prompt.split("❯", 1)[-1].strip() if "❯" in prompt else ""
    above = "\n".join(lines[-15:])
    if re.search(r'\d+s · |thinking|timeout \d', above):
        return "ACTIVE"
    if after_prompt and after_prompt != "Press up to edit queued messages":
        return "IDLE_WITH_INPUT"
    return "IDLE"

async def main(connection):
    app = await iterm2.async_get_app(connection)
    with open(LOG, "w") as f:
        f.write(f"{time.strftime('%H:%M:%S')} [START] Monitor (Python API)\n")
    cycle = 0
    while True:
        window = app.current_window
        if not window:
            await asyncio.sleep(15)
            continue
        sessions = {}
        for tab in window.tabs:
            for s in tab.sessions:
                for label, sid in SESSIONS.items():
                    if s.session_id == sid:
                        sessions[label] = s
        for label, session in sessions.items():
            try:
                screen = await session.async_get_screen_contents()
                text = "\n".join(
                    screen.line(i).string.replace("\x00", " ")
                    for i in range(screen.number_of_lines)
                )
                state = detect_state(text)
            except Exception as e:
                state = f"ERROR:{e}"
            if state != prev_states[label]:
                log(f"[{label}] {prev_states[label]} -> {state}")
                prev_states[label] = state
            if state in ("NEEDS_PERMISSION", "NEEDS_ACCEPT"):
                try:
                    await session.async_send_text("\r")
                    log(f"[{label}] AUTO: {state} -> Enter sent")
                    subprocess.Popen(["afplay", "/System/Library/Sounds/Tink.aiff"])
                except Exception as e:
                    log(f"[{label}] AUTO FAILED: {e}")
        cycle += 1
        if cycle % 8 == 0:
            states = " ".join(f"{l}={prev_states[l]}" for l in SESSIONS)
            log(f"[HB] {states}")
        await asyncio.sleep(15)

iterm2.run_forever(main)
```

### 3단계: 모니터 시작

```bash
nohup python3 /tmp/iterm-monitor-v6.py > /dev/null 2>&1 &
echo $! > /tmp/iterm-monitor.pid
```

### 4단계: 세션 제어

모니터가 돌아가는 동안 수동으로 세션에 지시를 보낼 수 있습니다:

```python
# 특정 세션에 텍스트 보내기
async def send(connection, session_id, text):
    app = await iterm2.async_get_app(connection)
    for w in app.windows:
        for tab in w.tabs:
            for s in tab.sessions:
                if s.session_id == session_id:
                    await s.async_send_text(text + "\n")

# 특정 세션 화면 읽기
async def read(connection, session_id):
    app = await iterm2.async_get_app(connection)
    for w in app.windows:
        for tab in w.tabs:
            for s in tab.sessions:
                if s.session_id == session_id:
                    screen = await s.async_get_screen_contents()
                    return "\n".join(
                        screen.line(i).string.replace("\x00", " ")
                        for i in range(screen.number_of_lines)
                    )
```

### 5단계: 상태 확인

```bash
tail -20 /tmp/iterm-monitor.log     # 최근 로그
kill -0 $(cat /tmp/iterm-monitor.pid) 2>&1  # 프로세스 확인
```

### 6단계: 모니터 종료

```bash
kill $(cat /tmp/iterm-monitor.pid)
```

## 주의사항

- 모니터는 자동 수락(permission/edit)만 수행하고, IDLE 세션에 자동 지시는 보내지 않음
- IDLE 세션에 작업 지시는 사용자 요청 시 수동으로 전송
- 15초 간격 체크, 2분 간격 heartbeat 로그
- 로그: `/tmp/iterm-monitor.log`, PID: `/tmp/iterm-monitor.pid`
