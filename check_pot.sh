#!/bin/bash

current="$(mktemp)"
updated="$(mktemp)"

cat po/adduser.pot | perl -0777 -pe "s/(.*?)\n\n//s" >"$current"

GENERATE_PO="0" POT_FILE="$updated" ./generate_pot.sh >/dev/null 2>&1
cat "$updated" | perl -0777 -pe "s/(.*?)\n\n//s" | tee "$updated" >/dev/null

diff -q "$current" "$updated"
