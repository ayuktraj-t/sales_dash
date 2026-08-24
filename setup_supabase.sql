-- ============================================================
-- VOYX DASHBOARD - COMPLETE SUPABASE DATABASE SETUP SCRIPT (v2)
-- Copy & Run this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/pcenxwfhavneypapwbxi/sql/new
--
-- CHANGE FROM v1: added the `sales_dash` schema with `orders` and
-- `users` tables, because get_sales_dashboard() queries
-- sales_dash.orders / sales_dash.users, not the public.* tables.
-- The public.* tables below are left in place in case other parts
-- of the dashboard read from them directly, but the RPC function
-- now has real source tables to query.
-- ============================================================

-- Enable UUID extension just in case
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- SCHEMA: sales_dash  (source tables used by get_sales_dashboard)
-- ============================================================
CREATE SCHEMA IF NOT EXISTS sales_dash;

-- ------------------------------------------------------------
-- sales_dash.users
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales_dash.users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE sales_dash.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public select users" ON sales_dash.users;
CREATE POLICY "Allow public select users" ON sales_dash.users FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert users" ON sales_dash.users;
CREATE POLICY "Allow public insert users" ON sales_dash.users FOR INSERT WITH CHECK (true);

INSERT INTO sales_dash.users (name) VALUES
('Faizan'),
('Talha'),
('Bhageshri'),
('Nidhi'),
('Sanika'),
('Prabhat'),
('Farooq')
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- sales_dash.orders
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales_dash.orders (
    order_id SERIAL PRIMARY KEY,
    order_date_time TIMESTAMP WITH TIME ZONE NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    discount_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    created_by INT NOT NULL REFERENCES sales_dash.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE sales_dash.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public select orders" ON sales_dash.orders;
CREATE POLICY "Allow public select orders" ON sales_dash.orders FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert orders" ON sales_dash.orders;
CREATE POLICY "Allow public insert orders" ON sales_dash.orders FOR INSERT WITH CHECK (true);

-- Seed ~4 months of sample orders (Feb 2026 - May 2026) spread
-- across reps, so MTD / prev-month / prev-month-same-day filters
-- in the function all have data to return when report_date is
-- e.g. '2026-05-17'.
INSERT INTO sales_dash.orders (order_date_time, amount, discount_amount, created_by)
SELECT
    ts,
    round((random() * 400 + 50)::numeric, 2)               AS amount,
    round((random() * 20)::numeric, 2)                     AS discount_amount,
    (SELECT user_id FROM sales_dash.users ORDER BY random() LIMIT 1) AS created_by
FROM generate_series(
    TIMESTAMP '2026-02-01 09:00:00',
    TIMESTAMP '2026-05-17 18:00:00',
    interval '6 hours'
) AS ts;

-- ------------------------------------------------------------
-- Grant schema usage to the API roles (required so PostgREST /
-- the RPC function can read sales_dash tables at all)
-- ------------------------------------------------------------
GRANT USAGE ON SCHEMA sales_dash TO anon, authenticated, service_role;
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA sales_dash TO anon, authenticated, service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA sales_dash TO anon, authenticated, service_role;


-- ============================================================
-- SCHEMA: public  (unchanged from v1 - kept for any widgets that
-- read directly from these summary tables)
-- ============================================================

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


-- ============================================================
-- FUNCTION: get_sales_dashboard(report_date date)
-- NOTE: parameter is `report_date`, not `report_data`.
-- Update your frontend .rpc() call to use this exact key name.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_sales_dashboard(report_date date)
RETURNS TABLE (
    daily_matrix json,
    month_matrix json,
    kpi_matrix json,
    leaderboard_matrix json
)
LANGUAGE plpgsql
AS $$
begin
return query
with base as(
  select u.name as sales_rep,
   o.order_date_time::date as order_date,
   (o.amount - o.discount_amount) as revenue
  from sales_dash.orders as o join sales_dash.users as u
  on o.created_by = u.user_id
  where o.order_date_time between date_trunc('month', report_date - interval '1 month')
  and report_date
),
daily_summary as(
  select order_date, count(*) as no_of_sales,
   sum(revenue) as total_revenue
  from base
  where order_date >= date_trunc('month', report_date)
  group by 1
  order by 1
),
month_summary as (
  select extract(year from order_date_time) as year,
   extract(month from order_date_time) as month,
   count(*) as no_of_sales
  from sales_dash.orders
  group by 1,2
  order by 1,2
),
kpi_matrix as(
  select
  count(*) filter(where order_date = report_date) as today_sales,
  sum(revenue) filter(where order_date = report_date) as today_revenue,
  count(*) filter(where order_date >= date_trunc('month', report_date)) as mtd_sales,
  sum(revenue) filter(where order_date >= date_trunc('month', report_date)) as mtd_revenue,
  count(*) filter(where order_date >= date_trunc('month', report_date - interval '1 month')::date) as prev_mon_same_day_sales,
  sum(revenue) filter(where order_date >= date_trunc('month', report_date - interval '1 month')::date) as prev_mon_same_day_revenue,
  count(*) filter(where order_date < date_trunc('month', report_date)) as prev_mon_sales,
  sum(revenue) filter(where order_date < date_trunc('month', report_date)) as prev_mon_revenue
  from base
),
leaderboard as(
  select ms.sales_rep, mtd_sales, mtd_revenue, td_sales, td_revenue
  from
  (select sales_rep, count(*) as mtd_sales, sum(revenue) as mtd_revenue
  from base where order_date >= date_trunc('month', report_date)
  group by 1) as ms
  left join
  (select sales_rep, count(*) as td_sales, sum(revenue) as td_revenue
  from base where order_date = report_date
  group by 1) as ts
  on ts.sales_rep = ms.sales_rep
  order by ms.mtd_sales desc
)
select
(select json_agg(to_jsonb(d)) from daily_summary d) as daily_matrix,
(select json_agg(to_jsonb(m)) from month_summary m) as month_matrix,
(select json_agg(to_jsonb(k)) from kpi_matrix k) as kpi_matrix,
(select json_agg(to_jsonb(l)) from leaderboard l) as leaderboard_matrix;
end;
$$;

-- Expose the function to the API roles
GRANT EXECUTE ON FUNCTION public.get_sales_dashboard(date) TO anon, authenticated, service_role;

-- Refresh PostgREST's schema cache so the new/updated function
-- is picked up immediately instead of waiting for the next auto-scan
NOTIFY pgrst, 'reload schema';
