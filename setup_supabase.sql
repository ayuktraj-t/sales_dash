-- ============================================================
-- VOYX DASHBOARD - COMPLETE SUPABASE DATABASE SETUP SCRIPT
-- Copy & Run this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/pcenxwfhavneypapwbxi/sql/new
-- ============================================================

-- Enable UUID extension just in case
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------
-- 1. TODAY PERFORMANCE TABLE
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.today_performance (
    id SERIAL PRIMARY KEY,
    orders INT NOT NULL DEFAULT 33,
    revenue NUMERIC(10,2) NOT NULL DEFAULT 30.80,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.today_performance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public select today_performance" ON public.today_performance;
CREATE POLICY "Allow public select today_performance" ON public.today_performance FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert today_performance" ON public.today_performance;
CREATE POLICY "Allow public insert today_performance" ON public.today_performance FOR INSERT WITH CHECK (true);

INSERT INTO public.today_performance (orders, revenue) VALUES (33, 30.80);


-- ------------------------------------------------------------
-- 2. STATS OVERVIEW TABLE (June MTD, Prev Month Same Day, Prev Month)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.stats_overview (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    count INT NOT NULL,
    revenue NUMERIC(10,2) NOT NULL,
    icon VARCHAR(50) DEFAULT 'bar-chart'
);

ALTER TABLE public.stats_overview ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public select stats_overview" ON public.stats_overview;
CREATE POLICY "Allow public select stats_overview" ON public.stats_overview FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert stats_overview" ON public.stats_overview;
CREATE POLICY "Allow public insert stats_overview" ON public.stats_overview FOR INSERT WITH CHECK (true);

INSERT INTO public.stats_overview (id, title, count, revenue, icon) VALUES
('june_mtd', 'JUNE MTD', 658, 574.69, 'bar-chart-2'),
('prev_month_sameday', 'PREV MONTH (SAME DAY)', 536, 459.44, 'history'),
('prev_month', 'PREV MONTH', 964, 818.90, 'file-text')
ON CONFLICT (id) DO UPDATE SET count = EXCLUDED.count, revenue = EXCLUDED.revenue;


-- ------------------------------------------------------------
-- 3. LEADERBOARD TABLE
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.leaderboard (
    id SERIAL PRIMARY KEY,
    rank INT NOT NULL,
    sales_rep VARCHAR(100) NOT NULL,
    day_orders INT DEFAULT 0,
    day_rev NUMERIC(10,2) DEFAULT 0,
    mtd_orders INT DEFAULT 0,
    mtd_rev NUMERIC(10,2) DEFAULT 0,
    arpu NUMERIC(10,2) DEFAULT 0,
    target INT DEFAULT 125,
    pv_month INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.leaderboard ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public select leaderboard" ON public.leaderboard;
CREATE POLICY "Allow public select leaderboard" ON public.leaderboard FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert leaderboard" ON public.leaderboard;
CREATE POLICY "Allow public insert leaderboard" ON public.leaderboard FOR INSERT WITH CHECK (true);

INSERT INTO public.leaderboard (rank, sales_rep, day_orders, day_rev, mtd_orders, mtd_rev, arpu, target, pv_month) VALUES
(1, 'Faizan', 10, 9.5, 155, 143.3, 924, 125, 84),
(2, 'Talha', 4, 5.0, 121, 103.7, 857, 125, 44),
(3, 'Bhageshri', 4, 2.5, 119, 94.0, 791, 125, 60),
(4, 'Nidhi', 5, 4.2, 95, 78.8, 829, 125, 50),
(5, 'Sanika', 5, 5.7, 95, 83.3, 877, 125, 54),
(6, 'Prabhat', 3, 2.8, 64, 62.6, 979, 125, 75),
(7, 'Farooq', 2, 1.1, 9, 9.0, 997, 125, 0);


-- ------------------------------------------------------------
-- 4. TOP DESTINATIONS TABLE
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.top_destinations (
    id SERIAL PRIMARY KEY,
    destination VARCHAR(150) NOT NULL,
    bookings INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.top_destinations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public select top_destinations" ON public.top_destinations;
CREATE POLICY "Allow public select top_destinations" ON public.top_destinations FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert top_destinations" ON public.top_destinations;
CREATE POLICY "Allow public insert top_destinations" ON public.top_destinations FOR INSERT WITH CHECK (true);

INSERT INTO public.top_destinations (destination, bookings) VALUES
('Thailand [True]', 231),
('Thailand', 206),
('Singapore, Malaysia', 33),
('Vietnam', 30),
('Singapore, Malaysia, Thailand...', 17),
('Japan', 15),
('Singapore, Malaysia, Indonesia...', 10);


-- ------------------------------------------------------------
-- 5. DAILY SUMMARY TABLE
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.daily_summary (
    id SERIAL PRIMARY KEY,
    day_label VARCHAR(10) NOT NULL,
    orders INT NOT NULL,
    revenue NUMERIC(10,2) NOT NULL
);

ALTER TABLE public.daily_summary ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public select daily_summary" ON public.daily_summary;
CREATE POLICY "Allow public select daily_summary" ON public.daily_summary FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert daily_summary" ON public.daily_summary;
CREATE POLICY "Allow public insert daily_summary" ON public.daily_summary FOR INSERT WITH CHECK (true);

INSERT INTO public.daily_summary (day_label, orders, revenue) VALUES
('01-06', 36, 31.5),
('02-06', 44, 38.2),
('03-06', 35, 29.8),
('04-06', 49, 42.0),
('05-06', 30, 26.5),
('06-06', 32, 28.0),
('07-06', 58, 51.2),
('08-06', 40, 34.8),
('09-06', 38, 33.1),
('10-06', 25, 21.0),
('11-06', 41, 36.4),
('12-06', 24, 20.8),
('13-06', 27, 23.5),
('14-06', 26, 22.9),
('15-06', 54, 48.0),
('16-06', 29, 25.1),
('17-06', 30, 26.0),
('18-06', 33, 30.8);


-- ------------------------------------------------------------
-- 6. MONTHLY SUMMARY TABLE
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.monthly_summary (
    id SERIAL PRIMARY KEY,
    month_label VARCHAR(15) NOT NULL,
    orders INT NOT NULL,
    revenue NUMERIC(10,2) NOT NULL
);

ALTER TABLE public.monthly_summary ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public select monthly_summary" ON public.monthly_summary;
CREATE POLICY "Allow public select monthly_summary" ON public.monthly_summary FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert monthly_summary" ON public.monthly_summary;
CREATE POLICY "Allow public insert monthly_summary" ON public.monthly_summary FOR INSERT WITH CHECK (true);

INSERT INTO public.monthly_summary (month_label, orders, revenue) VALUES
('Nov 25', 45, 38.5),
('Dec 25', 180, 155.0),
('Jan 26', 320, 275.4),
('Feb 26', 410, 360.0),
('Mar 26', 530, 465.8),
('Apr 26', 680, 595.0),
('May 26', 964, 818.9),
('Jun 26', 658, 574.69);


-- ------------------------------------------------------------
-- 7. WALLET SUMMARY TABLE
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.wallet_summary (
    id SERIAL PRIMARY KEY,
    account_balance NUMERIC(12,2) NOT NULL,
    pending_payouts NUMERIC(12,2) NOT NULL,
    total_withdrawn NUMERIC(12,2) NOT NULL
);

ALTER TABLE public.wallet_summary ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public select wallet_summary" ON public.wallet_summary;
CREATE POLICY "Allow public select wallet_summary" ON public.wallet_summary FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert wallet_summary" ON public.wallet_summary;
CREATE POLICY "Allow public insert wallet_summary" ON public.wallet_summary FOR INSERT WITH CHECK (true);

INSERT INTO public.wallet_summary (account_balance, pending_payouts, total_withdrawn) VALUES
(248950.00, 32450.00, 1850000.00);

-- Notify schema reload
NOTIFY pgrst, 'reload schema';
