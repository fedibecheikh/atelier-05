-- Atelier 5 — Offline-first + géolocalisation
-- À exécuter dans le SQL Editor du projet Supabase.

create extension if not exists pgcrypto;

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) > 0),
  lat double precision,
  lng double precision,
  location_accuracy_m double precision,
  created_at timestamptz not null default now(),
  constraint valid_latitude check (lat is null or lat between -90 and 90),
  constraint valid_longitude check (lng is null or lng between -180 and 180)
);

alter table public.clients enable row level security;

drop policy if exists "clients are readable" on public.clients;
create policy "clients are readable"
  on public.clients for select
  to anon, authenticated
  using (true);

drop policy if exists "anyone can join the queue" on public.clients;
create policy "anyone can join the queue"
  on public.clients for insert
  to anon, authenticated
  with check (true);

-- Nécessaire pour l'upsert de synchronisation.
drop policy if exists "anyone can update the queue" on public.clients;
create policy "anyone can update the queue"
  on public.clients for update
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "anyone can leave the queue" on public.clients;
create policy "anyone can leave the queue"
  on public.clients for delete
  to anon, authenticated
  using (true);

do $$
begin
  alter publication supabase_realtime add table public.clients;
exception
  when duplicate_object then null;
end $$;
