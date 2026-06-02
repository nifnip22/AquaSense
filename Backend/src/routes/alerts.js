// src/routes/alerts.js
import { Hono } from 'hono';
import { supabase } from '../db/supabase.js';

const app = new Hono();

// GET /api/alerts?resolved=false&limit=20
app.get('/', async (c) => {
  const resolved  = c.req.query('resolved');
  const device_id = c.req.query('device_id');
  const limit     = Math.min(parseInt(c.req.query('limit') ?? '20'), 200);

  let query = supabase
    .from('alerts')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);

  if (resolved  !== undefined) query = query.eq('resolved', resolved === 'true');
  if (device_id)               query = query.eq('device_id', device_id);

  const { data, error } = await query;
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ count: data.length, data });
});

// PATCH /api/alerts/:id/resolve
app.patch('/:id/resolve', async (c) => {
  const id = c.req.param('id');

  const { data, error } = await supabase
    .from('alerts')
    .update({ resolved: true, resolved_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single();

  if (error) return c.json({ error: error.message }, 500);
  return c.json({ message: 'Alert resolved', data });
});

export default app;
