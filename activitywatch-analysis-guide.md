# ActivityWatch Analysis Guide

## Quick Reference for Claude/AI Assistants

### 🚨 Critical: Timezone Handling

**ActivityWatch stores all timestamps in UTC!**

When analyzing data for users, always:
1. Ask for their timezone first OR check their location (Brussels = UTC+2/CEST)
2. Convert all timestamps to local time for display
3. Include timezone notation in reports

```javascript
// Example conversion
const utcTime = "2025-06-12T14:00:00Z";
const brusselsTime = new Date(utcTime).toLocaleString('en-GB', {
    timeZone: 'Europe/Brussels',
    hour12: false
});
```

### 📊 Creating Comprehensive Timesheets

#### 1. Initial Data Collection
```javascript
// Get full day's data
activitywatch_get_events({
    bucketId: "aw-watcher-window_[hostname]",
    start: "[date]T00:00:00Z",  // Start of day UTC
    end: "[date]T23:59:59Z",    // End of day UTC
    limit: 2000  // Ensure you get all events
})
```

#### 2. Check for Data Gaps
- Look for large time gaps between events
- Common causes:
  - System sleep/lock (check for "loginwindow" events)
  - Watcher crashes
  - Brief gaps (< 5 min) are usually normal

#### 3. Activity Grouping Strategy

**Group by meaningful work phases, not just hours:**
- Morning startup/planning
- Deep work sessions
- Meeting blocks
- Testing/debugging cycles
- Documentation periods
- Break/transition times

**Identify productivity patterns:**
- Look for long uninterrupted periods in same app
- Count context switches between apps
- Note testing cycles (Xcode → Simulator → Xcode)

#### 4. Key Metrics to Calculate
- Total work duration (first to last event)
- Context switches (app changes count)
- Peak productivity periods (longest focused sessions)
- App distribution percentages
- Break patterns

### 🏷️ Context Recognition

Look for contextual clues in window titles:
- `✳` symbols = User-added context markers
- Ticket numbers (e.g., "CA-5006")
- File names indicate specific work focus
- "Login" events indicate breaks/locks

### 📈 Visualization Best Practices

1. **Timeline view**: Show work phases chronologically
2. **Distribution charts**: Percentage time per app category
3. **Focus quality**: Rate periods by interruption frequency
4. **Hourly heatmap**: Show activity intensity

### ⚠️ Common Pitfalls to Avoid

1. **Don't assume continuous work** - Check for gaps
2. **Don't report UTC times to users** - Always convert
3. **Don't count total events** - Count meaningful context switches
4. **Don't ignore brief app switches** - They indicate workflow

### 🔧 Troubleshooting

If data seems incomplete:
1. Check both window and AFK watchers
2. Verify timezone conversions
3. Look for system events (login screens)
4. Consider increasing query limit

### 📝 Report Template Structure

```markdown
## Daily Activity Report - [Date]

### Overview
- **Work Hours**: [Start] - [End] ([Timezone])
- **Total Duration**: Xh Ym
- **Primary Focus**: [Main task/ticket]
- **Context Switches**: [Count]

### Productivity Timeline
[Chronological phases with descriptions]

### Activity Distribution
[App categories with percentages]

### Key Insights
[Patterns, achievements, recommendations]
```

### 🌍 Brussels-Specific Notes

- Working hours typically 9:00-17:00 CEST
- UTC+1 (winter) or UTC+2 (summer)
- Common apps: Xcode, Slack, Teams, Tower
- Lunch breaks often show as system locks

---

## Example Analysis Approach

```python
# 1. Get timezone
user_tz = "Europe/Brussels"  # or ask user

# 2. Fetch data in UTC
events = get_events(start_utc, end_utc)

# 3. Convert for display
for event in events:
    event.local_time = convert_to_tz(event.timestamp, user_tz)

# 4. Group into phases
phases = group_by_activity_type(events)

# 5. Calculate metrics
metrics = {
    'total_time': calculate_duration(events),
    'switches': count_context_switches(events),
    'focus_score': rate_focus_quality(phases)
}

# 6. Generate report with LOCAL times
```