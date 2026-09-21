# fixpaste

Fixes clipboard text so it pastes into Apple Notes the way you meant it.

```sh
fixpaste          # copy something, run this, then paste
```

## The problem

Copy a few paragraphs out of a chat window or a web page, paste into Notes, and
the paragraphs come out jammed together with no spacing. Markdown emphasis like
`*italic*` shows up as literal asterisks.

The cause is not the plain text. Copying from a browser puts **several flavors**
on the clipboard at once, and Notes prefers the HTML one:

```
$ osascript -e 'clipboard info'
«class HTML», 13163, «class utf8», 12900, «class ut16», 25668, string, 3, ...
```

That HTML is bare `<p>` tags with no margin CSS. Notes renders them flush
against each other, and the plain-text flavor — which had correct blank lines
all along — is ignored.

## What it does

Replaces the clipboard with two flavors of its own: styled **RTF** and clean
**plain text**. The HTML flavor is gone, so Notes has to use the RTF.

**Spacing.** Paragraphs are separated by real empty paragraphs, which is what
Notes actually honors. Margins are zeroed so the gaps do not double up. Four
broken input shapes all normalize to the same result:

| Input | Result |
|---|---|
| Single newline between paragraphs | blank line inserted |
| Blank line already | left alone |
| Runs of 2+ blank lines | collapsed to one |
| Hard-wrapped at ~72 columns (PDFs) | lines rejoined into paragraphs |

Unwrapping only fires when the text is genuinely machine-wrapped, measured by
whether continuation lines all run to roughly the same width. Uneven prose lines
are never joined — otherwise an essay whose paragraphs merely sit on their own
lines gets welded into one giant paragraph.

**Markdown.** Rendered as real styling rather than left as literal markers:
`*italic*`, `**bold**`, `~~strikethrough~~`, `` `code` ``, `# headings`,
bulleted and numbered lists, blockquotes, `[links](url)`, and fenced code blocks
with indentation preserved.

Text containing no markdown stays plain text, so ordinary prose picks up Notes'
own font instead of a pasted one.

## Usage

```sh
fixpaste              # rich text: markdown rendered, gaps between paragraphs
fixpaste -t           # plain text only; strip markdown markers instead
fixpaste -s           # single newline between paragraphs (tight, for Slack)
fixpaste -p           # print what would be copied, change nothing
fixpaste -c           # always read the clipboard, ignore stdin (for hotkeys)
fixpaste --font -apple-system --size 16
cat notes.txt | fixpaste
```

`fixpaste-test a|b|c|d` copies a labelled sample using a different spacing
strategy each time. Useful if some other app turns out to honor spacing
differently than Notes does.

## Install

```sh
ln -s "$PWD/fixpaste" /opt/homebrew/bin/fixpaste
ln -s "$PWD/fixpaste-test" /opt/homebrew/bin/fixpaste-test
```

No dependencies beyond macOS itself: `pbpaste`, `pbcopy`, `textutil` and
`osascript`. Runs on system Python 3.9, so annotations stay lazy via
`from __future__ import annotations` — launchers such as Shortcuts invoke
`/usr/bin/python3`, not Homebrew's.

## Hotkey

`Fix Paste.shortcut` is a signed Shortcuts file. Open it to import, then in the
Shortcuts editor open **Shortcut Details** (the ⓘ in the top-right) and click
**Add Keyboard Shortcut**.

It runs `fixpaste --clipboard`. The flag matters: Shortcuts hands the script an
empty pipe on stdin, and without it the script could sit waiting for input that
never arrives.

Note that the hotkey fixes the clipboard, it does not paste — so it is the
hotkey followed by ⌘V. Also beware that a global ⌘⇧V shadows paste-and-match-
style in Chrome, Slack and VS Code. Notes itself is clear: its match-style is
⌘⌥⇧V.

## Why RTF and not HTML

`pbcopy` can only carry one flavor, and an RTF-only clipboard pastes as nothing
into plain-text apps. So the clipboard is set through AppleScript instead, which
can hand over both flavors at once:

```applescript
set the clipboard to {«class RTF »:rtfData, string:plainText}
```

## Caveat

Styled text pastes in the RTF's font rather than the note's own body style.
⌘⌥⇧V (Paste and Match Style) would strip the italics along with it, so if the
font bothers you more than the emphasis helps, use `fixpaste -t`.
