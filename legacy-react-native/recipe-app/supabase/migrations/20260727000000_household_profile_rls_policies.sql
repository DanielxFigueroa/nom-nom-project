-- RLS policies for households & profiles.
-- Without these, an authenticated user cannot create a household, read it back,
-- look one up by invite code, or update their own profile.household_id — which
-- makes the "Create Household" / "Join Household" setup step fail silently.

-- Ensure RLS is enabled (idempotent).
ALTER TABLE public.households ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- HOUSEHOLDS ------------------------------------------------------------------

-- Any authenticated user may create a household.
DROP POLICY IF EXISTS "Authenticated users can create households" ON public.households;
CREATE POLICY "Authenticated users can create households"
ON public.households
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Authenticated users may read households. This is required to (a) read back the
-- row just inserted via .select().single(), and (b) look up a household by its
-- invite_code when joining.
DROP POLICY IF EXISTS "Authenticated users can view households" ON public.households;
CREATE POLICY "Authenticated users can view households"
ON public.households
FOR SELECT
TO authenticated
USING (true);

-- PROFILES --------------------------------------------------------------------

-- A user may create their own profile row (id must match their auth uid). This
-- covers the case where no signup trigger auto-creates the profile, so the app
-- upserts it when linking a household.
DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;
CREATE POLICY "Users can create their own profile"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- A user may read their own profile row.
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

-- A user may update their own profile row (e.g. set household_id).
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());
