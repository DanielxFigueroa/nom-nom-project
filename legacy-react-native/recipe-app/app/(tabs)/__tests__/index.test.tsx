import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';
import ExploreScreen from '../index';

jest.mock('@/components/RecipeList', () => ({
  RecipeList: jest.fn(({ searchQuery }) => null),
}));

describe('ExploreScreen', () => {
  it('renders title and SearchBar', () => {
    const { getByText, getByPlaceholderText } = render(<ExploreScreen />);
    expect(getByText('Explore')).toBeTruthy();
    expect(getByPlaceholderText('Search recipes or ingredients...')).toBeTruthy();
  });

  it('updates search query when user types into SearchBar', () => {
    const { getByTestId } = render(<ExploreScreen />);
    const searchInput = getByTestId('search-bar-input');

    fireEvent.changeText(searchInput, 'Quinoa');
    expect(searchInput.props.value).toBe('Quinoa');
  });
});
