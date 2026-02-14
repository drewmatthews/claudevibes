# Lou

A tiny macOS menu bar app that keeps an eye on your **Claude Code stats** so you don't have to.

Because if I'm gonna vibe-code, I want receipts.

## What's this thing?

Lou lives up in your menu bar and gives you a quick read on how hard you've been running Claude Code lately:

- **Today's damage** — messages, sessions, tool calls with live updates
- **Peak hours** — 24-hour activity chart showing when you're most active
- **7-day activity chart** — are we consistent or feral?
- **30-day trend** — sparkline with week-over-week comparison
- **Cache efficiency** — see how much you're saving on context reprocessing
- **Token usage** — input/output/cache, broken down by model
- **All-time stats** — totals + your longest session (a.k.a. *the incident*)
- **Milestones** — achievement badges for hitting message/token milestones
- **Value meter** — estimated API cost based on public pricing

Stats update automatically — no buttons, no fuss.

## Features

### Customizable Themes
Choose from 6 color themes with mini UI previews:
- Claude Pink (default)
- Ocean Blue
- Forest Green
- Sunset Orange
- Lavender
- Monochrome

### Preferences
- Toggle which sections are visible
- Choose vibe message categories
- Enable/disable milestone notifications

### Live Stats
Real-time parsing of Claude Code session files with automatic refresh.

## Install

1. Download the latest release
2. Drag `Lou.app` into your Applications folder
3. Open it
   - First time you'll need to **right-click → Open** (it's unsigned)
4. Look for the little Claude orb in your menu bar

## Requirements

- macOS 13 (Ventura) or newer
- [Claude Code](https://claude.ai/code) installed
- You've used it at least once (so it has stats to read)

## How it works

Lou reads data from two sources:

1. **Stats cache** — `~/.claude/stats-cache.json` for aggregated stats
2. **Session files** — `~/.claude/projects/*/` for live today stats

It watches these files for changes and updates instantly.

No polling.
No API calls.
No nonsense.
Just vibes.

## Credits

Built by [Drew](https://drewmatthews.ca)
Made with Claude Code
*Not affiliated with Anthropic*

---

*"Vibes are temporary. Stats are forever"*
