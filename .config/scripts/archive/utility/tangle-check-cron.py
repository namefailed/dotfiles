#!/usr/bin/env python3
"""Tangle-check: verify .org literate configs match their tangled outputs.

Reads the drift map from config-paths.ps1 (parsed), computes SHA256 hashes
of output files, re-tangles each .org via Emacs, compares, restores originals.
Reports which files are out of sync.
"""

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import uuid

USERPROFILE = os.environ["USERPROFILE"]
CONFIG_DIR = os.path.join(USERPROFILE, ".config")

# The drift map from config-paths.ps1 Get-ConfigOrgDriftMap
DRIFT_MAP = {
    "komorebi\\komorebi.org": ["komorebi\\komorebi.json", "komorebi\\komorebi.bar.json"],
    "kanata\\kanata.org": ["kanata\\kanata.kbd", "kanata\\kanata-plain.kbd"],
    "doom\\init.org": ["doom\\init.el", "doom\\packages.el"],
    "doom\\config.org": ["doom\\config.el"],
    "wtq\\wtq.org": ["wtq\\wtq.jsonc"],
    "starship\\starship.org": ["starship\\starship.toml"],
    "git\\git.org": ["git\\config"],  # fixed: was gitconfig
    "espanso\\espanso.org": ["espanso\\config\\default.yml", "espanso\\match\\base.yml"],
    "vscode\\vscode.org": ["vscode\\settings.json", "vscode\\keybindings.json"],
    "cursor\\cursor.org": ["cursor\\settings.json", "cursor\\keybindings.json"],
    "windsurf\\windsurf.org": ["windsurf\\settings.json", "windsurf\\keybindings.json"],
    "tridactyl\\tridactyl.org": ["tridactyl\\tridactylrc", "tridactyl\\native\\tridactyl.json"],  # fixed: was .tridactylrc
    "everything\\everything.org": ["everything\\Everything.ini"],
    "windows-terminal\\windows-terminal.org": ["windows-terminal\\settings.json"],
    "powershell\\powershell.org": ["powershell\\Microsoft.PowerShell_profile.ps1"],
    "flowlauncher\\flowlauncher.org": ["flowlauncher\\settings\\Settings.json"],
    "hermes\\hermes.org": ["hermes\\config.yaml", "hermes\\.gitignore"],
    "scripts\\scripts.org": [
        "scripts\\powershell\\_lib\\config-paths.ps1",
        "scripts\\powershell\\utility\\tangle-configs.ps1",
        "scripts\\powershell\\utility\\verify-org-tangle-sync.ps1",
    ],
}

EMACS = r"C:\Program Files\Emacs\emacs-30.2\bin\emacs.exe"
NOWEB_EL = os.path.join(CONFIG_DIR, "scripts\\powershell\\utility\\org-preexecute-noweb-blocks.el")


