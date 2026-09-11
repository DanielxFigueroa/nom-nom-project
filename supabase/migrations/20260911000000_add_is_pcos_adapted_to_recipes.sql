-- Add is_pcos_adapted column to recipes
ALTER TABLE public.recipes
  ADD COLUMN IF NOT EXISTS is_pcos_adapted BOOLEAN NOT NULL DEFAULT FALSE;

NOTIFY pgrst, 'reload schema';
