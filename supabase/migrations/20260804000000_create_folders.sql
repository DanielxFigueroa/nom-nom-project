-- Create folders table and add folder_id to recipes for household-scoped folder hierarchy.

create table folders (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  name text not null,
  parent_id uuid references folders(id) on delete cascade,   -- nesting
  created_at timestamptz not null default now()
);

alter table recipes add column folder_id uuid references folders(id) on delete set null;

-- Enable RLS
alter table folders enable row level security;

-- Folders RLS: household-scoped (same pattern as tags/recipes)
drop policy if exists "Allow full access to own household folders" on folders;
create policy "Allow full access to own household folders"
on folders
for all
using (household_id = (select household_id from profiles where id = auth.uid()))
with check (household_id = (select household_id from profiles where id = auth.uid()));

-- Reload PostgREST schema cache
notify pgrst, 'reload schema';
