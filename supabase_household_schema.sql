create table if not exists public.nsp_household_records (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  record_type text not null check (record_type in ('expense', 'income')),
  record_date date not null,
  category text not null,
  title text not null,
  amount numeric not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.nsp_household_budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  month_key text not null,
  monthly_budget numeric not null default 0,
  category_budgets jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_id, month_key)
);

create table if not exists public.nsp_household_fixed_costs (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  amount numeric not null,
  category text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.nsp_household_shopping_items (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  amount numeric,
  category text not null,
  store_name text,
  store_label text,
  source_discount_id text,
  checked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.nsp_household_recurring_items (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  frequency_days integer not null default 30 check (frequency_days > 0),
  estimated_amount numeric,
  last_purchased_date date not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.nsp_household_recurring_items
  add column if not exists estimated_amount numeric;

alter table public.nsp_household_records enable row level security;
alter table public.nsp_household_budgets enable row level security;
alter table public.nsp_household_fixed_costs enable row level security;
alter table public.nsp_household_shopping_items enable row level security;
alter table public.nsp_household_recurring_items enable row level security;

drop policy if exists "nsp users can read own household records" on public.nsp_household_records;
drop policy if exists "nsp users can insert own household records" on public.nsp_household_records;
drop policy if exists "nsp users can update own household records" on public.nsp_household_records;
drop policy if exists "nsp users can delete own household records" on public.nsp_household_records;

create policy "nsp users can read own household records"
  on public.nsp_household_records
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "nsp users can insert own household records"
  on public.nsp_household_records
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "nsp users can update own household records"
  on public.nsp_household_records
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "nsp users can delete own household records"
  on public.nsp_household_records
  for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "nsp users can read own household budgets" on public.nsp_household_budgets;
drop policy if exists "nsp users can insert own household budgets" on public.nsp_household_budgets;
drop policy if exists "nsp users can update own household budgets" on public.nsp_household_budgets;
drop policy if exists "nsp users can delete own household budgets" on public.nsp_household_budgets;

create policy "nsp users can read own household budgets"
  on public.nsp_household_budgets
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "nsp users can insert own household budgets"
  on public.nsp_household_budgets
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "nsp users can update own household budgets"
  on public.nsp_household_budgets
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "nsp users can delete own household budgets"
  on public.nsp_household_budgets
  for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "nsp users can read own fixed costs" on public.nsp_household_fixed_costs;
drop policy if exists "nsp users can insert own fixed costs" on public.nsp_household_fixed_costs;
drop policy if exists "nsp users can update own fixed costs" on public.nsp_household_fixed_costs;
drop policy if exists "nsp users can delete own fixed costs" on public.nsp_household_fixed_costs;

create policy "nsp users can read own fixed costs"
  on public.nsp_household_fixed_costs
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "nsp users can insert own fixed costs"
  on public.nsp_household_fixed_costs
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "nsp users can update own fixed costs"
  on public.nsp_household_fixed_costs
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "nsp users can delete own fixed costs"
  on public.nsp_household_fixed_costs
  for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "nsp users can read own shopping items" on public.nsp_household_shopping_items;
drop policy if exists "nsp users can insert own shopping items" on public.nsp_household_shopping_items;
drop policy if exists "nsp users can update own shopping items" on public.nsp_household_shopping_items;
drop policy if exists "nsp users can delete own shopping items" on public.nsp_household_shopping_items;

create policy "nsp users can read own shopping items"
  on public.nsp_household_shopping_items
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "nsp users can insert own shopping items"
  on public.nsp_household_shopping_items
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "nsp users can update own shopping items"
  on public.nsp_household_shopping_items
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "nsp users can delete own shopping items"
  on public.nsp_household_shopping_items
  for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "nsp users can read own recurring items" on public.nsp_household_recurring_items;
drop policy if exists "nsp users can insert own recurring items" on public.nsp_household_recurring_items;
drop policy if exists "nsp users can update own recurring items" on public.nsp_household_recurring_items;
drop policy if exists "nsp users can delete own recurring items" on public.nsp_household_recurring_items;

create policy "nsp users can read own recurring items"
  on public.nsp_household_recurring_items
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "nsp users can insert own recurring items"
  on public.nsp_household_recurring_items
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "nsp users can update own recurring items"
  on public.nsp_household_recurring_items
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "nsp users can delete own recurring items"
  on public.nsp_household_recurring_items
  for delete
  to authenticated
  using (auth.uid() = user_id);

create index if not exists nsp_household_records_user_date_idx
  on public.nsp_household_records (user_id, record_date desc);

create index if not exists nsp_household_budgets_user_month_idx
  on public.nsp_household_budgets (user_id, month_key);

create index if not exists nsp_household_fixed_costs_user_idx
  on public.nsp_household_fixed_costs (user_id, created_at desc);

create index if not exists nsp_household_shopping_items_user_idx
  on public.nsp_household_shopping_items (user_id, created_at desc);

create index if not exists nsp_household_recurring_items_user_idx
  on public.nsp_household_recurring_items (user_id, last_purchased_date desc);

create or replace function public.set_nsp_household_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_nsp_household_records_updated_at on public.nsp_household_records;
create trigger set_nsp_household_records_updated_at
before update on public.nsp_household_records
for each row
execute function public.set_nsp_household_updated_at();

drop trigger if exists set_nsp_household_budgets_updated_at on public.nsp_household_budgets;
create trigger set_nsp_household_budgets_updated_at
before update on public.nsp_household_budgets
for each row
execute function public.set_nsp_household_updated_at();

drop trigger if exists set_nsp_household_fixed_costs_updated_at on public.nsp_household_fixed_costs;
create trigger set_nsp_household_fixed_costs_updated_at
before update on public.nsp_household_fixed_costs
for each row
execute function public.set_nsp_household_updated_at();

drop trigger if exists set_nsp_household_shopping_items_updated_at on public.nsp_household_shopping_items;
create trigger set_nsp_household_shopping_items_updated_at
before update on public.nsp_household_shopping_items
for each row
execute function public.set_nsp_household_updated_at();

drop trigger if exists set_nsp_household_recurring_items_updated_at on public.nsp_household_recurring_items;
create trigger set_nsp_household_recurring_items_updated_at
before update on public.nsp_household_recurring_items
for each row
execute function public.set_nsp_household_updated_at();

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.nsp_household_records to authenticated;
grant select, insert, update, delete on public.nsp_household_budgets to authenticated;
grant select, insert, update, delete on public.nsp_household_fixed_costs to authenticated;
grant select, insert, update, delete on public.nsp_household_shopping_items to authenticated;
grant select, insert, update, delete on public.nsp_household_recurring_items to authenticated;
