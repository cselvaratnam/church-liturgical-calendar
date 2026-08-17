#!/usr/bin/env bash

# <xbar.title>Church of England Liturgical Calendar</xbar.title>
# <xbar.version>v1.2</xbar.version>
# <xbar.author>Christian Selvaratnam</xbar.author>
# <xbar.author.github>cselvaratnam</xbar.author.github>
# <xbar.desc>Displays the title of the church season or festival of the day and the Collect of the Day from the Church of England website.</xbar.desc>
# <xbar.image>https://raw.githubusercontent.com/cselvaratnam/images/6c68f941510460f27aca9677389f155f3abe6891/church-liturgical-calendar.png</xbar.image>
# <xbar.dependencies>bash,curl,sed</xbar.dependencies>
# <xbar.abouturl>https://bio.site/selvaratnam</xbar.abouturl>

# xbar sets $BitBar (legacy) and $XBAR_VERSION when it runs a plugin; both
# are unset when the script is run directly, e.g. from a terminal while
# debugging. See https://xbarapp.com/docs/plugins/Dev/Tutorial/is_bitbar.sh.html
if [ -n "$BitBar" ] || [ -n "$XBAR_VERSION" ]; then
  running_in_xbar=1
else
  running_in_xbar=0
fi

# Collect the front page of the Church of England website
if ! web=$(curl -f -s -S https://www.churchofengland.org/); then
  echo "⚠️ CofE calendar"
  echo "---"
  echo "Could not fetch churchofengland.org"
  echo "Refresh | refresh=true"
  exit 0
fi

# The markup we need spans several lines of the page, so flatten it to a
# single line first (this is what the sed patterns below expect).
web_flat=$(printf "%s" "$web" | tr '\n' ' ')

# Extract the season/festival title from the Prayer for the Day
full_title=$(echo "$web_flat" | sed 's/.*<div class="textfill-footer">.*<small>\(.*\)<\/small>.*/\1/')

# Make short version of the title
short_title=$(echo "$full_title" | sed -e 's/^The //' -e 's/Blessed Virgin Mary/BVM/' -e 's/ (.*$//' -e 's/,.*//')

# Override short_title if it contains the phrase
if [[ "$full_title" == *"Day of Thanksgiving for the Instituion of Holy Communion"* ]]; then
  short_title="Corpus Christi"
fi

# Extract the Collect of the Day and reformat. xbar renders a literal \r
# inside a menu item as a soft line-break within that single item, so we
# keep \r for xbar but swap it for a real newline when run in a terminal,
# so the Collect reads as separate lines there too instead of literal "\r".
collect=$(echo "$web_flat" | sed -e 's/.*<div class="textfill-footer">.*<p>\(.*\)<\/p>.*/\1/' -e 's/<br \/>/\\r/g' -e 's/\\r /\\r/g')

printf "%s\n" "$short_title"
echo "---"
printf "%s\n" "$full_title"
if [ "$running_in_xbar" -eq 1 ]; then
  printf "%s\n" "$collect"
else
  printf "%s\n" "$collect" | sed 's/\\r/\n/g'
fi
echo "Refresh | refresh=true"