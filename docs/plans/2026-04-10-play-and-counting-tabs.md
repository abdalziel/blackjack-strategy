# Play Mode + Card Counting Tabs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two new tabs to `blackjack-trainer.html` — a full-play casino mode with chip betting and a winnings tracker, and a Hi-Lo card counting trainer with animated deal and count quiz.

**Architecture:** Everything stays in the single `blackjack-trainer.html` file. A tab bar at the top switches between three panels (Strategy, Play, Count) by toggling CSS `display`. Each tab has its own JS state namespace. Shared infrastructure (`makeCardEl`, `buildShoe`, `dealCard`, `cardValue`, `handTotal`, `isSoft`, `isPair`, `basicStrategy`, and all rule toggles) is already in place — Play and Count tabs reuse it.

**Tech Stack:** Vanilla JS, CSS, HTML — no build tools, no dependencies. All styles and scripts inline in the single file.

---

## File Map

**Single file modified:** `blackjack-trainer.html`

Changes by section:

| Section | What changes |
|---|---|
| `<style>` (top) | Add tab nav styles, play mode styles, counting trainer styles |
| HTML body (before `.page-layout`) | Add tab navigation bar |
| HTML body (wrap existing) | Wrap strategy content in `<div id="tab-strategy" class="tab-panel">` |
| HTML body (after strategy panel) | Add `<div id="tab-play" class="tab-panel">` with play mode HTML |
| HTML body (after play panel) | Add `<div id="tab-count" class="tab-panel">` with counter HTML |
| `<script>` (add before closing tag) | Tab switching logic, Play Mode engine, Count Trainer engine |

---

## Task 1: Tab Navigation — CSS + HTML

**Files:**
- Modify: `blackjack-trainer.html` — add tab bar CSS + HTML, wrap existing content

- [ ] **Step 1: Add tab CSS** — insert this block into `<style>` just before the closing `</style>` tag (after the existing `@media (max-width: 480px)` block):

```css
/* ── Tab Navigation ──────────────────────────────────────────────────── */
.tab-nav {
  display: flex;
  gap: 6px;
  margin-bottom: 24px;
  background: rgba(0,0,0,0.25);
  border-radius: 12px;
  padding: 6px;
}
.tab-btn {
  flex: 1;
  padding: 10px 16px;
  border: none;
  border-radius: 8px;
  background: transparent;
  color: rgba(255,255,255,0.6);
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s, color 0.2s;
  letter-spacing: 0.3px;
}
.tab-btn:hover { background: rgba(255,255,255,0.1); color: #fff; }
.tab-btn.active { background: rgba(255,255,255,0.18); color: #fff; }
.tab-panel { display: none; width: 100%; }
.tab-panel.active { display: contents; }
```

- [ ] **Step 2: Add tab nav HTML** — replace the `<h1>Blackjack Strategy Trainer</h1>` and `<p class="subtitle">` block with:

```html
<h1>Blackjack Strategy Trainer</h1>
<p class="subtitle">T-H Basic Strategy &mdash; T. Hopper &mdash; Late Surrender, 6 decks</p>

<div class="tab-nav">
  <button class="tab-btn active" id="tabBtnStrategy" onclick="switchTab('strategy')">Strategy Trainer</button>
  <button class="tab-btn" id="tabBtnPlay" onclick="switchTab('play')">Play Mode</button>
  <button class="tab-btn" id="tabBtnCount" onclick="switchTab('count')">Card Counting</button>
</div>
```

- [ ] **Step 3: Wrap the existing strategy content** — the strategy tab content starts at the toggles (`.das-toggle`) and ends at the closing `</div><!-- end .main-col -->`. Wrap the entire `.page-layout` div (plus the `.chart-section` and `.grad-toast`) in a tab panel div:

Find:
```html
<div class="page-layout">
```

Replace with:
```html
<div id="tab-strategy" class="tab-panel active">
<div class="page-layout">
```

Find the last line before `</div><!-- end .page-layout -->`:
```html
</div><!-- end .page-layout -->

<div class="chart-section">
```

Replace with:
```html
</div><!-- end .page-layout -->

<div class="chart-section">
```
(no change here, but the chart-section and grad-toast also need to be inside the tab-strategy div)

Find:
```html
<div class="grad-toast" id="gradToast"></div>
```

Replace with:
```html
<div class="grad-toast" id="gradToast"></div>
</div><!-- end #tab-strategy -->
```

- [ ] **Step 4: Add tab switching JS** — add this function to the `<script>` block, before `// ─── Card Data`:

```javascript
// ─── Tab Switching ───────────────────────────────────────────────────────────
function switchTab(name) {
  ['strategy','play','count'].forEach(t => {
    document.getElementById('tab-' + t).classList.toggle('active', t === name);
    document.getElementById('tabBtn' + t.charAt(0).toUpperCase() + t.slice(1)).classList.toggle('active', t === name);
  });
  if (name === 'play' && !playInitialized) initPlay();
  if (name === 'count') resetCountRound();
}
```

- [ ] **Step 5: Verify** — open the file in a browser. Three tab buttons should appear. Strategy tab is active by default and works as before. Clicking Play or Count should switch the active tab (panels will be empty for now).

- [ ] **Step 6: Commit**

```bash
cd /Users/BlairDalziel/Documents/Claude/blackjack-strategy
git add blackjack-trainer.html
git commit -m "feat: add three-tab navigation shell"
```

---

## Task 2: Play Mode — HTML + CSS

**Files:**
- Modify: `blackjack-trainer.html` — add play tab HTML and CSS

- [ ] **Step 1: Add play mode CSS** — insert into `<style>` before `</style>`:

