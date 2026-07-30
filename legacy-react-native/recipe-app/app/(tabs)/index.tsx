import React, { useState } from 'react';
import { StyleSheet } from 'react-native';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { RecipeList } from '@/components/RecipeList';
import { SearchBar } from '@/components/SearchBar';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function ExploreScreen() {
  const [searchQuery, setSearchQuery] = useState('');

  return (
    <SafeAreaView style={styles.container}>
      <ThemedView style={styles.header}>
        <ThemedText type="title">Explore</ThemedText>
      </ThemedView>
      <SearchBar value={searchQuery} onChangeText={setSearchQuery} />
      <RecipeList searchQuery={searchQuery} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 8,
  },
});
