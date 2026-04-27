#!/bin/bash
# update.sh — Tactical Update Engine for X5Sentry [HELLHOUND-class]

# We use an embedded Python engine to handle the tactical animations 
# (Case-Wave + Braille-Wave) for a premium terminal experience.

python3 - << 'EOF'
import sys
import time
import math
import threading
import subprocess
import os

try:
    from rich.console import Console
    from rich.text import Text
    from rich.live import Live
    from rich.align import Align
    from rich.rule import Rule
except ImportError:
    # Fallback if rich is not installed (though it should be)
    print("[*] Checking for updates...")
    subprocess.run("git fetch --all && git reset --hard origin/main", shell=True)
    sys.exit(0)

# ------ CONFIGURATION & ASSETS ------
_BRAILLE_WAVE = ["⠁", "⠃", "⠇", "⡇", "⣇", "⣧", "⣷", "⣿", "⣾", "⣶", "⣦", "⣄", "⡄", "⠄", "⠀", "⠀"]
console = Console()

def case_wave(text: str, frame: float) -> Text:
    """Sinusoidal Case-Wave effect for terminal text."""
    result = Text()
    for i, ch in enumerate(text):
        if ch == " ":
            result.append(" ")
            continue
        val = math.sin(i * 0.45 + frame * 3.5)
        if val > 0.6:
            result.append(ch.upper(), style="bold red")
        elif val > 0.2:
            result.append(ch.upper(), style="red")
        elif val > -0.2:
            result.append(ch,         style="white")
        elif val > -0.6:
            result.append(ch.lower(), style="dim red")
        else:
            result.append(ch.lower(), style="dim")
    return result

def draw_ui(text, stop_event):
    """Animates the Braille-Wave and Case-Wave HUD."""
    n = len(_BRAILLE_WAVE)
    width = 26
    with Live("", refresh_per_second=15, transient=True) as live:
        while not stop_event.is_set():
            t = time.time()
            txt = case_wave(text, t)
            chars = ""
            for i in range(width):
                idx = int((i * 2 - t * 12)) % n
                if idx < 0: idx += n
                chars += _BRAILLE_WAVE[idx]
            
            content = Text.assemble(txt, "  ", (chars, "bold red"))
            live.update(Align.center(content))
            time.sleep(0.05)

def run_task(text, cmd):
    """Runs a command with a live tactical animation."""
    stop_event = threading.Event()
    t = threading.Thread(target=draw_ui, args=(text, stop_event), daemon=True)
    t.start()
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return res
    finally:
        stop_event.set()
        t.join(timeout=1)

def print_banner():
    art = r"""
  __  __  ____ ____  _____ _   _ _____ ____  __   __
  \ \/ / / ___/ ___|| ____| \ | |_   _|  _ \ \ \ / /
   \  /  \___ \___ \|  _| |  \| | | | | |_) | \ V / 
   /  \   ___) |__) | |___| |\  | | | |  _ <   | |  
  /_/\_\ |____/____/|_____|_| \_| |_| |_| \_\  |_|  
"""
    console.print("\n")
    console.print(Align.center(Text(art, style="bold white")))
    console.print(Align.center(Text("—  S Y S T E M   U P D A T E   E N G I N E  —", style="dim")))
    console.print(Rule(style="dim red"))
    console.print("\n")

def main():
    print_banner()
    
    # Phase 1: Git Sync
    res = run_task("CHECKING FOR UPDATES", "git fetch --all && git reset --hard origin/main")
    if res.returncode == 0:
        console.print(Align.center(Text("[+] SUCCESS: SYNCED WITH REMOTE CLOUD", style="bold green")))
    else:
        console.print(Align.center(Text("[-] ERROR: FAILED TO SYNC WITH REMOTE", style="bold red")))
        sys.exit(1)

    # Phase 2: Dependency Update
    if os.path.exists(".venv"):
        res = run_task("UPDATING DEPENDENCIES", "./.venv/bin/pip install --upgrade pip && ./.venv/bin/pip install -e .")
        if res.returncode == 0:
            console.print(Align.center(Text("[+] SUCCESS: VIRTUAL ENVIRONMENT OPTIMIZED", style="bold green")))
        else:
            console.print(Align.center(Text("[-] ERROR: DEPENDENCY INJECTION FAILED", style="bold red")))
            sys.exit(1)
    else:
        console.print(Align.center(Text("[!] WARNING: .VENV NOT FOUND - SKIPPING PIP", style="bold yellow")))
    
    console.print("\n")
    console.print(Rule(style="dim red"))
    console.print(Align.center(Text("THE SENTRY HAS BEEN RE-ARMED", style="bold white")))
    console.print(Align.center(Text("VERSION: 4.0.0-STABLE", style="dim")))
    console.print("\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[bold red][!] UPDATE ABORTED BY USER[/bold red]")
        sys.exit(1)
EOF
