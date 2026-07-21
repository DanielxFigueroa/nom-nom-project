import React from 'react';
import { StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { RecipeList } from '@/components/RecipeList';

export default function FavoritesScreen() {
  return (
    <SafeAreaView style={styles.container} testID="favorites-screen">
      <ThemedView style={styles.header}>
        <ThemedText type="title">Favorites</ThemedText>
      </ThemedView>
      <RecipeList onlyFavorites />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    padding: 16,
  },
});
