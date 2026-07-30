/* eslint-disable @typescript-eslint/no-require-imports */
import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import { RecipeForm } from '../../components/RecipeForm';
import ModalScreen from '../modal';
import { supabase } from '../../src/lib/supabase';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
const mockSetOptions = jest.fn();
const mockPush = jest.fn();

jest.mock('expo-router', () => ({
  useLocalSearchParams: () => ({
    id: 'recipe-pcos-1',
    title: 'PCOS Friendly Salmon Bowl',
    image_url: 'https://example.com/salmon.jpg',
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

jest.mock('../../src/lib/supabase', () => ({
  supabase: {
    from: jest.fn(),
    rpc: jest.fn(),
  },
}));

describe('PCOS Nutritional Fields Integration', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('RecipeForm PCOS Inputs', () => {
    it('renders insulin index notes and meal timing inputs in step 1 and includes them in onSubmit payload', async () => {
      const mockOnSubmit = jest.fn().mockResolvedValue(undefined);

      const { getByTestId } = render(
        <RecipeForm
          onSubmit={mockOnSubmit}
          initialData={{
            title: 'Initial Title',
            description: 'Initial Description',
            insulin_index_notes: 'Low GI food score',
            meal_timing_suggestions: 'Best for breakfast',
            instructions: 'Cook well',
          }}
          initialIngredients={[{ id: 'ing-1', recipe_id: 'recipe-pcos-1', name: 'Chicken', quantity: '1', unit: 'lb' }]}
        />
      );

      const insulinInput = getByTestId('form-insulin-notes-input');
      const mealTimingInput = getByTestId('form-meal-timing-input');

      expect(insulinInput.props.value).toBe('Low GI food score');
      expect(mealTimingInput.props.value).toBe('Best for breakfast');

      // Update PCOS fields
      fireEvent.changeText(insulinInput, 'Updated insulin notes: High protein pairing');
      fireEvent.changeText(mealTimingInput, 'Updated timing: Post-workout meal');

      // Navigate to step 2
      fireEvent.press(getByTestId('form-next-button'));

      // Navigate to step 3
      fireEvent.press(getByTestId('form-next-button'));

      // Save recipe
      fireEvent.press(getByTestId('form-save-button'));

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'Initial Title',
            insulin_index_notes: 'Updated insulin notes: High protein pairing',
            meal_timing_suggestions: 'Updated timing: Post-workout meal',
          }),
          expect.any(Array)
        );
      });
    });
  });

  describe('ModalScreen PCOS Guidance Display', () => {
    it('displays PCOS Guidance section when recipe contains insulin_index_notes and meal_timing_suggestions', async () => {
      const mockPcosRecipe = {
        id: 'recipe-pcos-1',
        title: 'PCOS Friendly Salmon Bowl',
        image_url: 'https://example.com/salmon.jpg',
        description: 'Nutritious bowl',
        instructions: 'Mix and serve.',
        household_id: 'household-1',
        insulin_index_notes: 'Low glycemic load, minimizes insulin spikes.',
        meal_timing_suggestions: 'Ideal for lunch to sustain afternoon energy.',
      };

      (supabase.from as jest.Mock).mockImplementation((table: string) => {
        if (table === 'recipes') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockResolvedValue({ data: mockPcosRecipe, error: null }),
          };
        }
        if (table === 'ingredients') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockResolvedValue({ data: [], error: null }),
          };
        }
        return { select: jest.fn().mockReturnThis() };
      });

      const { findByTestId, findByText } = render(<ModalScreen />);

      expect(await findByTestId('pcos-guidance-section')).toBeTruthy();
      expect(await findByTestId('insulin-notes-card')).toBeTruthy();
      expect(await findByTestId('meal-timing-card')).toBeTruthy();
      expect(await findByText('Low glycemic load, minimizes insulin spikes.')).toBeTruthy();
      expect(await findByText('Ideal for lunch to sustain afternoon energy.')).toBeTruthy();
    });

    it('hides PCOS Guidance section when recipe lacks PCOS fields', async () => {
      const mockRegularRecipe = {
        id: 'recipe-pcos-1',
        title: 'Regular Salad',
        image_url: 'https://example.com/salad.jpg',
        description: 'Basic salad',
        instructions: 'Toss greens.',
        household_id: 'household-1',
        insulin_index_notes: null,
        meal_timing_suggestions: null,
      };

      (supabase.from as jest.Mock).mockImplementation((table: string) => {
        if (table === 'recipes') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockResolvedValue({ data: mockRegularRecipe, error: null }),
          };
        }
        if (table === 'ingredients') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockResolvedValue({ data: [], error: null }),
          };
        }
        return { select: jest.fn().mockReturnThis() };
      });

      const { queryByTestId, findByTestId } = render(<ModalScreen />);

      // Wait for recipe title to load
      await findByTestId('recipe-title');

      expect(queryByTestId('pcos-guidance-section')).toBeNull();
    });
  });
});
