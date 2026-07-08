import React from 'react';
import { render } from '@testing-library/react-native';
import ExploreScreen from '../index';

jest.mock('@/components/RecipeList', () => ({
  RecipeList: () => null,
}));

describe('ExploreScreen', () => {
  it('renders correctly', () => {
    const { getByText } = render(<ExploreScreen />);
    expect(getByText('Explore')).toBeTruthy();
  });
});
