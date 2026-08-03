-- Create tags and recipe_tags tables for household-scoped tagging.
-- Includes a reserved is_pcos flag for the PCOS toggle-tag.

create table tags (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  name text not null,
  is_pcos boolean not null default false,
  created_at timestamptz not null default now()
);

-- Case-insensitive uniqueness of tag names within a household.
-- Must be a functional unique index; expressions aren't allowed in a
-- table-level UNIQUE constraint.
create unique index tags_household_id_lower_name_key
  on tags (household_id, lower(name));

create table recipe_tags (
  recipe_id uuid not null references recipes(id) on delete cascade,
  tag_id uuid not null references tags(id) on delete cascade,
  primary key (recipe_id, tag_id)
);

-- Enable RLS
alter table tags enable row level security;
alter table recipe_tags enable row level security;

-- Tags RLS: household-scoped (same pattern as recipes)
drop policy if exists "Allow full access to own household tags" on tags;
create policy "Allow full access to own household tags"
on tags
for all
using (household_id = (select household_id from profiles where id = auth.uid()))
with check (household_id = (select household_id from profiles where id = auth.uid()));

-- Recipe_tags RLS: gated via the parent recipe's household
drop policy if exists "Allow full access to recipe_tags in own household" on recipe_tags;
create policy "Allow full access to recipe_tags in own household"
on recipe_tags
for all
using (
  exists (
    select 1
    from recipes
    where recipes.id = recipe_tags.recipe_id
      and recipes.household_id = (select household_id from profiles where id = auth.uid())
  )
)
with check (
  exists (
    select 1
    from recipes
    where recipes.id = recipe_tags.recipe_id
      and recipes.household_id = (select household_id from profiles where id = auth.uid())
  )
);

-- Reload PostgREST schema cache
notify pgrst, 'reload schema';
