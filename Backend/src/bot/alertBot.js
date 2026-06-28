// src/bot/alertBot.js

let waSocket = null
const OWNER_NUMBER = process.env.WA_OWNER_NUMBER // Format: 628xxxxxxxxx@s.whatsapp.net

export function setWASocket(sock) {
  waSocket = sock
}

export async function sendWAAlert(message) {
  if (!waSocket || !OWNER_NUMBER) return

  try {
    await waSocket.sendMessage(OWNER_NUMBER, { text: message })
    console.log('[WA Alert] Terkirim:', message)
  } catch (err) {
    console.error('[WA Alert] Gagal kirim:', err)
  }
}

// Format alert yang bagus
export function formatAlert(reading) {
  const alerts = []

  if (reading.temp_status === 'too_hot')
    alerts.push(`🌡️ Suhu tinggi: ${reading.temperature}°C (max 30°C)`)

  if (reading.temp_status === 'too_cold')
    alerts.push(`🌡️ Suhu rendah: ${reading.temperature}°C (min 25°C)`)

  if (reading.ph_status === 'too_high')
    alerts.push(`🧪 pH terlalu tinggi: ${reading.ph}`)

  if (reading.ph_status === 'too_low')
    alerts.push(`🧪 pH terlalu rendah: ${reading.ph}`)

  if (reading.turbidity_status === 'danger')
    alerts.push(`🌊 Air terlalu keruh! ADC: ${reading.turbidity_filtered}`)

  if (reading.feed_status === 'empty')
    alerts.push(`🐟 Pakan HABIS: ${reading.feed_level_pct}%`)

  if (reading.feed_status === 'critical')
    alerts.push(`🐟 Pakan kritis: ${reading.feed_level_pct}%`)

  if (alerts.length === 0) return null

  return `⚠️ *ALERT AQUASENSE*\n\n` +
         alerts.join('\n') +
         `\n\n_${new Date().toLocaleString('id-ID')}_`
}