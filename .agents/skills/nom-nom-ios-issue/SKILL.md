---
name: nom-nom-ios-issue
description: Analyze and build a feature from a GitHub issue for the native SwiftUI (iOS) app, gating commit/push on a green Xcode build.
---

# Invoked as: /nom-nom-ios-issue <issue\*#>

Please analyze and implement the GitHub issue: $ARGUMENT, for the **native SwiftUI
iOS app** in `nom-nom-app/`.

This is the iOS counterpart to `nom-nom-github-issue`. It follows the same
PLAN → CREATE CODE → TEST → DEPLOY flow, but the **TEST gate is the Xcode build**:
nothing is committed or pushed until the iOS app builds successfully.

## Behavior

Follow these steps:

### PLAN

1. Use issue_read via GitHub Plugins to get the issue details.
2. Understand the problem described in the issue.
3. Ask clarifying questions if necessary.
4. Understand the prior art for this issue:
   - Search the `notepads` directory for previous thoughts related to the issue.
   - Search Pull Requests for history on this issue.
   - Read `nom-nom-app/MILESTONE_3_PLAN.md` — the issue was authored from it; use its
     migration, schema, file list, and acceptance criteria for this issue.
   - Search the codebase for the relevant Swift files (`nom-nom-app/NomNom/**`).
5. Think hard about how to break the issue into small, manageable tasks.
6. Document your plan in a new notepad:
   - Include the issue name in the filename.
   - Include a link to the issue in the notepad.

### CREATE CODE

- Retrieve the latest code from the branch `ios-build` with `git pull`.
- Create a new branch for the issue.
- Pull and merge the `ios-build` branch's changes into the new branch before any steps.
- Solve the issue in small, manageable steps according to your plan.
- **Supabase migrations:** if the issue adds/changes schema, prioritize the Supabase
  Plugins tools. Add the migration under `supabase/migrations/`
  (`YYYYMMDDHHMMSS_description.sql`), apply it, then reload PostgREST
  (`notify pgrst, 'reload schema';`). Migrations must be **additive** — never drop a
  column or destroy recipe data.
- New Swift files are picked up automatically by `xcodegen generate` (sources are
  globbed); do not hand-edit `NomNom.xcodeproj`.

### TEST — iOS build gate (must be green before any commit)

- Regenerate the project and build:
  ```
  cd "nom-nom-app" \
    && xcodegen generate \
    && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
       -project NomNom.xcodeproj -scheme NomNom \
       -destination 'generic/platform=iOS Simulator' \
       -skipMacroValidation -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO build
  ```
- The build **must** print `** BUILD SUCCEEDED **`. If it fails, read the compiler
  errors, fix them, and rebuild. **Do not proceed while the build is red.**
- If the project has an XCTest/XCUITest target, also run it and require it to pass:
  ```
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
    -project NomNom.xcodeproj -scheme NomNom \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -skipMacroValidation -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO test
  ```
- Verify the issue's **Acceptance criteria** are met (build boots in the simulator
  where the change is UI-facing).
- Only once the build (and any tests) return successful, move to the next step.

### COMMIT & PUSH — only after a green build

- Commit the changes with a clear prefix indicating the CLI and model made the
  commit (e.g. `[AGY:Gemini-3.5-Flash]` or the active model), referencing the issue
  number (`Closes #<issue>`).
- **Never commit or push if the iOS build did not return `** BUILD SUCCEEDED **`.**
- Push the branch to the repository.

### DEPLOY

- Open a Pull Request and request a review. Note in the PR body that the iOS build
  passed, and list any applied Supabase migrations.

Remember to use GitHub Plugins for all GitHub-related tasks, and Supabase Plugins
for all Supabase-related tasks. The single hard gate that distinguishes this skill:
**a successful `xcodebuild` is required before committing and pushing.**
