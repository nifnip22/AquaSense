// src/bot/waBot.js
import makeWASocket, {
  useMultiFileAuthState,
  DisconnectReason,
  fetchLatestBaileysVersion
} from '@whiskeysockets/baileys'
import { Boom } from '@hapi/boom'
import { chatWithAI } from '../services/aiService.js'
import qrcode from 'qrcode-terminal' // 👈 TAMBAHKAN INI (Import qrcode-terminal)

// Simpan histori chat per nomor WA
const chatHistories = new Map()

// ── Start WA Bot ──────────────────────────────────────────────
export async function startWABot() {
  const { state, saveCreds } = await useMultiFileAuthState('./wa_session')
  const { version } = await fetchLatestBaileysVersion()

  const sock = makeWASocket({
    version,
    auth: state,
    browser: ["Mac OS", "Chrome", "14.4.1"] // 👈 Opsi browser agar lebih stabil
    // printQRInTerminal: true, // Biarkan ini tetap dikomentari atau dihapus
  })

  // Simpan kredensial saat update
  sock.ev.on('creds.update', saveCreds)

  // Handle koneksi
  sock.ev.on('connection.update', (update) => {
    // 👈 TAMBAHKAN 'qr' PADA DESTRUCTURING DI BAWAH INI
    const { connection, lastDisconnect, qr } = update

    // 👈 TAMBAHKAN BLOK LOGIKA INI UNTUK MEMUNCULKAN QR
    if (qr) {
      console.log('\n🤖 AquaBot: Silakan scan QR Code di bawah ini:\n')
      qrcode.generate(qr, { small: true })
    }

    if (connection === 'close') {
      const shouldReconnect =
        new Boom(lastDisconnect?.error)?.output?.statusCode
        !== DisconnectReason.loggedOut

      console.log('[WA] Koneksi terputus, reconnect:', shouldReconnect)
      if (shouldReconnect) startWABot() // Auto reconnect
    }

    if (connection === 'open') {
      console.log('✅ [WA] WhatsApp Bot terhubung!')
    }
  })

  // Handle pesan masuk
  sock.ev.on('messages.upsert', async ({ messages }) => {
    const msg = messages[0]

    // Skip kalau bukan pesan baru atau dari bot sendiri
    if (!msg.message || msg.key.fromMe) return

    const sender    = msg.key.remoteJid
    const userText  = msg.message.conversation
                   || msg.message.extendedTextMessage?.text
                   || ''

    if (!userText) return

    console.log(`[WA] Pesan dari ${sender}: ${userText}`)

    try {
      // Ambil histori chat user ini (max 10 pesan)
      const history = chatHistories.get(sender) || []

      // Kirim ke AI
      const aiReply = await chatWithAI(userText, history)

      // Update histori
      history.push(
        { role: 'user',      content: userText  },
        { role: 'assistant', content: aiReply   }
      )
      if (history.length > 20) history.splice(0, 2)
      chatHistories.set(sender, history)

      // Kirim status "mengetik" ke WA selama 3 detik
      await sock.sendPresenceUpdate('composing', sender)
      await new Promise(resolve => setTimeout(resolve, 3000)) // Jeda 3 detik
      await sock.sendPresenceUpdate('paused', sender)

      // Balas ke WA
      await sock.sendMessage(sender, { text: aiReply })
      console.log(`[WA] Balas ke ${sender}: ${aiReply}`)

    } catch (err) {
      console.error('[WA] Error:', err)
      await sock.sendMessage(sender, {
        text: 'Maaf, AquaBot lagi gangguan sebentar 😅 Coba lagi ya!'
      })
    }
  })

  return sock
}