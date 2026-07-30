# nom-nom — Port Specification (React Native/Expo → native SwiftUI)

This document is the **porting contract** for rebuilding the app natively in
SwiftUI. The React Native app in `legacy-react-native/recipe-app/` is the
reference implementation and remains the source of truth for behavior. The
**Supabase backend is unchanged** — the SwiftUI app targets the same project,
schema, RLS, storage, and RPC.

- **App:** nom-nom — a household recipe-sharing app with PCOS-specific nutrition fields.
- **Native target:** iOS-only, SwiftUI, min deployment target **iOS 17** (`@Observable` / MVVM).
- **Project name:** `NomNom`, built in `nom-nom-app/` via **XcodeGen**.
- **Backend SDK:** `supabase-swift` (reuse the same project URL + anon key as the RN app).

---

## 1. Backend (do not modify — reuse as-is)

Source of truth: `legacy-react-native/recipe-app/supabase/migrations/*.sql`

### Tables
| Table | Columns |
|---|---|
| `recipes` | `id` uuid pk · `title` text · `description` text? · `instructions` text? · `image_url` text? · `household_id` uuid · `is_favorite` bool NOT NULL default false · `insulin_index_notes` text? · `meal_timing_suggestions` text? · `created_at` timestamptz |
| `ingredients` | `id` uuid pk · `recipe_id` uuid fk→recipes · `name` text · `quantity` text? · `unit` text? |
| `households` | `id` uuid pk · `invite_code` text (6-char) |
| `profiles` | `id` uuid (= auth.uid) · `household_id` uuid? |

### RLS (household-scoped)
- `recipes` / `ingredients`: full access only where
  `household_id = (SELECT household_id FROM profiles WHERE id = auth.uid())`
  (ingredients checked via their parent recipe).
- `households`: any authenticated user may INSERT and SELECT (needed to create,
  read-back, and look up by invite code).
- `profiles`: a user may INSERT/SELECT/UPDATE only their own row (`id = auth.uid()`).

### Storage
- Public bucket **`recipes`**. Public read; authenticated insert/update/delete.
- Upload path pattern: `<random>-<timestamp>.<ext>`; content type `image/png` or `image/jpeg`.
- Store the returned public URL in `recipes.image_url`.

### RPC
- `toggle_recipe_favorite(recipe_id_param uuid, is_fav_param bool) → bool` (SECURITY DEFINER).
- The RN client falls back to a direct `recipes.update({is_favorite})` if the RPC errors — **mirror this fallback**.

### Config
- Env vars in RN: `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_ANON_KEY`.
- In Swift: read from a gitignored `Secrets.xcconfig` → Info.plist → runtime. Same URL + anon key.

**Not used by the app (do not add):** Realtime subscriptions, Edge Functions.

---

## 2. Data models (Codable, snake_case via CodingKeys)

```
Recipe(id, title, description?, instructions?, imageURL?, householdId,
       isFavorite, insulinIndexNotes?, mealTimingSuggestions?, createdAt?, ingredients?)
Ingredient(id, recipeId, name, quantity?, unit?)
Household(id, inviteCode)
Profile(id, householdId?)
```
Reference shapes: `legacy-react-native/recipe-app/src/types/recipe.ts`.

---

## 3. Navigation & routing

Auth-gated root (from `app/_layout.tsx`):
- **No session** → auth flow (Login).
- **Session but no `householdId`** → Household Setup.
- **Session + household** → main `TabView`.

| RN route | SwiftUI target | Purpose |
|---|---|---|
| `app/_layout.tsx` | `RootView` | Auth/household gate |
| `(auth)/login.tsx` | `LoginView` | Email/password sign-in |
| `(auth)/signup.tsx` | `SignupView` | Create account |
| `(auth)/household-setup.tsx` | `HouseholdSetupView` | Create (gen 6-char code) or join by code |
| `(tabs)/index.tsx` | `ExploreView` (tab 1) | Search + recipe grid |
| `(tabs)/favorites.tsx` | `FavoritesView` (tab 2) | Favorites grid |
| `(tabs)/add-recipe.tsx` | `AddRecipeView` (tab 3) | Multi-step create form |
| `modal.tsx` | `RecipeDetailView` | Full recipe detail |
| `edit-recipe.tsx` | `EditRecipeView` | Edit + delete (danger zone) |

