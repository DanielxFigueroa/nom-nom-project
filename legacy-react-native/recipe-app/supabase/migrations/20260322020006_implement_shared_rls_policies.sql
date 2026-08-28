-- Enable RLS (should be idempotent)
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;

-- RECIPES RLS POLICY
DROP POLICY IF EXISTS "Allow full access to own household's recipes" ON public.recipes;
CREATE POLICY "Allow full access to own household's recipes"
ON public.recipes
FOR ALL
USING (household_id = (SELECT household_id FROM public.profiles WHERE id = auth.uid()))
WITH CHECK (household_id = (SELECT household_id FROM public.profiles WHERE id = auth.uid()));

-- INGREDIENTS RLS POLICY
DROP POLICY IF EXISTS "Allow full access to ingredients in own household's recipes" ON public.ingredients;
CREATE POLICY "Allow full access to ingredients in own household's recipes"
ON public.ingredients
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM public.recipes
    WHERE recipes.id = ingredients.recipe_id
      AND recipes.household_id = (SELECT household_id FROM public.profiles WHERE id = auth.uid())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.recipes
    WHERE recipes.id = ingredients.recipe_id
      AND recipes.household_id = (SELECT household_id FROM public.profiles WHERE id = auth.uid())
  )
);