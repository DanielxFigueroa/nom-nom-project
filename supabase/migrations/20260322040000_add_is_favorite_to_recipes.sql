-- Migration to add is_favorite column and RPC function for toggling favorite status

ALTER TABLE public.recipes
ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN NOT NULL DEFAULT FALSE;

-- Supabase function to toggle or set recipe favorite status
CREATE OR REPLACE FUNCTION public.toggle_recipe_favorite(recipe_id_param UUID, is_fav_param BOOLEAN)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.recipes
  SET is_favorite = is_fav_param
  WHERE id = recipe_id_param;
  
  RETURN is_fav_param;
END;
$$;
