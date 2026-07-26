from __future__ import annotations

import re
import subprocess
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENCODING = "gbk"
VERSION = "1.5.0"

RUNTIME_FILES = [
    ROOT / "YS-Tools" / "YS-Tools.lsp",
    ROOT / "YS-Tools" / "config.lsp",
    ROOT / "YS-Tools" / "utils.lsp",
    *sorted((ROOT / "YS-Tools" / "modules").glob("*.lsp")),
    ROOT / "小命令" / "排列框PAI.LSP",
    ROOT / "小命令" / "自动目录ZDML.lsp",
    ROOT / "小命令" / "自动页码HAO.lsp",
    ROOT / "YS-Tools" / "dcl" / "toolbar.lsp",
]

EXPECTED_COMMANDS = {
    "ADDKEYWORD", "BIAN", "CONT", "DIAGFRAME", "EXCEL", "FILLFRAMES",
    "GG", "GTX", "GTY", "HAO", "HE", "HEI", "KUANG", "LAN", "LONG",
    "NU", "PAI", "QSTXT", "QW", "RR", "SHANG", "SHOWBB", "SJ", "SSUO",
    "SYAN", "SYI", "T", "TXT", "UU", "WI", "XIA", "XIN", "XJ", "XSUO",
    "XY", "XYAN", "XYI", "Y", "YAN", "YOU", "YS", "YSDL", "YSOOLS", "YSRELOADAA",
    "YSTOOLS", "YYI", "ZDML", "ZDMLDEBUG", "ZHONG", "ZUO", "ZYI",
}

EXPECTED_AA_COMMANDS = {
    "AB", "AF", "AW", "BIAN", "C1", "C2", "CE", "DB", "DE", "DE2",
    "DF", "FIVE", "GE", "GG", "GTX", "GTY", "HAO", "HE", "HEI", "HP",
    "HUI", "JACC", "JZ", "KAI", "LAN", "NU", "QSTXT", "QW", "RR", "SHANG",
    "SJ", "SYAN", "T", "UU", "WI", "XIA", "XIN", "XJ", "XY", "XYAN",
    "Y", "YAN", "YSDL", "YOU", "ZDML", "ZDMLDEBUG", "ZHENG", "ZHONG", "ZI",
    "ZUO", "ZZ",
}


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def check_crlf(path: Path, data: bytes, errors: list[str]) -> None:
    remainder = data.replace(b"\r\n", b"")
    if b"\n" in remainder or b"\r" in remainder:
        fail(errors, f"non-CRLF line ending: {path.relative_to(ROOT)}")


def check_lisp_balance(path: Path, text: str, errors: list[str]) -> None:
    depth = 0
    in_string = False
    escaped = False
    in_comment = False
    for line_number, line in enumerate(text.splitlines(), start=1):
        in_comment = False
        for char in line:
            if in_comment:
                continue
            if not in_string and char == ";":
                in_comment = True
                continue
            if char == '"' and not escaped:
                in_string = not in_string
            elif not in_string:
                if char == "(":
                    depth += 1
                elif char == ")":
                    depth -= 1
                    if depth < 0:
                        fail(errors, f"extra closing parenthesis: {path.relative_to(ROOT)}:{line_number}")
                        return
            escaped = char == "\\" and not escaped if in_string else False
    if in_string:
        fail(errors, f"unclosed string: {path.relative_to(ROOT)}")
    if depth != 0:
        fail(errors, f"unbalanced parentheses ({depth}): {path.relative_to(ROOT)}")


