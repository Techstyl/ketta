-- ቀጥታ (KeTta) - Farmer to Buyer Marketplace
-- Run this SQL in your Supabase SQL Editor

-- 1. Users table (extends Supabase Auth)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone TEXT,
  location TEXT,
  user_type TEXT NOT NULL CHECK (user_type IN ('farmer', 'buyer', 'admin')),
  profile_image TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Categories table
CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name_am TEXT NOT NULL,
  name_en TEXT NOT NULL,
  icon TEXT DEFAULT 'grass',
  parent_id INTEGER REFERENCES categories(id)
);

-- 3. Products table
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id INTEGER REFERENCES categories(id),
  title TEXT NOT NULL,
  description TEXT,
  quantity NUMERIC NOT NULL,
  unit TEXT DEFAULT 'ኪንታል',
  price NUMERIC NOT NULL,
  location TEXT NOT NULL,
  images TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'sold', 'draft')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Conversations table
CREATE TABLE conversations (
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

-- 5. Messages table
CREATE TABLE messages (
  id BIGSERIAL PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  type TEXT DEFAULT 'text' CHECK (type IN ('text', 'image', 'system')),
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Favorites table
CREATE TABLE favorites (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, product_id)
);

-- 7. Reviews table
CREATE TABLE reviews (
  id BIGSERIAL PRIMARY KEY,
  from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. App settings table (for admin panel)
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  message TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_products_farmer ON products(farmer_id);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_created ON products(created_at DESC);
CREATE INDEX idx_conversations_buyer ON conversations(buyer_id);
CREATE INDEX idx_conversations_farmer ON conversations(farmer_id);
CREATE INDEX idx_conversations_product ON conversations(product_id);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created ON messages(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users: can read all users, update own profile
CREATE POLICY "Users are viewable by everyone" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Products: anyone can read active, farmers can manage own
CREATE POLICY "Products are viewable by everyone" ON products FOR SELECT USING (true);
CREATE POLICY "Farmers can insert own products" ON products FOR INSERT WITH CHECK (auth.uid() = farmer_id);
CREATE POLICY "Farmers can update own products" ON products FOR UPDATE USING (auth.uid() = farmer_id);
CREATE POLICY "Farmers can delete own products" ON products FOR DELETE USING (auth.uid() = farmer_id);

-- Conversations: participants can read
CREATE POLICY "Conversations viewable by participants" ON conversations
  FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = farmer_id);
CREATE POLICY "Conversations insertable by buyers" ON conversations
  FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- Messages: participants can read and insert
CREATE POLICY "Messages viewable by conversation participants" ON messages
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM conversations WHERE id = conversation_id AND (buyer_id = auth.uid() OR farmer_id = auth.uid()))
  );
CREATE POLICY "Messages insertable by conversation participants" ON messages
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM conversations WHERE id = conversation_id AND (buyer_id = auth.uid() OR farmer_id = auth.uid()))
  );

-- Favorites: users can manage own
CREATE POLICY "Favorites viewable by everyone" ON favorites FOR SELECT USING (true);
CREATE POLICY "Favorites insertable by own" ON favorites FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Favorites deletable by own" ON favorites FOR DELETE USING (auth.uid() = user_id);

-- App settings: only admins can manage
CREATE POLICY "App settings viewable by everyone" ON app_settings FOR SELECT USING (true);
CREATE POLICY "App settings manageable by admins" ON app_settings FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND user_type = 'admin')
);

-- Enable Supabase Realtime for chat
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE app_settings;

-- Seed categories
INSERT INTO categories (name_am, name_en, icon) VALUES
  ('ጤፍ', 'Teff', 'grass'),
  ('በቆሎ', 'Maize', 'grass'),
  ('ስንዴ', 'Wheat', 'grass'),
  ('ቡና', 'Coffee', 'coffee'),
  ('አተር', 'Beans', 'eco'),
  ('ሌላ', 'Other', 'more_horiz');

-- Create admin user trigger
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, username, user_type)
  VALUES (
    NEW.id,
    SPLIT_PART(NEW.email, '@', 1),
    CASE
      WHEN SPLIT_PART(NEW.email, '@', 1) = 'admin' THEN 'admin'
      ELSE 'buyer'
    END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile on signup
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
