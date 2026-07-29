/* eslint-disable @typescript-eslint/no-require-imports */
import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';
import { SearchBar } from '../SearchBar';

describe('SearchBar Component', () => {
  it('renders correctly with placeholder and value', () => {
    const { getByPlaceholderText, getByDisplayValue } = render(
      <SearchBar value="Salmon" onChangeText={jest.fn()} />
    );

    expect(getByPlaceholderText('Search recipes or ingredients...')).toBeTruthy();
    expect(getByDisplayValue('Salmon')).toBeTruthy();
  });

  it('calls onChangeText when text changes', () => {
    const onChangeTextMock = jest.fn();
    const { getByTestId } = render(
      <SearchBar value="" onChangeText={onChangeTextMock} />
    );

    const input = getByTestId('search-bar-input');
    fireEvent.changeText(input, 'Chicken');

    expect(onChangeTextMock).toHaveBeenCalledWith('Chicken');
  });

  it('renders clear button when value is non-empty and handles clear', () => {
    const onChangeTextMock = jest.fn();
    const onClearMock = jest.fn();
    const { getByTestId } = render(
      <SearchBar value="Avocado" onChangeText={onChangeTextMock} onClear={onClearMock} />
    );

    const clearBtn = getByTestId('search-bar-clear-btn');
    expect(clearBtn).toBeTruthy();

    fireEvent.press(clearBtn);
    expect(onChangeTextMock).toHaveBeenCalledWith('');
    expect(onClearMock).toHaveBeenCalled();
  });

  it('does not render clear button when value is empty', () => {
    const { queryByTestId } = render(
      <SearchBar value="" onChangeText={jest.fn()} />
    );

    expect(queryByTestId('search-bar-clear-btn')).toBeNull();
  });
});
