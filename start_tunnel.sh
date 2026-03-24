#!/bin/zsh

# ─────────────────────────────────────────────────────────────
# Script khởi động Cloudflare Quick Tunnel cho backend
# Chạy: chmod +x start_tunnel.sh && ./start_tunnel.sh
# ─────────────────────────────────────────────────────────────

LOG=/tmp/cloudflare_tunnel.log

echo "🚀 Bắt đầu Cloudflare Quick Tunnel..."
echo "📋 Log file: $LOG"
echo ""

# Kill tunnel cũ nếu có
pkill -f cloudflared 2>/dev/null && echo "⚡ Đã kill tunnel cũ" || echo "ℹ️  Không có tunnel cũ"

# Kill port 3001 nếu bị chiếm
lsof -ti :3001 | xargs kill -9 2>/dev/null && echo "⚡ Đã kill process cũ trên port 3001" || echo "ℹ️  Port 3001 đang trống"

sleep 1

# Start backend
echo ""
echo "▶️  Khởi động backend Node.js..."
cd /Users/buiphong/Development/landsale_flutterweb/backend
npm start &
sleep 3

# Start Cloudflare tunnel
echo ""
echo "▶️  Khởi động Cloudflare tunnel..."
cloudflared tunnel --url http://localhost:3001 > $LOG 2>&1 &

# Chờ URL xuất hiện
echo "⏳ Đang chờ URL tunnel..."
for i in {1..15}; do
  URL=$(grep -o 'https://[a-z0-9\-]*\.trycloudflare\.com' $LOG 2>/dev/null | head -1)
  if [ -n "$URL" ]; then
    break
  fi
  sleep 1
done

if [ -n "$URL" ]; then
  echo ""
  echo "✅ ─────────────────────────────────────────────────"
  echo "   Tunnel URL: $URL"
  echo "────────────────────────────────────────────────────"
  echo ""
  echo "📝 Copy URL trên vào api_constants.dart:"
  echo "   static const String baseUrl = '$URL';"
  echo ""
else
  echo "❌ Không lấy được URL. Xem log: cat $LOG"
fi
