/* eslint-disable @typescript-eslint/no-require-imports */
import React from 'react';
import { render } from '@testing-library/react-native';
import FavoritesScreen from '../favorites';

jest.mock('../../../src/contexts/AuthContext', () => ({
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

let mockDatabaseData: any[] = [];

// Chainable mock for Supabase query builder
const createQueryMock = () => {
  const getPromise = () => Promise.resolve({ data: mockDatabaseData, error: null });
  const mockObj: any = {
    then: (onfulfilled: any, onrejected: any) => getPromise().then(onfulfilled, onrejected),
    catch: (onrejected: any) => getPromise().catch(onrejected),
    eq: jest.fn(() => mockObj),
    select: jest.fn(() => mockObj),
  };
  return mockObj;
};

jest.mock('../../../src/lib/supabase', () => ({
  supabase: {
    from: jest.fn(() => createQueryMock()),
  },
}));

describe('FavoritesScreen', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockDatabaseData = [];
  });

  it('renders favorites screen title and favorite recipes', async () => {
    mockDatabaseData = [
      {
        id: 'fav-1',
        title: 'Favorite Avocado Toast',
        image_url: 'url1',
        household_id: 'test-household-id',
        is_favorite: true,
      },
    ];

    const { findByText, findByTestId } = render(<FavoritesScreen />);

    expect(await findByTestId('favorites-screen')).toBeTruthy();
    expect(await findByText('Favorites')).toBeTruthy();
    expect(await findByText('Favorite Avocado Toast')).toBeTruthy();
    expect(await findByTestId('favorite-badge-fav-1')).toBeTruthy();
  });

  it('renders empty favorites state when no recipes are bookmarked', async () => {
    mockDatabaseData = [];

    const { findByText } = render(<FavoritesScreen />);

    expect(await findByText('No favorite recipes yet. Bookmark recipes to view them here!')).toBeTruthy();
  });
});
