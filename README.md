# WaBridge (Baileys + Elixir API)

Outbound-only WhatsApp bridge powered by Baileys (Node.js) with a lightweight Elixir HTTP API.

## What This Does
- Generates a WhatsApp QR for pairing
- Saves session credentials
- Provides HTTP endpoints to send outbound messages

## Requirements
- Elixir 1.17+
- Node.js 18+ (for Baileys)

## Local Run
```bash
cd node
npm install

cd ..
mix run --no-halt
```

The server listens on `PORT` (default `4001`).

## Endpoints
- `GET /health` → `{ "status": "ok" }`
- `GET /status` → current pairing state
- `GET /qr` → QR string (JSON)
- `GET /qr.png` → QR image (640x640 PNG)
- `POST /send` → send message

### Send Message Example
```bash
curl -s -X POST http://localhost:4001/send \
  -H 'content-type: application/json' \
  -d '{"to":"+491234567890","message":"hello"}'
```

## Pairing Flow
1. Start server: `mix run --no-halt`
2. Request QR: `GET /qr.png`
3. Scan QR with WhatsApp
4. Check pairing: `GET /status` → `paired: true`

Session creds are stored in `node/baileys_auth`.

## Docker / Coolify
Build & run:
```bash
docker build -t wa-bridge .
docker run -p 4001:4001 -e PORT=4001 wa-bridge
```

Or use the included `docker-compose.yml` in Coolify.

## Notes
- QR is generated only when you request `/qr` or `/qr.png`.
- If pairing fails, delete `node/baileys_auth/*` and try again.
