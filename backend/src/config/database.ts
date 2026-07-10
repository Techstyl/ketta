import { Pool } from 'pg';
import { config } from './env';

export const pool = new Pool({
  connectionString: config.databaseUrl,
  ssl: config.databaseUrl.includes('supabase')
    ? { rejectUnauthorized: false }
    : undefined,
});

export async function initDatabase() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        username TEXT UNIQUE NOT NULL,
        full_name TEXT,
        phone TEXT,
        location TEXT,
        user_type TEXT NOT NULL CHECK (user_type IN ('farmer', 'buyer', 'admin')),
        profile_image TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT NOT NULL DEFAULT '';
      ALTER TABLE users ALTER COLUMN id SET DEFAULT gen_random_uuid();
      ALTER TABLE users DROP CONSTRAINT IF EXISTS users_id_fkey;

      CREATE TABLE IF NOT EXISTS categories (
        id SERIAL PRIMARY KEY,
        name_am TEXT NOT NULL,
        name_en TEXT NOT NULL,
        icon TEXT DEFAULT 'grass',
        parent_id INTEGER REFERENCES categories(id)
      );

      CREATE TABLE IF NOT EXISTS products (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        farmer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        category_id INTEGER REFERENCES categories(id),
        title TEXT NOT NULL,
        description TEXT,
        quantity NUMERIC NOT NULL,
        unit TEXT DEFAULT 'Quintal',
        price NUMERIC NOT NULL,
        location TEXT NOT NULL,
        images TEXT[] DEFAULT '{}',
        status TEXT DEFAULT 'active' CHECK (status IN ('active', 'sold', 'draft', 'out_of_stock')),
        payment_methods TEXT[] DEFAULT '{}',
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS conversations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        product_title TEXT,
        buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        buyer_name TEXT,
        farmer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        farmer_name TEXT,
        last_message TEXT,
        last_message_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS messages (
        id BIGSERIAL PRIMARY KEY,
        conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
        sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        image_url TEXT,
        type TEXT DEFAULT 'text' CHECK (type IN ('text', 'image', 'system')),
        read_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS favorites (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        PRIMARY KEY (user_id, product_id)
      );

      CREATE TABLE IF NOT EXISTS reviews (
        id BIGSERIAL PRIMARY KEY,
        from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        product_id UUID REFERENCES products(id) ON DELETE SET NULL,
        rating INTEGER CHECK (rating >= 1 AND rating <= 5),
        comment TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        message TEXT,
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );

      ALTER TABLE products ALTER COLUMN id SET DEFAULT gen_random_uuid();
      ALTER TABLE products ADD COLUMN IF NOT EXISTS payment_methods TEXT[] DEFAULT '{}';
      ALTER TABLE conversations ALTER COLUMN id SET DEFAULT gen_random_uuid();

      INSERT INTO categories (name_am, name_en, icon) VALUES
        ('ጤፍ', 'Teff', 'grass'),
        ('በቆሎ', 'Maize', 'grass'),
        ('ስንዴ', 'Wheat', 'grass'),
        ('ቡና', 'Coffee', 'coffee'),
        ('አተር', 'Beans', 'eco'),
        ('ሌላ', 'Other', 'more_horiz')
      ON CONFLICT DO NOTHING;
    `);
    console.log('Database tables initialized');
  } finally {
    client.release();
  }
}
