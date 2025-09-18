#!/bin/bash

#
# Copyright (c) 2021 Matthew Penner
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# --- CUSTOM HOOK: seed booty.sh if missing ---
BOOTY_FILE="/home/container/booty.sh"

if [ ! -f "$BOOTY_FILE" ]; then
  echo "[prestart] booty.sh not found, creating default..."
  cat <<'EOF' > "$BOOTY_FILE"
#!/usr/bin/env bash
# This file was automatically created by the container entrypoint.
# It runs before the Minecraft server starts. Edit as needed.

set -euo pipefail

echo "[bootstrap] starting pretend sync…"
echo "[mods] would delete managed IDs only"
echo "[mods] would copy jars into /home/container/mods"
echo "[datapacks] would replace managed pack folders only"
echo "[datapacks] would copy into /home/container/world/datapacks"
echo "[configs] would layer common→role→server and render *.tmpl"
echo "[bootstrap] done"
EOF
  chmod +x "$BOOTY_FILE"
fi

echo -e "\033[1m\033[33mcontainer@pterodactyl~ \033[0mRunning pre-start script $BOOTY_FILE"
/bin/bash "$BOOTY_FILE" || echo "[booty.sh] failed but continuing…"
# --- END CUSTOM HOOK ---

# Print Java version
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0mjava -version\n"
java -version

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Display the command we're running in the output, and then execute it with the env
# from the container itself.
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n" "$PARSED"
# shellcheck disable=SC2086
eval ${PARSED}
