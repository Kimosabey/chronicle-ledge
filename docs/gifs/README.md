# 🎬 Demo GIFs - Create After Implementation

This folder will contain animated GIFs demonstrating the system in action.

## GIFs to Create (After Building the App)

### 1. `ha-demo.gif` - High Availability Demo
**Recording Steps:**
1. Start all 3 CockroachDB nodes
2. Run traffic simulation (continuous writes)
3. Kill Node 2 using `docker stop cockroach2`
4. Show that writes continue successfully (green checkmarks in terminal)
5. Restart Node 2, show it rejoins cluster
6. Duration: ~15 seconds

**Terminal Recording Command:**
```bash
# Use asciinema or terminalizer
asciinema rec ha-demo.cast
# Convert to GIF using asciicast2gif
```

---

### 2. `time-travel-demo.gif` - Event Sourcing Time Travel
**Recording Steps:**
1. Show current account balance ($1500)
2. Query API: `GET /accounts/ACC-001/balance?at=2024-01-15T14:00:00Z`
3. Show response: Balance was $1000 at 2 PM
4. Highlight the event replay happening
5. Duration: ~10 seconds

**Browser Recording:**
Record Next.js UI showing time-travel slider

---

### 3. `concurrency-demo.gif` - Race Condition Prevention
**Recording Steps:**
1. Run script: `npm run test:concurrent-withdrawals`
2. Show 100 parallel requests being sent
3. Show results: 1 succeeds, 99 fail with "Conflict" error
4. Verify final balance is correct (no overdraft)
5. Duration: ~12 seconds

**Terminal Recording:**
Show parallel curl requests and responses

---

## Tools for Creating GIFs

### Option 1: Terminal Recordings
```bash
# Install terminalizer
npm install -g terminalizer

# Record
terminalizer record demo

# Generate GIF
terminalizer render demo
```

### Option 2: Browser Recordings
```bash
# Use ScreenToGif (Windows)
# https://www.screentogif.com/

# Or use browser DevTools recorder
# Chrome > More Tools > Recorder > Export as GIF
```

### Option 3: Automated (Browser Subagent)
The browser_subagent automatically saves recordings as WebP videos.
Convert to GIF using:
```bash
ffmpeg -i recording.webp -vf "fps=10,scale=800:-1" output.gif
```

---

## Placeholder Images

Currently using static diagrams:
- `ha_demo_visual.png` - Technical diagram (static)
- `time_travel_visual.png` - Timeline diagram (static)
- `concurrency_protection_visual.png` - Race condition diagram (static)

These will be replaced with actual GIFs once the application is built.

---

**Status**: 📝 Placeholders created, waiting for app implementation
**Next**: Build the services, then record live demos
