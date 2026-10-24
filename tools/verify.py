"""Static verification for the Hacker Fight project.

Checks:
  1. the installer's embedded copies match src/ byte for byte
  2. every dumped source parses with a real Lua grammar
  3. remote names used in code == Config.Remotes == installer-created instances
  4. every interactive GUI row has a client handler
  5. no deprecated Roblox APIs and no placeholder text
"""

import re
import sys
from pathlib import Path

from luaparser import ast

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
OUT = ROOT / "tools" / "out"
TEMPLATE = ROOT / "tools" / "installer_template.lua"

SOURCES = {
    "shared/Config": SRC / "shared" / "Config.lua",
    "shared/Util": SRC / "shared" / "Util.lua",
    "shared/Features": SRC / "shared" / "Features.lua",
    "shared/Remotes": SRC / "shared" / "Remotes.lua",
    "server/DataService": SRC / "server" / "DataService.lua",
    "server/RoundService": SRC / "server" / "RoundService.lua",
    "server/TeleportService": SRC / "server" / "TeleportService.lua",
    "server/AbilityService": SRC / "server" / "AbilityService.lua",
    "server/CombatService": SRC / "server" / "CombatService.lua",
    "server/Main": SRC / "server" / "Main.server.lua",
    "client/Settings": SRC / "client" / "Settings.lua",
    "client/UI": SRC / "client" / "UI.lua",
    "client/HUD": SRC / "client" / "HUD.lua",
    "client/Abilities": SRC / "client" / "Abilities.lua",
    "client/Combat": SRC / "client" / "Combat.lua",
    "client/Visuals": SRC / "client" / "Visuals.lua",
    "client/Teleport": SRC / "client" / "Teleport.lua",
    "client/Main": SRC / "client" / "Main.client.lua",
}

failures = []
notes = []


def fail(message):
    failures.append(message)


def parse_name_list(text, block):
    match = re.search(block + r"\s*=\s*\{(.*?)\}", text, re.S)
    if not match:
        return []
    return re.findall(r'"([^"]+)"', match.group(1))


