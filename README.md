# ✨ ClaudeVibes

A tiny macOS menu bar app that keeps an eye on your **Claude Code stats** so you don’t have to.

Because if I’m gonna vibe-code, I want receipts.

## What’s this thing?

ClaudeVibes lives up in your menu bar and gives you a quick read on how hard you’ve been running Claude Code lately:

- **Today’s damage** — messages, sessions, tool calls
- **7-day rhythm chart** — are we consistent or feral?
- **Token usage** — input/output/cache, broken down by model
- **All-time stats** — totals + your longest session (a.k.a. *the incident*)

Stats update automatically whenever Claude Code updates them — no buttons, no fuss.

## Install

1. Download the latest release  
2. Drag `ClaudeVibes.app` into your Applications folder  
3. Open it  
   - First time you’ll need to **right-click → Open** (it’s unsigned)  
4. Look for the little Claude orb in your menu bar

## Requirements

- macOS 13 (Ventura) or newer  
- [Claude Code](https://claude.ai/code) installed  
- You’ve used it at least once (so it has stats to read)

## How it works (aka: the part that matters)

ClaudeVibes reads the stats file Claude Code already keeps here:

`~/.claude/stats-cache.json`

It watches that file for changes and updates instantly.

No polling.  
No API calls.  
No nonsense.  
Just vibes.

## Credits

Built by [Drew](https://drewmatthews.ca) ✨  
Made with Claude Code  
*Not affiliated with Anthropic*

---

*"Vibes are temporary. Stats are forever ☕"*
