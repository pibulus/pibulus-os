// PIBULUS "Technical Difficulties" Cloudflare Worker
// Tries origin first. If down, serves a punk maintenance page.
// Deploy via Cloudflare Dashboard → Workers & Pages → Create

export default {
  async fetch(request) {
    try {
      // Try the real origin with a tight timeout
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 5000);

      const response = await fetch(request, {
        signal: controller.signal,
        cf: { resolveOverride: request.headers.get('host') }
      });
      clearTimeout(timeout);

      // If origin responded, pass it through
      if (response.status < 500) {
        return response;
      }
      throw new Error('Origin 5xx');
    } catch (e) {
      // Origin is down — show the goods
      return new Response(maintenancePage(), {
        status: 503,
        headers: {
          'Content-Type': 'text/html;charset=UTF-8',
          'Retry-After': '300',
          'Cache-Control': 'no-store'
        }
      });
    }
  }
};

function maintenancePage() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PIBULUS — Technical Difficulties</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=VT323&display=swap');
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #0a0a0a;
      color: #e0e0e0;
      font-family: 'VT323', monospace;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
      padding: 20px;
      overflow: hidden;
    }
    body::before {
      content: '';
      position: fixed;
      top: 0; left: 0; width: 100%; height: 100%;
      background: repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,0.15) 2px, rgba(0,0,0,0.15) 4px);
      pointer-events: none;
      z-index: 100;
    }
    .container { max-width: 600px; position: relative; z-index: 1; }
    h1 {
      font-size: clamp(36px, 8vw, 64px);
      color: #ff00ff;
      text-shadow: 0 0 10px rgba(255,0,255,0.6), 0 0 40px rgba(255,0,255,0.2);
      letter-spacing: 3px;
      margin-bottom: 8px;
      animation: flicker 4s ease-in-out infinite;
    }
    @keyframes flicker {
      0%, 100% { opacity: 1; }
      92% { opacity: 1; } 93% { opacity: 0.3; }
      94% { opacity: 1; } 95.5% { opacity: 0.2; }
      96% { opacity: 1; }
    }
    .subtitle {
      font-size: clamp(18px, 4vw, 28px);
      color: #00ffea;
      text-shadow: 0 0 8px rgba(0,255,234,0.4);
      letter-spacing: 6px;
      margin-bottom: 30px;
    }
    .image-frame {
      border: 3px solid #ff00ff;
      box-shadow: 0 0 20px rgba(255,0,255,0.3), inset 0 0 20px rgba(0,0,0,0.5);
      margin: 0 auto 24px;
      max-width: 400px;
      position: relative;
      overflow: hidden;
    }
    .image-frame img {
      width: 100%;
      display: block;
      filter: saturate(0.8) contrast(1.1);
    }
    .image-frame::after {
      content: '';
      position: absolute;
      top: 0; left: 0; width: 100%; height: 100%;
      background: repeating-linear-gradient(0deg, transparent, transparent 1px, rgba(0,0,0,0.08) 1px, rgba(0,0,0,0.08) 2px);
      pointer-events: none;
    }
    .message {
      font-size: 22px;
      color: #999;
      letter-spacing: 2px;
      line-height: 1.6;
      margin-bottom: 20px;
    }
    .message em {
      color: #00ffea;
      font-style: normal;
    }
    .status-line {
      font-size: 14px;
      color: #444;
      letter-spacing: 3px;
      text-transform: uppercase;
    }
    .dot {
      display: inline-block;
      width: 8px; height: 8px;
      background: #ff00ff;
      border-radius: 50%;
      margin-right: 8px;
      animation: blink 2s ease-in-out infinite;
    }
    @keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0.2; } }
    .retry-btn {
      display: inline-block;
      margin-top: 20px;
      padding: 10px 24px;
      font-family: 'VT323', monospace;
      font-size: 18px;
      letter-spacing: 3px;
      color: #00ffea;
      border: 1px solid #00ffea;
      background: transparent;
      cursor: pointer;
      text-decoration: none;
      transition: all 0.2s;
    }
    .retry-btn:hover {
      background: rgba(0,255,234,0.1);
      box-shadow: 0 0 14px rgba(0,255,234,0.3);
    }
    .footer {
      margin-top: 40px;
      font-size: 11px;
      color: #222;
      letter-spacing: 2px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>TECHNICAL DIFFICULTIES</h1>
    <div class="subtitle">PLEASE STAND BY</div>

    <div class="image-frame">
      <img src="https://i.imgur.com/JYKiMzH.gif" alt="Technical Difficulties - Please Stand By" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 width=%22400%22 height=%22300%22><rect fill=%22%23111%22 width=%22400%22 height=%22300%22/><text fill=%22%23ff00ff%22 font-family=%22monospace%22 font-size=%2248%22 x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22>%F0%9F%93%BA</text></svg>'">
    </div>

    <div class="message">
      The pirate signal is <em>temporarily offline</em>.<br>
      Our tiny server is probably rebooting,<br>
      updating, or having a nap.
    </div>

    <div class="status-line">
      <span class="dot"></span>
      Auto-retry in <span id="countdown">30</span>s
    </div>

    <a href="/" class="retry-btn" onclick="location.reload(); return false;">TRY AGAIN</a>

    <div class="footer">PIBULUS OS &middot; Pi 5 Node &middot; She'll be right</div>
  </div>

  <script>
    let t = 30;
    const el = document.getElementById('countdown');
    setInterval(() => {
      t--;
      if (el) el.textContent = t;
      if (t <= 0) location.reload();
    }, 1000);
  </script>
</body>
</html>`;
}
