#!/bin/bash

# ─── Blackjack Strategy Trainer — Local Dev Server ──────────────────────────
# Double-click this file in Finder to start a local server for testing.
# Make and test changes locally, then push to GitHub only when ready.
# ────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=8080
export PATH="/opt/homebrew/bin:$PATH"

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "    Blackjack Strategy Trainer — Dev Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo " Local:   http://localhost:$PORT/blackjack-trainer.html"
echo ""
echo " Edit blackjack-trainer.html, refresh the"
echo " browser to see changes — no deploy needed."
echo ""
echo " When ready to publish: git push"
echo " (each push = 1 Netlify deploy = 15 credits)"
echo ""
echo " Press Ctrl+C to stop the server."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Open browser after a short delay so the server is ready
(sleep 1 && open "http://localhost:$PORT/blackjack-trainer.html") &

cd "$SCRIPT_DIR"
npx serve -l $PORT --no-clipboard
