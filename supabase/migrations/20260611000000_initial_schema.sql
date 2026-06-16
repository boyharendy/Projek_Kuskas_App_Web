-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS for users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own profile." ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert their own profile." ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile." ON public.users FOR UPDATE USING (auth.uid() = id);

-- CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- null for global categories
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS for categories
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view global or their own categories." ON public.categories FOR SELECT USING (user_id IS NULL OR auth.uid() = user_id);
CREATE POLICY "Users can insert own categories." ON public.categories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own categories." ON public.categories FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own categories." ON public.categories FOR DELETE USING (auth.uid() = user_id);

-- TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  amount DECIMAL(20,2) NOT NULL,
  category_name TEXT NOT NULL,
  description TEXT,
  transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
  payment_method TEXT NOT NULL,
  input_method TEXT NOT NULL CHECK (input_method IN ('manual', 'voice')),
  voice_raw_text TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS for transactions
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own transactions." ON public.transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transactions." ON public.transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own transactions." ON public.transactions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own transactions." ON public.transactions FOR DELETE USING (auth.uid() = user_id);

-- Insert Default Categories
INSERT INTO public.categories (name, icon, type) VALUES
('Konsumsi & Belanja', 'shopping_basket_rounded', 'expense'),
('Tagihan & Kewajiban', 'receipt_long_rounded', 'expense'),
('Transportasi', 'directions_car_rounded', 'expense'),
('Gaya Hidup', 'sports_esports_rounded', 'expense'),
('Kesehatan & Edukasi', 'health_and_safety_rounded', 'expense'),
('Lainnya', 'more_horiz_rounded', 'expense'),
('Penghasilan Utama', 'monetization_on_rounded', 'income'),
('Penghasilan Tambahan', 'add_card_rounded', 'income'),
('Investasi & Lainnya', 'trending_up_rounded', 'income');
