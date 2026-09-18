#!/bin/bash
set -euo pipefail
sudo rm -f /bin/burpsuitepro /usr/bin/burpsuitepro /usr/local/bin/burpsuitepro
if command -v pacman >/dev/null 2>&1; then
  sudo pacman -Sy --needed --noconfirm git wget jre17-openjdk
elif command -v apt >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y git wget openjdk-17-jre
else
  echo "error: unsupported package manager (need pacman or apt)" >&2
  exit 1
fi
if [ ! -d Burpsuite-Professional ]; then
  git clone https://github.com/xiv3r/Burpsuite-Professional.git
fi
cd Burpsuite-Professional
version=2023.6.1
wget -O burpsuite_pro_v$version.jar "https://portswigger.net/burp/releases/download?product=pro&version=$version&type=Jar"
cat > burpsuitepro <<'LAUNCHER_EOF'
#!/bin/bash
set -euo pipefail
SRC="${BASH_SOURCE[0]}"
while [ -L "$SRC" ]; do SRC="$(readlink "$SRC")"; done
SCRIPT_DIR="$(cd "$(dirname "$SRC")" >/dev/null 2>&1 && pwd)"
BURP_DIR="${BURP_DIR:-$SCRIPT_DIR}"
if [ -n "${BURP_JAR:-}" ]; then
  JAR="$BURP_JAR"
else
  JAR="$(ls -t "$BURP_DIR"/burpsuite_pro_v*.jar 2>/dev/null | head -n 1)"
fi
if [ -z "${JAR:-}" ]; then
  echo "error: no burpsuite_pro_v*.jar found in $BURP_DIR" >&2
  exit 1
fi
LOADER="$BURP_DIR/loader.jar"
if [ ! -f "$LOADER" ]; then
  echo "error: loader.jar not found in $BURP_DIR" >&2
  exit 1
fi
START_KEYGEN=1
ARGS=()
for a in "$@"; do
  if [ "$a" = "--no-keygen" ]; then START_KEYGEN=0; else ARGS+=("$a"); fi
done
if [ "${BURP_NO_KEYGEN:-0}" = "1" ]; then START_KEYGEN=0; fi
if [ "$START_KEYGEN" = "1" ]; then
  (java -jar "$LOADER" -a 0 >/dev/null 2>&1 &) &
fi
exec java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:"$LOADER" -noverify -jar "$JAR" "${ARGS[@]:-}"
LAUNCHER_EOF
chmod +x burpsuitepro
sudo install -m 0755 burpsuitepro /usr/local/bin/burpsuitepro
(./burpsuitepro >/dev/null 2>&1 &)
