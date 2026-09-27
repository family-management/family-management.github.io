-- ============================================================
-- FamilyHub — Complete Schema (run in Supabase SQL Editor)
-- ============================================================

-- 1. PROFILES
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  pronouns text,
  role text default 'Parent',
  designation text default 'Member',
  avatar_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();


-- 2. FAMILY MEMBERS
create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  pronouns text,
  role text default 'Member',
  designation text default 'Member',
  created_at timestamptz default now()
);


-- 3. EVENTS
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  event_date date not null,
  event_time time,
  note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now()
);
create index if not exists events_date_idx on public.events (event_date);


-- 4. TASKS
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  done boolean default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
drop trigger if exists tasks_updated_at on public.tasks;
create trigger tasks_updated_at
  before update on public.tasks
  for each row execute procedure public.set_updated_at();


-- 5. NOTES
create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now()
);


-- 6. LOGIN LOGS (IP, location, time)
create table if not exists public.login_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  email text,
  ip_address text,
  city text,
  region text,
  country text,
  user_agent text,
  logged_in_at timestamptz default now()
);
create index if not exists login_logs_time_idx on public.login_logs (logged_in_at desc);


-- 7. ACTIVITY LOGS (who changed what)
create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  email text,
  action text not null,          -- e.g. 'created_task', 'deleted_event', 'updated_profile'
  entity_type text,              -- 'task', 'event', 'note', 'member', 'profile'
  entity_id text,
  details text,                  -- human readable description
  created_at timestamptz default now()
);
create index if not exists activity_logs_time_idx on public.activity_logs (created_at desc);


-- ============================================================
-- RLS
-- ============================================================
alter table public.profiles enable row level security;
alter table public.family_members enable row level security;
alter table public.events enable row level security;
alter table public.tasks enable row level security;
alter table public.notes enable row level security;
alter table public.login_logs enable row level security;
alter table public.activity_logs enable row level security;

-- Profiles
drop policy if exists "Authenticated users can view all profiles" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Authenticated users can view all profiles" on public.profiles for select to authenticated using (true);
create policy "Users can update their own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
create policy "Users can insert their own profile" on public.profiles for insert to authenticated with check (auth.uid() = id);

-- Family members
drop policy if exists "Authenticated can view family members" on public.family_members;
drop policy if exists "Authenticated can insert family members" on public.family_members;
drop policy if exists "Authenticated can update family members" on public.family_members;
drop policy if exists "Authenticated can delete family members" on public.family_members;
create policy "Authenticated can view family members" on public.family_members for select to authenticated using (true);
create policy "Authenticated can insert family members" on public.family_members for insert to authenticated with check (true);
create policy "Authenticated can update family members" on public.family_members for update to authenticated using (true);
create policy "Authenticated can delete family members" on public.family_members for delete to authenticated using (true);

-- Events
drop policy if exists "Authenticated can view events" on public.events;
drop policy if exists "Authenticated can insert events" on public.events;
drop policy if exists "Authenticated can update events" on public.events;
drop policy if exists "Authenticated can delete events" on public.events;
create policy "Authenticated can view events" on public.events for select to authenticated using (true);
create policy "Authenticated can insert events" on public.events for insert to authenticated with check (true);
create policy "Authenticated can update events" on public.events for update to authenticated using (true);
create policy "Authenticated can delete events" on public.events for delete to authenticated using (true);

-- Tasks
drop policy if exists "Authenticated can view tasks" on public.tasks;
drop policy if exists "Authenticated can insert tasks" on public.tasks;
drop policy if exists "Authenticated can update tasks" on public.tasks;
drop policy if exists "Authenticated can delete tasks" on public.tasks;
create policy "Authenticated can view tasks" on public.tasks for select to authenticated using (true);
create policy "Authenticated can insert tasks" on public.tasks for insert to authenticated with check (true);
create policy "Authenticated can update tasks" on public.tasks for update to authenticated using (true);
create policy "Authenticated can delete tasks" on public.tasks for delete to authenticated using (true);

-- Notes
drop policy if exists "Authenticated can view notes" on public.notes;
drop policy if exists "Authenticated can insert notes" on public.notes;
drop policy if exists "Authenticated can update notes" on public.notes;
drop policy if exists "Authenticated can delete notes" on public.notes;
create policy "Authenticated can view notes" on public.notes for select to authenticated using (true);
create policy "Authenticated can insert notes" on public.notes for insert to authenticated with check (true);
create policy "Authenticated can update notes" on public.notes for update to authenticated using (true);
create policy "Authenticated can delete notes" on public.notes for delete to authenticated using (true);

-- Login logs (everyone can insert their own, only admin-ish can read all — we allow all authenticated to read for simplicity, restrict in UI)
drop policy if exists "Authenticated can insert login logs" on public.login_logs;
drop policy if exists "Authenticated can view login logs" on public.login_logs;
create policy "Authenticated can insert login logs" on public.login_logs for insert to authenticated with check (true);
create policy "Authenticated can view login logs" on public.login_logs for select to authenticated using (true);

-- Activity logs
drop policy if exists "Authenticated can insert activity logs" on public.activity_logs;
drop policy if exists "Authenticated can view activity logs" on public.activity_logs;
create policy "Authenticated can insert activity logs" on public.activity_logs for insert to authenticated with check (true);
create policy "Authenticated can view activity logs" on public.activity_logs for select to authenticated using (true);

grant usage on schema public to authenticated;
grant all on all tables in schema public to authenticated;
grant all on all sequences in schema public to authenticated;
