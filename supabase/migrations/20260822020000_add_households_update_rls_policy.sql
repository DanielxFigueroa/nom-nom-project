-- Allow household owners to update their household record (e.g. require_approval, name)
DROP POLICY IF EXISTS "Owners can update their household" ON public.households;
CREATE POLICY "Owners can update their household"
ON public.households
FOR UPDATE
TO authenticated
USING (
  public.is_household_owner(id, auth.uid())
  OR
  id IN (SELECT household_id FROM public.profiles WHERE id = auth.uid())
)
WITH CHECK (
  public.is_household_owner(id, auth.uid())
  OR
  id IN (SELECT household_id FROM public.profiles WHERE id = auth.uid())
);

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
