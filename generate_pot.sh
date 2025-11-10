#!/bin/bash
# This file is distributed under the same license as the adduser package.
# This process is currently being tested. It is possible that it might go again
#
# The program here is being used to regenerated POT and PO files for 
# the program translations of adduser.
#
# After Generation:
# Create e-mail messages with
# podebconf-report-po --verbose --call --deadline=2025-03-31 --notdebconf --package=adduser --postpone=/tmp/acall --utf8 --withtranslators --gzip
# call mutt, type :set postponed=/tmp/acall
# Call up postpones messages (R) and  send one by one.
#
# It is suggested to commit the POT file immediately and the PO files only
# when they have been touched by a translator.

# Define file names
POT_FILE="${POT_FILE:-po/adduser.pot}"
COPYRIGHT_FILE="tmp.copyright"
SOURCE_FILES="adduser deluser *.pm"
PLANG="perl"

sed -n '/Files: po\/adduser.pot doc\/po4a\/po\/adduser.pot/,/^$/ {s/^/# /; p;}' debian/copyright > "${COPYRIGHT_FILE}"

# Extract strings and generate POT file
xgettext \
    --keyword=mtx --keyword=gtx --from-code=UTF-8 -L "${PLANG}" \
    --package-name=adduser \
    --package-version="$(dpkg-parsechangelog --show-field Version)" \
    --copyright-holder="===MATCH COPYRIGHT===" \
    --msgid-bugs-address=adduser@packages.debian.org \
    -o "${POT_FILE}" ${SOURCE_FILES}
# sed in things that cannot be changed in gettext
# see https://savannah.gnu.org/bugs/index.php?66933 (quickly rejected)
sed -i "1s/.*/# Translation of adduser program into LANGUAGE/" "${POT_FILE}"
sed -i "0,/^Content-Type: text\/plain; charset=CHARSET/s/CHARSET/UTF-8/" "${POT_FILE}"
sed -i -e "/===MATCH COPYRIGHT===/{r ${COPYRIGHT_FILE}" -e "; d}" "${POT_FILE}"
rm -f "${COPYRIGHT_FILE}"

echo "POT file generated: ${POT_FILE}"

[ "$GENERATE_PO" == 0 ] && exit;

# Loop through all .po files in the locale directory
for PO_FILE in po/*.po; do
    if [ -f "${PO_FILE}" ]; then
        echo "Updating ${PO_FILE}..."
        msgmerge --update --backup=none --no-fuzzy-matching "${PO_FILE}" "${POT_FILE}"
    fi
done

echo "PO files generation finished"

