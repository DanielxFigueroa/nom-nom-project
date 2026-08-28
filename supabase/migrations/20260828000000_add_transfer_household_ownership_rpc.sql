-- RPC function to atomically transfer household ownership between active members
CREATE OR REPLACE FUNCTION public.transfer_household_ownership(p_household_id uuid, p_new_owner_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verify caller is the current active owner
  IF NOT public.is_household_owner(p_household_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only the current household owner can transfer ownership.';
  END IF;

  -- Verify target member is active in this household
  IF NOT EXISTS (
    SELECT 1 FROM public.household_members
    WHERE household_id = p_household_id
      AND user_id = p_new_owner_id
      AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Target user must be an active member of the household.';
  END IF;

  -- If target is already the caller, no-op
  IF p_new_owner_id = auth.uid() THEN
    RETURN;
  END IF;

  -- Promote target member to owner
  UPDATE public.household_members
  SET role = 'owner'
  WHERE household_id = p_household_id
    AND user_id = p_new_owner_id;

  -- Demote previous owner to regular member
  UPDATE public.household_members
  SET role = 'member'
  WHERE household_id = p_household_id
    AND user_id = auth.uid();
END;
$$;

NOTIFY pgrst, 'reload schema';