```css
/* ── Play Mode ───────────────────────────────────────────────────────── */
#tab-play { display: none; flex-direction: column; align-items: center; }
#tab-play.active { display: flex; }

.play-layout {
  display: flex;
  gap: 20px;
  align-items: flex-start;
  width: 100%;
  max-width: 1120px;
}
.play-main { flex: 0 0 auto; width: 100%; max-width: 680px; display: flex; flex-direction: column; align-items: center; }

/* Chip tray */
.chip-tray {
  display: flex;
  gap: 8px;
  align-items: center;
  justify-content: center;
  flex-wrap: wrap;
  margin-bottom: 14px;
}
.chip {
  width: 56px; height: 56px;
  border-radius: 50%;
  border: 3px dashed rgba(255,255,255,0.5);
  font-size: 0.75rem; font-weight: 800;
  cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  transition: transform 0.1s, box-shadow 0.15s;
  user-select: none;
  color: #fff;
}
.chip:hover:not(:disabled) { transform: translateY(-3px); box-shadow: 0 6px 14px rgba(0,0,0,0.4); }
.chip:active:not(:disabled) { transform: translateY(0); }
.chip:disabled { opacity: 0.35; cursor: not-allowed; }
.chip-5   { background: #dc2626; }
.chip-10  { background: #2563eb; }
.chip-25  { background: #15803d; }
.chip-50  { background: #7c3aed; }
.chip-100 { background: #92400e; }

.bet-display {
  text-align: center;
  margin-bottom: 14px;
}
.bet-amount {
  font-size: 2rem;
  font-weight: 800;
  color: #fbbf24;
}
.bet-label {
  font-size: 0.72rem;
  opacity: 0.6;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.play-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-bottom: 10px;
}
.play-action-full { margin-bottom: 10px; }

/* Bankroll bar */
.bankroll-bar {
  display: flex;
  gap: 20px;
  justify-content: center;
  margin-bottom: 16px;
  flex-wrap: wrap;
}
.bankroll-item {
  background: rgba(0,0,0,0.25);
  border-radius: 10px;
  padding: 8px 20px;
  text-align: center;
}
.bankroll-label { font-size: 0.7rem; opacity: 0.7; text-transform: uppercase; letter-spacing: 1px; }
.bankroll-value { font-size: 1.4rem; font-weight: 700; }
.bankroll-pos { color: #6ee87a; }
.bankroll-neg { color: #f87171; }
.bankroll-neu { color: #fbbf24; }

/* Result overlay on table */
.play-result {
  text-align: center;
  font-size: 1.5rem;
  font-weight: 800;
  letter-spacing: 1px;
  padding: 10px;
  border-radius: 10px;
  margin-bottom: 12px;
  display: none;
}
.play-result.win  { background: rgba(22,163,74,0.3);  border: 1px solid #16a34a; color: #86efac; }
.play-result.lose { background: rgba(185,28,28,0.3);  border: 1px solid #b91c1c; color: #fca5a5; }
.play-result.push { background: rgba(251,191,36,0.2); border: 1px solid #d97706; color: #fde68a; }
.play-result.bj   { background: rgba(168,85,247,0.3); border: 1px solid #a855f7; color: #e9d5ff; }

/* Dealer total display */
.dealer-total {
  font-size: 0.8rem;
  opacity: 0.7;
  margin-bottom: 6px;
  min-height: 18px;
}

/* Bet chip tray control buttons */
.tray-controls {
  display: flex;
  gap: 8px;
  justify-content: center;
  margin-bottom: 12px;
}
.tray-btn {
  padding: 7px 16px;
  border: 1px solid rgba(255,255,255,0.2);
  border-radius: 8px;
  background: rgba(0,0,0,0.25);
  color: #fff;
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}
.tray-btn:hover { background: rgba(0,0,0,0.4); }
.tray-btn:disabled { opacity: 0.35; cursor: not-allowed; }

/* Winnings sidebar */
.winnings-panel {
  flex: 1; min-width: 220px;
  background: rgba(0,0,0,0.25);
  border-radius: 16px;
  padding: 16px 14px;
  position: sticky; top: 24px;
}
.winnings-title {
  font-size: 0.88rem; font-weight: 700; letter-spacing: 0.5px;
  text-align: center; margin-bottom: 10px; padding-bottom: 8px;
  border-bottom: 1px solid rgba(255,255,255,0.15);
  cursor: pointer; user-select: none;
}
.winnings-body { overflow: hidden; }
.winnings-row {
  display: flex; justify-content: space-between;
  padding: 5px 0;
  border-bottom: 1px solid rgba(255,255,255,0.06);
  font-size: 0.8rem;
}
.winnings-row:last-child { border-bottom: none; }
.winnings-row span:first-child { opacity: 0.65; }
.winnings-row span:last-child { font-weight: 700; }
.w-pos { color: #6ee87a; }
.w-neg { color: #f87171; }
.w-neu { color: #fbbf24; }

@media (max-width: 860px) {
  .play-layout { flex-direction: column; align-items: center; }
  .winnings-panel { max-width: 680px; width: 100%; position: static; }
}
```

- [ ] **Step 2: Add play mode HTML** — insert this between `</div><!-- end #tab-strategy -->` and `<div class="grad-toast"`:

