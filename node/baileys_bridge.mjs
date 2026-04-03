import makeWASocket, {
  useMultiFileAuthState,
  fetchLatestBaileysVersion,
  Browsers
} from '@whiskeysockets/baileys'
import P from 'pino'
import readline from 'readline'

const authDir = process.argv[2] || 'node/baileys_auth'
const logger = P({ level: 'silent' })

const send = (obj) => {
  process.stdout.write(`${JSON.stringify(obj)}\n`)
}

const start = async () => {
  const { state, saveCreds } = await useMultiFileAuthState(authDir)
  const { version } = await fetchLatestBaileysVersion()

  const sock = makeWASocket({
    auth: state,
    logger,
    version,
    browser: Browsers.macOS('Chrome'),
    printQRInTerminal: false
  })

  sock.ev.on('creds.update', saveCreds)

  sock.ev.on('connection.update', (update) => {
    if (update.qr) {
      send({ type: 'qr', qr: update.qr })
    }
    if (update.connection === 'open') {
      send({ type: 'paired' })
    }
    if (update.connection === 'close') {
      send({
        type: 'close',
        reason:
          update.lastDisconnect?.error?.output?.statusCode ||
          update.lastDisconnect?.error?.message ||
          'unknown'
      })
    }
  })

  const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity })

  rl.on('line', async (line) => {
    if (!line) return
    let msg
    try {
      msg = JSON.parse(line)
    } catch {
      return send({ type: 'error', error: 'invalid_json' })
    }

    if (msg.type === 'send') {
      const to = msg.to?.trim()
      const message = msg.message
      if (!to || !message) {
        return send({ type: 'error', error: 'invalid_send_payload' })
      }
      const jid = to.includes('@s.whatsapp.net') ? to : `${to}@s.whatsapp.net`
      try {
        await sock.sendMessage(jid, { text: message })
      } catch (err) {
        send({ type: 'error', error: err?.message || 'send_failed' })
      }
    }
  })
}

start().catch((err) => {
  send({ type: 'error', error: err?.message || 'startup_failed' })
})
