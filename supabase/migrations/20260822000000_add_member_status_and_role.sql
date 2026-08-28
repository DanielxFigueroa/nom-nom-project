-- Add status and role columns to household_members
ALTER TABLE public.household_members
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('pending', 'active', 'declined')),
  ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'member'
    CHECK (role IN ('owner', 'member'));

-- Add require_approval toggle to households
ALTER TABLE public.households
  ADD COLUMN IF NOT EXISTS require_approval boolean NOT NULL DEFAULT false;

-- Backfill: mark existing members as active; mark the profile-linked user as owner
UPDATE public.household_members hm
SET role = 'owner'
FROM public.profiles p
WHERE hm.user_id = p.id
  AND hm.household_id = p.household_id;

-- Update household_members RLS: users can view their own rows + owners can view all members of their household
DROP POLICY IF EXISTS "Users can view own memberships" ON public.household_members;
DROP POLICY IF EXISTS "Users can view own memberships and owners see all" ON public.household_members;
CREATE POLICY "Users can view own memberships and owners see all"
ON public.household_members
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
);

-- Insert: authenticated users can create a pending row for themselves
DROP POLICY IF EXISTS "Users can insert own memberships" ON public.household_members;
DROP POLICY IF EXISTS "Users can insert pending membership" ON public.household_members;
CREATE POLICY "Users can insert pending membership"
ON public.household_members
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid() AND status = 'pending');

-- Update: only owners can change status (accept/decline)
DROP POLICY IF EXISTS "Owners can update member status" ON public.household_members;
CREATE POLICY "Owners can update member status"
ON public.household_members
FOR UPDATE
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
)
WITH CHECK (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
);

-- Delete: owners can remove members; members can remove themselves (leave)
DROP POLICY IF EXISTS "Owners can remove members or members can leave" ON public.household_members;
CREATE POLICY "Owners can remove members or members can leave"
ON public.household_members
FOR DELETE
TO authenticated
USING (
  user_id = auth.uid()  -- self-leave
  OR
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
);

-- Update recipes RLS: only active members can read; only owners can write
DROP POLICY IF EXISTS "Allow access to joined households' recipes" ON public.recipes;
DROP POLICY IF EXISTS "Active members can read joined households' recipes" ON public.recipes;
DROP POLICY IF EXISTS "Owners can write to their household's recipes" ON public.recipes;
DROP POLICY IF EXISTS "Owners can update their household's recipes" ON public.recipes;
DROP POLICY IF EXISTS "Owners can delete their household's recipes" ON public.recipes;

CREATE POLICY "Active members can read joined households' recipes"
ON public.recipes
FOR SELECT
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND status = 'active'
  )
);

CREATE POLICY "Owners can write to their household's recipes"
ON public.recipes
FOR INSERT
TO authenticated
WITH CHECK (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
);

CREATE POLICY "Owners can update their household's recipes"
ON public.recipes
FOR UPDATE
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
)
WITH CHECK (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
);

CREATE POLICY "Owners can delete their household's recipes"
ON public.recipes
FOR DELETE
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
);

-- Update ingredients RLS: active members read; active owners write
DROP POLICY IF EXISTS "Allow access to ingredients in joined households" ON public.ingredients;
DROP POLICY IF EXISTS "Active members can access ingredients in joined households" ON public.ingredients;
CREATE POLICY "Active members can access ingredients in joined households"
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
      AND hm.status = 'active'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.recipes r
    JOIN public.household_members hm ON hm.household_id = r.household_id
    WHERE r.id = ingredients.recipe_id
      AND hm.user_id = auth.uid()
      AND hm.role = 'owner'
      AND hm.status = 'active'
  )
);

-- Update folders RLS: active members read; active owners write
DROP POLICY IF EXISTS "Allow access to joined households' folders" ON public.folders;
DROP POLICY IF EXISTS "Active members can read joined households' folders" ON public.folders;
DROP POLICY IF EXISTS "Owners can write joined households' folders" ON public.folders;

CREATE POLICY "Active members can read joined households' folders"
ON public.folders
FOR SELECT
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND status = 'active'
  )
);

CREATE POLICY "Owners can write joined households' folders"
ON public.folders
FOR ALL
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
)
WITH CHECK (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
);

-- Update tags RLS: active members read; active owners write
DROP POLICY IF EXISTS "Allow access to joined households' tags" ON public.tags;
DROP POLICY IF EXISTS "Active members can read joined households' tags" ON public.tags;
DROP POLICY IF EXISTS "Owners can write joined households' tags" ON public.tags;

CREATE POLICY "Active members can read joined households' tags"
ON public.tags
FOR SELECT
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND status = 'active'
  )
);

CREATE POLICY "Owners can write joined households' tags"
ON public.tags
FOR ALL
TO authenticated
USING (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
)
WITH CHECK (
  household_id IN (
    SELECT household_id FROM public.household_members
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  )
);

-- Update recipe_tags RLS: active members read; active owners write
DROP POLICY IF EXISTS "Allow access to recipe_tags in joined households" ON public.recipe_tags;
DROP POLICY IF EXISTS "Active members can read recipe_tags in joined households" ON public.recipe_tags;
DROP POLICY IF EXISTS "Owners can write recipe_tags in joined households" ON public.recipe_tags;

CREATE POLICY "Active members can read recipe_tags in joined households"
ON public.recipe_tags
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.recipes r
    JOIN public.household_members hm ON hm.household_id = r.household_id
    WHERE r.id = recipe_tags.recipe_id
      AND hm.user_id = auth.uid()
      AND hm.status = 'active'
  )
);

CREATE POLICY "Owners can write recipe_tags in joined households"
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
      AND hm.role = 'owner'
      AND hm.status = 'active'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.recipes r
    JOIN public.household_members hm ON hm.household_id = r.household_id
    WHERE r.id = recipe_tags.recipe_id
      AND hm.user_id = auth.uid()
      AND hm.role = 'owner'
      AND hm.status = 'active'
  )
);

NOTIFY pgrst, 'reload schema';
