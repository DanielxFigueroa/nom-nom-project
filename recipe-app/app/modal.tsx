import { useLocalSearchParams, useNavigation } from 'expo-router';
import { StyleSheet, View, ScrollView, Pressable, ActivityIndicator } from 'react-native';
import { Image } from 'expo-image';
import Animated from 'react-native-reanimated';
import React, { useEffect, useLayoutEffect, useState, useCallback } from 'react';
import Markdown from 'react-native-markdown-display';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { supabase } from '../src/lib/supabase';
import { useThemeColor } from '@/hooks/use-theme-color';
import type { Recipe, Ingredient } from '../src/types/recipe';

const AnimatedImage = Animated.createAnimatedComponent(Image) as any;

// ---------------------------------------------------------------------------
// Ingredient Checklist Item
// ---------------------------------------------------------------------------
function IngredientItem({
  ingredient,
  checked,
  onToggle,
}: {
  ingredient: Ingredient;
  checked: boolean;
  onToggle: () => void;
}) {
  const textColor = useThemeColor({}, 'text');

  const label = [ingredient.quantity, ingredient.unit, ingredient.name]
    .filter(Boolean)
    .join(' ');

  return (
    <Pressable
      style={styles.ingredientRow}
      onPress={onToggle}
      accessibilityRole="checkbox"
      accessibilityState={{ checked }}
      testID={`ingredient-${ingredient.id}`}
    >
      {/* Checkbox indicator */}
      <View
        style={[
          styles.checkbox,
          checked && styles.checkboxChecked,
        ]}
      >
        {checked && <ThemedText style={styles.checkmark}>✓</ThemedText>}
      </View>

      <ThemedText
        style={[
          styles.ingredientText,
          checked && { textDecorationLine: 'line-through', opacity: 0.5 },
        ]}
      >
        {label}
      </ThemedText>
    </Pressable>
  );
}

// ---------------------------------------------------------------------------
// Main Modal Screen
// ---------------------------------------------------------------------------
export default function ModalScreen() {
  const { id, title, image_url } = useLocalSearchParams<{
    id: string;
    title: string;
    image_url: string;
  }>();
  const navigation = useNavigation();

  const [recipe, setRecipe] = useState<Recipe | null>(null);
  const [ingredients, setIngredients] = useState<Ingredient[]>([]);
  const [checkedIds, setCheckedIds] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);

  const textColor = useThemeColor({}, 'text');

  // Set the header title dynamically
  useLayoutEffect(() => {
    navigation.setOptions({ title: title || 'Recipe Details' });
  }, [navigation, title]);

  // Fetch full recipe + ingredients from Supabase
  useEffect(() => {
    async function fetchRecipeDetails() {
      if (!id) {
        setLoading(false);
        return;
      }

      const [recipeResult, ingredientsResult] = await Promise.all([
        supabase.from('recipes').select('*').eq('id', id).single(),
        supabase.from('ingredients').select('*').eq('recipe_id', id),
      ]);

      if (recipeResult.data) {
        setRecipe(recipeResult.data as Recipe);
      }
      if (ingredientsResult.data) {
        setIngredients(ingredientsResult.data as Ingredient[]);
      }

      setLoading(false);
    }

    fetchRecipeDetails();
  }, [id]);

  const toggleIngredient = useCallback((ingredientId: string) => {
    setCheckedIds((prev) => {
      const next = new Set(prev);
      if (next.has(ingredientId)) {
        next.delete(ingredientId);
      } else {
        next.add(ingredientId);
      }
      return next;
    });
  }, []);

  // Markdown style overrides to match the themed text color
  const markdownStyles = {
    body: { color: textColor, fontSize: 16, lineHeight: 24 },
    heading1: { color: textColor, fontSize: 24, fontWeight: 'bold' as const, marginVertical: 8 },
    heading2: { color: textColor, fontSize: 20, fontWeight: 'bold' as const, marginVertical: 6 },
    heading3: { color: textColor, fontSize: 18, fontWeight: '600' as const, marginVertical: 4 },
    bullet_list: { marginVertical: 4 },
    ordered_list: { marginVertical: 4 },
    list_item: { marginVertical: 2 },
    paragraph: { marginVertical: 4 },
    strong: { fontWeight: 'bold' as const },
    em: { fontStyle: 'italic' as const },
  };

  // ------ Loading state ------
  if (loading) {
    return (
      <ThemedView style={styles.centered}>
        <ActivityIndicator size="large" />
      </ThemedView>
    );
  }

  const displayTitle = recipe?.title ?? title ?? 'Recipe Details';
  const imageUri =
    recipe?.image_url || image_url || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400';
  const description = recipe?.description;
  const instructions = recipe?.instructions;

  return (
    <ThemedView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Hero Image */}
        <AnimatedImage
          source={{ uri: imageUri }}
          style={styles.image}
          contentFit="cover"
          sharedTransitionTag={`recipe-image-${id}`}
          testID="recipe-hero-image"
        />

        <View style={styles.body}>
          {/* Title */}
          <ThemedText type="title" style={styles.title} testID="recipe-title">
            {displayTitle}
          </ThemedText>

          {/* Description */}
          {description ? (
            <ThemedText style={styles.description} testID="recipe-description">
              {description}
            </ThemedText>
          ) : null}

          {/* Ingredients */}
          {ingredients.length > 0 && (
            <View style={styles.section} testID="ingredients-section">
              <ThemedText type="subtitle" style={styles.sectionTitle}>
                Ingredients
              </ThemedText>
              {ingredients.map((ingredient) => (
                <IngredientItem
                  key={ingredient.id}
                  ingredient={ingredient}
                  checked={checkedIds.has(ingredient.id)}
                  onToggle={() => toggleIngredient(ingredient.id)}
                />
              ))}
            </View>
          )}

          {/* Instructions */}
          {instructions ? (
            <View style={styles.section} testID="instructions-section">
              <ThemedText type="subtitle" style={styles.sectionTitle}>
                Instructions
              </ThemedText>
              <Markdown style={markdownStyles}>{instructions}</Markdown>
            </View>
          ) : null}
        </View>
      </ScrollView>
    </ThemedView>
  );
}

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------
const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scroll: {
    paddingBottom: 40,
  },
  image: {
    width: '100%',
    height: 280,
  },
  body: {
    padding: 20,
    flex: 1,
  },
  title: {
    marginBottom: 20,
  },
  title: {
    marginBottom: 8,
  },
  description: {
    fontSize: 16,
    lineHeight: 24,
    opacity: 0.8,
    marginBottom: 16,
  },
  section: {
    marginTop: 24,
  },
  sectionTitle: {
    marginBottom: 12,
  },

  // Ingredient checklist
  ingredientRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(150,150,150,0.3)',
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: 6,
    borderWidth: 2,
    borderColor: '#0a7ea4',
    marginRight: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  checkboxChecked: {
    backgroundColor: '#0a7ea4',
  },
  checkmark: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
    lineHeight: 16,
  },
  ingredientText: {
    flex: 1,
    fontSize: 16,
    lineHeight: 22,
  },
});
