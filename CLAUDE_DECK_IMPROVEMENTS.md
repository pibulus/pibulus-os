# Claude Deck Improvements

## What to Remove
- Signal rail (3 status pills: mode/workspace/idle) — lines 609-613
- Mode buttons (Plan/Ask/Act/Full) + workspace dropdown — lines 614-617
- CSS: `.signal-rail`, `.signal-cell`, `.controls`, `.modes`, `.mode`, `.select`
- JS: `renderModes()`, `setMode()`, `renderWorkspaces()` functions

## What to Add

### 1. Spending Tracker HTML:
```html
<div class="spending-bar">
  <span class="spending-label">chat cost:</span>
  <span class="spending-amount" id="spendingAmount">$0.00</span>
</div>
```

### 2. Add CSS:
```css
.spending-bar {
  margin-top: 10px;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 8px;
  border: 1px solid rgba(var(--green-rgb),.24);
  border-radius: var(--radius);
  background: rgba(var(--green-rgb),.06);
  font-size: 13px;
}
.spending-label { color: var(--soft); font-weight: 600; }
.spending-amount { color: var(--green); font-weight: 800; }

.assistant.thinking .bubble {
  animation: breathe 1.8s ease-in-out infinite;
  border-color: rgba(var(--green-rgb),.42);
  box-shadow: 0 0 12px rgba(var(--green-rgb),.16);
}
@keyframes breathe {
  0%, 100% { opacity: 0.6; }
  50% { opacity: 1; }
}
```

### 3. Add Audio Functions (JS):
```javascript
const audioContext = new (window.AudioContext || window.webkitAudioContext)();
function playSound(f, d) {
  try {
    const osc = audioContext.createOscillator();
    const gain = audioContext.createGain();
    osc.connect(gain); gain.connect(audioContext.destination);
    osc.frequency.setValueAtTime(f, audioContext.currentTime);
    gain.gain.setValueAtTime(0.08, audioContext.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + d);
    osc.start(audioContext.currentTime);
    osc.stop(audioContext.currentTime + d);
  } catch (_) {}
}
function beepSend() { playSound(800, 0.1); }
function beepThinking() { playSound(400, 0.08); setTimeout(() => playSound(520, 0.08), 80); }
function beepDone() { playSound(600, 0.08); setTimeout(() => playSound(420, 0.08), 80); }
```

### 4. Update `fitInput()` for auto-scroll:
```javascript
function fitInput() {
  input.style.height = 'auto';
  input.style.height = Math.min(input.scrollHeight, 180) + 'px';
  setTimeout(() => { input.scrollTop = input.scrollHeight; }, 0);
}
```

### 5. Add to chat handler:
- Add `let chatCost = 0;` at top
- Track tokens, update `#spendingAmount` live
- Call `beepSend()` on form submit
- Call `beepThinking()` in `startAssistantPlaceholder()`
- Call `beepDone()` when event.type === 'done'

---

## Reply Copy Icon & Full Access Hold Button
TBD — See main Deck implementation for current state.
