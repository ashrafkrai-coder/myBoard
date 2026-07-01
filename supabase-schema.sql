create table if not exists public.teacher_activity_records (
  id text primary key,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.teacher_activity_records enable row level security;

drop policy if exists "Allow public read teacher activity records" on public.teacher_activity_records;
drop policy if exists "Allow public insert teacher activity records" on public.teacher_activity_records;
drop policy if exists "Allow public update teacher activity records" on public.teacher_activity_records;
drop policy if exists "Allow public delete teacher activity records" on public.teacher_activity_records;

create policy "Allow public read teacher activity records"
on public.teacher_activity_records
for select
to anon
using (true);

create policy "Allow public insert teacher activity records"
on public.teacher_activity_records
for insert
to anon
with check (true);

create policy "Allow public update teacher activity records"
on public.teacher_activity_records
for update
to anon
using (true)
with check (true);

create policy "Allow public delete teacher activity records"
on public.teacher_activity_records
for delete
to anon
using (true);

do $$
begin
  alter publication supabase_realtime add table public.teacher_activity_records;
exception
  when duplicate_object then null;
end $$;
