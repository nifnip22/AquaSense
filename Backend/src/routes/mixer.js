// src/routes/mixer.js
import { Hono } from 'hono';
import { supabase } from '../db/supabase.js';
import { publishMixerCommand, publishMixerSchedules } from '../mqtt/mqttClient.js';

const app = new Hono();

// #region agent log
import { appendFileSync } from 'fs';
import { join } from 'path';
const DEBUG_LOG_PATH = join(process.cwd(), '../Arduino/ESP32/debug-fafb2e.log');
function _agentLog(location, message, data = {}, hypothesisId = 'D', runId = 'pre-fix') {
    const entry = {
        sessionId: 'fafb2e',
        runId,
        hypothesisId,
        location,
        message,
        data,
        timestamp: Date.now(),
    };
    try { appendFileSync(DEBUG_LOG_PATH, JSON.stringify(entry) + '\n'); } catch {}
    fetch('http://127.0.0.1:7573/ingest/61263a7c-8ce0-4bf4-9952-f0bafbdf00fd', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Debug-Session-Id': 'fafb2e' },
        body: JSON.stringify(entry),
    }).catch(() => {});
}
// #endregion

// ─────────────────────────────────────────────────────────────
// Helper: ambil semua jadwal aktif lalu sync ke ESP32
// Dipanggil setiap kali jadwal berubah (create/update/delete)
// ─────────────────────────────────────────────────────────────
async function syncSchedulesToESP32(device_id) {
    const { data: schedules, error } = await supabase
        .from('mixer_schedules')
        .select('schedule_time, duration_min')
        .eq('device_id', device_id)
        .eq('is_active', true)
        .order('schedule_time', { ascending: true });

    if (error) {
        console.error('[Mixer] Gagal ambil jadwal untuk sync:', error.message);
        return false;
    }

    // Format jadwal: potong ke "HH:MM" saja (TIME bisa datang sebagai "HH:MM:SS")
    const formatted = schedules.map(s => ({
        time:         s.schedule_time.slice(0, 5),  // "08:00:00" → "08:00"
        duration_min: s.duration_min,
    }));

    return publishMixerSchedules(device_id, formatted);
}

// ─────────────────────────────────────────────────────────────
// GET /api/mixer/status?device_id=
// Status mixer real-time dari DB
// ─────────────────────────────────────────────────────────────
app.get('/status', async (c) => {
    const device_id = c.req.query('device_id') ?? 'ESP32-DEVKIT-01';

    const { data, error } = await supabase
        .from('mixer_status')
        .select('*')
        .eq('device_id', device_id)
        .single();

    if (error) return c.json({ error: error.message }, 500);
    return c.json({ data });
});

// ─────────────────────────────────────────────────────────────
// POST /api/mixer/control
// Toggle mixer ON/OFF manual dari app
// Body: { "device_id": "ESP32-DEVKIT-01", "is_on": true, "duration_min": 15 }
// ─────────────────────────────────────────────────────────────
app.post('/control', async (c) => {
    const body         = await c.req.json();
    const device_id    = body.device_id   ?? 'ESP32-DEVKIT-01';
    const is_on        = body.is_on;
    const duration_min = body.duration_min ?? 15;

    if (typeof is_on !== 'boolean') {
        return c.json({ error: 'is_on harus boolean (true/false)' }, 400);
    }
    if (is_on && (duration_min < 1 || duration_min > 120)) {
        return c.json({ error: 'duration_min harus antara 1–120 menit' }, 400);
    }

    // Kirim MQTT command ke ESP32
    const mqtt_sent = publishMixerCommand(device_id, is_on, is_on ? duration_min : 0);

    // #region agent log
    _agentLog('mixer.js:control', 'POST /api/mixer/control handled', {
        device_id,
        is_on,
        duration_min,
        mqtt_sent,
    }, mqtt_sent ? 'B' : 'C');
    // #endregion

    // Update mixer_status di DB (upsert — baris id=1 selalu ada)
    const { data, error } = await supabase
        .from('mixer_status')
        .upsert({
            id:         1,
            device_id,
            is_on,
            updated_at: new Date().toISOString(),
        }, { onConflict: 'id' })
        .select()
        .single();

    if (error) return c.json({ error: error.message }, 500);

    return c.json({
        message:   `Mixer ${is_on ? 'ON' : 'OFF'} command sent`,
        mqtt_sent,
        data,
    });
});

