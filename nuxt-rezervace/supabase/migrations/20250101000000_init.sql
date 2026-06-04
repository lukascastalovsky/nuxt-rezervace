
create type public.app_role as enum ('student', 'admin');


create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  role public.app_role not null default 'student',
  created_at timestamptz not null default now()
);

grant select, insert, update on public.profiles to authenticated;
grant all on public.profiles to service_role;

alter table public.profiles enable row level security;


create or replace function public.has_role(_user_id uuid, _role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.profiles where id = _user_id and role = _role)
$$;

create policy "profile select - vlastní nebo admin"
  on public.profiles for select to authenticated
  using (id = auth.uid() or public.has_role(auth.uid(), 'admin'));

create policy "profile update - vlastní (kromě role) nebo admin"
  on public.profiles for update to authenticated
  using (id = auth.uid() or public.has_role(auth.uid(), 'admin'))
  with check (id = auth.uid() or public.has_role(auth.uid(), 'admin'));


create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'display_name', new.email));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


create table public.resources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null,
  description text,
  location text,
  quantity integer not null default 1 check (quantity >= 0),
  created_at timestamptz not null default now()
);

grant select on public.resources to anon, authenticated;
grant insert, update, delete on public.resources to authenticated;
grant all on public.resources to service_role;

alter table public.resources enable row level security;

create policy "resources: kdokoli vidí" on public.resources
  for select using (true);

create policy "resources: pouze admin CUD - insert" on public.resources
  for insert to authenticated with check (public.has_role(auth.uid(), 'admin'));

create policy "resources: pouze admin CUD - update" on public.resources
  for update to authenticated
  using (public.has_role(auth.uid(), 'admin'))
  with check (public.has_role(auth.uid(), 'admin'));

create policy "resources: pouze admin CUD - delete" on public.resources
  for delete to authenticated using (public.has_role(auth.uid(), 'admin'));


create type public.reservation_status as enum ('pending', 'confirmed', 'cancelled');

create table public.reservations (
  id uuid primary key default gen_random_uuid(),
  resource_id uuid not null references public.resources(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  start_time timestamptz not null,
  end_time timestamptz not null,
  status public.reservation_status not null default 'confirmed',
  created_at timestamptz not null default now(),
  check (end_time > start_time)
);

create index reservations_resource_time_idx
  on public.reservations(resource_id, start_time, end_time);

grant select, insert, update, delete on public.reservations to authenticated;
grant all on public.reservations to service_role;

alter table public.reservations enable row level security;

create policy "reservations: vlastní nebo admin select" on public.reservations
  for select to authenticated
  using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));

create policy "reservations: insert pouze za sebe" on public.reservations
  for insert to authenticated with check (user_id = auth.uid());

create policy "reservations: update vlastní nebo admin" on public.reservations
  for update to authenticated
  using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'))
  with check (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));

create policy "reservations: delete vlastní nebo admin" on public.reservations
  for delete to authenticated
  using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));


create or replace function public.check_reservation_overlap()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'cancelled' then return new; end if;
  if exists (
    select 1 from public.reservations r
    where r.resource_id = new.resource_id
      and r.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and r.status <> 'cancelled'
      and r.start_time < new.end_time
      and r.end_time > new.start_time
  ) then
    raise exception 'Rezervace se překrývá s jinou aktivní rezervací (kolize).';
  end if;
  return new;
end;
$$;

create trigger reservations_no_overlap
  before insert or update on public.reservations
  for each row execute function public.check_reservation_overlap();
