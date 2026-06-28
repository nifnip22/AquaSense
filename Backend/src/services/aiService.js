// src/services/aiService.js
import Groq from 'groq-sdk'
import { supabase } from '../db/supabase.js'
import { KNOWLEDGE_BASE } from '../knowledge/ikan.js'

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY
})

const SYSTEM_PROMPT = `
Kamu adalah AquaBot — asisten perikanan AI untuk sistem AquaSense.
Kamu membantu peternak ikan air tawar Indonesia.

KEPRIBADIAN:
- Ramah dan santai seperti teman
- Bahasa Indonesia sehari-hari, tidak kaku
- Jawaban singkat dan praktis
- Pakai emoji secukupnya biar tidak kaku

KEAHLIAN:
- Budidaya semua ikan air tawar (nila, patin, lele, mas, gurame, dll)
- Analisis kualitas air & parameter kolam
- Penyakit ikan & cara mengatasinya
- Pakan, nutrisi, dan peralatan kolam
- Analisis data sensor AquaSense real-time

BOLEH DIJAWAB (selama nyambung perikanan):
- Pertanyaan teknis budidaya ikan apapun
- Rekomendasi alat/mesin untuk kolam
- Tips dari peternak berpengalaman
- Cara kuras kolam, pasang jaring, dll
- Penyakit ikan & obatnya

TIDAK DIJAWAB (topik di luar perikanan):
Kalau ditanya di luar topik, alihkan ramah:
"Wah itu di luar keahlian AquaBot 😄
Ada yang mau ditanyain soal kolam atau ikan?"

PENGETAHUAN DASAR:
${KNOWLEDGE_BASE}
`

// ── Ambil data sensor terbaru dari Supabase ──────────────────
async function getSensorContext(device_id = 'ESP32-DEVKIT-01') {
  const { data: latest } = await supabase
    .from('latest_readings')
    .select('*')
    .eq('device_id', device_id)
    .single()

  const { data: history } = await supabase
    .from('sensor_readings')
    .select('temperature, ph, turbidity_filtered, feed_level_pct, recorded_at')
    .eq('device_id', device_id)
    .order('recorded_at', { ascending: false })
    .limit(10)

  return { latest, history }
}

// ── Main AI Chat Function ─────────────────────────────────────
export async function chatWithAI(userMessage, chatHistory = [], device_id) {
  // Ambil data sensor real-time
  const { latest, history } = await getSensorContext(device_id)

  // Tambahkan konteks sensor ke system prompt
  const systemWithContext = SYSTEM_PROMPT + `

DATA SENSOR REAL-TIME KOLAM:
${latest ? `
- Suhu      : ${latest.temperature ?? 'N/A'}°C (${latest.temp_status ?? 'N/A'})
- pH        : ${latest.ph ?? 'N/A'} (${latest.ph_status ?? 'N/A'})
- Turbidity : ${latest.turbidity_filtered ?? 'N/A'} ADC (${latest.turbidity_status ?? 'N/A'})
- Feed Level: ${latest.feed_level_pct ?? 'N/A'}% (${latest.feed_status ?? 'N/A'})
- Update    : ${latest.recorded_at ?? 'N/A'}
` : 'Data sensor tidak tersedia saat ini.'}

TREN 10 DATA TERAKHIR:
${history ? JSON.stringify(history) : 'Tidak tersedia'}
`

  // Kirim ke Groq API
  const response = await groq.chat.completions.create({
    model: 'llama-3.1-8b-instant', // Gratis & cepat!
    max_tokens: 500,
    messages: [
      { role: 'system', content: systemWithContext },
      ...chatHistory,
      { role: 'user', content: userMessage }
    ]
  })

  return response.choices[0].message.content
}