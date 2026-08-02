# Milestone 3 — Plan: Structured ingredients, serving scaling, tags & folders

Implementation plan for the next feature set on the native SwiftUI app
(`nom-nom-app/`), building on the completed port (Milestones 1–2). The Supabase
backend is extended with **additive migrations only** — no existing tables are
dropped and no recipe data is destroyed.

This document is written as an **ordered set of GitHub issues**. Each `### Issue`
block below is self-contained and can be lifted directly into a GitHub issue, then
picked up **one at a time** by the `/nom-nom-ios-issue <#>` skill (which builds the
iOS app and requires a green build before commit/push). Implement in listed order;
each issue lists what it **Depends on**.

Four feature areas → **6 issues**:

- **A. Structured ingredient entry** — Qty & Unit dropdowns + Metric/Imperial toggle (geo default). → Issue 1
- **B. Serving sizes** — base serving count + ingredient scaling on the detail screen. → Issue 2
- **C. Tags** — user-defined tags + reserved **PCOS** toggle-tag (replacing the free-text PCOS/meal-timing cards); Explore sort + tag filter. → Issues 3, 4
- **D. Nested folders** — folder hierarchy surfaced through a Collectr-style **pill-dropdown bar**. → Issues 5, 6

---

## Conventions & workflow

**Build / test gate (run by `/nom-nom-ios-issue`; must print `** BUILD SUCCEEDED **`):**
```
cd "/Users/daniel/Desktop/Development Projects/nom-nom-project-ios/nom-nom-app" \
  && xcodegen generate \
  && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
     -project NomNom.xcodeproj -scheme NomNom \
     -destination 'generic/platform=iOS Simulator' \
     -skipMacroValidation -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO build
```
When a **new .swift file** is added it must be picked up by `xcodegen generate`
(it is, since sources are globbed) — no manual project edits.

**Migrations** live at repo root `supabase/migrations/`, named
`YYYYMMDDHHMMSS_description.sql` (latest existing:
`20260728000000_add_pcos_nutritional_fields_to_recipes.sql`). Apply via the
Supabase Plugins/CLI (`supabase db push`), then `notify pgrst, 'reload schema';`.
Every new table is **household-scoped** with the same RLS shape as `recipes`:
`household_id = (select household_id from profiles where id = auth.uid())`.

**Repo:** `DanielxFigueroa/nom-nom-project`. Branch per issue off the default
branch; the `/nom-nom-ios-issue` skill opens a PR after a green build.

---

## Confirmed decisions (locked)

1. **Geo default:** region **US → Imperial**, everywhere else → **Metric** (the
   original note was reversed; corrected here).
2. **Region source:** `Locale.current` (`region` / `measurementSystem`) — no
   permission prompt, no CoreLocation.
