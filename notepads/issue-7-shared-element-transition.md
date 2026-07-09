# Plan for Issue #7: Animation: Shared Element Transition on Navigation

Link: https://github.com/DanielxFigueroa/nom-nom-project/issues/7

## Objective
Create a seamless and fluid animation when a user navigates from the recipe grid to the recipe detail view.

## Tasks

### 1. Update `RecipeList` component
- Wrap `RecipeCard` content in a `Pressable` to handle navigation.
- On press, navigate to `/modal` (the detail view) and pass recipe params (id, title, image_url).
- Add `sharedTransitionTag` to the image and title text to enable shared element transitions via `react-native-reanimated`.
- Wrap the `Image` and `ThemedText` with `Animated.createAnimatedComponent`.

### 2. Update the Recipe Detail view (`app/modal.tsx`)
- Read recipe params (`id`, `title`, `image_url`) using `useLocalSearchParams`.
- Render the `AnimatedImage` and `AnimatedText` with the same `sharedTransitionTag` as in the grid.
- Ensure layout allows the shared element to smoothly transition to its final size.

### 3. Testing
- Write/update Jest tests if needed.
- Open app manually to verify visually using `playwright` (if possible, though React Native Reanimated shared transitions are tricky to test in playwright on web, so we'll ensure code is correct).

### 4. Deploy
- Commit changes using prefix `[AGY:Gemini-3.5-Flash]`.
- Push to GitHub and create a Pull Request.
