# Issue 8: UI: Interactive Recipe Detail Modal
Link: https://github.com/DanielxFigueroa/nom-nom-project/issues/8

## Breakdown

1. Install `react-native-markdown-display` or `react-native-markdown-renderer` (if not already installed) to support Markdown rendering. Or `expo-markdown`. Wait, `react-native-markdown-display` is standard. Let's use it.
2. Update `recipe-app/app/modal.tsx` to accept and render additional fields: `description`, `instructions`, and `ingredients`. Since `useLocalSearchParams` only passes strings, the ingredients might need to be passed as JSON strings and parsed, or maybe we fetch the full recipe data if we only pass `id`? For now, we will assume they are passed as JSON strings or we fetch the recipe. Looking at `RecipeList.tsx`, I should check how it passes data.
3. Build the interactive ingredients checklist. It should maintain an array of checked indices or IDs in state. Use `TouchableOpacity` or similar with an icon.
4. Render `instructions` using the markdown component.
5. Create a Jest test for the new modal functionality.

## Steps

1. Create a branch `issue-8-recipe-detail-modal`.
2. Add necessary dependencies (e.g. `react-native-markdown-display` and maybe some icons if not already there).
3. Update `RecipeList.tsx` to pass the new fields to the modal.
4. Update `modal.tsx` UI to include image, title, description, ingredients checklist, and markdown instructions.
5. Add a test in `recipe-app/app/__tests__/modal.test.tsx` (if applicable) or update existing tests.
6. Commit and open PR.