def file_hash(path):
    """SHA256 hex digest of a file."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(8192)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def uses_noweb(org_path):
    """Check if org file uses :noweb yes."""
    try:
        with open(org_path, "r", encoding="utf-8") as f:
            return bool(re.search(r"(?m):noweb\s+yes", f.read()))
    except FileNotFoundError:
        return False


def tangle_org(org_path):
    """Run Emacs batch tangle on an .org file. Returns stdout+stderr."""
    fwd = org_path.replace("\\", "/")
    cmd = [EMACS, "--batch"]
    cmd.extend(["--eval", "(require 'org)"])
    cmd.extend(["--eval", "(require 'ob-tangle)"])
    cmd.extend(["--eval", "(require 'ob-python nil t)"])
    cmd.extend(["--eval", "(setq coding-system-for-write 'utf-8-unix)"])
    cmd.extend(["--eval", "(setq org-confirm-babel-evaluate nil)"])

    if uses_noweb(org_path) and os.path.isfile(NOWEB_EL):
        noweb_fwd = NOWEB_EL.replace("\\", "/")
        cmd.extend(["--load", noweb_fwd])
        cmd.extend(["--eval", "(my/org-preexecute-noweb-blocks)"])

    cmd.append(fwd)
    cmd.extend(["--eval", "(org-babel-tangle)"])

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    return result.stdout + "\n" + result.stderr


def repair_kanata(kanata_dir):
    """Post-process kanata .kbd files: replace noweb placeholders with resolved paths."""
    scripts_fwd = os.path.join(USERPROFILE, ".config", "scripts").replace("\\", "/")
    olk_fwd = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Microsoft", "WindowsApps", "olk.exe").replace("\\", "/")
    broken_scripts = '(replace-regexp-in-string "\\\\\\\\" "/" (expand-file-name "~/.config/scripts"))'

    for kbd_name in ["kanata.kbd", "kanata-plain.kbd"]:
        kbd_path = os.path.join(kanata_dir, kbd_name)
        if not os.path.isfile(kbd_path):
            continue
        with open(kbd_path, "r", encoding="utf-8") as f:
            text = f.read()
        text = text.replace("<<config-scripts-fwd>>", scripts_fwd)
        text = text.replace(broken_scripts, scripts_fwd)
        text = text.replace("<<local-windowsapps-olk>>", olk_fwd)
        with open(kbd_path, "w", encoding="utf-8", newline="") as f:
            f.write(text)


def main():
    if not os.path.isfile(EMACS):
        print(f"ERROR: Emacs not found at {EMACS}")
        sys.exit(1)

    print(f"Emacs: {EMACS}")
    print(f"Config: {CONFIG_DIR}")
    print()

    drift_all = []
    skipped = []

    for org_rel, outputs in DRIFT_MAP.items():
        org_path = os.path.join(CONFIG_DIR, org_rel)

        if not os.path.isfile(org_path):
            print(f"SKIP  {org_rel}  (org source missing)")
            skipped.append(f"{org_rel} (org source not found)")
            continue

        # Check that at least one output exists
        existing_outputs = [o for o in outputs if os.path.isfile(os.path.join(CONFIG_DIR, o))]
        if not existing_outputs:
            print(f"SKIP  {org_rel}  (no output files exist — drift-map targets may be wrong)")
            skipped.append(f"{org_rel} (no output files found)")
            continue

        # Compute before-hashes and backup
        before = {}
        backups = []
        backup_root = os.path.join(tempfile.gettempdir(), f"config-drift-check-{uuid.uuid4().hex}")

        for out_rel in outputs:
            full_path = os.path.join(CONFIG_DIR, out_rel)
            if os.path.isfile(full_path):
                before[out_rel] = file_hash(full_path)
                bak_path = os.path.join(backup_root, out_rel)
                os.makedirs(os.path.dirname(bak_path), exist_ok=True)
                shutil.copy2(full_path, bak_path)
                backups.append({"dest": full_path, "backup": bak_path, "existed": True})
            else:
                backups.append({"dest": full_path, "backup": None, "existed": False})

        try:
            print(f"Check {org_rel} ... ", end="", flush=True)
            tangle_output = tangle_org(org_path)

            if "Tangled " not in tangle_output and "Tangled 0" in tangle_output:
                print("FAIL (tangle error or 0 blocks)")
                drift_all.append(f"{org_rel} -> tangle FAILED")
                continue

            # Kanata post-processing
            if org_rel == "kanata\\kanata.org":
                kanata_dir = os.path.join(CONFIG_DIR, "kanata")
                if os.path.isdir(kanata_dir):
                    repair_kanata(kanata_dir)

            drifted = []
            for out_rel in outputs:
                full_path = os.path.join(CONFIG_DIR, out_rel)
                if not os.path.isfile(full_path):
                    continue
                after_hash = file_hash(full_path)
                if out_rel in before and before[out_rel] != after_hash:
                    drifted.append(out_rel)

            if drifted:
                print("DRIFT")
                for d in drifted:
                    drift_all.append(f"{org_rel} -> {d}")
            else:
                print("OK")

        finally:
            # Restore originals
            for entry in backups:
                if entry["existed"]:
                    shutil.copy2(entry["backup"], entry["dest"])
                elif os.path.isfile(entry["dest"]):
                    os.remove(entry["dest"])
            if os.path.isdir(backup_root):
                shutil.rmtree(backup_root, ignore_errors=True)

    print()
    if skipped:
        print(f"Skipped ({len(skipped)}):")
        for s in skipped:
            print(f"  {s}")
    if drift_all:
        print(f"DRIFT DETECTED ({len(drift_all)} file(s)):")
        for d in drift_all:
            print(f"  {d}")
        print("Fix: edit the .org source, then re-tangle with tangle-configs.ps1")
        sys.exit(1)
    if not skipped and not drift_all:
        print("All configs match their .org sources.")
        sys.exit(0)
    else:
        sys.exit(2)


if __name__ == "__main__":
    main()
