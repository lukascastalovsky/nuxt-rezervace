npm install

npm run dev

SUPABASE_URL=https:// projekt .supabase.co

SUPABASE_KEY= anon-public-key 

-- ENUMY
create type user_role as enum ('student', 'admin');
create type reservation_status as enum ('pending', 'approved', 'rejected', 'cancelled');

-- PROFILES (rozšíření auth.users)
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  role user_role not null default 'student',
  created_at timestamptz default now()
);

-- RESOURCES (učebny / vybavení)
create table resources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null,
  description text,
  location text,
  quantity int not null default 1,
  created_at timestamptz default now()
);

-- RESERVATIONS
create table reservations (
  id uuid primary key default gen_random_uuid(),
  resource_id uuid not null references resources(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  start_time timestamptz not null,
  end_time timestamptz not null,
  status reservation_status not null default 'pending',
  created_at timestamptz default now(),
  check (end_time > start_time)
);

-- TRIGGER: automatické založení profilu po registraci
create or replace function handle_new_user() returns trigger
language plpgsql security definer as $$
begin
  insert into profiles (id, email, display_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'display_name', new.email));
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- TRIGGER: detekce kolize rezervací
create or replace function check_reservation_overlap() returns trigger
language plpgsql as $$
begin
  if exists (
    select 1 from reservations
    where resource_id = new.resource_id
      and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and status in ('pending','approved')
      and start_time < new.end_time
      and end_time > new.start_time
  ) then
    raise exception 'Časový konflikt s existující rezervací.';
  end if;
  return new;
end; $$;

create trigger reservations_no_overlap
  before insert or update on reservations
  for each row execute function check_reservation_overlap();

-- RLS
alter table profiles enable row level security;
alter table resources enable row level security;
alter table reservations enable row level security;

create policy "profiles: self read" on profiles for select using (auth.uid() = id);
create policy "profiles: admin read all" on profiles for select
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

create policy "resources: read all" on resources for select using (true);
create policy "resources: admin write" on resources for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

create policy "reservations: own read" on reservations for select using (user_id = auth.uid());
create policy "reservations: admin read all" on reservations for select
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
create policy "reservations: own write" on reservations for insert with check (user_id = auth.uid());
create policy "reservations: own update" on reservations for update using (user_id = auth.uid());
create policy "reservations: admin all" on reservations for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
