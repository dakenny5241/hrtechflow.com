-- ═══════════════════════════════════════════════════════════════
-- HRTECHFLOW — MASTER DATABASE MIGRATION
-- Safe to run all at once, and safe to re-run — every line either
-- adds something only if missing, or skips cleanly if it already exists.
-- ═══════════════════════════════════════════════════════════════

-- ── Companies table ──────────────────────────────────────────────
alter table companies add column if not exists currency text default 'NGN';
alter table companies add column if not exists country text default 'Nigeria';
alter table companies add column if not exists referral_source text;

-- ── Users table ──────────────────────────────────────────────────
alter table users add column if not exists must_change_pw boolean default false;
alter table users add column if not exists hotel_role text;

-- ── Hotel bookings ───────────────────────────────────────────────
alter table hotel_bookings add column if not exists group_ref text;
alter table hotel_bookings add column if not exists actual_checkin timestamp with time zone;
alter table hotel_bookings add column if not exists actual_checkout timestamp with time zone;
alter table hotel_bookings add column if not exists guest_dob text;

-- ── Hotel rooms ──────────────────────────────────────────────────
alter table hotel_rooms add column if not exists hk_status text default 'ready';

-- ── Invoices ─────────────────────────────────────────────────────
alter table invoices add column if not exists salesperson text;

-- ── Appointments (Salon/Clinic) ──────────────────────────────────
alter table appointments add column if not exists birthday text;

-- ── Real Estate — tenancy tracking ───────────────────────────────
alter table re_sales add column if not exists tenancy_status text default 'active';
alter table re_sales add column if not exists alert_days integer default 30;
alter table re_sales add column if not exists group_ref text;


-- ═══════════════════════════════════════════════════════════════
-- NEW TABLES — created only if they don't already exist
-- ═══════════════════════════════════════════════════════════════

-- ── Hotel: Guest profiles ────────────────────────────────────────
create table if not exists hotel_guests (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  guest_name text not null,
  guest_contact text,
  visit_count integer default 0,
  first_stay text,
  last_stay text,
  total_spent numeric default 0,
  notes text,
  created_at timestamp with time zone default now()
);
alter table hotel_guests enable row level security;
drop policy if exists "anon_all" on hotel_guests;
create policy "anon_all" on hotel_guests for all to anon using (true) with check (true);

-- ── Hotel: POS sales (restaurant/bar) ────────────────────────────
create table if not exists hotel_pos_sales (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  receipt_number text,
  department text default 'restaurant',
  customer_name text default 'Walk-in',
  items jsonb default '[]',
  subtotal numeric default 0,
  vat_amount numeric default 0,
  total numeric default 0,
  cashier text,
  created_at timestamp with time zone default now()
);
alter table hotel_pos_sales enable row level security;
drop policy if exists "anon_all" on hotel_pos_sales;
create policy "anon_all" on hotel_pos_sales for all to anon using (true) with check (true);

-- ── Hotel: Kitchen/Bar stock ──────────────────────────────────────
create table if not exists hotel_stock (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  stock_type text default 'kitchen',
  name text not null,
  unit text default 'pieces',
  os numeric default 0,
  ns numeric default 0,
  qs numeric default 0,
  bd numeric default 0,
  unit_cost numeric default 0,
  selling_price numeric default 0,
  reorder_level numeric default 3,
  category text,
  created_at timestamp with time zone default now()
);
alter table hotel_stock enable row level security;
drop policy if exists "anon_all" on hotel_stock;
create policy "anon_all" on hotel_stock for all to anon using (true) with check (true);

-- ── Hotel: General inventory ──────────────────────────────────────
create table if not exists hotel_inventory (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  name text not null,
  department text default 'general',
  quantity integer default 0,
  unit text default 'pieces',
  updated_at timestamp with time zone default now(),
  created_at timestamp with time zone default now()
);
alter table hotel_inventory enable row level security;
drop policy if exists "anon_all" on hotel_inventory;
create policy "anon_all" on hotel_inventory for all to anon using (true) with check (true);

-- ── Salon/Clinic: Treatments ───────────────────────────────────────
create table if not exists clinic_treatments (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  client_name text not null,
  treatment text,
  practitioner text,
  notes text,
  next_visit text,
  amount numeric default 0,
  date text,
  created_at timestamp with time zone default now()
);
alter table clinic_treatments enable row level security;
drop policy if exists "anon_all" on clinic_treatments;
create policy "anon_all" on clinic_treatments for all to anon using (true) with check (true);

