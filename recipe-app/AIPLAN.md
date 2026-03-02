# PCOS Meal Planner App - High-Level Development Plan

This document outlines the high-level plan for developing the PCOS Meal Planner mobile application using React Native and Supabase.

## 1. Supabase Backend Setup

*   **Objective:** Establish the Supabase project and define the initial database schema for recipes and ingredients.
*   **Steps:**
    *   Create a new Supabase project.
    *   Define `recipes` table: `id` (PK), `title` (TEXT), `description` (TEXT), `instructions` (TEXT), `image_url` (TEXT, optional), `is_favorite` (BOOLEAN), `created_at` (TIMESTAMP WITH TIME ZONE, default NOW()), `user_id` (FK to `auth.users.id`).
    *   Define `ingredients` table: `id` (PK), `recipe_id` (FK to `recipes.id`), `name` (TEXT), `quantity` (NUMERIC), `unit` (TEXT), `notes` (TEXT, optional), `user_id` (FK to `auth.users.id`).
    *   Implement Row Level Security (RLS) policies to ensure secure data access for authenticated users.
    *   Set up the Supabase client library configuration for the application.

## 2. React Native App Scaffolding

*   **Objective:** Set up a basic React Native project structure.
*   **Steps:**
    *   Initialize a new React Native project (e.g., using Expo CLI for ease of development and deployment).
    *   Configure the Supabase client within the React Native application to connect to the backend.
    *   Set up basic navigation using a library like React Navigation, including routes for a `RecipeList` (Home) screen and a `RecipeDetail` screen.

## 3. Recipe Listing and Display (Frontend)

*   **Objective:** Fetch and display recipes from Supabase in a card format, similar to the existing `src` example, but without the price information.
*   **Steps:**
    *   Develop a `RecipeList` component responsible for fetching all available recipes from the Supabase `recipes` table.
    *   Create a `RecipeCard` component to render each individual recipe. This component will display the recipe's title, a brief description, and an image (if available).
    *   Ensure the styling for these components is optimized for a mobile-first experience.

## 4. Interactive Recipe Details (Frontend)

*   **Objective:** Implement interactive elements allowing users to view full recipe ingredients and instructions.
*   **Steps:**
    *   Make the `RecipeCard` component clickable.
    *   Upon clicking a card, implement an animation (e.g., a card flip effect) or transition to a modal popup (`RecipeDetail` screen) that reveals the complete list of ingredients and detailed instructions for the selected recipe.
    *   Focus on smooth transitions and a responsive layout for mobile devices.

## 5. Global Search Functionality

*   **Objective:** Enable users to search for recipes throughout the application.
*   **Steps:**
    *   Integrate a search input component that can be easily accessed from different parts of the app (e.g., in a header or a dedicated search screen).
    *   Implement backend search queries, potentially leveraging Supabase's full-text search capabilities, to filter recipes based on criteria like title, ingredient names, or description.
    *   Display search results dynamically as the user types or after a search submission.

## 6. User Authentication

*   **Objective:** Provide user login/signup capabilities to enable personalized features, such as saving favorite recipes.
*   **Steps:**
    *   Integrate Supabase Authentication to handle user registration, login, and session management (e.g., email/password, social logins).
    *   Apply authentication checks to protect sensitive actions and ensure that users can only manage their own data (e.g., adding or marking recipes as favorites).

## 7. AppleScript Integration (Local to Remote)

*   **Objective:** Connect existing AppleScript workflows for creating recipes and ingredient lists to the new Supabase backend.
*   **Considerations:** Since AppleScripts run locally on the user's machine and Supabase is a remote service, direct integration requires a bridge.
*   **Recommended Approach (API Endpoint):**
    *   Develop small API endpoints (e.g., using Supabase Edge Functions, or a minimal Node.js/Python server) that the AppleScripts can call via HTTP POST requests.
    *   AppleScripts would be modified to use `curl` commands to send recipe data or grocery items to these API endpoints, which would then insert the data into the respective Supabase tables.
    *   This approach supports the workflow where AppleScripts generate recipes locally, and the user then decides to "save" them to the app by triggering an API call.

## 8. Deployment

*   **Objective:** Make the application accessible to end-users.
*   **Steps:**
    *   For the React Native application, deployment can involve building for iOS and Android app stores, or using platforms like Expo Go for easy sharing and testing during development.
    *   The Supabase backend is already a hosted service.