```html
<!-- ═══ PLAY MODE TAB ═══════════════════════════════════════════════════ -->
<div id="tab-play" class="tab-panel">
<div class="play-layout">
<div class="play-main">

  <!-- Bankroll bar -->
  <div class="bankroll-bar">
    <div class="bankroll-item">
      <div class="bankroll-label">Bankroll</div>
      <div class="bankroll-value bankroll-neu" id="playBankroll">$500</div>
    </div>
    <div class="bankroll-item">
      <div class="bankroll-label">Net P/L</div>
      <div class="bankroll-value bankroll-neu" id="playNetPL">$0</div>
    </div>
  </div>

  <!-- Bet area -->
  <div class="bet-display">
    <div class="bet-label">Current Bet</div>
    <div class="bet-amount" id="playBetDisplay">$0</div>
  </div>

  <div class="chip-tray" id="chipTray">
    <button class="chip chip-5"   onclick="addChip(5)"   id="chip5">$5</button>
    <button class="chip chip-10"  onclick="addChip(10)"  id="chip10">$10</button>
    <button class="chip chip-25"  onclick="addChip(25)"  id="chip25">$25</button>
    <button class="chip chip-50"  onclick="addChip(50)"  id="chip50">$50</button>
    <button class="chip chip-100" onclick="addChip(100)" id="chip100">$100</button>
  </div>

  <div class="tray-controls">
    <button class="tray-btn" id="btnClearBet" onclick="clearBet()">Clear</button>
    <button class="tray-btn" id="btnDoubleBet" onclick="doubleBet()">2× Last Bet</button>
    <button class="tray-btn" id="btnDealPlay" onclick="startPlayHand()">Deal</button>
  </div>

  <!-- Table -->
  <div class="table-area">
    <div class="hand-label">Dealer</div>
    <div class="dealer-total" id="playDealerTotal"></div>
    <div class="hand" id="playDealerHand"></div>

    <hr class="divider" />

    <div class="hand-label">Your Hand</div>
    <div class="hand" id="playPlayerHand"></div>
    <div class="hand-info" id="playHandInfo">&nbsp;</div>

    <div class="play-result" id="playResult"></div>

    <div class="play-actions" id="playActionBtns" style="display:none">
      <button class="btn btn-hit"    onclick="playAction('hit')">Hit</button>
      <button class="btn btn-stand"  onclick="playAction('stand')">Stand</button>
      <button class="btn btn-double" id="playBtnDouble" onclick="playAction('double')">Double Down</button>
      <button class="btn btn-split"  id="playBtnSplit"  onclick="playAction('split')">Split</button>
    </div>
    <div class="play-action-full" id="playSurrenderArea" style="display:none">
      <button class="btn btn-surrender" onclick="playAction('surrender')">Surrender</button>
    </div>

    <button class="btn-next" id="btnPlayNext" style="display:none" onclick="playNextHand()">Next Hand &rarr;</button>
  </div>

</div><!-- end .play-main -->

<!-- Winnings sidebar -->
<div class="winnings-panel">
  <div class="winnings-title" onclick="toggleWinnings()">Session Stats ▼</div>
  <div class="winnings-body" id="winningsBody">
    <div class="winnings-row"><span>Hands Played</span><span id="wHandsPlayed">0</span></div>
    <div class="winnings-row"><span>Wins</span><span id="wWins" class="w-pos">0</span></div>
    <div class="winnings-row"><span>Losses</span><span id="wLosses" class="w-neg">0</span></div>
    <div class="winnings-row"><span>Pushes</span><span id="wPushes" class="w-neu">0</span></div>
    <div class="winnings-row"><span>Blackjacks</span><span id="wBJs" class="w-pos">0</span></div>
    <div class="winnings-row"><span>Biggest Win</span><span id="wBigWin" class="w-pos">$0</span></div>
    <div class="winnings-row"><span>Biggest Loss</span><span id="wBigLoss" class="w-neg">$0</span></div>
    <button class="btn-reset" onclick="resetPlaySession()" style="margin-top:12px">Reset Session</button>
  </div>
</div>

</div><!-- end .play-layout -->
</div><!-- end #tab-play -->
```

- [ ] **Step 3: Verify HTML structure** — open in browser, click "Play Mode" tab. Should see bankroll bar, chip tray, empty table area and winnings sidebar. No JS errors in console.

- [ ] **Step 4: Commit**

```bash
git add blackjack-trainer.html
git commit -m "feat: add play mode HTML and CSS"
```

---

## Task 3: Play Mode — Game Engine JS

**Files:**
- Modify: `blackjack-trainer.html` — add play mode JS before closing `</script>`

- [ ] **Step 1: Add play mode state and helper functions** — insert before `// ─── Init`:

