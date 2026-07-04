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

alter table public.nsp_household_records enable row level security;
alter table public.nsp_household_budgets enable row level security;

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

create index if not exists nsp_household_records_user_date_idx
  on public.nsp_household_records (user_id, record_date desc);

create index if not exists nsp_household_budgets_user_month_idx
  on public.nsp_household_budgets (user_id, month_key);

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

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.nsp_household_records to authenticated;
grant select, insert, update, delete on public.nsp_household_budgets to authenticated;
