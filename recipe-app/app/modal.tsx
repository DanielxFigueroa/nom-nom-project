import { Link, useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { Image } from 'expo-image';
import Animated from 'react-native-reanimated';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';

const AnimatedImage = Animated.createAnimatedComponent(Image);
const AnimatedText = Animated.createAnimatedComponent(ThemedText);

export default function ModalScreen() {
  const { id, title, image_url } = useLocalSearchParams<{ id: string, title: string, image_url: string }>();

  return (
    <ThemedView style={styles.container}>
      <AnimatedImage
        source={{ uri: image_url || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400' }}
        style={styles.image}
        contentFit="cover"
        sharedTransitionTag={`recipe-image-${id}`}
      />
      <View style={styles.textContainer}>
        <AnimatedText type="title" style={styles.title} sharedTransitionTag={`recipe-title-${id}`}>
          {title || 'Recipe Details'}
        </AnimatedText>
        
        <Link href="/" dismissTo style={styles.link}>
          <ThemedText type="link">Go back to home</ThemedText>
        </Link>
      </View>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  image: {
    width: '100%',
    height: 300,
  },
  textContainer: {
    padding: 20,
    flex: 1,
  },
  title: {
    marginBottom: 20,
  },
  link: {
    marginTop: 15,
    paddingVertical: 15,
  },
});