```javascript
// ═══ PLAY MODE ENGINE ════════════════════════════════════════════════════════
let playInitialized = false;

// State
let playBankroll   = 500;
let playBet        = 0;
let playLastBet    = 0;
let playPhase      = 'bet';   // 'bet' | 'play' | 'done'
let playPlayerCards = [];
let playDealerCards = [];
let playSplitHands  = [];
let playSplitIndex  = 0;
let playInSplit     = false;
let playFirstAction = true;   // true until first hit/action (enables double/surrender)

// Session stats
let playStats = {
  handsPlayed: 0, wins: 0, losses: 0, pushes: 0,
  blackjacks: 0, biggestWin: 0, biggestLoss: 0,
  startBankroll: 500
};

function initPlay() {
  playInitialized = true;
  loadPlayState();
  updatePlayBankrollUI();
  updateWinningsUI();
  updatePlayBetDisplay();
  setPlayChipsEnabled(true);
  document.getElementById('playActionBtns').style.display = 'none';
  document.getElementById('playSurrenderArea').style.display = 'none';
  document.getElementById('btnPlayNext').style.display = 'none';
  document.getElementById('playDealerHand').innerHTML = '';
  document.getElementById('playPlayerHand').innerHTML = '';
  document.getElementById('playResult').style.display = 'none';
  document.getElementById('playHandInfo').innerHTML = '&nbsp;';
  document.getElementById('playDealerTotal').textContent = '';
}

// ─── Betting ─────────────────────────────────────────────────────────────────
function addChip(value) {
  if (playPhase !== 'bet') return;
  if (playBet + value > playBankroll) return; // can't bet more than bankroll
  playBet += value;
  updatePlayBetDisplay();
}

function clearBet() {
  if (playPhase !== 'bet') return;
  playBet = 0;
  updatePlayBetDisplay();
}

function doubleBet() {
  if (playPhase !== 'bet') return;
  const target = playLastBet * 2 || playLastBet;
  if (!playLastBet) return;
  const newBet = Math.min(target, playBankroll);
  playBet = newBet;
  updatePlayBetDisplay();
}

function updatePlayBetDisplay() {
  document.getElementById('playBetDisplay').textContent = '$' + playBet;
  document.getElementById('btnDoubleBet').disabled = playPhase !== 'bet' || !playLastBet;
  document.getElementById('btnClearBet').disabled  = playPhase !== 'bet' || playBet === 0;
  document.getElementById('btnDealPlay').disabled  = playPhase !== 'bet' || playBet === 0;
}

// ─── Deal ─────────────────────────────────────────────────────────────────────
function startPlayHand() {
  if (playPhase !== 'bet' || playBet === 0) return;
  if (needsReshuffle) { buildShoe(); needsReshuffle = false; }

  playLastBet      = playBet;
  playBankroll    -= playBet;
  playPhase        = 'play';
  playFirstAction  = true;
  playInSplit      = false;
  playSplitHands   = [];
  playSplitIndex   = 0;

  playPlayerCards = [dealCard(), dealCard()];
  playDealerCards = [dealCard(), dealCard()];

  setPlayChipsEnabled(false);
  renderPlayHands(false);
  updatePlayHandInfo();
  updatePlayBankrollUI();
  document.getElementById('playResult').style.display = 'none';
  document.getElementById('btnPlayNext').style.display = 'none';

  // Check natural blackjack
  const playerBJ = isBlackjack(playPlayerCards);
  const dealerBJ = isBlackjack(playDealerCards);

  if (playerBJ || dealerBJ) {
    renderPlayHands(true); // reveal dealer
    updatePlayDealerTotal(true);
    if (playerBJ && dealerBJ) {
      settlePlay('push', playBet);
    } else if (playerBJ) {
      settlePlay('blackjack', Math.floor(playBet * 1.5));
    } else {
      settlePlay('lose', 0);
    }
    return;
  }

  showPlayActions();
}

function isBlackjack(cards) {
  if (cards.length !== 2) return false;
  const vals = cards.map(c => cardValue(c.rank));
  return vals.includes(11) && vals.includes(10); // Ace + 10-value
}

// ─── Actions ─────────────────────────────────────────────────────────────────
function playAction(action) {
  if (playPhase !== 'play') return;

  if (action === 'hit') {
    playFirstAction = false;
    playPlayerCards.push(dealCard());
    renderPlayHands(false);
    updatePlayHandInfo();
    // Refresh action buttons (disable double/split after first hit)
    showPlayActions();
    const total = handTotal(playPlayerCards);
    if (total >= 21) {
      setTimeout(() => {
        if (total > 21) {
          playDealerRevealAndSettle();
        } else {
          // 21 — auto-stand
          playDealerRevealAndSettle();
        }
      }, 300);
    }
    return;
  }

  if (action === 'stand') {
    playDealerRevealAndSettle();
    return;
  }

  if (action === 'double') {
    if (!playFirstAction) return;
    if (playBankroll < playBet) return; // not enough to double
    playBankroll -= playBet;
    playBet      *= 2;
    updatePlayBankrollUI();
    playFirstAction = false;
    playPlayerCards.push(dealCard());
    renderPlayHands(false);
    updatePlayHandInfo();
    updatePlayBetDisplay();
    setTimeout(playDealerRevealAndSettle, 400);
    return;
  }

  if (action === 'split') {
    if (!playFirstAction || !isPair(playPlayerCards)) return;
    if (playBankroll < playLastBet) return; // need another bet
    // Put current hand into split hands
    playBankroll -= playLastBet;
    updatePlayBankrollUI();
    playInSplit    = true;
    playSplitHands = [
      [playPlayerCards[0], dealCard()],
      [playPlayerCards[1], dealCard()]
    ];
    playSplitIndex  = 0;
    playPlayerCards = playSplitHands[0];
    playFirstAction = true;
    renderPlayHands(false);
    updatePlayHandInfo();
    showPlayActions();
    return;
  }

  if (action === 'surrender') {
    if (!playFirstAction || playInSplit) return;
    // Return half bet
    playBankroll += Math.floor(playBet / 2);
    playBet = 0;
    updatePlayBankrollUI();
    updatePlayBetDisplay();
    settlePlay('surrender', 0);
    return;
  }
}

// ─── Dealer play-out ─────────────────────────────────────────────────────────
function playDealerRevealAndSettle() {
  if (playPhase !== 'play') return;
  document.getElementById('playActionBtns').style.display = 'none';
  document.getElementById('playSurrenderArea').style.display = 'none';

  // If in split mode and not last hand, advance to next split hand
  if (playInSplit && playSplitIndex < playSplitHands.length - 1) {
    playSplitIndex++;
    playPlayerCards = playSplitHands[playSplitIndex];
    playFirstAction = true;
    renderPlayHands(false);
    updatePlayHandInfo();
    showPlayActions();
    return;
  }

  renderPlayHands(true); // reveal hole card
  dealerPlayOut(playDealerCards, () => {
    updatePlayDealerTotal(true);
    if (playInSplit) {
      settleSplitHands();
    } else {
      const pTotal = handTotal(playPlayerCards);
      const dTotal = handTotal(playDealerCards);
      if (pTotal > 21) {
        settlePlay('lose', 0);
      } else if (dTotal > 21 || pTotal > dTotal) {
        settlePlay('win', playBet);
      } else if (pTotal === dTotal) {
        settlePlay('push', playBet);
      } else {
        settlePlay('lose', 0);
      }
    }
  });
}

function dealerPlayOut(cards, callback) {
  // Dealer hits until 17+ (or soft 17 if H17 is off)
  const hitSoft17 = h17Enabled;
  function hitStep() {
    const total = handTotal(cards);
    const soft  = isSoft(cards);
    const shouldHit = total < 17 || (hitSoft17 && soft && total === 17);
    if (shouldHit) {
      cards.push(dealCard());
      renderPlayHands(true);
      updatePlayDealerTotal(true);
      setTimeout(hitStep, 400);
    } else {
      callback();
    }
  }
  hitStep();
}

function settleSplitHands() {
  const dTotal = handTotal(playDealerCards);
  let netGain = 0;
  playSplitHands.forEach(hand => {
    const pTotal = handTotal(hand);
    if (pTotal > 21) {
      // lose this hand's bet (already deducted)
    } else if (dTotal > 21 || pTotal > dTotal) {
      netGain += playLastBet * 2; // return bet + win
    } else if (pTotal === dTotal) {
      netGain += playLastBet; // push — return bet
    }
    // loss: nothing returned
  });
  playBankroll += netGain;
  const totalBet = playLastBet * playSplitHands.length;
  const profit   = netGain - totalBet;
  if (profit > 0)      showPlayResult('win',  `+$${profit}`);
  else if (profit < 0) showPlayResult('lose', `-$${Math.abs(profit)}`);
  else                 showPlayResult('push', 'Push');
  recordPlayResult(profit);
  finalizePlay();
}

// ─── Settlement ──────────────────────────────────────────────────────────────
function settlePlay(outcome, returnAmount) {
  let resultLabel, netProfit, cssClass;

  if (outcome === 'blackjack') {
    resultLabel = `Blackjack! +$${returnAmount + playBet}`;
    netProfit   = returnAmount;              // the bonus (1.5x) above the original bet
    playBankroll += playBet + returnAmount + playBet; // original bet back + winnings
    cssClass = 'bj';
  } else if (outcome === 'win') {
    resultLabel = `+$${returnAmount}`;
    netProfit   = returnAmount;
    playBankroll += playBet + returnAmount;
    cssClass = 'win';
  } else if (outcome === 'push') {
    resultLabel = 'Push';
    netProfit   = 0;
    playBankroll += playBet;
    cssClass = 'push';
  } else if (outcome === 'lose') {
    resultLabel = `-$${playBet}`;
    netProfit   = -playBet;
    cssClass = 'lose';
    // bankroll already reduced at deal time
  } else if (outcome === 'surrender') {
    resultLabel = `Surrender (-$${Math.floor(playLastBet/2)})`;
    netProfit   = -Math.floor(playLastBet/2);
    cssClass = 'lose';
  }

  showPlayResult(cssClass, resultLabel);
  recordPlayResult(netProfit);
  finalizePlay();
}

function recordPlayResult(netProfit) {
  playStats.handsPlayed++;
  if (netProfit > 0 && netProfit !== Math.floor(playLastBet * 0.5)) playStats.wins++;
  else if (netProfit <= 0 && netProfit !== 0) playStats.losses++;
  else playStats.pushes++;
  if (netProfit > playStats.biggestWin)          playStats.biggestWin  = netProfit;
  if (netProfit < -playStats.biggestLoss)         playStats.biggestLoss = Math.abs(netProfit);
  updateWinningsUI();
  savePlayState();
}

function finalizePlay() {
  playPhase = 'bet';
  playBet   = 0;
  updatePlayBankrollUI();
  updatePlayBetDisplay();
  setPlayChipsEnabled(true);
  document.getElementById('playActionBtns').style.display = 'none';
  document.getElementById('playSurrenderArea').style.display = 'none';
  document.getElementById('btnPlayNext').style.display = 'block';
  document.getElementById('btnPlayNext').textContent = 'Next Hand →';
}

function playNextHand() {
  document.getElementById('btnPlayNext').style.display = 'none';
  document.getElementById('playResult').style.display = 'none';
  document.getElementById('playDealerHand').innerHTML = '';
  document.getElementById('playPlayerHand').innerHTML = '';
  document.getElementById('playHandInfo').innerHTML = '&nbsp;';
  document.getElementById('playDealerTotal').textContent = '';
  // Check if bankroll is busted
  if (playBankroll <= 0) {
    playBankroll = 500;
    playStats.startBankroll = 500;
    updatePlayBankrollUI();
    updateWinningsUI();
    alert('Bankroll exhausted — resetting to $500!');
  }
}

// ─── Render ───────────────────────────────────────────────────────────────────
function renderPlayHands(revealDealer) {
  const dh = document.getElementById('playDealerHand');
  dh.innerHTML = '';
  playDealerCards.forEach((c, i) =>
    dh.appendChild(makeCardEl(c, i === 0 && !revealDealer)));

  const ph = document.getElementById('playPlayerHand');
  ph.innerHTML = '';
  if (playInSplit) {
    // Show all split hands side-by-side (simplified for now — just the active hand's cards)
    playSplitHands.forEach((hand, hi) => {
      const wrapper = document.createElement('div');
      wrapper.style.cssText = `display:flex;gap:4px;border:2px solid ${hi===playSplitIndex?'#fbbf24':'rgba(255,255,255,0.15)'};border-radius:8px;padding:4px;`;
      hand.forEach(c => wrapper.appendChild(makeCardEl(c)));
      ph.appendChild(wrapper);
    });
  } else {
    playPlayerCards.forEach(c => ph.appendChild(makeCardEl(c)));
  }
}

function updatePlayHandInfo() {
  const total = handTotal(playPlayerCards);
  const soft  = isSoft(playPlayerCards) && total <= 21;
  let desc = soft ? `Soft ${total}` : `Hard ${total}`;
  if (total > 21) desc = `Bust (${total})`;
  if (total === 21) desc = '21!';
  document.getElementById('playHandInfo').textContent = `Your hand: ${desc}`;
}

function updatePlayDealerTotal(show) {
  if (!show) { document.getElementById('playDealerTotal').textContent = ''; return; }
  const total = handTotal(playDealerCards);
  const soft  = isSoft(playDealerCards);
  const label = soft && total <= 21 ? `Soft ${total}` : `${total}`;
  const bust  = total > 21 ? ' — Bust!' : '';
  document.getElementById('playDealerTotal').textContent = `Dealer: ${label}${bust}`;
}

function showPlayActions() {
  document.getElementById('playActionBtns').style.display = 'grid';
  const canDouble = playFirstAction && playBankroll >= playBet;
  const canSplit  = playFirstAction && isPair(playPlayerCards) && playBankroll >= playLastBet && (!playInSplit || playSplitHands.length < 4);
  const canSurr   = surrenderEnabled && playFirstAction && !playInSplit;
  document.getElementById('playBtnDouble').disabled = !canDouble;
  document.getElementById('playBtnSplit').disabled  = !canSplit;
  document.getElementById('playSurrenderArea').style.display = canSurr ? 'block' : 'none';
}

function showPlayResult(cssClass, label) {
  const el = document.getElementById('playResult');
  el.className = `play-result ${cssClass}`;
  el.textContent = label;
  el.style.display = 'block';
}

// ─── Bankroll UI ──────────────────────────────────────────────────────────────
function updatePlayBankrollUI() {
  const net = playBankroll - playStats.startBankroll;
  document.getElementById('playBankroll').textContent = `$${playBankroll}`;
  const nlEl = document.getElementById('playNetPL');
  nlEl.textContent = (net >= 0 ? '+' : '') + `$${net}`;
  nlEl.className = `bankroll-value ${net > 0 ? 'bankroll-pos' : net < 0 ? 'bankroll-neg' : 'bankroll-neu'}`;
}

function updateWinningsUI() {
  document.getElementById('wHandsPlayed').textContent = playStats.handsPlayed;
  document.getElementById('wWins').textContent        = playStats.wins;
  document.getElementById('wLosses').textContent      = playStats.losses;
  document.getElementById('wPushes').textContent      = playStats.pushes;
  document.getElementById('wBJs').textContent         = playStats.blackjacks;
  document.getElementById('wBigWin').textContent      = `$${playStats.biggestWin}`;
  document.getElementById('wBigLoss').textContent     = `$${playStats.biggestLoss}`;
}

function setPlayChipsEnabled(enabled) {
  ['chip5','chip10','chip25','chip50','chip100','btnDealPlay'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.disabled = !enabled;
  });
}

function toggleWinnings() {
  const body  = document.getElementById('winningsBody');
  const title = document.querySelector('.winnings-title');
  const open  = body.style.display !== 'none';
  body.style.display  = open ? 'none' : '';
  title.textContent   = (open ? '▶' : '▼') + ' Session Stats';
}

// ─── Persistence ──────────────────────────────────────────────────────────────
function savePlayState() {
  try {
    localStorage.setItem('bjPlay', JSON.stringify({ playBankroll, playLastBet, playStats }));
  } catch(e) {}
}

function loadPlayState() {
  try {
    const s = JSON.parse(localStorage.getItem('bjPlay') || 'null');
    if (!s) return;
    playBankroll  = s.playBankroll  || 500;
    playLastBet   = s.playLastBet   || 0;
    Object.assign(playStats, s.playStats || {});
    if (!playStats.startBankroll) playStats.startBankroll = 500;
  } catch(e) {}
}

function resetPlaySession() {
  if (!confirm('Reset play session? Bankroll will return to $500.')) return;
  playBankroll = 500;
  playLastBet  = 0;
  playBet      = 0;
  playStats = { handsPlayed:0, wins:0, losses:0, pushes:0, blackjacks:0, biggestWin:0, biggestLoss:0, startBankroll:500 };
  savePlayState();
  updatePlayBankrollUI();
  updateWinningsUI();
  updatePlayBetDisplay();
  document.getElementById('playDealerHand').innerHTML = '';
  document.getElementById('playPlayerHand').innerHTML = '';
  document.getElementById('playResult').style.display = 'none';
  document.getElementById('playActionBtns').style.display = 'none';
  document.getElementById('playSurrenderArea').style.display = 'none';
  document.getElementById('btnPlayNext').style.display = 'none';
}
```

