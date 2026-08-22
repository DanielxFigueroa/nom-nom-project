# Issue 53: M5: DB — Add status/role columns to household_members + approval-aware RLS

Link to Issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/53

## Overview
Add `status` and `role` columns to `household_members` and `require_approval` to `households`. Update RLS policies so that only active members have access to household data (recipes, ingredients, folders, tags, recipe_tags), and only owners can write recipe data and manage memberships. Update Swift models in NomNom iOS app to support these new fields.

## Tasks

1. **Database Migration**
   - Create `supabase/migrations/20260822000000_add_member_status_and_role.sql`.
   - Add `status` (`'pending' | 'active' | 'declined'`, default `'active'`) and `role` (`'owner' | 'member'`, default `'member'`) columns to `household_members`.
   - Add `require_approval` (`boolean`, default `false`) column to `households`.
   - Backfill: mark profile-linked household members with `role = 'owner'`.
   - RLS Policies for `household_members`:
     - SELECT: users can view own memberships OR owners (active) can view all members in their household.
     - INSERT: authenticated users can insert pending membership (`status = 'pending'`).
     - UPDATE: owners can update status.
     - DELETE: owners can remove members, or members can leave (self-delete).
   - RLS Policies for `recipes`, `ingredients`, `folders`, `tags`, `recipe_tags`:
     - SELECT: only active members of joined households.
     - INSERT/UPDATE/DELETE: only active owners of joined households.

2. **Swift Models Update**
   - Update `NomNom/Models/HouseholdMember.swift`: add `status` and `role` properties.
   - Update `NomNom/Models/Household.swift`: add `requireApproval: Bool?` property (`require_approval` coding key).
   - Update `NomNom/Auth/HouseholdRepository.swift`: support status during join inserts if needed and ensure `HouseholdMemberInsert` handles status/role.

3. **Verification & iOS Build Gate**
   - Run `xcodegen generate`.
   - Run `xcodebuild` to ensure project builds cleanly with `** BUILD SUCCEEDED **`.
   - Commit and push to git repo.
   - Open Pull Request for Issue 53.
