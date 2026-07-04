create extension if not exists pgcrypto;

create table if not exists public.nsp_user_discounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  store_id text not null,
  store_name text not null,
  store_label text,
  origin_label text,
  store_type text not null,
  item_name text not null,
  price numeric not null,
  sale_mode text not null default 'once',
  sale_date date,
  sale_weekday integer,
  sale_weekdays text,
  sale_month_day integer,
  sale_month_days text,
  sale_end_date date,
  note text,
  shared_enabled boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.nsp_user_discounts
  add column if not exists store_label text,
  add column if not exists origin_label text,
  add column if not exists sale_weekdays text,
  add column if not exists sale_month_days text,
  add column if not exists sale_end_date date,
  add column if not exists shared_enabled boolean not null default false;

create index if not exists nsp_user_discounts_user_created_idx
  on public.nsp_user_discounts (user_id, created_at desc);

create index if not exists nsp_user_discounts_store_idx
  on public.nsp_user_discounts (store_id);

create index if not exists nsp_user_discounts_shared_store_idx
  on public.nsp_user_discounts (store_id, shared_enabled)
  where shared_enabled = true;

create or replace function public.nsp_user_has_discount_for_store(target_store_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.nsp_user_discounts own_discount
    where own_discount.user_id = auth.uid()
      and own_discount.store_id = target_store_id
  );
$$;

revoke all on function public.nsp_user_has_discount_for_store(text) from public;
grant execute on function public.nsp_user_has_discount_for_store(text) to authenticated;

alter table public.nsp_user_discounts enable row level security;

drop policy if exists "nsp users can read own discounts" on public.nsp_user_discounts;
drop policy if exists "nsp users can insert own discounts" on public.nsp_user_discounts;
drop policy if exists "nsp users can update own discounts" on public.nsp_user_discounts;
drop policy if exists "nsp users can delete own discounts" on public.nsp_user_discounts;

create policy "nsp users can read own discounts"
  on public.nsp_user_discounts
  for select
  to authenticated
  using (
    auth.uid() = user_id
    or (
      shared_enabled = true
      and public.nsp_user_has_discount_for_store(store_id)
    )
  );

create policy "nsp users can insert own discounts"
  on public.nsp_user_discounts
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "nsp users can update own discounts"
  on public.nsp_user_discounts
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "nsp users can delete own discounts"
  on public.nsp_user_discounts
  for delete
  to authenticated
  using (auth.uid() = user_id);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.nsp_user_discounts to authenticated;

create table if not exists public.nsp_user_discount_share_hides (
  user_id uuid not null references auth.users(id) on delete cascade,
  discount_id uuid not null references public.nsp_user_discounts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, discount_id)
);

alter table public.nsp_user_discount_share_hides enable row level security;

drop policy if exists "nsp users can read own hidden shared discounts" on public.nsp_user_discount_share_hides;
drop policy if exists "nsp users can hide shared discounts" on public.nsp_user_discount_share_hides;
drop policy if exists "nsp users can unhide own shared discounts" on public.nsp_user_discount_share_hides;

create policy "nsp users can read own hidden shared discounts"
  on public.nsp_user_discount_share_hides
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "nsp users can hide shared discounts"
  on public.nsp_user_discount_share_hides
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "nsp users can unhide own shared discounts"
  on public.nsp_user_discount_share_hides
  for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, delete on public.nsp_user_discount_share_hides to authenticated;
