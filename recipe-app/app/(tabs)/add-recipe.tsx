import React, { useState } from 'react';
import { StyleSheet, Alert, SafeAreaView, Platform, View } from 'react-native';
import { useRouter } from 'expo-router';

import { ThemedView } from '@/components/themed-view';
import { ThemedText } from '@/components/themed-text';
import { RecipeForm } from '../../components/RecipeForm';
import { useAuth } from '../../src/contexts/AuthContext';
import { supabase } from '../../src/lib/supabase';

export default function AddRecipeScreen() {
  const router = useRouter();
  const { householdId } = useAuth();
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (
    recipeData: { title: string; description: string; instructions: string; image_url: string },
    ingredientsData: { name: string; quantity?: string; unit?: string }[]
  ) => {
    if (!householdId) {
      Alert.alert('Error', 'You must join a household before adding recipes.');
      return;
    }

    setIsSubmitting(true);

    try {
      // 1. Insert the recipe
      const { data: recipeResult, error: recipeError } = await supabase
        .from('recipes')
        .insert({
          title: recipeData.title,
          description: recipeData.description,
          instructions: recipeData.instructions,
          image_url: recipeData.image_url,
          household_id: householdId,
        })
        .select()
        .single();

      if (recipeError) throw recipeError;
      if (!recipeResult) throw new Error('Recipe creation failed. No data returned.');

      // 2. Insert the ingredients linked to the created recipe
      if (ingredientsData.length > 0) {
        const { error: ingredientsError } = await supabase
          .from('ingredients')
          .insert(
            ingredientsData.map((ing) => ({
              recipe_id: recipeResult.id,
              name: ing.name,
              quantity: ing.quantity || null,
              unit: ing.unit || null,
            }))
          );

        if (ingredientsError) throw ingredientsError;
      }

      Alert.alert('Success', 'Recipe added successfully!', [
        {
          text: 'OK',
          onPress: () => {
            // Redirect to Explore tab (which is index.tsx)
            router.replace('/(tabs)');
          },
        },
      ]);
    } catch (error: any) {
      console.error('Error saving recipe:', error);
      Alert.alert('Error', error.message || 'Failed to save recipe.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <ThemedView style={styles.container}>
        <View style={styles.header}>
          <ThemedText type="title" style={styles.title}>
            Add Recipe
          </ThemedText>
        </View>
        <RecipeForm onSubmit={handleSubmit} isSubmitting={isSubmitting} submitButtonText="Create Recipe" />
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
  header: {
    paddingHorizontal: 20,
    paddingTop: Platform.OS === 'android' ? 40 : 10,
    paddingBottom: 10,
  },
  title: {
    fontSize: 28,
  },
});
