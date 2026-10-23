#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BudsBridge contributors. See LICENSE and LEGAL.md.
"""Package a previously built app and a clean corresponding source archive."""
import argparse
import hashlib
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parent.parent
VERSION = "0.2.1-beta.1"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--app", type=Path, default=ROOT / "dist/BudsBridge.app")
parser.add_argument("--output", type=Path, default=ROOT / "dist/release")
args = parser.parse_args()
app, dest = args.app.resolve(), args.output.resolve()
with (app / "Contents/Info.plist").open("rb") as stream:
    info = plistlib.load(stream)
if info.get("CFBundleIdentifier") != "dev.budsbridge.mac" or info.get("CFBundleShortVersionString") != "0.2.1":
    raise SystemExit("Expected a BudsBridge 0.2.1 application bundle")
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
arch = subprocess.check_output(["lipo", "-archs", str(app / "Contents/MacOS/BudsBridge")], text=True).strip()
if arch not in ("arm64", "x86_64"):
    raise SystemExit("This packager expects a single-architecture build")
dest.mkdir(parents=True, exist_ok=True)
source_zip = dest / f"BudsBridge-{VERSION}-source.zip"
binary_zip = dest / f"BudsBridge-{VERSION}-macos-{arch}.zip"
# Explicit allowlist: never copy research logs, APKs, tools, preferences or build caches.
files = [ROOT / name for name in (".gitignore", "README.md", "LICENSE", "LEGAL.md", "PRIVACY.md", "THIRD_PARTY_NOTICES.md", "CONTRIBUTING.md")]
files += [ROOT / "macOS/Info.plist", ROOT / "macOS/Package.swift"]
for folder in ("docs", "scripts", "macOS/Sources", "macOS/Tests", "macOS/Widget"):
    files += [p for p in (ROOT / folder).rglob("*") if p.is_file() and not any(part.startswith(".") or part == "__pycache__" for part in p.relative_to(ROOT / folder).parts)]
with zipfile.ZipFile(source_zip, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(set(files)):
        archive.write(path, str(Path(f"BudsBridge-{VERSION}") / path.relative_to(ROOT)))
subprocess.run(["ditto", "-c", "-k", "--norsrc", "--noextattr", "--keepParent", str(app), str(binary_zip)], check=True)
with tempfile.TemporaryDirectory(prefix="budsbridge-verify-") as tmp:
    subprocess.run(["ditto", "-x", "-k", str(binary_zip), tmp], check=True)
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(Path(tmp) / "BudsBridge.app")], check=True)
dmg = dest / f"BudsBridge-{VERSION}-macos-{arch}.dmg"
subprocess.run(["bash", str(ROOT / "scripts/create-dmg.sh"), str(app), str(dmg), str(ROOT / "docs/GETTING_STARTED.txt")], check=True)
checksums = []
for path in (binary_zip, source_zip, dmg):
    checksums.append(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}")
(dest / "SHA256SUMS.txt").write_text("\n".join(checksums) + "\n")
print(f"Packaged {len(set(files))} source files; app architecture: {arch}")
print("\n".join(checksums))
