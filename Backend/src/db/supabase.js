// src/db/supabase.js
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const supabaseUrl  = process.env.SUPABASE_URL;
const supabaseKey  = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('[Supabase] SUPABASE_URL atau SUPABASE_SERVICE_ROLE_KEY belum di-set di .env');
}

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: { persistSession: false }
});

console.log('[Supabase] Client initialized.');
