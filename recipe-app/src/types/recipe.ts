/**
 * Represents a recipe record from the `recipes` Supabase table.
 */
export interface Recipe {
  id: string;
  title: string;
  image_url: string;
  description?: string;
  instructions?: string;
  household_id: string;
  created_at?: string;
}

/**
 * Represents an ingredient record from the `ingredients` Supabase table.
 */
export interface Ingredient {
  id: string;
  recipe_id: string;
  name: string;
  quantity?: string;
  unit?: string;
}
