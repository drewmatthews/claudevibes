# Plan: Adding Rate Limit Features to ClaudeVibes

## Current State

**What we have (from `~/.claude/stats-cache.json`):**
- Message counts, session counts, tool calls
- Token usage (input, output, cache)
- Daily activity history
- Model names

**What we DON'T have:**
- Plan type (Pro/Max/Free)
- Rate limit windows (5-hour rolling, weekly)
- Usage percentages vs limits
- Reset timers
- Notifications at thresholds

---

## The Challenge: Two Different Rate Limit Systems

### 1. API Rate Limits (for developers)
- Based on usage tiers (Tier 1-4)
- Measured in RPM, ITPM, OTPM (requests/tokens per minute)
- Uses token bucket algorithm (continuous replenishment)
- **Headers returned with every API response:**
  - `anthropic-ratelimit-requests-limit/remaining/reset`
  - `anthropic-ratelimit-tokens-limit/remaining/reset`
  - `anthropic-ratelimit-input-tokens-limit/remaining/reset`
  - `anthropic-ratelimit-output-tokens-limit/remaining/reset`

### 2. Claude Code Pro/Max Limits (what the competitor app shows)
- 5-hour rolling window
- Weekly limits
- Different system entirely from API tiers
- **NOT documented publicly**
- Likely uses internal Anthropic endpoints

---

## Options

### Option A: Minimal API Integration (Medium effort)
**Approach:** Make a single lightweight API call on startup/refresh to get rate limit headers.

**Pros:**
- Uses documented, stable API
- Gets real rate limit data
- Works with existing OAuth credentials in Keychain

**Cons:**
- Only gets API-style rate limits (per-minute), not the 5-hour/weekly windows
- Requires making actual API calls (even if minimal)
- May not match what Claude Code Pro/Max users actually experience

**Implementation:**
1. Read OAuth token from Keychain (`Claude Code-credentials`)
2. Make a minimal messages API call (or find a lighter endpoint)
3. Parse rate limit headers from response
4. Display remaining capacity and reset times

### Option B: Reverse Engineer Claude Code's Rate Limit Source (High effort)
**Approach:** Figure out where Claude Code gets its 5-hour/weekly limit data.

**Investigation needed:**
- Monitor Claude Code's network traffic
- Check if there's an internal `/usage` or `/limits` endpoint
- Look at what the competitor app is actually calling

**Pros:**
- Would get the exact same data users see in Claude Code
- Matches the UI in the competitor screenshot

**Cons:**
- Relies on undocumented/internal APIs
- Could break with any Claude Code update
- More complex to implement

### Option C: Estimate from Local Data (Low effort, limited accuracy)
**Approach:** Use local stats to estimate usage without API calls.

**Implementation:**
- Track tokens used in rolling 5-hour windows from local history
- Estimate percentage based on assumed limits
- Show "estimated" usage with appropriate caveats

**Pros:**
- No API calls needed
- No credential access needed
- Simple to implement

**Cons:**
- Limits are guesses (we don't know actual Pro/Max limits)
- No accurate reset timers
- No plan detection

### Option D: UI Improvements Only (Minimal effort)
**Approach:** Keep current data sources, just improve the presentation.

**Add:**
- Progress bar visualizations (like competitor)
- Better layout and visual hierarchy
- Cleaner "Today" section

**Skip:**
- Rate limit percentages
- Reset timers
- Notifications

**Pros:**
- Ship quickly
- No new complexity
- No API/credential concerns

**Cons:**
- Doesn't add the "killer features" from competitor

---

## Recommendation

**Start with Option D + partial Option C:**

1. **Phase 1: UI refresh** (quick win)
   - Add progress bar components
   - Cleaner layout matching competitor style
   - Settings button for future features

2. **Phase 2: Estimated windows** (medium effort)
   - Track rolling 5-hour usage from local data
   - Show "~X% of typical limit" with disclaimer
   - Add weekly rollup view

3. **Phase 3: Investigate real API** (if worth it)
   - Research what endpoint the competitor uses
   - Evaluate if Keychain auth is worth the complexity
   - Consider user privacy/trust implications

---

## Questions to Answer Before Proceeding

1. **Do you want to access user credentials?**
   - Feels more invasive than reading local cache
   - Requires trust from users
   - But enables accurate rate limit data

2. **Is estimated data good enough?**
   - We could show "~20% of typical daily usage"
   - Without knowing exact limits, it's approximate
   - But still useful for relative tracking

3. **What's your priority?**
   - A) Match competitor features exactly
   - B) Ship improvements quickly with current approach
   - C) Build something differentiated

---

## Technical Notes

### Keychain Access (if we go that route)
```swift
// Read from Keychain
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "Claude Code-credentials",
    kSecAttrAccount as String: NSUserName(),
    kSecReturnData as String: true
]
// ... SecItemCopyMatching
```

### API Rate Limit Headers (if making calls)
```
anthropic-ratelimit-requests-remaining: 49
anthropic-ratelimit-requests-reset: 2026-01-24T18:30:00Z
anthropic-ratelimit-tokens-remaining: 450000
anthropic-ratelimit-tokens-reset: 2026-01-24T18:30:00Z
```

### Local Rolling Window Calculation
```swift
// Estimate 5-hour window usage
let fiveHoursAgo = Date().addingTimeInterval(-5 * 60 * 60)
let recentTokens = sessions
    .filter { $0.timestamp > fiveHoursAgo }
    .reduce(0) { $0 + $1.tokens }
let estimatedPercent = Double(recentTokens) / assumedLimit * 100
```

---

## Sources

- [Anthropic Rate Limits Documentation](https://platform.claude.com/docs/en/api/rate-limits)
- [Rate limit headers are documented](https://platform.claude.com/docs/en/api/rate-limits#response-headers)
- Local investigation of `~/.claude/` directory
