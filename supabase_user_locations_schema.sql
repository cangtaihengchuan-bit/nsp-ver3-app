create table if not exists public.nsp_user_locations (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null,
  lat double precision not null,
  lon double precision not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.nsp_user_locations enable row level security;

drop policy if exists "Users can read own locations" on public.nsp_user_locations;
drop policy if exists "Users can insert own locations" on public.nsp_user_locations;
drop policy if exists "Users can update own locations" on public.nsp_user_locations;
drop policy if exists "Users can delete own locations" on public.nsp_user_locations;

create policy "Users can read own locations"
  on public.nsp_user_locations
  for select
  using (auth.uid() = user_id);

create policy "Users can insert own locations"
  on public.nsp_user_locations
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update own locations"
  on public.nsp_user_locations
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own locations"
  on public.nsp_user_locations
  for delete
  using (auth.uid() = user_id);

create index if not exists nsp_user_locations_user_id_idx
  on public.nsp_user_locations(user_id);

create or replace function public.set_nsp_user_locations_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_nsp_user_locations_updated_at on public.nsp_user_locations;

create trigger set_nsp_user_locations_updated_at
before update on public.nsp_user_locations
for each row
execute function public.set_nsp_user_locations_updated_at();
