#!/usr/bin/env python3
"""speak-aloud host TTS server.

Run this on the HOST when Claude Code runs inside a container. The container's Stop
hook POSTs response text here, and this server speaks it with the host's native TTS
engine. Audio cannot cross the container boundary, so the host owns the speakers.

Usage:
  python3 tts-host-server.py             # listen on 0.0.0.0:8765
  PORT=9000 python3 tts-host-server.py   # custom port

Config via env (all optional):
  PORT               listen port (default 8765)
  SPEAK_ALOUD_VOICE  voice name (macOS `say` only)
  SPEAK_ALOUD_RATE   words-per-minute (macOS `say` only)

Security: binds 0.0.0.0 so the container can reach it via host.docker.internal. Text is
passed to the TTS engine as argv (no shell), so there is no command injection — worst
case a caller makes the host speak. On an untrusted network, firewall the port to the
Docker subnet.
"""
import os
import platform
import shutil
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

VOICE = os.environ.get("SPEAK_ALOUD_VOICE")
RATE = os.environ.get("SPEAK_ALOUD_RATE")


def _run(cmd, env_text=None):
    env = dict(os.environ)
    if env_text is not None:
        env["SPEAK_TEXT"] = env_text
    try:
        subprocess.Popen(cmd, env=env)
    except Exception as exc:  # noqa: BLE001 - never crash the server on a bad call
        print(f"[speak-aloud] TTS failed: {exc}")


def speak(text: str) -> None:
    text = text.strip()
    if not text:
        return
    system = platform.system()
    if system == "Darwin":
        cmd = ["say"]
        if VOICE:
            cmd += ["-v", VOICE]
        if RATE:
            cmd += ["-r", RATE]
        cmd.append(text)
        _run(cmd)
    elif system == "Windows":
        ps = (
            "Add-Type -AssemblyName System.Speech; "
            "(New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak($env:SPEAK_TEXT)"
        )
        _run(["powershell", "-NoProfile", "-Command", ps], env_text=text)
    else:  # Linux / other
        if shutil.which("spd-say"):
            _run(["spd-say", "-w", text])
        elif shutil.which("espeak-ng"):
            _run(["espeak-ng", text])
        elif shutil.which("espeak"):
            _run(["espeak", text])
        else:
            print("[speak-aloud] no TTS engine found "
                  "(install speech-dispatcher or espeak-ng)")


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):  # noqa: N802 - http.server API
        length = int(self.headers.get("Content-Length", 0))
        text = self.rfile.read(length).decode("utf-8", "ignore")
        self.send_response(204)
        self.end_headers()
        speak(text)

    def do_GET(self):  # noqa: N802 - health check
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"speak-aloud host TTS server: OK\n")

    def log_message(self, *args):  # silence access log
        pass


def main():
    port = int(os.environ.get("PORT", "8765"))
    print(f"[speak-aloud] host TTS server listening on 0.0.0.0:{port} "
          f"({platform.system()})")
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()


if __name__ == "__main__":
    main()
