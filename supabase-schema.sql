alter table public.teacher_activity_records
  add column if not exists user_id uuid;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_name = 'teacher_activity_records'
      and constraint_name like '%user_id%'
  ) then
    alter table public.teacher_activity_records
      add constraint teacher_activity_records_user_id_fkey
      foreign key (user_id) references auth.users(id);
  end if;
end $$;

alter table public.teacher_activity_records enable row level security;

drop policy if exists "Allow public read teacher activity records" on public.teacher_activity_records;
drop policy if exists "Allow public insert teacher activity records" on public.teacher_activity_records;
drop policy if exists "Allow public update teacher activity records" on public.teacher_activity_records;
drop policy if exists "Allow public delete teacher activity records" on public.teacher_activity_records;

create policy "Users can read own records"
on public.teacher_activity_records
for select
to authenticated
using (user_id = auth.uid());

create policy "Users can insert own records"
on public.teacher_activity_records
for insert
to authenticated
with check (user_id = auth.uid());

create policy "Users can update own records"
on public.teacher_activity_records
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can delete own records"
on public.teacher_activity_records
for delete
to authenticated
using (user_id = auth.uid());

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;

create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using (id = auth.uid());

create policy "Users can update own profile"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

do $$
begin
  alter publication supabase_realtime add table public.teacher_activity_records;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.profiles;
exception
  when duplicate_object then null;
end $$;