3. **Qty options:** `1…10` plus common fractions `¼, ⅓, ½, ⅔, ¾, 1½, 2½`.
4. **Measurement toggle:** *entry-time only* (chooses which unit list shows + stores
   the recipe's system). No live metric↔imperial conversion when viewing (out of scope).
5. **PCOS / meal-timing text fields: REMOVED from the UI.** A recipe is marked as
   PCOS via a **reserved PCOS tag** (a toggle at creation). Meal timing becomes
   ordinary tags (Breakfast/Lunch/Dinner). The `insulin_index_notes` /
   `meal_timing_suggestions` **columns are left in place** (no destructive
   migration, no data loss) but are no longer read or written by the app.
6. **Folders:** one folder per recipe (filesystem model), nesting via `parent_id`.
7. **Pill bar:** matches the Collectr reference screenshot (see Issue 6).

---

# Issues

## Issue 1 — Structured ingredient entry: Qty/Unit dropdowns + Metric/Imperial toggle

**Labels:** `milestone-3`, `feature`, `ingredients`
**Depends on:** none

### Summary
Replace the free-text `Qty`/`Unit` fields in the add/edit ingredients step with a
**Qty picker** (1–10 + common fractions) and a **Unit picker** whose options depend
on a **Metric/Imperial** toggle that defaults from the user's region.

### Migration — `..._add_measurement_system_to_recipes.sql`
```sql
alter table recipes
  add column measurement_system text not null default 'imperial';
```

### New files
- `Core/MeasurementUnits.swift`
  ```swift
  enum MeasurementSystem: String, Codable { case metric, imperial }

  enum RecipeUnit: String, CaseIterable, Codable, Identifiable {
      case piece, clove, slice, pinch, dash, toTaste   // shared / count
      case tsp, tbsp                                    // shared volume
      case cup, flOz, pint, quart, oz, lb               // imperial
      case ml, liter, g, kg                             // metric
      var id: String { rawValue }
      var displayName: String { /* "fl oz", "l", etc. */ }
      static func options(for system: MeasurementSystem) -> [RecipeUnit]
  }
  ```
- `Core/RegionDefaults.swift` — `static func measurementSystem() -> MeasurementSystem`
  returning `.imperial` when `Locale.current.region == "US"` (or
  `Locale.current.measurementSystem == .us`), else `.metric`.

### Model / repository changes
- `Models/Recipe.swift`: add `measurementSystem: MeasurementSystem` (CodingKey
  `measurement_system`, default `.imperial` for legacy rows).
- `Models/Ingredient.swift`: no schema change here (numeric value lands in Issue 2).
- `RecipesRepository`: `RecipeInput`/`RecipeInsert`/`RecipeUpdate` gain
  `measurement_system`.

### UI — `RecipeFormModel.swift` + `RecipeFormView.swift`
- `RecipeFormModel`: add `measurementSystem` (init from `RegionDefaults` on create,
  from the recipe on edit); `ingUnit: RecipeUnit?`; `ingQtyValue: Double?`.
- Ingredients step: segmented `Picker` (or two pills) to switch system at top;
  **Qty** `Menu`/`Picker` (fraction list) and **Unit** `Menu`/`Picker`
  (`RecipeUnit.options(for: measurementSystem)`) replacing the two `TextField`s.
- `IngredientDraft` gains `quantityValue: Double?`; `displayLabel` formats fractions.

### Acceptance criteria
- [ ] Qty and Unit are dropdowns, not free text.
- [ ] Unit options change with the Metric/Imperial toggle; `tsp`/`tbsp`/count units appear in both.
- [ ] The toggle defaults to Imperial on a US-region simulator, Metric elsewhere.
- [ ] Selected system + units persist and round-trip through edit.
- [ ] `** BUILD SUCCEEDED **`.

---

## Issue 2 — Serving sizes & ingredient scaling

**Labels:** `milestone-3`, `feature`, `recipes`
**Depends on:** Issue 1 (numeric quantity)

### Summary
Store a **base serving count** per recipe; on the detail screen let the user pick a
desired serving count and scale every ingredient amount proportionally.

### Migration — `..._add_servings_and_numeric_qty.sql`
```sql
alter table recipes add column servings integer not null default 4;
alter table ingredients add column quantity_value numeric;  -- scalable amount (nullable)
```

### Model / repository
- `Recipe.servings: Int` (CodingKey `servings`, default 4).
- `Ingredient.quantityValue: Double?` (CodingKey `quantity_value`).
- `IngredientInput`/`IngredientInsert` gain `quantity_value`; the form writes both
  the numeric value (from Issue 1's Qty picker) and the display text.
- `RecipeInput`/`RecipeInsert`/`RecipeUpdate` gain `servings`.

### Scaling — `RecipeDetailModel.swift` + `Core/FractionFormatter.swift` (new)
- `desiredServings: Int` init to `recipe.servings`;
  `scaleFactor = Double(desiredServings)/Double(max(recipe.servings,1))`.
- Per row: if `quantityValue != nil`, show `format(quantityValue*scaleFactor)`;
  else show the raw `quantity` text unscaled (legacy rows).
- `FractionFormatter` renders tidy fractions (`1.5 → "1 ½"`, `0.25 → "¼"`).

### UI
- `RecipeDetailView`: a **Servings** stepper above the ingredient checklist
  ("Serves 6 · base 4", with reset when changed); rows show scaled amounts.
- `RecipeFormView` details step: a **Servings** stepper (min 1) bound to `model.servings`.

### Acceptance criteria
- [ ] Recipes store a base serving count set in the form.
- [ ] Changing desired servings on the detail screen scales numeric amounts and formats fractions cleanly.
- [ ] Legacy recipes without numeric amounts show original text + a "scaling unavailable" note.
- [ ] `** BUILD SUCCEEDED **`.

---

## Issue 3 — Tags: schema, models, creation/detail UI, PCOS toggle (remove PCOS text cards)

**Labels:** `milestone-3`, `feature`, `tags`
**Depends on:** none (parallel with 1–2; do before 4)

### Summary
Add household-scoped, user-defined **tags** with a reserved **PCOS** tag toggled at
creation. Remove the free-text PCOS/meal-timing UI (columns stay in the DB, unused).

### Migration — `..._create_tags.sql`
```sql
create table tags (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  name text not null,
  is_pcos boolean not null default false,
  created_at timestamptz not null default now(),
  unique (household_id, lower(name))
);
create table recipe_tags (
  recipe_id uuid not null references recipes(id) on delete cascade,
  tag_id uuid not null references tags(id) on delete cascade,
  primary key (recipe_id, tag_id)
);
-- RLS: household-scoped for `tags`; `recipe_tags` gated via the parent recipe's household.
```
- Seed exactly one `is_pcos = true` tag named `"PCOS"` per household (lazily via
  `ensurePCOSTag`, or seed on household creation).

### Model / repository
- `Models/Tag.swift` (`id, householdId, name, isPCOS`).
- `Recipe.tags: [Tag]?`, populated via `select("*, ingredients(*), tags(*)")`.
- `Recipes/TagsRepository.swift` (new): `fetchTags(householdID:)`,
  `createTag(name:householdID:)`, `ensurePCOSTag(householdID:)`,
  `setRecipeTags(recipeID:tagIDs:)` (delete-by-recipe then insert).
- `createRecipe`/`updateRecipe` accept `tagIDs: [UUID]`.

### UI
- **Form (`RecipeFormView` details step):** remove the "Insulin Index Notes" and
  "Meal Timing Suggestions" fields. Add a **tag editor** (selectable chips of
  existing household tags + "Add tag" to create) and a dedicated **PCOS `Toggle`**
  that adds/removes the reserved PCOS tag. `RecipeFormModel` drops
  `insulinIndexNotes`/`mealTimingSuggestions`, gains `selectedTagIDs: Set<UUID>` +
  `isPCOS: Bool`.
- **Detail (`RecipeDetailView`):** remove the PCOS guidance cards
  (`pcosSection`/`PCOSGuidanceCard`). Show tag chips near the title; the PCOS chip
  styled distinctly (`Color.nnTint` badge).

### Acceptance criteria
- [ ] Creating/editing a recipe shows tag chips + a PCOS toggle; no free-text PCOS/meal-timing fields.
- [ ] The PCOS toggle marks the recipe with the reserved PCOS tag; it renders as a distinct chip.
- [ ] Tags are household-scoped (RLS) and reusable across recipes.
- [ ] `** BUILD SUCCEEDED **`.

---

## Issue 4 — Explore sort options + tag filtering (model + minimal UI)

**Labels:** `milestone-3`, `feature`, `explore`
**Depends on:** Issue 3

### Summary
Add sort options and tag filtering to Explore. Build the shared filter/sort model
here; Issue 6 upgrades the presentation to the pill bar.

### Model — `ExploreModel.swift`
- `enum RecipeSort { case newest, oldest, titleAsc, titleZ, favoritesFirst }`.
- Add `sort: RecipeSort` and `selectedTagIDs: Set<UUID>`.
- `filteredRecipes` applies **search AND tag filter**, then sorts (newest/oldest via
  the existing `created_at` string; title via localized compare; favorites-first).

### UI — `ExploreView.swift`
- Interim: a **Sort** `Menu` in the toolbar + a horizontal **tag chip strip** under
  the search bar (multi-select). `FavoritesModel` may reuse the same filter model.

### Acceptance criteria
- [ ] Sort options reorder the grid (newest/oldest/A–Z/Z–A/favorites-first).
- [ ] Selecting one or more tag chips filters the grid; combines with text search.
- [ ] `** BUILD SUCCEEDED **`.

---

## Issue 5 — Nested folders: schema, model, repository, move-to-folder UI

**Labels:** `milestone-3`, `feature`, `folders`
**Depends on:** Issue 3 (shared filter plumbing helpful, not strict)

### Summary
Organize recipes into a **folder hierarchy** (one folder per recipe, nested via
`parent_id`).

### Migration — `..._create_folders.sql`
```sql
create table folders (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  name text not null,
  parent_id uuid references folders(id) on delete cascade,   -- nesting
  created_at timestamptz not null default now()
);
alter table recipes add column folder_id uuid references folders(id) on delete set null;
-- RLS: household-scoped like `tags`.
```
- `on delete cascade` removes subfolders; `on delete set null` **un-files** recipes
  (recipes are never deleted with a folder).

### Model / repository
- `Models/Folder.swift` (`id, householdId, name, parentId`).
- `Recipe.folderId: UUID?`.
- `Recipes/FoldersRepository.swift` (new): `fetchFolders(householdID:)` (whole tree
  in one query; build hierarchy client-side from `parent_id`), `createFolder`,
  `renameFolder`, `deleteFolder`, `moveRecipe(recipeID:toFolder:)`.

### UI
- "Move to folder" picker on `RecipeDetailView`/`EditRecipeView` (with inline "New
  folder…" + parent selection).
- A lightweight folder manager (create/rename/delete, set parent) reachable from
  Explore or Account.

### Acceptance criteria
- [ ] Create nested folders (e.g. Meals → Breakfast) and file recipes into them.
- [ ] Deleting a folder un-files its recipes (they still exist, `folder_id` null).
- [ ] Folders are household-scoped.
- [ ] `** BUILD SUCCEEDED **`.

---

## Issue 6 — Collectr-style pill-dropdown filter bar on Explore

**Labels:** `milestone-3`, `feature`, `explore`, `ui`
**Depends on:** Issues 4 and 5

### Summary
Surface sort + tags + folder through a horizontal row of **pill-shaped dropdown
controls** at the top of Explore, matching the reference screenshot (Collectr).

### Reference (from screenshot)
- A horizontally scrollable row of pills below the search bar. Each pill =
  **leading SF Symbol + label + trailing `chevron.down`**.
- **Selected/active pill is filled with the accent color** (`Color.nnTint`, white
  text); inactive pills use `Color(.secondarySystemBackground)` with primary text.
- Tapping a pill opens a **dropdown** (`Menu`) / sheet of options.
- The folder context shows as a title/breadcrumb above the grid (screenshot's
  "Illustrator Shrines"); an optional folder summary card (recipe count, created
  date) is **nice-to-have polish**, not required.

### New components
- `Components/PillDropdown.swift` — a reusable pill: `icon`, `label`, `isActive`,
  and menu content; styling per the reference.
- `Components/PillFilterBar.swift` — horizontal `ScrollView` of pills wired to the
  shared `ExploreModel` filter state.

### Pills (v1)
- **Sort Order** (`arrow.up.arrow.down`) → `RecipeSort` (single-select).
- **Tags** (`tag`) → multi-select from household tags (includes PCOS).
- **Folder** (`folder`) → drill into the hierarchy; a breadcrumb/"back" affordance;
  selecting a folder scopes the grid to that folder (+ its subfolders).

### UI — `ExploreView.swift`
- Insert `PillFilterBar` between the search bar and the grid; the grid renders the
  folder-scoped, tag-filtered, sorted result from the shared model.

### Acceptance criteria
- [ ] Pill bar renders below search; active pills are accent-filled with a chevron, matching the reference.
- [ ] Sort, Tags, and Folder pills each open a dropdown and update the grid; they compose.
- [ ] Drilling into a nested folder scopes the grid; a breadcrumb allows going back up.
- [ ] `** BUILD SUCCEEDED **`.

---

## Dependency graph & order

```
1 (ingredients)  ──▶ 2 (servings)
3 (tags) ──▶ 4 (explore sort/filter) ──┐
3 (tags) ──▶ 5 (folders) ─────────────▶ 6 (pill bar)
```
Recommended sequence: **1 → 2 → 3 → 4 → 5 → 6.**

## Migrations summary
| Issue | Migration |
|---|---|
| 1 | `..._add_measurement_system_to_recipes.sql` |
| 2 | `..._add_servings_and_numeric_qty.sql` |
| 3 | `..._create_tags.sql` |
| 5 | `..._create_folders.sql` |

All additive; none drop columns or destroy recipe data. The deprecated
`insulin_index_notes` / `meal_timing_suggestions` columns are intentionally left in
place (unused by the app).

## Creating the GitHub issues
Each `### Issue` block maps 1:1 to a GitHub issue (title = the heading, body = the
block). Create with, e.g.:
```
gh issue create --repo DanielxFigueroa/nom-nom-project \
  --title "Structured ingredient entry: Qty/Unit dropdowns + Metric/Imperial toggle" \
  --label milestone-3 --label feature \
  --body-file <block>
```
Then implement one at a time with `/nom-nom-ios-issue <#>`.

## Out of scope
Realtime, edge functions, cross-system unit conversion at view time, offline
caching, and device/TestFlight distribution.
