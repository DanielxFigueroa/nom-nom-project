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

jest.mock('expo-image', () => {
  const React = require('react');
  const { View } = require('react-native');
  return {
    Image: jest.fn((props) => React.createElement(View, props)),
  };
});

jest.mock('../../src/lib/supabase', () => ({
  supabase: {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn().mockResolvedValue({
          data: [
            { id: '1', title: 'Test Recipe 1', image_url: 'url1', household_id: '123' },
            { id: '2', title: 'Test Recipe 2', image_url: 'url2', household_id: '123' },
          ],
          error: null,
        }),
      })),
    })),
  },
}));

describe('RecipeList Component', () => {
  it('renders correctly', async () => {
    const { findByText } = render(<RecipeList />);
    
    const recipe1 = await findByText('Test Recipe 1');
    const recipe2 = await findByText('Test Recipe 2');
    
    expect(recipe1).toBeTruthy();
    expect(recipe2).toBeTruthy();
  });
});