- [ ] **Step 2: Fix blackjack payout accounting** — note that `settlePlay('blackjack', ...)` currently adds `playBet + returnAmount + playBet`. Verify the math: player starts with bankroll reduced by bet at deal. On BJ with 3:2, player gets back: original bet (1×) + winnings (1.5×). So total returned = `playBet * 2.5`. The call `settlePlay('blackjack', Math.floor(playBet * 1.5))` sets `returnAmount = floor(bet * 1.5)`. Inside `settlePlay`: `playBankroll += playBet + returnAmount + playBet` — that's wrong (adds bet twice). Fix the blackjack branch:

```javascript
  if (outcome === 'blackjack') {
    resultLabel  = `Blackjack! +$${returnAmount}`;
    netProfit    = returnAmount;
    playBankroll += playBet + returnAmount; // original bet back + 1.5x winnings
    cssClass = 'bj';
    playStats.blackjacks++;
  }
```

- [ ] **Step 3: Test in browser** — click Play Mode tab. Place a $25 bet. Click Deal. Verify:
  - Cards appear for both player and dealer (hole card face down)
  - Hit adds a card
  - Stand triggers dealer play-out and shows result
  - Bankroll updates correctly
  - Double Down deducts another bet and deals one card
  - Surrender returns half the bet
  - Winnings panel updates after each hand

