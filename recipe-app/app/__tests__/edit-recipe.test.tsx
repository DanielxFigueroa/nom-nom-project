/* eslint-disable @typescript-eslint/no-require-imports */
import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import EditRecipeScreen from '../edit-recipe';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const mockSetOptions = jest.fn();
const mockBack = jest.fn();
const mockReplace = jest.fn();

jest.mock('expo-router', () => ({
  useLocalSearchParams: () => ({ id: 'recipe-1' }),
  useNavigation: () => ({
    setOptions: mockSetOptions,
  }),
  useRouter: () => ({
    back: mockBack,
    replace: mockReplace,
  }),
}));

jest.mock('expo-image', () => {
  const RN = require('react-native');
  return {
    Image: jest.fn((props: any) =>
      require('react').createElement(RN.View, { ...props, testID: props.testID }),
    ),
  };
});

jest.mock('expo-image-picker', () => ({
  requestMediaLibraryPermissionsAsync: jest.fn().mockResolvedValue({ status: 'granted' }),
  launchImageLibraryAsync: jest.fn().mockResolvedValue({
    canceled: false,
    assets: [{ uri: 'https://example.com/selected-image.jpg' }],
  }),
}));

jest.mock('@expo/vector-icons/MaterialIcons', () => {
  const RN = require('react-native');
  return (props: any) =>
    require('react').createElement(RN.Text, {}, `[Icon: ${props.name}]`);
});

jest.mock('react-native-markdown-display', () => {
  const RN = require('react-native');
  return {
    __esModule: true,
    default: ({ children }: { children: string }) =>
      require('react').createElement(RN.Text, { testID: 'markdown-content' }, children),
  };
});

// Mock Alert
const mockAlert = jest.spyOn(require('react-native').Alert, 'alert');

const mockRecipe = {
  id: 'recipe-1',
  title: 'Edit Test Recipe',
  description: 'Original description',
  instructions: 'Original instructions',
  image_url: 'https://example.com/original.jpg',
  household_id: 'household-123',
};

const mockIngredients = [
  { id: 'ing-1', recipe_id: 'recipe-1', name: 'Original Item 1', quantity: '1', unit: 'tbsp' }
];

// Chainable Supabase mocks
const mockSingleFn = jest.fn().mockResolvedValue({ data: mockRecipe, error: null });
const mockEqRecipes = jest.fn(() => ({ single: mockSingleFn }));
const mockSelectRecipes = jest.fn(() => ({ eq: mockEqRecipes }));
const mockUpdateRecipes = jest.fn(() => ({ eq: jest.fn().mockResolvedValue({ error: null }) }));
const mockDeleteRecipes = jest.fn(() => ({ eq: jest.fn().mockResolvedValue({ error: null }) }));

const mockEqIngredients = jest.fn().mockResolvedValue({ data: mockIngredients, error: null });
const mockSelectIngredients = jest.fn(() => ({ eq: mockEqIngredients }));
const mockDeleteIngredients = jest.fn(() => ({ eq: jest.fn().mockResolvedValue({ error: null }) }));
const mockInsertIngredients = jest.fn().mockResolvedValue({ error: null });

jest.mock('../../src/lib/supabase', () => ({
  supabase: {
    from: jest.fn((table: string) => {
      if (table === 'recipes') {
        return {
          select: mockSelectRecipes,
          update: mockUpdateRecipes,
          delete: mockDeleteRecipes,
        };
      }
      if (table === 'ingredients') {
        return {
          select: mockSelectIngredients,
          delete: mockDeleteIngredients,
          insert: mockInsertIngredients,
        };
      }
      return { select: jest.fn() };
    }),
    storage: {
      from: jest.fn(() => ({
        upload: jest.fn().mockResolvedValue({ data: { path: 'path' }, error: null }),
        getPublicUrl: jest.fn().mockReturnValue({ data: { publicUrl: 'https://example.com/uploaded.jpg' } }),
      })),
    },
  },
}));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('EditRecipeScreen', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders loading state initially', () => {
    const { getByTestId } = render(<EditRecipeScreen />);
    expect(getByTestId('loading-state')).toBeTruthy();
  });

  it('pre-populates the form with fetched recipe details', async () => {
    const { findByTestId, findByDisplayValue } = render(<EditRecipeScreen />);

    // Wait for load
    const titleInput = await findByDisplayValue('Edit Test Recipe');
    const descInput = await findByDisplayValue('Original description');
    
    expect(titleInput).toBeTruthy();
    expect(descInput).toBeTruthy();
  });

  it('allows navigation between steps and changing values', async () => {
    const { findByDisplayValue, findByTestId, findByText } = render(<EditRecipeScreen />);
    
    // Step 1 title change
    const titleInput = await findByDisplayValue('Edit Test Recipe');
    fireEvent.changeText(titleInput, 'Updated Recipe Title');

    // Click next to go to Step 2: Ingredients
    const nextBtn = await findByTestId('form-next-button');
    fireEvent.press(nextBtn);

    // Verify step 2 screen loads (should display ingredients)
    const ingredientItem = await findByText('1 tbsp Original Item 1');
    expect(ingredientItem).toBeTruthy();
  });

  it('handles adding and removing ingredients dynamically', async () => {
    const { findByTestId, findByText, queryByText } = render(<EditRecipeScreen />);
    
    // Go to step 2
    const nextBtn = await findByTestId('form-next-button');
    fireEvent.press(nextBtn);

    // Enter details for new ingredient
    const nameInput = await findByTestId('ing-name-input');
    const qtyInput = await findByTestId('ing-qty-input');
    const unitInput = await findByTestId('ing-unit-input');
    const addSubmit = await findByTestId('add-ing-submit');

    fireEvent.changeText(nameInput, 'Organic Tofu');
    fireEvent.changeText(qtyInput, '200');
    fireEvent.changeText(unitInput, 'g');
    fireEvent.press(addSubmit);

    // Verify organic tofu is added
    const newIng = await findByText('200 g Organic Tofu');
    expect(newIng).toBeTruthy();

    // Remove the original item (index 0)
    const removeBtn = await findByTestId('remove-ingredient-0');
    fireEvent.press(removeBtn);

    // Verify original item is removed
    await waitFor(() => {
      expect(queryByText('1 tbsp Original Item 1')).toBeNull();
    });
  });

  it('shows PCOS seafood warning alert when typing seafood ingredients', async () => {
    const { findByTestId } = render(<EditRecipeScreen />);
    
    // Go to step 2
    const nextBtn = await findByTestId('form-next-button');
    fireEvent.press(nextBtn);

    // Input seafood
    const nameInput = await findByTestId('ing-name-input');
    fireEvent.changeText(nameInput, 'Shrimp');

    // Warning text container should appear
    const warning = await findByTestId('seafood-warning');
    expect(warning).toBeTruthy();
  });

  it('triggers delete confirmation alert when clicking delete button', async () => {
    const { findByTestId } = render(<EditRecipeScreen />);
    
    // Wait for load
    const deleteBtn = await findByTestId('delete-recipe-btn');
    fireEvent.press(deleteBtn);

    // Verify Alert.alert is triggered
    expect(mockAlert).toHaveBeenCalledWith(
      'Delete Recipe',
      expect.stringContaining('Edit Test Recipe'),
      expect.any(Array)
    );
  });
});
