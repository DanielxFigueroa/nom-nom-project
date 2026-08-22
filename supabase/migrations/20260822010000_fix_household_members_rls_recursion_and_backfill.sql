-- Fix infinite recursion in household_members RLS by using SECURITY DEFINER helper functions.
-- Also ensure all existing profiles have an active owner membership in household_members and backward-compatible recipe access.

-- 1. Helper functions to check ownership and membership without triggering RLS recursion
CREATE OR REPLACE FUNCTION public.is_household_owner(_household_id uuid, _user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.household_members
    WHERE household_id = _household_id
      AND user_id = _user_id
      AND role = 'owner'
      AND status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_household_member(_household_id uuid, _user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.household_members
    WHERE household_id = _household_id
      AND user_id = _user_id
      AND status = 'active'
  );
$$;

-- 2. Backfill: ensure all profiles have an active owner row in household_members
INSERT INTO public.household_members (user_id, household_id, status, role)
SELECT id, household_id, 'active', 'owner'
FROM public.profiles
WHERE household_id IS NOT NULL
ON CONFLICT (user_id, household_id)
DO UPDATE SET status = 'active', role = 'owner';

-- 3. Fix household_members RLS policies
DROP POLICY IF EXISTS "Users can view own memberships" ON public.household_members;
DROP POLICY IF EXISTS "Users can view own memberships and owners see all" ON public.household_members;
CREATE POLICY "Users can view own memberships and owners see all"
ON public.household_members
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR
  public.is_household_owner(household_id, auth.uid())
);

DROP POLICY IF EXISTS "Users can insert own memberships" ON public.household_members;
DROP POLICY IF EXISTS "Users can insert pending membership" ON public.household_members;
DROP POLICY IF EXISTS "Users can insert memberships" ON public.household_members;
CREATE POLICY "Users can insert memberships"
ON public.household_members
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
  OR
  public.is_household_owner(household_id, auth.uid())
);

DROP POLICY IF EXISTS "Owners can update member status" ON public.household_members;
CREATE POLICY "Owners can update member status"
ON public.household_members
FOR UPDATE
TO authenticated
USING (
  public.is_household_owner(household_id, auth.uid())
)
WITH CHECK (
  public.is_household_owner(household_id, auth.uid())
);

DROP POLICY IF EXISTS "Owners can remove members or members can leave" ON public.household_members;
CREATE POLICY "Owners can remove members or members can leave"
ON public.household_members
FOR DELETE
TO authenticated
USING (
  user_id = auth.uid()
  OR
  public.is_household_owner(household_id, auth.uid())
);

-- 4. Recipe RLS policies: active members + fallback to profile household
DROP POLICY IF EXISTS "Allow access to joined households' recipes" ON public.recipes;
DROP POLICY IF EXISTS "Active members can read joined households' recipes" ON public.recipes;
CREATE POLICY "Active members can read joined households' recipes"
ON public.recipes
FOR SELECT
TO authenticated
USING (
  public.is_household_member(household_id, auth.uid())
  OR
  household_id IN (SELECT household_id FROM public.profiles WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Owners can write to their household's recipes" ON public.recipes;
CREATE POLICY "Owners can write to their household's recipes"
ON public.recipes
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_household_owner(household_id, auth.uid())
  OR
  household_id IN (SELECT household_id FROM public.profiles WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Owners can update their household's recipes" ON public.recipes;
CREATE POLICY "Owners can update their household's recipes"
ON public.recipes
FOR UPDATE
TO authenticated
USING (
  public.is_household_owner(household_id, auth.uid())
  OR
  household_id IN (SELECT household_id FROM public.profiles WHERE id = auth.uid())
)
WITH CHECK (
  public.is_household_owner(household_id, auth.uid())
  OR
  household_id IN (SELECT household_id FROM public.profiles WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Owners can delete their household's recipes" ON public.recipes;
CREATE POLICY "Owners can delete their household's recipes"
ON public.recipes
FOR DELETE
TO authenticated
USING (
  public.is_household_owner(household_id, auth.uid())
  OR
  household_id IN (SELECT household_id FROM public.profiles WHERE id = auth.uid())
);

NOTIFY pgrst, 'reload schema';
