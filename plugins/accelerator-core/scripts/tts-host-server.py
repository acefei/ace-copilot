#!/usr/bin/env python3
"""speak-aloud host TTS server (stateful: latest-wins + active-session gating).

Run this on the HOST when Claude Code runs inside a container. The container's hooks
POST here and this server speaks with the host's native engine. It keeps two pieces of
state so only the session you are driving talks, and only the latest reply is heard:

  - current speech process : a new utterance kills the one in progress (latest wins).
  - active session id      : only the active session may speak; others are ignored.
                             Set by the UserPromptSubmit hook (POST /active).

Endpoints (session id travels in the `X-Session-Id` header):
  GET  /          health check -> "OK"
  POST /speak     body = text. Speaks IF X-Session-Id == active (or no active set yet).
  POST /active    mark X-Session-Id active AND stop any current speech (barge-in).
  POST /cancel    stop any current speech.
  POST /          backward-compat: speak the body, ungated (manual `curl -d ...`).

Usage:
  python3 tts-host-server.py             # listen on 0.0.0.0:8765
  PORT=9000 python3 tts-host-server.py   # custom port

Config via env (optional): PORT, SPEAK_ALOUD_VOICE, SPEAK_ALOUD_RATE.

Security: binds 0.0.0.0 so the container can reach it via host.docker.internal. Text is
passed to the engine as argv (no shell) -> no command injection. /active and /cancel are
unauthenticated like /speak; on an untrusted network, firewall the port to the Docker subnet.
"""
import os
import platform
import shutil
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

VOICE = os.environ.get("SPEAK_ALOUD_VOICE")
RATE = os.environ.get("SPEAK_ALOUD_RATE")

_lock = threading.Lock()
_current = None          # in-flight TTS subprocess (or None)
_active_session = None   # session id currently allowed to speak (or None = unset)


def _build_cmd(text):
    """Return (argv, env_text) for the host's TTS engine, or (None, None)."""
    system = platform.system()
    if system == "Darwin":
        cmd = ["say"]
        if VOICE:
            cmd += ["-v", VOICE]
        if RATE:
            cmd += ["-r", RATE]
        cmd.append(text)
        return cmd, None
    if system == "Windows":
        ps = ("Add-Type -AssemblyName System.Speech; "
              "(New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak($env:SPEAK_TEXT)")
        return ["powershell", "-NoProfile", "-Command", ps], text
    # Linux / other
    if shutil.which("spd-say"):
        return ["spd-say", "-w", text], None
    if shutil.which("espeak-ng"):
        return ["espeak-ng", text], None
    if shutil.which("espeak"):
        return ["espeak", text], None
    return None, None


def _stop_current_locked():
    """Terminate the in-flight utterance. Caller must hold _lock."""
    global _current
    if _current and _current.poll() is None:
        try:
            _current.terminate()
            try:
                _current.wait(timeout=1)
            except Exception:
                _current.kill()
        except Exception:
            pass
    _current = None


def stop():
    with _lock:
        _stop_current_locked()


def speak(text):
    global _current
    text = text.strip()
    if not text:
        return
    cmd, env_text = _build_cmd(text)
    if not cmd:
        print("[speak-aloud] no TTS engine found "
              "(install speech-dispatcher or espeak-ng)")
        return
    env = dict(os.environ)
    if env_text is not None:
        env["SPEAK_TEXT"] = env_text
    with _lock:
        _stop_current_locked()                 # latest wins
        try:
            _current = subprocess.Popen(cmd, env=env)
        except Exception as exc:  # noqa: BLE001
            print(f"[speak-aloud] TTS failed: {exc}")


def set_active(sid):
    global _active_session
    with _lock:
        _active_session = sid or None
        _stop_current_locked()                 # switching active stops old speech


def may_speak(sid):
    with _lock:
        active = _active_session
    # No active set yet -> allow (and the first prompt will set it). No sid (manual
    # curl test) -> allow. Otherwise only the active session may speak.
    return active is None or not sid or sid == active


class Handler(BaseHTTPRequestHandler):
    def _read_body(self):
        n = int(self.headers.get("Content-Length", 0) or 0)
        return self.rfile.read(n).decode("utf-8", "ignore") if n else ""

    def _sid(self):
        return (self.headers.get("X-Session-Id") or "").strip()

    def do_GET(self):  # noqa: N802
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"speak-aloud host TTS server: OK\n")

    def do_POST(self):  # noqa: N802
        path = self.path.rstrip("/") or "/"
        body = self._read_body()
        sid = self._sid()
        self.send_response(204)
        self.end_headers()
        if path == "/active":
            set_active(sid)
        elif path == "/cancel":
            stop()
        elif path == "/speak":
            if may_speak(sid):
                speak(body)
            # else: a non-active (e.g. background) session -> stay silent
        else:
            speak(body)  # backward-compat: bare POST / speaks, ungated

    def log_message(self, *args):  # silence access log
        pass


def main():
    port = int(os.environ.get("PORT", "8765"))
    print(f"[speak-aloud] host TTS server listening on 0.0.0.0:{port} "
          f"({platform.system()})")
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()


if __name__ == "__main__":
    main()
