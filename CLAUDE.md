# church-liturgical-calendar

An [xbar](https://xbarapp.com/) plugin for macOS. It scrapes the front page of
churchofengland.org and shows today's liturgical season/festival and the
Collect of the Day in the menu bar.

## Files

- `church-liturgical-calendar.1h.sh` — the plugin itself. The `.1h.` in the
  filename is xbar's refresh-interval convention (runs hourly); it must stay
  in the filename for xbar to schedule it.
- `church-liturgical-calendar.png`, `xbar.png` — reference screenshots, not
  used by the script at runtime (the `xbar.image` metadata tag in the script
  points to a hosted copy in the `cselvaratnam/images` repo instead).

## How the script works

1. `curl`s `https://www.churchofengland.org/` and captures the HTML in `$web`.
2. Flattens `$web` to a single line (`web_flat`) with `tr '\n' ' '` — the
   markup we need (`<div class="textfill-footer">…<small>…</small>` and
   `…<p>…</p>`) spans multiple source lines, and the `sed` patterns that pull
   the title and Collect out only work against one line.
3. `sed` extracts the season/festival title (`full_title`) and a short form
   for the menu bar (`short_title`), plus the Collect text (`collect`), with
   `<br />` converted to a literal two-character `\r`.
4. Prints xbar's plugin format: menu-bar line, `---`, then the dropdown lines.

**This is HTML-scraping, not an API** — if churchofengland.org changes its
markup (class names, tag nesting), the `sed` patterns will silently stop
matching and the script will print the raw page HTML instead of the intended
text. If that happens, re-derive the `sed` patterns from a fresh `curl` of
the page rather than patching blindly.

### The `\r` in the Collect text — don't quote-fix this

xbar renders a literal `\r` (backslash + r, not an actual carriage-return
byte) inside one menu item's text as a soft line-break *within that single
item*. That's why `collect` is built with literal `\r` rather than real
newlines — a real newline would start a *new* xbar menu item instead of
wrapping the same one.

Running the script directly in a terminal doesn't get this special
treatment, so the same literal `\r` used to just print as visible backslash-r
text. The script now detects that case (`$BitBar` / `$XBAR_VERSION` are only
set when xbar itself runs the plugin — see [xbar's own tutorial on
this](https://xbarapp.com/docs/plugins/Dev/Tutorial/is_bitbar.sh.html)) and
swaps `\r` for a real newline only when *not* running inside xbar, so
terminal debugging output reads naturally too. When editing this script,
preserve that branch — don't "simplify" it back to a single unconditional
`printf`, and don't quote-wrap `$web`/`$web_flat` back to real newlines
before the `sed` extraction (see point 2 above) or the multi-line matches
will stop working.

### The trailing "Refresh" line — xbar-only

The last line of xbar output, `Refresh | refresh=true`, defines a clickable
menu item (the `| refresh=true` param makes clicking it re-run the plugin).
It isn't part of the Collect content. A terminal has nothing to click, so
printing it there just adds a stray trailing "Refresh" line after "Amen." —
the `refresh_line()` helper omits it entirely when `$running_in_xbar` is 0,
rather than printing a plain "Refresh" with no `| refresh=true`. Keep using
`refresh_line()` for this rather than a bare `echo`.

## Permissions

xbar requires the plugin script to be executable, and won't run it otherwise
(this has bitten us before after a fresh clone). The executable bit is
tracked by git as part of the commit, so a clone of this repo should already
be executable — but if xbar reports the plugin isn't running, check first:

```sh
chmod 700 church-liturgical-calendar.1h.sh
```

## Testing changes

Run the script directly — it produces the same text either way, formatted
for the current context (see the `\r`/newline note above):

```sh
./church-liturgical-calendar.1h.sh
```

To sanity-check the xbar-mode branch specifically (real xbar not required):

```sh
BitBar=1 ./church-liturgical-calendar.1h.sh
```

For UI-visible changes, symlink into xbar's plugin folder and use xbar's
"Refresh all" (or wait for the `.1h.` interval) to confirm it renders
correctly in the actual menu bar dropdown, not just in terminal output —
terminal output can look fine while the xbar rendering differs (this is what
prompted writing this file in the first place).
