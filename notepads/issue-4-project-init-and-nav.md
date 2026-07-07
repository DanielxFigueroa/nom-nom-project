# Issue 4: Frontend: Project Initialization & Navigation

Link: https://github.com/DanielxFigueroa/nom-nom-project/issues/4

## Plan

1. **Check Existing Setup:** Project is already initialized with Expo. Some core dependencies (`expo-image`, `react-native-reanimated`, `expo-router` handling navigation) are already present.
2. **Install Supabase:** Run `npm install @supabase/supabase-js` in `recipe-app`.
3. **Configure Supabase:** Create a supabase client configuration file at `src/lib/supabase.ts` (using placeholder URLs if env variables aren't set yet).
4. **Setup Navigation:** 
   - Modify `app/(tabs)/_layout.tsx` to have three tabs: `Explore`, `Favorites`, and `Add Recipe`.
   - Ensure the respective screen files exist (e.g., `explore.tsx` or `index.tsx`, `favorites.tsx`, `add-recipe.tsx`).
5. **Testing:** Run frontend checks using Playwright/DevTools or jest tests (we will add a simple Jest test if missing).
6. **Deploy:** Commit and open a PR.
