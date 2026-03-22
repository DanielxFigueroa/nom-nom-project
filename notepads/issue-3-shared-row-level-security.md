# Issue #3: Implement Shared Row-Level Security (RLS)

- **Issue Link:** https://github.com/DanielxFigueroa/nom-nom-project/issues/3

## Summary

Implemented Row-Level Security (RLS) policies on the `recipes` and `ingredients` tables in the Supabase database. This ensures that users can only access data belonging to their own household, fulfilling the requirements of the GitHub issue.

## Implementation Steps

1.  **Inspected Schema:** Verified the table structures using the Supabase MCP. Confirmed that `recipes` has a `household_id` and `ingredients` is linked via `recipe_id`.
2.  **Defined RLS Policies:** Created SQL statements to define RLS policies.
    - For the `recipes` table, the policy checks that the `household_id` matches the current user's household.
    - For the `ingredients` table, the policy checks that the ingredient belongs to a recipe that is owned by the current user's household.
3.  **Applied Migration:** Applied the policies to the production database using the `mcp_supabase_apply_migration` tool. The initial attempt failed due to permissions, but a revised version that inlined the user's household ID logic succeeded.
4.  **Fetched Migration:** The applied migration will be fetched locally to be committed to the repository.

## SQL Migration

```sql
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
```
