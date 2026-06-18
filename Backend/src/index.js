// src/index.js
import 'dotenv/config';
import { Hono }       from 'hono';
import { cors }       from 'hono/cors';
import { logger }     from 'hono/logger';
import { serve }      from '@hono/node-server';

import sensorRoutes  from './routes/sensors.js';
import alertRoutes   from './routes/alerts.js';
import feedingRoutes from './routes/feeding.js';
import mixerRoutes   from './routes/mixer.js';
import { startMqttClient } from './mqtt/mqttClient.js';

const app  = new Hono();
const PORT = Number(process.env.PORT) || 3000;

// ── Middleware ────────────────────────────────────────────────
app.use('*', cors());
app.use('*', logger());

// ── Health check ──────────────────────────────────────────────
app.get('/health', (c) => {
    return c.json({
        status:  'ok',
        service: 'AquaSense Backend',
        time:    new Date().toISOString(),
    });
});

// ── API Routes ────────────────────────────────────────────────
app.route('/api/sensors', sensorRoutes);
app.route('/api/alerts',  alertRoutes);
app.route('/api/feeding', feedingRoutes);
app.route('/api/mixer',   mixerRoutes);

// ── 404 fallback ──────────────────────────────────────────────
app.notFound((c) => {
    return c.json({ error: `Route ${c.req.method} ${c.req.path} tidak ditemukan` }, 404);
});

// ── Start server ──────────────────────────────────────────────
serve({ fetch: app.fetch, port: PORT }, () => {
    console.log('============================================');
    console.log('  AquaSense Backend — Starting...          ');
    console.log(`  REST API : http://localhost:${PORT}       `);
    console.log('============================================');
});

// ── Start MQTT Client ─────────────────────────────────────────
startMqttClient();