import React, { useEffect, useState, useCallback } from 'react';
import { View, StyleSheet, ScrollView, ActivityIndicator, Pressable } from 'react-native';
import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import { useFocusEffect } from '@react-navigation/native';
import MaterialIcons from '@expo/vector-icons/MaterialIcons';
import Animated from 'react-native-reanimated';
import { ThemedText } from './themed-text';
import { supabase } from '../src/lib/supabase';
import { useAuth } from '../src/contexts/AuthContext';
import type { Recipe } from '../src/types/recipe';

export type { Recipe };

interface RecipeListProps {
  onlyFavorites?: boolean;
}

const AnimatedImage = Animated.createAnimatedComponent(Image) as any;
const AnimatedText = Animated.createAnimatedComponent(ThemedText) as any;

export function RecipeList({ onlyFavorites = false }: RecipeListProps) {
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [loading, setLoading] = useState(true);
  const { householdId } = useAuth();
  const router = useRouter();

  const fetchRecipes = useCallback(async () => {
    if (!householdId) {
      setLoading(false);
      return;
    }

    let query = supabase.from('recipes').select('*').eq('household_id', householdId);

    if (onlyFavorites) {
      query = query.eq('is_favorite', true);
    }

    const { data } = await query;

    if (data) {
      setRecipes(data);
    }
    setLoading(false);
  }, [householdId, onlyFavorites]);

  useEffect(() => {
    fetchRecipes();
  }, [fetchRecipes]);

  useFocusEffect(
    useCallback(() => {
      fetchRecipes();
    }, [fetchRecipes])
  );

  if (loading) {
    return <ActivityIndicator style={styles.loader} size="large" testID="recipe-list-loader" />;
  }

  if (recipes.length === 0) {
    return (
      <View style={styles.emptyContainer} testID="empty-recipes-container">
        <ThemedText style={styles.emptyText} testID="empty-recipes-text">
          {onlyFavorites
            ? 'No favorite recipes yet. Bookmark recipes to view them here!'
            : 'No recipes found in your household.'}
        </ThemedText>
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
      <Pressable
        key={item.id}
        style={[styles.card, { height }]}
        testID={`recipe-card-${item.id}`}
        onPress={() =>
          router.push({
            pathname: '/modal' as any,
            params: { id: item.id, title: item.title, image_url: item.image_url },
          })
        }
      >
        <AnimatedImage
          source={{
            uri: item.image_url || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
          }}
          style={styles.image}
          contentFit="cover"
          transition={200}
          sharedTransitionTag={`recipe-image-${item.id}`}
        />
        {item.is_favorite && (
          <View style={styles.favoriteBadge} testID={`favorite-badge-${item.id}`}>
            <MaterialIcons name="favorite" size={16} color="#e63946" />
          </View>
        )}
        <View style={styles.textContainer}>
          <AnimatedText
            style={styles.titleText}
            numberOfLines={2}
            sharedTransitionTag={`recipe-title-${item.id}`}
          >
            {item.title}
          </AnimatedText>
        </View>
      </Pressable>
    );
  };

  return (
    <ScrollView contentContainerStyle={styles.listContainer}>
      <View style={styles.column}>{leftColumn.map(renderCard)}</View>
      <View style={styles.column}>{rightColumn.map(renderCard)}</View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  loader: { flex: 1, justifyContent: 'center' },
  emptyContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 },
  emptyText: { textAlign: 'center', fontSize: 16, opacity: 0.8 },
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
  favoriteBadge: {
    position: 'absolute',
    top: 10,
    right: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    borderRadius: 12,
    padding: 4,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 2,
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
  },
});
