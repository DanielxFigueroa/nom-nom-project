-- Migration: Add PCOS Nutritional Fields to recipes table
ALTER TABLE recipes
  ADD COLUMN IF NOT EXISTS insulin_index_notes TEXT,
  ADD COLUMN IF NOT EXISTS meal_timing_suggestions TEXT;
