// src/routes/sensors.js
import { Hono } from 'hono';
import { supabase } from '../db/supabase.js';

const app = new Hono();

// ─────────────────────────────────────────────────────────────
// GET /api/sensors/latest
// Data terbaru per device (dari view latest_readings)
// ─────────────────────────────────────────────────────────────
app.get('/latest', async (c) => {
    const { data, error } = await supabase
        .from('latest_readings')
        .select('*');

    if (error) return c.json({ error: error.message }, 500);
    return c.json({ data });
});

// ─────────────────────────────────────────────────────────────
// GET /api/sensors/history?device_id=&limit=50&from=&to=
// Riwayat pembacaan sensor dengan filter opsional
// ─────────────────────────────────────────────────────────────
app.get('/history', async (c) => {
    const device_id = c.req.query('device_id');
    const limit     = Math.min(parseInt(c.req.query('limit') ?? '50'), 1000);
    const from      = c.req.query('from');
    const to        = c.req.query('to');

    let query = supabase
        .from('sensor_readings')
        .select('*')
        .order('recorded_at', { ascending: false })
        .limit(limit);

    if (device_id) query = query.eq('device_id', device_id);
    if (from)      query = query.gte('recorded_at', from);
    if (to)        query = query.lte('recorded_at', to);

    const { data, error } = await query;
    if (error) return c.json({ error: error.message }, 500);
    return c.json({ count: data.length, data });
});

// ─────────────────────────────────────────────────────────────
// GET /api/sensors/stats?device_id=&period=1h|6h|24h|7d
// Statistik min/max/avg per periode untuk semua sensor
// ─────────────────────────────────────────────────────────────
app.get('/stats', async (c) => {
    const device_id = c.req.query('device_id') ?? 'ESP32-DEVKIT-01';
    const period    = c.req.query('period')    ?? '24h';

    const periodMap = { '1h': 1, '6h': 6, '24h': 24, '7d': 168 };
    const hours     = periodMap[period] ?? 24;
    const from      = new Date(Date.now() - hours * 60 * 60 * 1000).toISOString();

    // ✅ Gunakan turbidity_filtered, hapus stir_interval_min & stir_duration_sec
    // (kolom stirrer sudah tidak ada di sensor_readings)
    const { data, error } = await supabase
        .from('sensor_readings')
        .select('temperature, ph, turbidity_filtered, feed_level_pct, mixer_on, mixer_remaining_sec')
        .eq('device_id', device_id)
        .gte('recorded_at', from);

    if (error) return c.json({ error: error.message }, 500);
    if (!data.length) return c.json({ period, device_id, count: 0, stats: null });

    // Helper: hitung min/max/avg dari array objek per key
    const calc = (arr, key) => {
        const vals = arr.map(r => r[key]).filter(v => v !== null && v !== undefined);
        if (!vals.length) return null;
        return {
            min:   +Math.min(...vals).toFixed(2),
            max:   +Math.max(...vals).toFixed(2),
            avg:   +(vals.reduce((a, b) => a + b, 0) / vals.length).toFixed(2),
            count: vals.length,
        };
    };

    // Status mixer terkini (ambil record terbaru, bukan avg)
    const latestMixer = [...data].find(r => r.mixer_on !== null);

    return c.json({
        period,
        device_id,
        count: data.length,
        stats: {
            temperature:        calc(data, 'temperature'),
            ph:                 calc(data, 'ph'),
            // ✅ turbidity_filtered menggantikan turbidity_raw
            turbidity_filtered: calc(data, 'turbidity_filtered'),
            feed_level_pct:     calc(data, 'feed_level_pct'),
        },
        // ✅ Snapshot status mixer terkini dalam periode yang dipilih
        mixer_latest: latestMixer ? {
            is_on:         latestMixer.mixer_on,
            remaining_sec: latestMixer.mixer_remaining_sec,
        } : null,
    });
});

export default app;