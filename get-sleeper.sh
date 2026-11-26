#!/usr/bin/env bash
# Installeert Sleeper rechtstreeks vanuit je GitHub-repo (nieuwste release), zonder eerst bestanden op de server te zetten.
#
#   curl -fsSL https://raw.githubusercontent.com/EIGENAAR/REPO/main/get-sleeper.sh | sudo bash -s -- EIGENAAR/REPO
#
# Privé-repo? Zet eerst een alleen-lezen token:  export GITHUB_TOKEN=...   en gebruik  sudo -E bash -s -- EIGENAAR/REPO
# Je repo moet een release hebben met het bestand  sleeper-launcher-v<versie>.zip  (zie UITLEG.md).
set -euo pipefail
REPO="${1:-}"
if ! [[ "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "Gebruik: sudo bash get-sleeper.sh EIGENAAR/REPO"; exit 1
fi
ROOT="${SLEEPER_ROOT:-/opt/sleeper}"
if [ "$(id -u)" -ne 0 ] && [ -z "${SLEEPER_ROOT:-}" ]; then echo "Start dit met sudo."; exit 1; fi
command -v python3 >/dev/null 2>&1 || { echo "python3 is nodig: sudo apt install python3"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is nodig: sudo apt install curl"; exit 1; }
API="${SLEEPER_GH_API:-https://api.github.com}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
AUTH=(); [ -n "${GITHUB_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")

echo "==> Nieuwste release van $REPO ophalen"
curl -fsSL "${AUTH[@]}" -H "Accept: application/vnd.github+json" "$API/repos/$REPO/releases/latest" -o "$TMP/rel.json" \
  || { echo "Kon de release niet ophalen. Bestaat de repo, is er een release gemaakt, en is een privé-repo voorzien van GITHUB_TOKEN?"; exit 1; }
URL="$(python3 - "$TMP/rel.json" "${GITHUB_TOKEN:-}" <<'PY'
import json, re, sys
rel = json.load(open(sys.argv[1]))
for a in rel.get("assets", []):
    if re.match(r"^sleeper-launcher-v?\d+(\.\d+)*\.zip$", a.get("name", "")):
        print(a["url"] if sys.argv[2] else (a.get("browser_download_url") or a["url"]))
        break
PY
)"
[ -n "$URL" ] || { echo "In de release zit geen bestand sleeper-launcher-v<versie>.zip."; exit 1; }
echo "==> Downloaden"
curl -fsSL "${AUTH[@]}" -H "Accept: application/octet-stream" "$URL" -o "$TMP/sleeper.zip"
python3 - "$TMP/sleeper.zip" "$TMP/src" <<'PY'
import os, sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
for n in z.namelist():
    if os.path.isabs(n) or ".." in n.split("/"):
        sys.exit("Onveilige zip.")
z.extractall(sys.argv[2])
PY
INSTALLER="$(find "$TMP/src" -maxdepth 2 -name install.sh | head -1)"
[ -n "$INSTALLER" ] || { echo "install.sh ontbreekt in de zip."; exit 1; }
bash "$INSTALLER"
python3 - "$ROOT/launcher.json" "$REPO" "$TMP" <<'PY'
import json, os, sys
p, repo, tmp = sys.argv[1:4]
try:
    c = json.load(open(p))
except Exception:
    c = {}
c["local_dirs"] = [d for d in c.get("local_dirs", []) if not d.startswith(tmp)]
c.setdefault("server_name", ""); c.setdefault("setup_done", False)
c["github"] = {"repo": repo, "branch": (c.get("github") or {}).get("branch", "main") or "main"}
json.dump(c, open(p, "w"), indent=2)
print("==> GitHub-repo %s ingesteld als store" % repo)
PY
echo
echo "Klaar. Start de launcher met:  sudo sleeper   (daar typ je beheerder, wachtwoord en je launcher-code)"
echo "Apps installeer je met:  sudo sleeper install eco   (of via de Store)"