def main() -> int:
    errors: list[str] = []
    command_locations: dict[str, list[str]] = {}
    absolute_path = re.compile(r"(?i)(?:^|[\"'])\s*[a-z]:[\\/]")

    for path in RUNTIME_FILES:
        data = path.read_bytes()
        check_crlf(path, data, errors)
        try:
            text = data.decode(ENCODING)
        except UnicodeDecodeError as exc:
            fail(errors, f"not GBK-decodable: {path.relative_to(ROOT)} ({exc})")
            continue
        if text.encode(ENCODING) != data:
            fail(errors, f"mixed or non-round-trippable encoding: {path.relative_to(ROOT)}")
        check_lisp_balance(path, text, errors)
        for line_number, line in enumerate(text.splitlines(), start=1):
            if line.endswith((" ", "\t")):
                fail(errors, f"trailing whitespace: {path.relative_to(ROOT)}:{line_number}")
            if absolute_path.search(line):
                fail(errors, f"absolute path: {path.relative_to(ROOT)}:{line_number}")
        for match in re.finditer(r"(?im)^\s*\(defun\s+c:([^\s()]+)", text):
            command = match.group(1).upper()
            line_number = text.count("\n", 0, match.start()) + 1
            command_locations.setdefault(command, []).append(
                f"{path.relative_to(ROOT)}:{line_number}"
            )

    counts = Counter({name: len(locations) for name, locations in command_locations.items()})
    for command, count in sorted(counts.items()):
        if count != 1:
            fail(errors, f"duplicate command {command}: {', '.join(command_locations[command])}")
    actual_commands = set(command_locations)
    for command in sorted(EXPECTED_COMMANDS - actual_commands):
        fail(errors, f"missing command: {command}")
    for command in sorted(actual_commands - EXPECTED_COMMANDS):
        fail(errors, f"unexpected command: {command}")

    toolbar = (ROOT / "YS-Tools" / "dcl" / "toolbar.lsp").read_text(encoding=ENCODING)
    dcl = (ROOT / "YS-Tools" / "dcl" / "toolbar.dcl").read_text(encoding=ENCODING)
    mapped_keys = set(re.findall(r'\(= key "([^"]+)"\)', toolbar))
    mapped_keys.update(re.findall(r'\(action_tile\s+"([^"]+)"', toolbar))
    dialog_keys = {"ys_toolbar", "ys_aa_toolbar"}
    dcl_keys = set(re.findall(r'key\s*=\s*"([^"]+)"', dcl)) - dialog_keys
    if mapped_keys != dcl_keys:
        fail(errors, f"DCL key mismatch: missing={sorted(dcl_keys - mapped_keys)}, extra={sorted(mapped_keys - dcl_keys)}")
    for command in re.findall(r'ys:run-command "([^"]+)"', toolbar, re.I):
        if command.upper() not in EXPECTED_COMMANDS:
            fail(errors, f"toolbar command is not registered: {command}")
    aa_commands = set(re.findall(r'^\s*\("([A-Z0-9]+)"\s+"\[', toolbar, re.M))
    if aa_commands != EXPECTED_AA_COMMANDS:
        fail(errors, f"AA command panel mismatch: missing={sorted(EXPECTED_AA_COMMANDS - aa_commands)}, extra={sorted(aa_commands - EXPECTED_AA_COMMANDS)}")

    version_files = [
        ROOT / "YS-Tools" / "YS-Tools.lsp",
        ROOT / "YS-Tools" / "dcl" / "toolbar.dcl",
        ROOT / "YS-Tools" / "install.ps1",
        ROOT / "AA整合版本.lsp",
    ]
    for path in version_files:
        encoding = "utf-8-sig" if path.suffix == ".ps1" else ENCODING
        if VERSION not in path.read_text(encoding=encoding):
            fail(errors, f"version {VERSION} missing: {path.relative_to(ROOT)}")

    for path in (
        ROOT / "YS-Tools" / "install.ps1",
        ROOT / "YS-Tools" / "uninstall.ps1",
        ROOT / "tests" / "test_installer.ps1",
    ):
        if not path.read_bytes().startswith(b"\xef\xbb\xbf"):
            fail(errors, f"PowerShell script must use UTF-8 BOM: {path.relative_to(ROOT)}")

    result = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "build_bundle.py"), "--check"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        fail(errors, result.stderr.strip() or result.stdout.strip())

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"validated {len(RUNTIME_FILES)} runtime files and {len(actual_commands)} commands")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
