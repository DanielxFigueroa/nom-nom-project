import React, { useEffect, useState } from 'react';
import { StyleSheet, View, ActivityIndicator, Alert, ScrollView, Pressable, SafeAreaView } from 'react-native';
import { useLocalSearchParams, useRouter, useNavigation } from 'expo-router';
import MaterialIcons from '@expo/vector-icons/MaterialIcons';

import { ThemedView } from '@/components/themed-view';
import { ThemedText } from '@/components/themed-text';
import { RecipeForm } from '../components/RecipeForm';
import { supabase } from '../src/lib/supabase';
import { useThemeColor } from '@/hooks/use-theme-color';
import { useColorScheme } from '@/hooks/use-color-scheme';
import type { Recipe, Ingredient } from '../src/types/recipe';

export default function EditRecipeScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const navigation = useNavigation();
  const colorScheme = useColorScheme();

  const [loading, setLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [recipe, setRecipe] = useState<Recipe | null>(null);
  const [ingredients, setIngredients] = useState<Ingredient[]>([]);

  // Theme colors
  const borderClr = colorScheme === 'dark' ? '#3E4246' : '#CBD5E1';
  const cardBg = colorScheme === 'dark' ? '#25282A' : '#F1F5F9';
  const tintClr = useThemeColor({}, 'tint');
  const textClr = useThemeColor({}, 'text');

  // Fetch recipe details
  useEffect(() => {
    async function fetchRecipeDetails() {
      if (!id) {
        Alert.alert('Error', 'No recipe ID provided.');
        router.back();
        return;
      }

      try {
        const [recipeResult, ingredientsResult] = await Promise.all([
          supabase.from('recipes').select('*').eq('id', id).single(),
          supabase.from('ingredients').select('*').eq('recipe_id', id),
        ]);

        if (recipeResult.error) throw recipeResult.error;

        if (recipeResult.data) {
          setRecipe(recipeResult.data as Recipe);
        }
        if (ingredientsResult.data) {
          setIngredients(ingredientsResult.data as Ingredient[]);
        }
      } catch (error: any) {
        console.error('Error fetching recipe for edit:', error);
        Alert.alert('Error', 'Failed to load recipe. Please try again.');
        router.back();
      } finally {
        setLoading(false);
      }
    }

    fetchRecipeDetails();
  }, [id, router]);

  // Update navigation options dynamically
  useEffect(() => {
    navigation.setOptions({
      title: 'Edit Recipe',
      headerLeft: () => (
        <Pressable onPress={() => router.back()} style={{ marginLeft: 10 }} testID="edit-back-btn">
          <MaterialIcons name="close" size={24} color={textClr} />
        </Pressable>
      ),
    });
  }, [navigation, router, textClr]);

  // Update recipe handler
  const handleUpdate = async (
    updatedRecipe: { title: string; description: string; instructions: string; image_url: string },
    updatedIngredients: { name: string; quantity?: string; unit?: string }[]
  ) => {
    if (!id || !recipe) return;

    setIsSubmitting(true);

    try {
      // 1. Update recipe details
      const { error: recipeUpdateError } = await supabase
        .from('recipes')
        .update({
          title: updatedRecipe.title,
          description: updatedRecipe.description,
          instructions: updatedRecipe.instructions,
          image_url: updatedRecipe.image_url,
        })
        .eq('id', id);

      if (recipeUpdateError) throw recipeUpdateError;

      // 2. Update ingredients by deleting existing and inserting new ones
      const { error: deleteIngredientsError } = await supabase
        .from('ingredients')
        .delete()
        .eq('recipe_id', id);

      if (deleteIngredientsError) throw deleteIngredientsError;

      if (updatedIngredients.length > 0) {
        const { error: insertIngredientsError } = await supabase
          .from('ingredients')
          .insert(
            updatedIngredients.map((ing) => ({
              recipe_id: id,
              name: ing.name,
              quantity: ing.quantity || null,
              unit: ing.unit || null,
            }))
          );

        if (insertIngredientsError) throw insertIngredientsError;
      }

      Alert.alert('Success', 'Recipe updated successfully!', [
        {
          text: 'OK',
          onPress: () => {
            // Dismiss edit screen and refresh previous view by replacing with explore / main
            router.replace('/(tabs)');
          },
        },
      ]);
    } catch (error: any) {
      console.error('Error updating recipe:', error);
      Alert.alert('Error', error.message || 'Failed to update recipe.');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Delete recipe handler
  const handleDeleteRecipe = () => {
    if (!id || !recipe) return;

    Alert.alert(
      'Delete Recipe',
      `Are you sure you want to permanently delete "${recipe.title}"? This action cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            setIsDeleting(true);
            try {
              // Delete recipe (foreign key cascades or explicit delete deletes ingredients first)
              const { error: deleteIngredientsError } = await supabase
                .from('ingredients')
                .delete()
                .eq('recipe_id', id);

              if (deleteIngredientsError) throw deleteIngredientsError;

              const { error: deleteRecipeError } = await supabase
                .from('recipes')
                .delete()
                .eq('id', id);

              if (deleteRecipeError) throw deleteRecipeError;

              Alert.alert('Deleted', 'Recipe deleted successfully.', [
                {
                  text: 'OK',
                  onPress: () => {
                    router.replace('/(tabs)');
                  },
                },
              ]);
            } catch (err: any) {
              console.error('Error deleting recipe:', err);
              Alert.alert('Error', err.message || 'Failed to delete recipe.');
            } finally {
              setIsDeleting(false);
            }
          },
        },
      ]
    );
  };

  if (loading) {
    return (
      <ThemedView style={styles.centered} testID="loading-state">
        <ActivityIndicator size="large" color={tintClr} />
      </ThemedView>
    );
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <ThemedView style={styles.container}>
        <ScrollView style={styles.scroll} contentContainerStyle={styles.scrollContent} keyboardShouldPersistTaps="handled">
          {recipe && (
            <RecipeForm
              initialData={recipe}
              initialIngredients={ingredients}
              onSubmit={handleUpdate}
              submitButtonText="Update Recipe"
              isSubmitting={isSubmitting}
            />
          )}

          {/* Delete Button Area */}
          <View style={[styles.deleteSection, { borderTopColor: borderClr, backgroundColor: cardBg }]}>
            <ThemedText style={styles.deletePrompt}>Danger Zone</ThemedText>
            <Pressable
              style={[styles.deleteButton, isDeleting && styles.disabledButton]}
              onPress={handleDeleteRecipe}
              disabled={isDeleting || isSubmitting}
              testID="delete-recipe-btn"
            >
              {isDeleting ? (
                <ActivityIndicator size="small" color="#FFF" />
              ) : (
                <>
                  <MaterialIcons name="delete-forever" size={20} color="#FFF" />
                  <ThemedText style={styles.deleteButtonText}>Delete Recipe</ThemedText>
                </>
              )}
            </Pressable>
          </View>
        </ScrollView>
      </ThemedView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
  },
  container: {
    flex: 1,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
  },
  deleteSection: {
    margin: 20,
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E53E3E',
    alignItems: 'center',
    marginBottom: 40,
  },
  deletePrompt: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#E53E3E',
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  deleteButton: {
    flexDirection: 'row',
    backgroundColor: '#E53E3E',
    height: 48,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
    width: '100%',
  },
  disabledButton: {
    opacity: 0.5,
  },
  deleteButtonText: {
    color: '#FFF',
    fontWeight: 'bold',
    fontSize: 15,
    marginLeft: 6,
  },
});
