-- Add pcos_settings column to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS pcos_settings jsonb;

NOTIFY pgrst, 'reload schema';