- [ ] **Step 4: Commit**

```bash
git add blackjack-trainer.html
git commit -m "feat: play mode game engine with chip betting and winnings tracker"
```

---

## Task 4: Card Counting Tab — HTML + CSS

**Files:**
- Modify: `blackjack-trainer.html` — add count tab HTML and CSS

- [ ] **Step 1: Add counting tab CSS** — insert into `<style>` before `</style>`:

```css
/* ── Card Counting Tab ───────────────────────────────────────────────── */
#tab-count { display: none; flex-direction: column; align-items: center; }
#tab-count.active { display: flex; }

.count-main {
  width: 100%; max-width: 680px;
  display: flex; flex-direction: column; align-items: center;
}

.count-settings {
  display: flex; gap: 12px; align-items: center;
  flex-wrap: wrap; justify-content: center;
  margin-bottom: 20px;
  background: rgba(0,0,0,0.2);
  border-radius: 12px; padding: 14px 20px;
  width: 100%; max-width: 680px;
}
.count-settings label { font-size: 0.85rem; opacity: 0.75; }
.count-settings select {
  background: rgba(0,0,0,0.35);
  border: 1px solid rgba(255,255,255,0.2);
  border-radius: 8px; color: #fff;
  padding: 6px 12px; font-size: 0.9rem; cursor: pointer;
}

.count-deal-area {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  min-height: 120px;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
  width: 100%;
}

/* Card enters with slide-down animation */
@keyframes cardDeal {
  from { opacity: 0; transform: translateY(-30px) rotate(-5deg); }
  to   { opacity: 1; transform: translateY(0) rotate(0deg); }
}
.card-dealing { animation: cardDeal 0.35s ease-out forwards; }

.count-status {
  text-align: center;
  font-size: 1rem;
  opacity: 0.75;
  margin-bottom: 16px;
  min-height: 24px;
}

.count-input-area {
  display: flex; gap: 10px; align-items: center;
  justify-content: center; margin-bottom: 16px;
  flex-wrap: wrap;
}
.count-input {
  width: 90px; padding: 10px;
  background: rgba(0,0,0,0.3);
  border: 2px solid rgba(255,255,255,0.25);
  border-radius: 10px; color: #fff;
  font-size: 1.4rem; font-weight: 700; text-align: center;
}
.count-input:focus { outline: none; border-color: #fbbf24; }

.btn-count-submit {
  padding: 10px 24px;
  background: #2563eb; color: #fff;
  border: none; border-radius: 10px;
  font-size: 1rem; font-weight: 700;
  cursor: pointer; transition: background 0.2s;
}
.btn-count-submit:hover { background: #1d4ed8; }
.btn-count-submit:disabled { opacity: 0.4; cursor: not-allowed; }

.count-feedback {
  min-height: 56px; border-radius: 10px;
  padding: 12px 16px; font-size: 0.95rem;
  line-height: 1.5; display: flex;
  align-items: center; gap: 10px;
  margin-bottom: 16px;
  background: rgba(0,0,0,0.15);
  border: 1px solid rgba(255,255,255,0.08);
  width: 100%;
}
.count-feedback.correct { background: rgba(22,163,74,0.3); border-color: #16a34a; }
.count-feedback.wrong   { background: rgba(185,28,28,0.3); border-color: #b91c1c; }

.count-scoreboard {
  display: flex; gap: 16px; flex-wrap: wrap;
  justify-content: center; margin-bottom: 20px;
}
.count-score-item {
  background: rgba(0,0,0,0.25); border-radius: 10px;
  padding: 8px 18px; text-align: center;
}
.count-score-label { font-size: 0.7rem; opacity: 0.65; text-transform: uppercase; letter-spacing: 1px; }
.count-score-value { font-size: 1.3rem; font-weight: 700; }

/* Hi-Lo reference */
.hilo-ref {
  display: flex; gap: 16px; flex-wrap: wrap;
  justify-content: center; margin-bottom: 16px;
  font-size: 0.8rem;
}
.hilo-ref span {
  background: rgba(0,0,0,0.2); border-radius: 8px;
  padding: 5px 12px;
}
.hilo-plus  { color: #6ee87a; }
.hilo-zero  { color: #fbbf24; }
.hilo-minus { color: #f87171; }
```

