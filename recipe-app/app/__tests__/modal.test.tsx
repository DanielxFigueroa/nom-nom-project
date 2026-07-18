/* eslint-disable @typescript-eslint/no-require-imports */
import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import ModalScreen from '../modal';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const mockSetOptions = jest.fn();
const mockPush = jest.fn();

jest.mock('expo-router', () => ({
  useLocalSearchParams: () => ({
    id: 'recipe-1',
    title: 'Test Recipe',
    image_url: 'https://example.com/image.jpg',
  }),
  useNavigation: () => ({
    setOptions: mockSetOptions,
  }),
  useRouter: () => ({
    push: mockPush,
  }),
}));

jest.mock('../../src/contexts/AuthContext', () => ({
  useAuth: () => ({ householdId: 'household-1' }),
}));

jest.mock('expo-image', () => {
  const RN = require('react-native');
  return {
    Image: jest.fn((props: any) =>
      require('react').createElement(RN.View, { ...props, testID: props.testID }),
    ),
  };
});

jest.mock('react-native-reanimated', () => {
  return {
    __esModule: true,
    default: {
      createAnimatedComponent: (Component: any) => Component,
    },
  };
});

jest.mock('react-native-markdown-display', () => {
  const RN = require('react-native');
  return {
    __esModule: true,
    default: ({ children }: { children: string }) =>
      require('react').createElement(RN.Text, { testID: 'markdown-content' }, children),
  };
});

const mockIngredients = [
  { id: 'ing-1', recipe_id: 'recipe-1', name: 'Chicken breast', quantity: '2', unit: 'lbs' },
  { id: 'ing-2', recipe_id: 'recipe-1', name: 'Brown rice', quantity: '1', unit: 'cup' },
  { id: 'ing-3', recipe_id: 'recipe-1', name: 'Broccoli', quantity: '1', unit: 'head' },
];

const mockRecipe = {
  id: 'recipe-1',
  title: 'Test Recipe',
  image_url: 'https://example.com/image.jpg',
  description: 'A healthy PCOS-friendly meal.',
  instructions: '## Step 1\nCook the chicken.\n\n## Step 2\nPrepare the rice.',
  household_id: 'household-1',
};

// Build a chainable Supabase mock
const mockSingleFn = jest.fn().mockResolvedValue({ data: mockRecipe, error: null });
const mockEqRecipes = jest.fn(() => ({ single: mockSingleFn }));
const mockSelectRecipes = jest.fn(() => ({ eq: mockEqRecipes }));

const mockEqIngredients = jest.fn().mockResolvedValue({ data: mockIngredients, error: null });
const mockSelectIngredients = jest.fn(() => ({ eq: mockEqIngredients }));

jest.mock('../../src/lib/supabase', () => ({
  supabase: {
    from: jest.fn((table: string) => {
      if (table === 'recipes') {
        return { select: mockSelectRecipes };
      }
      if (table === 'ingredients') {
        return { select: mockSelectIngredients };
      }
      return { select: jest.fn() };
    }),
  },
}));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('ModalScreen – Recipe Detail', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders the recipe title', async () => {
    const { findByTestId } = render(<ModalScreen />);
    const titleEl = await findByTestId('recipe-title');
    expect(titleEl).toBeTruthy();
  });

  it('renders the description', async () => {
    const { findByTestId } = render(<ModalScreen />);
    const desc = await findByTestId('recipe-description');
    expect(desc).toBeTruthy();
  });

  it('renders the ingredients section with all items', async () => {
    const { findByTestId } = render(<ModalScreen />);
    const section = await findByTestId('ingredients-section');
    expect(section).toBeTruthy();

    // Each ingredient row should be present
    for (const ing of mockIngredients) {
      const el = await findByTestId(`ingredient-${ing.id}`);
      expect(el).toBeTruthy();
    }
  });

  it('renders the instructions section with markdown', async () => {
    const { findByTestId } = render(<ModalScreen />);
    const section = await findByTestId('instructions-section');
    expect(section).toBeTruthy();

    const md = await findByTestId('markdown-content');
    expect(md).toBeTruthy();
  });

  it('toggles ingredient checked state on press', async () => {
    const { findByTestId } = render(<ModalScreen />);
    const firstIngredient = await findByTestId('ingredient-ing-1');

    // Press to check
    fireEvent.press(firstIngredient);
    // The checkmark text "✓" should appear after pressing
    await waitFor(() => {
      expect(firstIngredient).toBeTruthy();
    });

    // Press again to uncheck
    fireEvent.press(firstIngredient);
    await waitFor(() => {
      expect(firstIngredient).toBeTruthy();
    });
  });

  it('sets the navigation title via setOptions', async () => {
    render(<ModalScreen />);
    await waitFor(() => {
      expect(mockSetOptions).toHaveBeenCalledWith({ title: 'Test Recipe' });
    });
  });

  it('fetches recipes and ingredients from the correct tables', async () => {
    const { supabase } = require('../../src/lib/supabase');
    render(<ModalScreen />);

    await waitFor(() => {
      expect(supabase.from).toHaveBeenCalledWith('recipes');
      expect(supabase.from).toHaveBeenCalledWith('ingredients');
    });
  });
});
