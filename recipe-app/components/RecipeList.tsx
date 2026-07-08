import React, { useEffect, useState } from 'react';
import { View, StyleSheet, ScrollView, ActivityIndicator, Dimensions } from 'react-native';
import { Image } from 'expo-image';
import { ThemedText } from './themed-text';
import { supabase } from '../src/lib/supabase';
import { useAuth } from '../src/contexts/AuthContext';

export interface Recipe {
  id: string;
  title: string;
  image_url: string;
  household_id: string;
}

export function RecipeList() {
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [loading, setLoading] = useState(true);
  const { householdId } = useAuth();

  useEffect(() => {
    async function fetchRecipes() {
      if (!householdId) {
        setLoading(false);
        return;
      }
      const { data, error } = await supabase
        .from('recipes')
        .select('*')
        .eq('household_id', householdId);

      if (data) {
        setRecipes(data);
      }
      setLoading(false);
    }
    fetchRecipes();
  }, [householdId]);

  if (loading) {
    return <ActivityIndicator style={styles.loader} size="large" />;
  }

  if (recipes.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        <ThemedText>No recipes found in your household.</ThemedText>
      </View>
    );
  }

  // Split into left and right columns for masonry
  const leftColumn = recipes.filter((_, i) => i % 2 === 0);
  const rightColumn = recipes.filter((_, i) => i % 2 !== 0);

  const renderCard = (item: Recipe, index: number) => {
    // Generate pseudo-random height based on id or index to create staggered effect
    const height = index % 3 === 0 ? 250 : index % 2 === 0 ? 200 : 300;
    
    return (
      <View key={item.id} style={[styles.card, { height }]}>
        <Image
          source={{ uri: item.image_url || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400' }}
          style={styles.image}
          contentFit="cover"
          transition={200}
        />
        <View style={styles.textContainer}>
          <ThemedText style={styles.titleText} numberOfLines={2}>
            {item.title}
          </ThemedText>
        </View>
      </View>
    );
  };

  return (
    <ScrollView contentContainerStyle={styles.listContainer}>
      <View style={styles.column}>
        {leftColumn.map(renderCard)}
      </View>
      <View style={styles.column}>
        {rightColumn.map(renderCard)}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  loader: { flex: 1, justifyContent: 'center' },
  emptyContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 },
  listContainer: { 
    flexDirection: 'row', 
    padding: 8,
  },
  column: {
    flex: 1,
    flexDirection: 'column',
  },
  card: {
    margin: 8,
    borderRadius: 16,
    overflow: 'hidden',
    backgroundColor: '#333', // fallback background
  },
  image: {
    ...StyleSheet.absoluteFillObject,
  },
  textContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: 12,
    backgroundColor: 'rgba(0,0,0,0.5)',
  },
  titleText: {
    color: '#fff',
    fontWeight: 'bold',
  }
});
