// src/routes/feeding.js
import { Hono } from 'hono';
import { supabase } from '../db/supabase.js';
import { publishFeedCommand } from '../mqtt/mqttClient.js';

const app = new Hono();

// GET /api/feeding?device_id=&limit=20
app.get('/', async (c) => {
    const device_id = c.req.query('device_id');
    const limit     = Math.min(parseInt(c.req.query('limit') ?? '20'), 200);

    let query = supabase
        .from('feeding_logs')
        .select('*')
        .order('fed_at', { ascending: false })
        .limit(limit);

    if (device_id) query = query.eq('device_id', device_id);

    const { data, error } = await query;
    if (error) return c.json({ error: error.message }, 500);
    return c.json({ count: data.length, data });
});

// POST /api/feeding — trigger feeding manual
// Body: { "device_id": "ESP32-DEVKIT-01", "duration_sec": 5, "notes": "..." }
//
// Alur:
//   1. Publish MQTT command → ESP32 (aquasense/{device_id}/command/feed)
//   2. ESP32 akan buka gate + publish balik ke topic feeding
//   3. Backend catat log dari MQTT feeding event (handleFeedingLog)
//
// Catatan: insert manual ke feeding_logs juga dilakukan di sini sebagai
// fallback jika ESP32 tidak publish balik (misal offline / no feeding event).
// src/routes/feeding.js (Revisi POST)
app.post('/', async (c) => {
    const body         = await c.req.json();
    const device_id    = body.device_id    ?? 'ESP32-DEVKIT-01';
    const duration_sec = body.duration_sec ?? 3;
    // notes dihapus karena nanti dicatat oleh mqttClient dari balikan ESP32

    // Validasi safety (sesuai SERVO_MIN_OPEN_SEC dan MAX di ESP32)
    if (duration_sec < 1 || duration_sec > 30) {
        return c.json({ error: 'duration_sec harus antara 1–30 detik' }, 400);
    }

    // 1. Kirim MQTT command ke ESP32 (Hanya ini tugasnya!)
    const mqttSent = publishFeedCommand(device_id, duration_sec);

    if (!mqttSent) {
        return c.json({ error: 'Gagal mengirim perintah ke alat (MQTT disconnected)' }, 500);
    }

    // 2. HAPUS KODE INSERT SUPABASE DI SINI!
    // Kita tunggu ESP32 publish balik ke topic feeding, 
    // biar file mqttClient.js -> handleFeedingLog() yang melakukan insert ke DB.

    return c.json({
        message: 'Perintah pakan berhasil dikirim ke ESP32',
        duration_sec: duration_sec
    }, 200);
});

export default app;