-- ── Real Estate: Properties ────────────────────────────────────────
create table if not exists re_properties (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  title text not null,
  property_type text,
  address text,
  state text,
  listing_type text default 'sale',
  price numeric default 0,
  sqm numeric default 0,
  bedrooms text,
  bathrooms text,
  title_document text,
  agent text,
  features text,
  description text,
  commission_rate numeric default 5,
  date_listed text,
  status text default 'Available',
  created_at timestamp with time zone default now()
);
alter table re_properties enable row level security;
drop policy if exists "anon_all" on re_properties;
create policy "anon_all" on re_properties for all to anon using (true) with check (true);

-- ── Real Estate: Sales / Lettings ───────────────────────────────────
create table if not exists re_sales (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  ref_number text,
  property_id uuid,
  property_name text,
  client_name text not null,
  client_phone text,
  client_email text,
  trans_type text default 'sale',
  price numeric default 0,
  sqm numeric default 0,
  agent text,
  commission_rate numeric default 5,
  commission_amt numeric default 0,
  commission_paid boolean default false,
  payment_status text default 'part',
  amount_paid numeric default 0,
  transaction_date text,
  completion_date text,
  notes text,
  tenancy_status text default 'active',
  alert_days integer default 30,
  group_ref text,
  created_at timestamp with time zone default now()
);
alter table re_sales enable row level security;
drop policy if exists "anon_all" on re_sales;
create policy "anon_all" on re_sales for all to anon using (true) with check (true);

-- ── Real Estate: Clients ──────────────────────────────────────────
create table if not exists re_clients (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  name text not null,
  phone text,
  email text,
  client_type text default 'buyer',
  budget numeric default 0,
  preferred_location text,
  property_interest text,
  source text,
  status text default 'Hot Lead',
  created_at timestamp with time zone default now()
);
alter table re_clients enable row level security;
drop policy if exists "anon_all" on re_clients;
create policy "anon_all" on re_clients for all to anon using (true) with check (true);

-- ── Real Estate: Agents ───────────────────────────────────────────
create table if not exists re_agents (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  name text not null,
  phone text,
  email text,
  commission_rate numeric default 5,
  bank text,
  account text,
  created_at timestamp with time zone default now()
);
alter table re_agents enable row level security;
drop policy if exists "anon_all" on re_agents;
create policy "anon_all" on re_agents for all to anon using (true) with check (true);

-- ── Real Estate: Documents ────────────────────────────────────────
create table if not exists re_documents (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  property_id uuid,
  doc_type text,
  doc_number text,
  date_issued text,
  expiry_date text,
  status text default 'available',
  notes text,
  created_at timestamp with time zone default now()
);
alter table re_documents enable row level security;
drop policy if exists "anon_all" on re_documents;
create policy "anon_all" on re_documents for all to anon using (true) with check (true);

-- ── Hotel: Debtors (guests who checked out owing money) ────────────
create table if not exists hotel_debtors (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  guest_name text not null,
  guest_phone text,
  guest_dob text,
  amount_owed numeric default 0,
  room_number text,
  checkout_date text,
  status text default 'owing',
  notes text,
  created_at timestamp with time zone default now()
);
alter table hotel_debtors enable row level security;
drop policy if exists "anon_all" on hotel_debtors;
create policy "anon_all" on hotel_debtors for all to anon using (true) with check (true);

-- ── Hotel: Payments (record payments as they happen — daily, ──────
-- ── on arrival, or at checkout) ────────────────────────────────────
create table if not exists hotel_payments (
  id uuid default gen_random_uuid() primary key,
  company_id uuid references companies(id) on delete cascade,
  booking_id uuid,
  room_number text,
  guest_name text,
  amount numeric default 0,
  method text default 'cash',
  recorded_by text,
  notes text,
  created_at timestamp with time zone default now()
);
alter table hotel_payments enable row level security;
drop policy if exists "anon_all" on hotel_payments;
create policy "anon_all" on hotel_payments for all to anon using (true) with check (true);


-- ═══════════════════════════════════════════════════════════════
-- DONE. Run the verification query below to confirm everything
-- landed correctly.
-- ═══════════════════════════════════════════════════════════════

select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'hotel_guests','hotel_pos_sales','hotel_stock','hotel_inventory',
    'clinic_treatments','re_properties','re_sales','re_clients',
    're_agents','re_documents','hotel_debtors','hotel_payments'
  )
order by table_name;
