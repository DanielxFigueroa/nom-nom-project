-- Add optional name column to households table
ALTER TABLE public.households ADD COLUMN IF NOT EXISTS name text;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
