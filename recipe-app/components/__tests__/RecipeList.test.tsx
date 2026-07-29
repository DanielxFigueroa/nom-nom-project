/* eslint-disable @typescript-eslint/no-require-imports */
import React from 'react';
import { render } from '@testing-library/react-native';
import { RecipeList } from '../RecipeList';

// Mock dependencies
jest.mock('../../src/contexts/AuthContext', () => ({
  useAuth: () => ({ householdId: 'test-household-id' }),
}));

jest.mock('expo-router', () => ({
  useRouter: () => ({ push: jest.fn() }),
}));

jest.mock('@react-navigation/native', () => ({
  useFocusEffect: (callback: () => void) => require('react').useEffect(callback, []),
}));

jest.mock('expo-image', () => {
  const React = require('react');
  const { View } = require('react-native');
  return {
    Image: jest.fn((props) => React.createElement(View, props)),
  };
});

const mockRecipes = [
  {
    id: '1',
    title: 'Avocado Toast',
    image_url: 'url1',
    household_id: '123',
    ingredients: [
      { id: 'i1', recipe_id: '1', name: 'Avocado' },
      { id: 'i2', recipe_id: '1', name: 'Sourdough Bread' },
    ],
  },
  {
    id: '2',
    title: 'Grilled Salmon Bowl',
    image_url: 'url2',
    household_id: '123',
    ingredients: [
      { id: 'i3', recipe_id: '2', name: 'Wild Salmon' },
      { id: 'i4', recipe_id: '2', name: 'Quinoa' },
    ],
  },
];

jest.mock('../../src/lib/supabase', () => ({
  supabase: {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn().mockResolvedValue({
          data: mockRecipes,
          error: null,
        }),
      })),
    })),
  },
}));

describe('RecipeList Component', () => {
  it('renders all recipes when searchQuery is empty', async () => {
    const { findByText } = render(<RecipeList searchQuery="" />);

    const recipe1 = await findByText('Avocado Toast');
    const recipe2 = await findByText('Grilled Salmon Bowl');

    expect(recipe1).toBeTruthy();
    expect(recipe2).toBeTruthy();
  });

  it('filters recipes by title (case-insensitive)', async () => {
    const { findByText, queryByText } = render(<RecipeList searchQuery="salmon" />);

    const recipe2 = await findByText('Grilled Salmon Bowl');
    expect(recipe2).toBeTruthy();
    expect(queryByText('Avocado Toast')).toBeNull();
  });

  it('filters recipes by ingredient name (case-insensitive)', async () => {
    const { findByText, queryByText } = render(<RecipeList searchQuery="sourdough" />);

    const recipe1 = await findByText('Avocado Toast');
    expect(recipe1).toBeTruthy();
    expect(queryByText('Grilled Salmon Bowl')).toBeNull();
  });

  it('displays empty search results message when query matches nothing', async () => {
    const { findByText, queryByText } = render(<RecipeList searchQuery="Pizza" />);

    const noResults = await findByText('No recipes matching "Pizza"');
    expect(noResults).toBeTruthy();
    expect(queryByText('Avocado Toast')).toBeNull();
    expect(queryByText('Grilled Salmon Bowl')).toBeNull();
  });
});
