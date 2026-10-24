"""Builds HackerFightInstaller.lua from src/ + tools/installer_template.lua,
then syntax-checks every file with a real Lua grammar (luaparser) and verifies
the embedded sources round-trip byte for byte."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
TEMPLATE = ROOT / "tools" / "installer_template.lua"
OUT = ROOT / "HackerFightInstaller.lua"

# key -> source path (order matters only for readability)
SOURCES = [
    ("shared/Config", SRC / "shared" / "Config.lua"),
    ("shared/Util", SRC / "shared" / "Util.lua"),
    ("shared/Features", SRC / "shared" / "Features.lua"),
    ("shared/Remotes", SRC / "shared" / "Remotes.lua"),
    ("server/DataService", SRC / "server" / "DataService.lua"),
    ("server/RoundService", SRC / "server" / "RoundService.lua"),
    ("server/TeleportService", SRC / "server" / "TeleportService.lua"),
    ("server/AbilityService", SRC / "server" / "AbilityService.lua"),
    ("server/CombatService", SRC / "server" / "CombatService.lua"),
    ("server/Main", SRC / "server" / "Main.server.lua"),
    ("client/Settings", SRC / "client" / "Settings.lua"),
    ("client/UI", SRC / "client" / "UI.lua"),
    ("client/HUD", SRC / "client" / "HUD.lua"),
    ("client/Abilities", SRC / "client" / "Abilities.lua"),
    ("client/Combat", SRC / "client" / "Combat.lua"),
    ("client/Visuals", SRC / "client" / "Visuals.lua"),
    ("client/Teleport", SRC / "client" / "Teleport.lua"),
    ("client/Main", SRC / "client" / "Main.client.lua"),
]


def choose_bracket_level(texts):
    level = 3
    while True:
        marker = "]" + "=" * level + "]"
        if not any(marker in text for text in texts):
            return level
        level += 1


def long_string(text, level):
    eq = "=" * level
    body = text.rstrip("\n")
    return "[%s[\n%s\n]%s]" % (eq, body, eq)


def build():
    entries = []
    for key, path in SOURCES:
        if not path.exists():
            raise SystemExit("missing source: %s" % path)
        entries.append((key, path.read_text(encoding="utf-8")))

    level = choose_bracket_level([text for _, text in entries])
    table_lines = ["local SOURCES = {"]
    for key, text in entries:
        table_lines.append('\t["%s"] = %s,' % (key, long_string(text, level)))
    table_lines.append("}")
    sources_block = "\n".join(table_lines)

    template = TEMPLATE.read_text(encoding="utf-8")
    if "--@SOURCES@" not in template:
        raise SystemExit("template marker --@SOURCES@ not found")
    installer = template.replace("--@SOURCES@", sources_block)
    OUT.write_text(installer, encoding="utf-8")

    # ---- round-trip check: extract the table back out ----
    pattern = re.compile(r'\["([^"]+)"\] = \[(=*)\[\n(.*?)\n\]\2\]', re.S)
    found = {key: body for key, _, body in pattern.findall(installer)}
    problems = []
    for key, text in entries:
        if key not in found:
            problems.append("%s missing from generated installer" % key)
        elif found[key].rstrip("\n") != text.rstrip("\n"):
            problems.append("%s does not round-trip" % key)
    print("installer bytes: %d" % len(installer.encode("utf-8")))
    print("embedded scripts: %d" % len(entries))
    if problems:
        for problem in problems:
            print("ROUND-TRIP FAIL: %s" % problem)
        return 1
    print("round-trip: OK")
    return 0


def syntax_check():
    from luaparser import ast  # noqa: WPS433

    targets = [path for _, path in SOURCES] + [TEMPLATE, OUT]
    failures = 0
    for path in targets:
        text = path.read_text(encoding="utf-8")
        try:
            ast.parse(text)
        except Exception as error:  # noqa: BLE001
            failures += 1
            print("SYNTAX FAIL %s: %s" % (path.relative_to(ROOT), error))
    if failures:
        print("%d file(s) failed to parse" % failures)
        return 1
    print("syntax: OK (%d files)" % len(targets))
    return 0


if __name__ == "__main__":
    code = build()
    if code == 0:
        code = syntax_check()
    sys.exit(code)