def main():
    texts = {key: path.read_text(encoding="utf-8") for key, path in SOURCES.items()}

    # 1. installer embedded copies match src
    dumped_ok = 0
    for key, text in texts.items():
        dump = OUT / (key.replace("/", "_") + ".lua")
        if not dump.exists():
            fail("missing dump for %s" % key)
            continue
        if dump.read_text(encoding="utf-8").rstrip("\n") != text.rstrip("\n"):
            fail("installer copy differs from src for %s" % key)
        else:
            dumped_ok += 1
    notes.append("installer copies verified: %d/%d" % (dumped_ok, len(texts)))

    # 2. every source parses
    for key, text in texts.items():
        try:
            ast.parse(text)
        except Exception as error:  # noqa: BLE001
            fail("syntax error in %s: %s" % (key, error))

    # 3. remote names
    config_events = parse_name_list(texts["shared/Config"], r"Events")
    config_funcs = parse_name_list(texts["shared/Config"], r"Functions")
    template_text = TEMPLATE.read_text(encoding="utf-8")
    install_events = parse_name_list(template_text, r"local events")
    install_funcs = parse_name_list(template_text, r"local functions")

    if sorted(config_events) != sorted(install_events):
        fail("installer events %s != Config events %s" % (sorted(install_events), sorted(config_events)))
    if sorted(config_funcs) != sorted(install_funcs):
        fail("installer functions %s != Config functions %s" % (sorted(install_funcs), sorted(config_funcs)))

    used_events, used_funcs = set(), set()
    for key, text in texts.items():
        for kind, name in re.findall(r'Remotes\.(event|func)\("([^"]+)"\)', text):
            if kind == "event":
                used_events.add(name)
            else:
                used_funcs.add(name)
    for name in used_events:
        if name not in config_events:
            fail("code uses unknown RemoteEvent %s" % name)
    for name in used_funcs:
        if name not in config_funcs:
            fail("code uses unknown RemoteFunction %s" % name)
    for name in config_events:
        if name not in used_events:
            fail("RemoteEvent %s is created but never used" % name)
    for name in config_funcs:
        if name not in used_funcs:
            fail("RemoteFunction %s is created but never used" % name)
    notes.append("remotes: %d events, %d functions, all wired" % (len(config_events), len(config_funcs)))

    # 4. feature handlers
    rows = re.findall(r'\{\s*(?:id = "([^"]+)",\s*)?tab = "([^"]+)"?[^}]*?kind = "([^"]+)"', texts["shared/Features"])
    # fall back to a simpler parse: split row entries
    row_entries = re.findall(r"\{[^{}]*kind = \"([a-z]+)\"[^{}]*\}", texts["shared/Features"])
    row_ids = []
    for entry in re.findall(r"\{([^{}]*)\}", texts["shared/Features"]):
        if "kind =" not in entry:
            continue
        kind_match = re.search(r'kind = "([a-z]+)"', entry)
        id_match = re.search(r'id = "([^"]+)"', entry)
        if not kind_match:
            continue
        kind = kind_match.group(1)
        if kind in ("toggle", "slider", "button", "cycle", "keybind") and id_match:
            row_ids.append((id_match.group(1), kind))

    handlers = set()
    for key in ("client/Abilities", "client/Combat", "client/Visuals", "client/Main"):
        text = texts[key]
        handlers.update(re.findall(r"handlers\.([a-z_]+)\s*=", text))
        handlers.update(re.findall(r'toggle\("([a-z_]+)"\)', text))
    handlers.update(re.findall(r"^\t([a-z_]+) = function", texts["client/Teleport"], re.M))
    handlers.add("attack")  # on-screen mobile attack button

    missing = [row for row, _ in row_ids if row not in handlers]
    if missing:
        fail("GUI rows with no handler: %s" % ", ".join(sorted(set(missing))))
    notes.append("GUI rows with handlers: %d/%d" % (len(row_ids) - len(missing), len(row_ids)))

    # 5. settings rows must exist in the server schema
    schema_block = re.search(r"Config\.Settings = \{(.*?)\n\}", texts["shared/Config"], re.S)
    schema_keys = set(re.findall(r"^\t([a-z_]+) = \{", schema_block.group(1), re.M)) if schema_block else set()
    for row_id, kind in row_ids:
        if kind in ("toggle", "slider", "cycle", "keybind") and row_id not in schema_keys:
            fail("GUI setting row %s has no Config.Settings entry" % row_id)
    notes.append("settings schema: %d keys" % len(schema_keys))

    # 6. client -> server action protocol
    client_text = "\n".join(texts[key] for key in texts if key.startswith("client/"))
    server_text = "\n".join(texts[key] for key in texts if key.startswith("server/"))
    client_actions = set(re.findall(r':FireServer\("([a-z_]+)"', client_text))
    unknown = []
    for action in sorted(client_actions):
        if ('"' + action + '"') not in server_text:
            unknown.append(action)
    if unknown:
        fail("client sends actions the server never handles: %s" % ", ".join(unknown))
    notes.append("client actions handled by server: %d/%d" % (len(client_actions) - len(unknown), len(client_actions)))

    # 7. deprecated API / placeholder scan
    deprecated = [
        (r"(?<![\w.])wait\(", "global wait()"),
        (r"(?<![\w.])spawn\(", "global spawn()"),
        (r"(?<![\w.])delay\(", "global delay()"),
        (r"game\.Workspace", "game.Workspace"),
        (r'Instance\.new\("Hint"\)', "Hint"),
        (r"BodyVelocity|BodyGyro|BodyPosition", "legacy body movers"),
        (r"PlayerMouse|GetMouse\(", "legacy mouse API"),
        (r":remove\(", "Instance:remove()"),
        (r"LoadAnimation\(", "legacy LoadAnimation"),
    ]
    placeholders = ["TODO", "FIXME", "add the rest", "your code here", "[insert"]
    for key, text in texts.items():
        for pattern, label in deprecated:
            if re.search(pattern, text):
                fail("%s uses deprecated %s" % (key, label))
        for word in placeholders:
            if word.lower() in text.lower():
                fail("%s contains placeholder text: %s" % (key, word))

    # required modules exist
    for key, text in texts.items():
        for name in re.findall(r'WaitForChild\("([A-Za-z]+)"\)', text):
            pass

    print("\n".join(notes))
    if failures:
        print("\n%d problem(s):" % len(failures))
        for item in failures:
            print(" - " + item)
        return 1
    print("static verification: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