- [ ] **Step 2: Add counting tab HTML** — insert after `</div><!-- end #tab-play -->` and before `<div class="grad-toast"`:

```html
<!-- ═══ CARD COUNTING TAB ════════════════════════════════════════════════════ -->
<div id="tab-count" class="tab-panel">
<div class="count-main">

  <div class="count-settings">
    <label for="countCardCount">Cards to show:</label>
    <select id="countCardCount" onchange="onCountSettingChange()">
      <option value="5">5</option>
      <option value="10" selected>10</option>
      <option value="15">15</option>
      <option value="20">20</option>
      <option value="26">Half shoe</option>
      <option value="52">Full shoe (1 deck)</option>
    </select>

    <label for="countDeckSel">Decks:</label>
    <select id="countDeckSel" onchange="onCountSettingChange()">
      <option value="1">1</option>
      <option value="2">2</option>
      <option value="6" selected>6</option>
      <option value="8">8</option>
    </select>
  </div>

  <!-- Hi-Lo reference legend -->
  <div class="hilo-ref">
    <span class="hilo-plus">2–6: <strong>+1</strong></span>
    <span class="hilo-zero">7–9: <strong>0</strong></span>
    <span class="hilo-minus">10/J/Q/K/A: <strong>−1</strong></span>
  </div>

  <div class="count-scoreboard">
    <div class="count-score-item">
      <div class="count-score-label">Correct</div>
      <div class="count-score-value" style="color:#6ee87a" id="countCorrect">0</div>
    </div>
    <div class="count-score-item">
      <div class="count-score-label">Attempts</div>
      <div class="count-score-value" style="color:#fbbf24" id="countAttempts">0</div>
    </div>
    <div class="count-score-item">
      <div class="count-score-label">Streak</div>
      <div class="count-score-value" style="color:#a78bfa" id="countStreak">0</div>
    </div>
  </div>

  <div class="table-area" style="width:100%">
    <div class="count-status" id="countStatus">Press Start to begin a round</div>

    <div class="count-deal-area" id="countDealArea"></div>

    <div class="count-input-area" id="countInputArea" style="display:none">
      <input type="number" class="count-input" id="countGuess" placeholder="0"
        onkeydown="if(event.key==='Enter') submitCount()" />
      <button class="btn-count-submit" onclick="submitCount()" id="btnSubmitCount">Submit</button>
    </div>

    <div class="count-feedback" id="countFeedback" style="display:none"></div>

    <button class="btn-next" id="btnCountStart" onclick="startCountRound()">Start Round</button>
    <button class="btn-next" id="btnCountNext"  onclick="resetCountRound()" style="display:none">Next Round &rarr;</button>
  </div>

</div>
</div><!-- end #tab-count -->
```

- [ ] **Step 3: Verify structure** — open in browser. Click Card Counting tab. Should show settings row, Hi-Lo legend, scoreboard, and the table area with "Start Round" button. No JS errors.

- [ ] **Step 4: Commit**

```bash
git add blackjack-trainer.html
git commit -m "feat: card counting tab HTML and CSS"
```

---

## Task 5: Card Counting — JS Engine

**Files:**
- Modify: `blackjack-trainer.html` — add counting trainer JS before `// ─── Init`

- [ ] **Step 1: Add counting engine** — insert into `<script>` before `// ─── Init`:

```javascript
// ═══ CARD COUNTING TRAINER ════════════════════════════════════════════════════
let countShoe        = [];
let countShoeIndex   = 0;
let countCards       = [];    // cards shown this round
let countRunning     = 0;     // correct running count for shown cards
let countDealTimer   = null;  // interval handle during animation
let countRoundActive = false;
let countCorrectAll  = 0;
let countAttempts    = 0;
let countStreak      = 0;

function buildCountShoe() {
  const decks = parseInt(document.getElementById('countDeckSel').value) || 6;
  countShoe = [];
  for (let d = 0; d < decks; d++) {
    for (const suit of SUITS) {
      for (const rank of RANKS) {
        countShoe.push({ rank, suit });
      }
    }
  }
  // Fisher-Yates
  for (let i = countShoe.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [countShoe[i], countShoe[j]] = [countShoe[j], countShoe[i]];
  }
  countShoeIndex = 0;
}

function hiLoValue(rank) {
  const v = cardValue(rank);
  if (v >= 2 && v <= 6) return +1;
  if (v >= 7 && v <= 9) return  0;
  return -1; // 10, J, Q, K, A
}

function onCountSettingChange() {
  buildCountShoe();
  resetCountRound();
}

function resetCountRound() {
  clearTimeout(countDealTimer);
  countRoundActive = false;
  countCards = [];
  countRunning = 0;
  document.getElementById('countDealArea').innerHTML = '';
  document.getElementById('countInputArea').style.display  = 'none';
  document.getElementById('countFeedback').style.display   = 'none';
  document.getElementById('btnCountStart').style.display   = 'block';
  document.getElementById('btnCountNext').style.display    = 'none';
  document.getElementById('countGuess').value = '';
  document.getElementById('countStatus').textContent = 'Press Start to begin a round';
  document.getElementById('btnSubmitCount').disabled = true;
}

function startCountRound() {
  if (!countShoe.length) buildCountShoe();
  // Rebuild shoe if exhausted
  const numCards = parseInt(document.getElementById('countCardCount').value) || 10;
  if (countShoeIndex + numCards > countShoe.length) buildCountShoe();

  countRoundActive = true;
  countCards = [];
  countRunning = 0;

  document.getElementById('countDealArea').innerHTML = '';
  document.getElementById('countFeedback').style.display = 'none';
  document.getElementById('btnCountStart').style.display = 'none';
  document.getElementById('btnCountNext').style.display  = 'none';
  document.getElementById('countInputArea').style.display = 'none';
  document.getElementById('btnSubmitCount').disabled = true;

  let i = 0;
  function dealNext() {
    if (i >= numCards) {
      // All cards dealt — show input
      document.getElementById('countStatus').textContent = `What is the running count after ${numCards} cards?`;
      document.getElementById('countInputArea').style.display = 'flex';
      document.getElementById('btnSubmitCount').disabled = false;
      document.getElementById('countGuess').focus();
      return;
    }

    const card = countShoe[countShoeIndex++];
    countCards.push(card);
    countRunning += hiLoValue(card.rank);

    const el = makeCardEl(card);
    el.classList.add('card-dealing');
    document.getElementById('countDealArea').appendChild(el);

    document.getElementById('countStatus').textContent =
      `Dealing card ${i + 1} of ${numCards}…`;

    i++;
    countDealTimer = setTimeout(dealNext, 700);
  }

  dealNext();
}

function submitCount() {
  if (!countRoundActive) return;
  const guess = parseInt(document.getElementById('countGuess').value);
  if (isNaN(guess)) return;

  document.getElementById('btnSubmitCount').disabled = true;
  countAttempts++;
  const isCorrect = guess === countRunning;

  const fb = document.getElementById('countFeedback');
  fb.style.display = 'flex';

  if (isCorrect) {
    countCorrectAll++;
    countStreak++;
    fb.className = 'count-feedback correct';
    fb.innerHTML = `<span style="font-size:1.3rem">✅</span><span><strong>Correct!</strong> The running count was <strong>${countRunning}</strong>.</span>`;
  } else {
    countStreak = 0;
    fb.className = 'count-feedback wrong';
    fb.innerHTML = `<span style="font-size:1.3rem">❌</span><span><strong>Not quite.</strong> You said <strong>${guess}</strong>, the correct count was <strong>${countRunning}</strong>.</span>`;
  }

  document.getElementById('countCorrect').textContent  = countCorrectAll;
  document.getElementById('countAttempts').textContent = countAttempts;
  document.getElementById('countStreak').textContent   = countStreak;
  document.getElementById('countStatus').textContent   = '';
  document.getElementById('countInputArea').style.display = 'none';
  document.getElementById('btnCountNext').style.display  = 'block';
  countRoundActive = false;
}
```

