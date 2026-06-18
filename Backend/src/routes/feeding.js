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
app.post('/', async (c) => {
    const body        = await c.req.json();
    const device_id   = body.device_id   ?? 'ESP32-DEVKIT-01';
    const duration_sec = body.duration_sec ?? 3;
    const notes       = body.notes        ?? 'Triggered via API';

    // Validasi
    if (duration_sec < 1 || duration_sec > 30) {
        return c.json({ error: 'duration_sec harus antara 1–30 detik' }, 400);
    }

    // Kirim MQTT command ke ESP32
    const mqttSent = publishFeedCommand(device_id, duration_sec);

    // Catat di feeding_logs (trigger = 'remote' karena dari API/app)
    const { data, error } = await supabase
        .from('feeding_logs')
        .insert([{
            device_id,
            trigger_type: 'remote',
            duration_sec,
            notes,
        }])
        .select()
        .single();

    if (error) return c.json({ error: error.message }, 500);

    return c.json({
        message:   'Feeding command sent',
        mqtt_sent: mqttSent,
        data,
    }, 201);
});

export default app;