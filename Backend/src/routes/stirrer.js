// src/routes/stirrer.js
import { Hono } from 'hono';
import { publishStirCommand } from '../mqtt/mqttClient.js';
import { validateStirSchedule } from '../services/thresholds.js';

const app = new Hono();

// ─────────────────────────────────────────────────────────────
// POST /api/stirrer/schedule
// Update jadwal pengadukan pakan ke ESP32.
//
// Body: { "device_id": "ESP32-DEVKIT-01", "interval_min": 30, "duration_sec": 10 }
//
// ESP32 akan menyimpan jadwal baru ke NVS (Preferences) sehingga
// bertahan setelah restart.
// ─────────────────────────────────────────────────────────────
app.post('/schedule', async (c) => {
    const body         = await c.req.json();
    const device_id    = body.device_id    ?? 'ESP32-DEVKIT-01';
    const interval_min = parseInt(body.interval_min);
    const duration_sec = parseInt(body.duration_sec);

    const validation = validateStirSchedule(interval_min, duration_sec);
    if (!validation.valid) {
        return c.json({ error: validation.reason }, 400);
    }

    const payload    = { mode: 'schedule', interval_min, duration_sec };
    const mqtt_sent  = publishStirCommand(device_id, payload);

    return c.json({
        message:   'Stirrer schedule command sent',
        mqtt_sent,
        payload,
        device_id,
    });
});

// ─────────────────────────────────────────────────────────────
// POST /api/stirrer/manual
// Kontrol manual motor pengaduk dari app.
//
// Body: { "device_id": "ESP32-DEVKIT-01", "action": "on" | "off" }
// ─────────────────────────────────────────────────────────────
app.post('/manual', async (c) => {
    const body      = await c.req.json();
    const device_id = body.device_id ?? 'ESP32-DEVKIT-01';
    const action    = body.action;

    if (!['on', 'off'].includes(action)) {
        return c.json({ error: 'action harus "on" atau "off"' }, 400);
    }

    const payload   = { mode: 'manual', action };
    const mqtt_sent = publishStirCommand(device_id, payload);

    return c.json({
        message:   `Stirrer ${action} command sent`,
        mqtt_sent,
        payload,
        device_id,
    });
});

export default app;