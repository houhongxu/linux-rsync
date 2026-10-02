#!/usr/bin/env python3
"""Render a local HelmChartConfig without storing contact details in Git."""
import json
import os
from pathlib import Path
import re
import sys
import tempfile

PLACEHOLDER = "REPLACE_WITH_CONTACT_EMAIL"


def main():
    if len(sys.argv) != 3:
        raise SystemExit("Usage: render_traefik_config.py TEMPLATE OUTPUT")
    email = os.environ.get("ACME_EMAIL", "")
    if not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
        raise SystemExit("Set ACME_EMAIL to the confirmed contact email; do not store it in Git.")
    template = Path(sys.argv[1]).read_text()
    if template.count(PLACEHOLDER) != 1:
        raise SystemExit("Expected exactly one contact-email placeholder.")
    output = Path(sys.argv[2])
    output.parent.mkdir(parents=True, exist_ok=True)
    rendered = template.replace(PLACEHOLDER, json.dumps(email))
    fd, temporary = tempfile.mkstemp(prefix=".traefik-", dir=output.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(rendered)
        os.replace(temporary, output)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == "__main__":
    main()
