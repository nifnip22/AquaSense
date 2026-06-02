// src/routes/feeding.js
import { Hono } from 'hono';
import { supabase } from '../db/supabase.js';

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

// POST /api/feeding — trigger feeding manual via API
app.post('/', async (c) => {
  const body = await c.req.json();
  const { device_id = 'ESP32-DEVKIT-01', duration_sec, notes } = body;

  const { data, error } = await supabase
    .from('feeding_logs')
    .insert([{
      device_id,
      trigger_type: 'manual',
      duration_sec: duration_sec ?? null,
      notes:        notes        ?? 'Triggered via API',
    }])
    .select()
    .single();

  if (error) return c.json({ error: error.message }, 500);

  // TODO: publish MQTT command ke ESP32
  // mqttClient.publish(`aquasense/${device_id}/command/feed`, JSON.stringify({ duration_sec }));

  return c.json({ message: 'Feeding log created', data }, 201);
});

export default app;