---

## 4. Screen-by-screen behavior (porting checklist)

- [ ] **LoginView** — email + password → `auth.signIn(email:password:)`; link to signup; loading state.
- [ ] **SignupView** — email + password → `auth.signUp(...)`; on success route to Household Setup.
- [ ] **HouseholdSetupView**
  - *Create:* generate 6-char code (port `src/utils/household.ts`) → insert `households` → `profiles.upsert(id, household_id)` → `refreshProfile()`.
  - *Join:* look up `households` by `invite_code` (uppercased, `.maybeSingle`) → `profiles.upsert(...)` → `refreshProfile()`.
  - Error messaging; OR divider between the two.
- [ ] **ExploreView** — fetch `recipes` with joined ingredients for the household; 2-column grid with variable image heights; `SearchBar` filters **client-side by recipe title OR any ingredient name**.
- [ ] **FavoritesView** — same grid filtered to `is_favorite == true`; empty state ("No favorite recipes yet…").
- [ ] **RecipeDetailView** — hero image; **ingredient checklist** (local strikethrough state, *not* persisted); **markdown-rendered instructions** (swift-markdown-ui); **PCOS guidance cards** shown when `insulin_index_notes` / `meal_timing_suggestions` are non-empty; **favorite toggle** via `toggle_recipe_favorite` RPC with update fallback; **owner-only Edit** entry.
- [ ] **AddRecipeView / EditRecipeView** — 3-step form (Details → Ingredients → Instructions); `PhotosPicker` → upload to `recipes` bucket → `getPublicURL` → store `image_url` (on upload failure, proceed without image as RN does); insert/update recipe then **replace ingredient rows** (delete by `recipe_id`, then insert); **seafood-substitution warning** during ingredient entry; Edit adds a **delete "danger zone"** with confirmation.

---

## 5. State & foundations

- **AuthModel** (`@Observable`, injected via `.environment`) mirrors RN `AuthContext`
  (`src/contexts/AuthContext.tsx`): holds `session`, `user`, `householdId`, `isLoading`;
  on launch reads `client.auth.session`; subscribes to `authStateChanges`; fetches
  `household_id` from `profiles`; exposes `refreshProfile()` and a new `signOut()`
  (RN never implemented sign-out — add it).
- **SupabaseManager** — single shared `SupabaseClient`; session persists in Keychain
  automatically (replaces AsyncStorage).
- **RecipesRepository** — one method per Supabase operation listed above.

---

## 6. Theme / assets

- Tint/primary `#0a7ea4` · success/create `#34C759` · error/delete `#E53E3E` · splash `#208AEF`.
- Automatic light/dark (mirror `constants/theme.ts`).
- Portrait only.
- Icons/splash source: `legacy-react-native/recipe-app/assets/images/` (`icon.png`, `splash-icon.png`, etc.).
- Design references: `notepads/*.md` (per-issue write-ups) and the HTML mockup in `prototype/`.

---

## 7. Reference files (read-only source of truth)

| Concern | Path |
|---|---|
| Schema / RLS / RPC / storage | `legacy-react-native/recipe-app/supabase/migrations/*.sql` |
| Data shapes | `legacy-react-native/recipe-app/src/types/recipe.ts` |
| Auth logic | `legacy-react-native/recipe-app/src/contexts/AuthContext.tsx` |
| Supabase client config | `legacy-react-native/recipe-app/src/lib/supabase.ts` |
| Invite-code util | `legacy-react-native/recipe-app/src/utils/household.ts` |
| Screen behavior | `legacy-react-native/recipe-app/app/**`, `components/RecipeForm.tsx`, `components/RecipeList.tsx` |
| Theme | `legacy-react-native/recipe-app/constants/theme.ts` |