// ─────────────────────────────────────────────────────────────
// GET /api/mixer/schedules?device_id=
// Ambil semua jadwal mixer
// ─────────────────────────────────────────────────────────────
app.get('/schedules', async (c) => {
    const device_id = c.req.query('device_id') ?? 'ESP32-DEVKIT-01';

    const { data, error } = await supabase
        .from('mixer_schedules')
        .select('*')
        .eq('device_id', device_id)
        .order('schedule_time', { ascending: true });

    if (error) return c.json({ error: error.message }, 500);
    return c.json({ count: data.length, data });
});

// ─────────────────────────────────────────────────────────────
// POST /api/mixer/schedules
// Tambah jadwal baru, lalu sync semua jadwal aktif ke ESP32
// Body: { "device_id": "ESP32-DEVKIT-01", "schedule_time": "08:00", "duration_min": 15 }
// ─────────────────────────────────────────────────────────────
app.post('/schedules', async (c) => {
    const body          = await c.req.json();
    const device_id     = body.device_id     ?? 'ESP32-DEVKIT-01';
    const schedule_time = body.schedule_time;
    const duration_min  = body.duration_min  ?? 15;

    if (!schedule_time || !/^\d{2}:\d{2}$/.test(schedule_time)) {
        return c.json({ error: 'schedule_time harus format "HH:MM", contoh: "08:00"' }, 400);
    }
    if (duration_min < 1 || duration_min > 120) {
        return c.json({ error: 'duration_min harus antara 1–120 menit' }, 400);
    }

    const { data, error } = await supabase
        .from('mixer_schedules')
        .insert([{ device_id, schedule_time, duration_min }])
        .select()
        .single();

    if (error) return c.json({ error: error.message }, 500);

    // Sync jadwal terbaru ke ESP32
    const mqtt_sent = await syncSchedulesToESP32(device_id);

    return c.json({
        message:   'Jadwal ditambahkan dan disync ke ESP32',
        mqtt_sent,
        data,
    }, 201);
});

// ─────────────────────────────────────────────────────────────
// PATCH /api/mixer/schedules/:id
// Edit jadwal (waktu, durasi, atau aktif/nonaktif)
// Body: { "schedule_time": "10:00", "duration_min": 20, "is_active": true }
// ─────────────────────────────────────────────────────────────
app.patch('/schedules/:id', async (c) => {
    const id   = parseInt(c.req.param('id'));
    const body = await c.req.json();

    const updates = {};
    if (body.schedule_time !== undefined) {
        if (!/^\d{2}:\d{2}$/.test(body.schedule_time)) {
            return c.json({ error: 'schedule_time harus format "HH:MM"' }, 400);
        }
        updates.schedule_time = body.schedule_time;
    }
    if (body.duration_min !== undefined) {
        if (body.duration_min < 1 || body.duration_min > 120) {
            return c.json({ error: 'duration_min harus antara 1–120 menit' }, 400);
        }
        updates.duration_min = body.duration_min;
    }
    if (body.is_active !== undefined) {
        updates.is_active = body.is_active;
    }

    if (Object.keys(updates).length === 0) {
        return c.json({ error: 'Tidak ada field yang diupdate' }, 400);
    }

    const { data, error } = await supabase
        .from('mixer_schedules')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    if (error) return c.json({ error: error.message }, 500);

    // Sync jadwal terbaru ke ESP32
    const mqtt_sent = await syncSchedulesToESP32(data.device_id);

    return c.json({
        message:   'Jadwal diupdate dan disync ke ESP32',
        mqtt_sent,
        data,
    });
});

// ─────────────────────────────────────────────────────────────
// DELETE /api/mixer/schedules/:id
// Hapus jadwal, lalu sync ulang ke ESP32
// ─────────────────────────────────────────────────────────────
app.delete('/schedules/:id', async (c) => {
    const id = parseInt(c.req.param('id'));

    // Ambil device_id dulu sebelum hapus (untuk sync)
    const { data: existing, error: fetchErr } = await supabase
        .from('mixer_schedules')
        .select('device_id')
        .eq('id', id)
        .single();

    if (fetchErr) return c.json({ error: 'Jadwal tidak ditemukan' }, 404);

    const { error } = await supabase
        .from('mixer_schedules')
        .delete()
        .eq('id', id);

    if (error) return c.json({ error: error.message }, 500);

    // Sync jadwal tersisa ke ESP32
    const mqtt_sent = await syncSchedulesToESP32(existing.device_id);

    return c.json({
        message:   'Jadwal dihapus dan ESP32 disync',
        mqtt_sent,
    });
});

export default app;