- [ ] **Step 2: Initialize count shoe on first use** — in `resetCountRound`, the shoe may not be built yet if user goes straight to count tab. Add to the top of `resetCountRound`:

```javascript
  if (!countShoe.length) buildCountShoe();
```

- [ ] **Step 3: Test counting trainer**
  - Click Card Counting tab
  - Set 10 cards, 1 deck
  - Click Start Round
  - Cards should appear one every 0.7 seconds
  - After all 10 cards, input field appears
  - Enter a number and click Submit
  - Correct/wrong feedback shows with the real count
  - Click Next Round → clears and resets

- [ ] **Step 4: Test edge cases**
  - Set "Half shoe" (26 cards) with 1 deck — all 26 cards should deal without error
  - Verify count arithmetic: spot-check by dealing 3 low cards (2,3,4 = +3) and entering 3

- [ ] **Step 5: Commit**

```bash
git add blackjack-trainer.html
git commit -m "feat: card counting trainer with Hi-Lo animation and count quiz"
```

---

## Task 6: Polish + Shared Settings Sync

**Files:**
- Modify: `blackjack-trainer.html` — wire DAS/H17/Surrender/deck toggles to Play Mode, final polish

- [ ] **Step 1: Play mode inherits ruleset toggles** — the play mode engine already uses `dasEnabled`, `surrenderEnabled`, `h17Enabled`, and `deckCount` globals from the strategy trainer. Verify that toggling DAS/H17/Surrender on the strategy tab affects play mode behaviour. No code changes needed — just verify.

- [ ] **Step 2: Add keyboard shortcut for count submission** — the `countGuess` input already has `onkeydown="if(event.key==='Enter') submitCount()"`. Verify this works in browser.

- [ ] **Step 3: Fix tab-panel CSS for flex children** — the `.tab-panel` uses `display: contents` when active, which makes the panel invisible as a flex container. The children (`.page-layout`, `.play-layout`, etc.) rely on being inside a flex column. Change the strategy/play/count specific panels to use `display: flex` not `display: contents`:

Update the CSS:

```css
/* Replace the generic tab-panel rules */
.tab-panel { display: none; }
.tab-panel.active { display: flex; flex-direction: column; align-items: center; width: 100%; }

/* Strategy panel needs its children to be block-level */
#tab-strategy.active { display: contents; }
```

- [ ] **Step 4: Ensure play tab uses its own shoe** — currently Play mode calls `dealCard()` which uses the strategy trainer's shared shoe. This is fine — both use the same global shoe, which simulates a real casino shared shoe correctly. No change needed.

- [ ] **Step 5: Final browser test — full walkthrough**
  - Strategy tab: deal a hand, answer, get feedback, next hand ✓
  - Play tab: place $25 bet, deal, hit a few times, stand, dealer plays out, winnings update ✓
  - Play tab: try double down ✓
  - Play tab: try split ✓
  - Play tab: verify bankroll tracks correctly across multiple hands ✓
  - Count tab: start round with 10 cards, cards animate in, submit correct count ✓
  - Count tab: switch to 20 cards, verify all 20 deal ✓
  - Tab switching: switch between all 3 tabs, no state corruption ✓

- [ ] **Step 6: Final commit + push**

```bash
git add blackjack-trainer.html
git commit -m "feat: polish tab sync, css fixes, verified full play and count flows"
git push
```

---

## Spec Coverage Check

| Requirement | Task |
|---|---|
| Three tabs | Task 1 |
| Same ruleset toggles (DAS, H17, Surrender, deck count) affect play mode | Task 6 Step 1 |
| Chip denominations: $5, $10, $25, $50, $100 | Task 2 |
| Clear chips button | Task 2 / Task 3 |
| Double bet at next hand start | Task 3 |
| Collapsible winnings/losses sidebar | Task 2 / Task 3 |
| Full casino play (dealer plays out, bust, BJ) | Task 3 |
| Card counting tab | Task 4 |
| Selectable card count before quiz | Task 4 |
| Deal animation 0.7s per card | Task 5 |
| Hi-Lo: 2–6 = +1, 7–9 = 0, 10/J/Q/K/A = −1 | Task 5 |
| Ask player for count after cards dealt | Task 5 |
| Correct/wrong feedback with real count | Task 5 |
