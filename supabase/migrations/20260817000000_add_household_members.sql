-- Create household_members join table and update RLS policies for multi-household support.

-- 1. Create household_members join table
CREATE TABLE IF NOT EXISTS public.household_members (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  household_id uuid NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, household_id)
);

-- Enable RLS on household_members
ALTER TABLE public.household_members ENABLE ROW LEVEL SECURITY;

-- Household Members RLS Policies
DROP POLICY IF EXISTS "Users can view own memberships" ON public.household_members;
CREATE POLICY "Users can view own memberships"
ON public.household_members
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own memberships" ON public.household_members;
CREATE POLICY "Users can insert own memberships"
ON public.household_members
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- 2. Backfill existing profile links into household_members
INSERT INTO public.household_members (user_id, household_id)
SELECT id, household_id
FROM public.profiles
WHERE household_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- 3. Update RECIPES RLS POLICY
DROP POLICY IF EXISTS "Allow full access to own household's recipes" ON public.recipes;
DROP POLICY IF EXISTS "Allow access to joined households' recipes" ON public.recipes;
CREATE POLICY "Allow access to joined households' recipes"
ON public.recipes
FOR ALL
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  household_id IN (
    SELECT household_id FROM public.household_members WHERE user_id = auth.uid()
  )
);

-- 4. Update INGREDIENTS RLS POLICY
DROP POLICY IF EXISTS "Allow full access to ingredients in own household's recipes" ON public.ingredients;
DROP POLICY IF EXISTS "Allow access to ingredients in joined households" ON public.ingredients;
CREATE POLICY "Allow access to ingredients in joined households"
ON public.ingredients
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.recipes r
    JOIN public.household_members hm ON hm.household_id = r.household_id
    WHERE r.id = ingredients.recipe_id
      AND hm.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.recipes r
    JOIN public.household_members hm ON hm.household_id = r.household_id
    WHERE r.id = ingredients.recipe_id
      AND hm.user_id = auth.uid()
  )
);

-- 5. Update FOLDERS RLS POLICY
DROP POLICY IF EXISTS "Allow full access to own household folders" ON public.folders;
DROP POLICY IF EXISTS "Allow access to joined households' folders" ON public.folders;
CREATE POLICY "Allow access to joined households' folders"
ON public.folders
FOR ALL
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  household_id IN (
    SELECT household_id FROM public.household_members WHERE user_id = auth.uid()
  )
);

-- 6. Update TAGS RLS POLICY
DROP POLICY IF EXISTS "Allow full access to own household tags" ON public.tags;
DROP POLICY IF EXISTS "Allow access to joined households' tags" ON public.tags;
CREATE POLICY "Allow access to joined households' tags"
ON public.tags
FOR ALL
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  household_id IN (
    SELECT household_id FROM public.household_members WHERE user_id = auth.uid()
  )
);

-- 7. Update RECIPE_TAGS RLS POLICY
DROP POLICY IF EXISTS "Allow full access to recipe_tags in own household" ON public.recipe_tags;
DROP POLICY IF EXISTS "Allow access to recipe_tags in joined households" ON public.recipe_tags;
CREATE POLICY "Allow access to recipe_tags in joined households"
ON public.recipe_tags
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.recipes r
    JOIN public.household_members hm ON hm.household_id = r.household_id
    WHERE r.id = recipe_tags.recipe_id
      AND hm.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.recipes r
    JOIN public.household_members hm ON hm.household_id = r.household_id
    WHERE r.id = recipe_tags.recipe_id
      AND hm.user_id = auth.uid()
  )
);

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
