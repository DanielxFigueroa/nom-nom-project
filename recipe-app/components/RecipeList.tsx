import React, { useEffect, useState } from 'react';
import { View, StyleSheet, ScrollView, ActivityIndicator, Pressable } from 'react-native';
import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import Animated from 'react-native-reanimated';
import { ThemedText } from './themed-text';
import { supabase } from '../src/lib/supabase';
import { useAuth } from '../src/contexts/AuthContext';

const AnimatedImage = Animated.createAnimatedComponent(Image) as any;
const AnimatedText = Animated.createAnimatedComponent(ThemedText) as any;

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
  const router = useRouter();

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
      <Pressable 
        key={item.id} 
        style={[styles.card, { height }]}
        onPress={() => router.push({ pathname: '/modal' as any, params: { id: item.id, title: item.title, image_url: item.image_url } })}
      >
        <AnimatedImage
          source={{ uri: item.image_url || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400' }}
          style={styles.image}
          contentFit="cover"
          transition={200}
          sharedTransitionTag={`recipe-image-${item.id}`}
        />
        <View style={styles.textContainer}>
          <AnimatedText style={styles.titleText} numberOfLines={2} sharedTransitionTag={`recipe-title-${item.id}`}>
            {item.title}
          </AnimatedText>
        </View>
      </Pressable>
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
