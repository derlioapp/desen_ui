#!/usr/bin/env python3
"""Watches the Flutter semantics API that Desen works around.

Some screen reader behavior waits on Flutter: no toolbar role, no way to
say that an item opens a submenu or to link a description to a control,
and combobox and spin button roles that the framework does not support
yet. Component docs say what each one means for users ("Flutter 3.47 has
no ...").

This tool records, in tool/flutter_gaps.json, the semantics roles, the
roles the framework does not support yet, and the fields of
SemanticsProperties. After a Flutter upgrade, `--check` fails when any of
them changed: look at what is new, use it where it closes a gap (and
update the docs that name the Flutter version), then run without
`--check` to record the new state.

    python3 tool/flutter_gaps.py [--check]
"""

import json
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SNAPSHOT = os.path.join(ROOT, "tool", "flutter_gaps.json")


def sdk():
    flutter = shutil.which("flutter")
    if flutter is None:
        sys.exit("flutter is not on PATH")
    return os.path.dirname(os.path.dirname(os.path.realpath(flutter)))


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def block(source, start):
    """The text from the line matching [start] to the next line "}"."""
    m = re.search(start, source, re.M)
    if m is None:
        sys.exit(f"not found in the Flutter SDK: {start}")
    end = source.index("\n}", m.end())
    return source[m.end() : end]


def current():
    root = sdk()
    version = json.loads(read(os.path.join(root, "bin", "cache", "flutter.version.json")))
    ui = read(os.path.join(root, "bin", "cache", "pkg", "sky_engine", "lib", "ui", "semantics.dart"))
    framework = read(
        os.path.join(root, "packages", "flutter", "lib", "src", "semantics", "semantics.dart")
    )
    roles = re.findall(r"^  (\w+),", block(ui, r"^enum SemanticsRole \{"), re.M)
    unsupported = sorted(set(re.findall(r"SemanticsRole\.(\w+) => _unimplemented", framework)))
    properties = sorted(
        set(
            re.findall(
                r"^  final [^;=]+?\b(\w+);",
                block(framework, r"^class SemanticsProperties\b.*\{"),
                re.M,
            )
        )
    )
    return {
        "flutter": version["frameworkVersion"],
        "roles": roles,
        "unsupported_roles": unsupported,
        "semantics_properties": properties,
    }


def main():
    now = current()
    if "--check" not in sys.argv:
        with open(SNAPSHOT, "w", encoding="utf-8") as f:
            json.dump(now, f, indent=2)
            f.write("\n")
        print(f"recorded Flutter {now['flutter']}")
        return
    then = json.loads(read(SNAPSHOT))
    changes = []
    for key in ("roles", "unsupported_roles", "semantics_properties"):
        added = sorted(set(now[key]) - set(then[key]))
        removed = sorted(set(then[key]) - set(now[key]))
        if added:
            changes.append(f"{key} added: {', '.join(added)}")
        if removed:
            changes.append(f"{key} removed: {', '.join(removed)}")
    if changes:
        print(f"Flutter's semantics API changed since {then['flutter']} (now {now['flutter']}):")
        print("\n".join(f"  {c}" for c in changes))
        print("See whether this closes a gap, then run tool/flutter_gaps.py to record it.")
        sys.exit(1)
    print(f"semantics API as recorded (Flutter {then['flutter']}, now {now['flutter']})")


if __name__ == "__main__":
    main()
