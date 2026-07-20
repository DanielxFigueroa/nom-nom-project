import React, { useState } from 'react';
import {
  StyleSheet,
  View,
  TextInput,
  Pressable,
  ScrollView,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Image } from 'expo-image';
import * as ImagePicker from 'expo-image-picker';
import MaterialIcons from '@expo/vector-icons/MaterialIcons';
import Markdown from 'react-native-markdown-display';

import { ThemedText } from './themed-text';
import { useThemeColor } from '@/hooks/use-theme-color';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { supabase } from '../src/lib/supabase';
import type { Recipe, Ingredient } from '../src/types/recipe';

// Common seafood keywords for PCOS food substitutions warning
const SEAFOOD_KEYWORDS = [
  'seafood', 'shrimp', 'fish', 'salmon', 'tuna', 'crab', 'lobster', 
  'prawn', 'cod', 'haddock', 'trout', 'halibut', 'mackerel', 'sardine', 
  'anchovy', 'scallop', 'clam', 'mussel', 'oyster', 'squid', 'octopus',
  'calamari', 'prawns', 'scallops', 'clams', 'mussels', 'oysters'
];

interface RecipeFormProps {
  initialData?: Partial<Recipe>;
  initialIngredients?: Ingredient[];
  onSubmit: (
    recipe: {
      title: string;
      description: string;
      instructions: string;
      image_url: string;
    },
    ingredients: {
      name: string;
      quantity?: string;
      unit?: string;
    }[]
  ) => Promise<void>;
  submitButtonText?: string;
  isSubmitting?: boolean;
}

export function RecipeForm({
  initialData,
  initialIngredients,
  onSubmit,
  submitButtonText = 'Save Recipe',
  isSubmitting = false,
}: RecipeFormProps) {
  const colorScheme = useColorScheme();
  const theme = colorScheme ?? 'light';

  // Theme colors
  const textClr = useThemeColor({}, 'text');
  const tintClr = useThemeColor({}, 'tint');
  const cardBg = theme === 'dark' ? '#25282A' : '#F1F5F9';
  const borderClr = theme === 'dark' ? '#3E4246' : '#CBD5E1';
  const inputBg = theme === 'dark' ? '#1E2022' : '#FFFFFF';
  const placeholderClr = theme === 'dark' ? '#718096' : '#A0AEC0';

  // Steps state: 1: Details, 2: Ingredients, 3: Instructions
  const [step, setStep] = useState<1 | 2 | 3>(1);

  // Step 1: Details state
  const [title, setTitle] = useState(initialData?.title ?? '');
  const [description, setDescription] = useState(initialData?.description ?? '');
  const [imageUri, setImageUri] = useState<string | null>(initialData?.image_url ?? null);
  const [isUploading, setIsUploading] = useState(false);

  // Step 2: Ingredients state
  const [ingredients, setIngredients] = useState<
    { id?: string; name: string; quantity: string; unit: string }[]
  >(
    initialIngredients?.map((i) => ({
      id: i.id,
      name: i.name,
      quantity: i.quantity ? String(i.quantity) : '',
      unit: i.unit ?? '',
    })) ?? []
  );
  const [ingName, setIngName] = useState('');
  const [ingQty, setIngQty] = useState('');
  const [ingUnit, setIngUnit] = useState('');

  // Step 3: Instructions state
  const [instructions, setInstructions] = useState(initialData?.instructions ?? '');
  const [instructionMode, setInstructionMode] = useState<'write' | 'preview'>('write');

  // Helper: check if seafood warning should be shown for a name
  const isSeafood = (name: string) => {
    const cleaned = name.trim().toLowerCase();
    return SEAFOOD_KEYWORDS.some((kw) => cleaned.includes(kw));
  };

  // Image upload to Supabase Storage
  const handlePickImage = async () => {
    try {
      const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission Denied', 'We need photo library permissions to upload images.');
        return;
      }

      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ['images'],
        allowsEditing: true,
        aspect: [16, 10],
        quality: 0.8,
      });

      if (!result.canceled && result.assets && result.assets.length > 0) {
        const selected = result.assets[0].uri;
        setImageUri(selected);
        setIsUploading(true);

        const publicUrl = await uploadImageToSupabase(selected);
        if (publicUrl) {
          setImageUri(publicUrl);
        }
      }
    } catch (error) {
      console.error('Error selecting image:', error);
      Alert.alert('Error', 'Failed to pick image.');
    } finally {
      setIsUploading(false);
    }
  };

  const uploadImageToSupabase = async (localUri: string): Promise<string | null> => {
    try {
      const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL || '';
      if (!supabaseUrl || supabaseUrl.includes('placeholder')) {
        console.log('Skipping image upload to storage (placeholder supabase config).');
        return localUri;
      }

      const response = await fetch(localUri);
      const blob = await response.blob();
      const fileExt = localUri.split('.').pop() || 'jpg';
      const fileName = `${Math.random().toString(36).substring(2)}-${Date.now()}.${fileExt}`;
      const filePath = `${fileName}`;

      const { error } = await supabase.storage
        .from('recipes')
        .upload(filePath, blob, {
          contentType: `image/${fileExt === 'png' ? 'png' : 'jpeg'}`,
          upsert: true,
        });

      if (error) throw error;

      const { data: publicUrlData } = supabase.storage
        .from('recipes')
        .getPublicUrl(filePath);

      return publicUrlData?.publicUrl || null;
    } catch (err) {
      console.error('Upload error details:', err);
      Alert.alert('Upload Warning', 'Failed to upload image to remote storage. Keeping local image path.');
      return localUri;
    }
  };

  // Add ingredient
  const handleAddIngredient = () => {
    if (!ingName.trim()) {
      Alert.alert('Validation Error', 'Ingredient name is required.');
      return;
    }
    setIngredients((prev) => [
      ...prev,
      {
        name: ingName.trim(),
        quantity: ingQty.trim(),
        unit: ingUnit.trim(),
      },
    ]);
    setIngName('');
    setIngQty('');
    setIngUnit('');
  };

  // Remove ingredient
  const handleRemoveIngredient = (index: number) => {
    setIngredients((prev) => prev.filter((_, i) => i !== index));
  };

  // Step Navigations
  const handleNext = () => {
    if (step === 1) {
      if (!title.trim()) {
        Alert.alert('Validation Error', 'Recipe Title is required.');
        return;
      }
      setStep(2);
    } else if (step === 2) {
      if (ingredients.length === 0) {
        Alert.alert('Validation Error', 'Please add at least one ingredient.');
        return;
      }
      setStep(3);
    }
  };

  const handleBack = () => {
    if (step === 2) setStep(1);
    if (step === 3) setStep(2);
  };

  // Submit Recipe Form
  const handleSave = async () => {
    if (!title.trim()) {
      Alert.alert('Validation Error', 'Recipe Title is required.');
      return;
    }
    if (ingredients.length === 0) {
      Alert.alert('Validation Error', 'Please add at least one ingredient.');
      return;
    }
    if (!instructions.trim()) {
      Alert.alert('Validation Error', 'Recipe instructions are required.');
      return;
    }

    const cleanIngredients = ingredients.map((i) => ({
      name: i.name,
      quantity: i.quantity || undefined,
      unit: i.unit || undefined,
    }));

    await onSubmit(
      {
        title: title.trim(),
        description: description.trim(),
        instructions: instructions.trim(),
        image_url: imageUri || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      },
      cleanIngredients
    );
  };

  // Markdown styling overrides
  const markdownStyles = {
    body: { color: textClr, fontSize: 15, lineHeight: 22 },
    heading1: { color: textClr, fontSize: 20, fontWeight: 'bold' as const, marginVertical: 6 },
    heading2: { color: textClr, fontSize: 18, fontWeight: 'bold' as const, marginVertical: 4 },
    list_item: { marginVertical: 2 },
    paragraph: { marginVertical: 4 },
    strong: { fontWeight: 'bold' as const },
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={styles.keyboardContainer}
    >
      <View style={styles.container}>
        {/* Step Progress Header */}
        <View style={styles.progressHeader}>
          <View style={styles.stepsTextRow}>
            <ThemedText style={styles.stepTitle}>
              {step === 1 ? 'Recipe Details' : step === 2 ? 'Ingredients List' : 'Cooking Instructions'}
            </ThemedText>
            <ThemedText style={styles.stepIndicator}>Step {step} of 3</ThemedText>
          </View>
          <View style={[styles.progressBar, { backgroundColor: borderClr }]}>
            <View
              style={[
                styles.progressBarFill,
                {
                  backgroundColor: tintClr,
                  width: step === 1 ? '33.3%' : step === 2 ? '66.6%' : '100%',
                },
              ]}
            />
          </View>
        </View>

        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          {/* STEP 1: DETAILS */}
          {step === 1 && (
            <View style={styles.stepContainer} testID="step-1-details">
              <View style={styles.inputGroup}>
                <ThemedText style={styles.label}>Recipe Title *</ThemedText>
                <TextInput
                  style={[styles.input, { color: textClr, borderColor: borderClr, backgroundColor: inputBg }]}
                  placeholder="Enter recipe title..."
                  placeholderTextColor={placeholderClr}
                  value={title}
                  onChangeText={setTitle}
                  testID="form-title-input"
                />
              </View>

              <View style={styles.inputGroup}>
                <ThemedText style={styles.label}>Description</ThemedText>
                <TextInput
                  style={[
                    styles.input,
                    styles.textArea,
                    { color: textClr, borderColor: borderClr, backgroundColor: inputBg },
                  ]}
                  placeholder="Describe your recipe briefly..."
                  placeholderTextColor={placeholderClr}
                  value={description}
                  onChangeText={setDescription}
                  multiline
                  numberOfLines={3}
                  textAlignVertical="top"
                  testID="form-description-input"
                />
              </View>

              <View style={styles.inputGroup}>
                <ThemedText style={styles.label}>Cover Image</ThemedText>
                <Pressable
                  style={[
                    styles.imagePickerCard,
                    { borderColor: borderClr, backgroundColor: cardBg },
                  ]}
                  onPress={handlePickImage}
                  testID="form-image-picker-button"
                >
                  {isUploading ? (
                    <ActivityIndicator size="large" color={tintClr} />
                  ) : imageUri ? (
                    <View style={styles.previewImageContainer}>
                      <Image source={{ uri: imageUri }} style={styles.previewImage} contentFit="cover" />
                      <View style={styles.imageOverlay}>
                        <MaterialIcons name="photo-camera" size={24} color="#FFF" />
                        <ThemedText style={styles.overlayText}>Change Image</ThemedText>
                      </View>
                    </View>
                  ) : (
                    <View style={styles.placeholderImageContainer}>
                      <MaterialIcons name="add-a-photo" size={32} color={tintClr} />
                      <ThemedText style={styles.placeholderImageText}>
                        Select a recipe image
                      </ThemedText>
                    </View>
                  )}
                </Pressable>
              </View>
            </View>
          )}

          {/* STEP 2: INGREDIENTS */}
          {step === 2 && (
            <View style={styles.stepContainer} testID="step-2-ingredients">
              <ThemedText style={styles.subText}>
                Add ingredients for your recipe below. Ensure they comply with PCOS guidelines.
              </ThemedText>

              {/* Add Ingredient Sub-Form */}
              <View style={[styles.addIngCard, { backgroundColor: cardBg, borderColor: borderClr }]}>
                <ThemedText style={styles.cardHeader}>Add Ingredient</ThemedText>

                <View style={styles.ingInputsRow}>
                  <View style={styles.qtyCol}>
                    <TextInput
                      style={[
                        styles.input,
                        { color: textClr, borderColor: borderClr, backgroundColor: inputBg },
                      ]}
                      placeholder="Qty"
                      placeholderTextColor={placeholderClr}
                      value={ingQty}
                      onChangeText={setIngQty}
                      testID="ing-qty-input"
                    />
                  </View>

                  <View style={styles.unitCol}>
                    <TextInput
                      style={[
                        styles.input,
                        { color: textClr, borderColor: borderClr, backgroundColor: inputBg },
                      ]}
                      placeholder="Unit"
                      placeholderTextColor={placeholderClr}
                      value={ingUnit}
                      onChangeText={setIngUnit}
                      testID="ing-unit-input"
                    />
                  </View>

                  <View style={styles.nameCol}>
                    <TextInput
                      style={[
                        styles.input,
                        { color: textClr, borderColor: borderClr, backgroundColor: inputBg },
                      ]}
                      placeholder="Name (e.g. Chicken)"
                      placeholderTextColor={placeholderClr}
                      value={ingName}
                      onChangeText={setIngName}
                      testID="ing-name-input"
                    />
                  </View>
                </View>

                {/* Seafood Warnings */}
                {isSeafood(ingName) && (
                  <View style={styles.warningContainer} testID="seafood-warning">
                    <MaterialIcons name="warning" size={18} color="#D69E2E" />
                    <ThemedText style={styles.warningText}>
                      PCOS Health Warning: Seafood requires dietary substitution. Consider substituting with organic chicken, turkey, or tofu.
                    </ThemedText>
                  </View>
                )}

                <Pressable
                  style={[styles.addIngButton, { backgroundColor: tintClr }]}
                  onPress={handleAddIngredient}
                  testID="add-ing-submit"
                >
                  <MaterialIcons name="add" size={20} color="#FFF" />
                  <ThemedText style={styles.addIngButtonText}>Add to List</ThemedText>
                </Pressable>
              </View>

              {/* Added Ingredients List */}
              <View style={styles.listSection}>
                <ThemedText style={styles.label}>Ingredients List ({ingredients.length})</ThemedText>
                {ingredients.length === 0 ? (
                  <View style={styles.emptyIngredients}>
                    <MaterialIcons name="shopping-basket" size={40} color={placeholderClr} />
                    <ThemedText style={[styles.emptyIngredientsText, { color: placeholderClr }]}>
                      No ingredients added yet.
                    </ThemedText>
                  </View>
                ) : (
                  ingredients.map((item, idx) => {
                    const hasWarning = isSeafood(item.name);
                    return (
                      <View
                        key={idx}
                        style={[
                          styles.ingredientRowItem,
                          { borderColor: borderClr, backgroundColor: cardBg },
                          hasWarning && styles.warningRowItem,
                        ]}
                        testID={`added-ingredient-${idx}`}
                      >
                        <View style={styles.ingRowInfo}>
                          <ThemedText style={styles.ingLabel}>
                            {[item.quantity, item.unit, item.name].filter(Boolean).join(' ')}
                          </ThemedText>
                          {hasWarning && (
                            <ThemedText style={styles.ingRowWarningLabel}>
                              ⚠️ Substitution needed
                            </ThemedText>
                          )}
                        </View>
                        <Pressable
                          style={styles.removeIngBtn}
                          onPress={() => handleRemoveIngredient(idx)}
                          testID={`remove-ingredient-${idx}`}
                        >
                          <MaterialIcons name="delete" size={20} color="#E53E3E" />
                        </Pressable>
                      </View>
                    );
                  })
                )}
              </View>
            </View>
          )}

          {/* STEP 3: INSTRUCTIONS */}
          {step === 3 && (
            <View style={styles.stepContainer} testID="step-3-instructions">
              {/* Write/Preview Tabs */}
              <View style={[styles.tabBar, { borderColor: borderClr }]}>
                <Pressable
                  style={[
                    styles.tab,
                    instructionMode === 'write' && { borderBottomColor: tintClr, borderBottomWidth: 2 },
                  ]}
                  onPress={() => setInstructionMode('write')}
                  testID="tab-write"
                >
                  <ThemedText
                    style={[
                      styles.tabText,
                      instructionMode === 'write' ? { color: tintClr, fontWeight: 'bold' } : { color: placeholderClr },
                    ]}
                  >
                    Write Instructions
                  </ThemedText>
                </Pressable>
                <Pressable
                  style={[
                    styles.tab,
                    instructionMode === 'preview' && { borderBottomColor: tintClr, borderBottomWidth: 2 },
                  ]}
                  onPress={() => setInstructionMode('preview')}
                  testID="tab-preview"
                >
                  <ThemedText
                    style={[
                      styles.tabText,
                      instructionMode === 'preview' ? { color: tintClr, fontWeight: 'bold' } : { color: placeholderClr },
                    ]}
                  >
                    Markdown Preview
                  </ThemedText>
                </Pressable>
              </View>

              {instructionMode === 'write' ? (
                <View style={styles.inputGroup}>
                  <ThemedText style={styles.label}>Instructions (Markdown supported) *</ThemedText>
                  <TextInput
                    style={[
                      styles.input,
                      styles.instructionsTextArea,
                      { color: textClr, borderColor: borderClr, backgroundColor: inputBg },
                    ]}
                    placeholder="Provide detailed instructions. You can use markdown (e.g. ## Step 1, * bullets)..."
                    placeholderTextColor={placeholderClr}
                    value={instructions}
                    onChangeText={setInstructions}
                    multiline
                    textAlignVertical="top"
                    testID="form-instructions-input"
                  />
                </View>
              ) : (
                <View style={[styles.previewBox, { backgroundColor: cardBg, borderColor: borderClr }]} testID="instructions-markdown-preview">
                  {instructions.trim() ? (
                    <Markdown style={markdownStyles}>{instructions}</Markdown>
                  ) : (
                    <ThemedText style={[styles.emptyPreviewText, { color: placeholderClr }]}>
                      Instructions preview will appear here.
                    </ThemedText>
                  )}
                </View>
              )}
            </View>
          )}
        </ScrollView>

        {/* Footer Navigation Buttons */}
        <View style={[styles.footer, { borderTopColor: borderClr, backgroundColor: cardBg }]}>
          {step > 1 ? (
            <Pressable
              style={[styles.navButton, styles.outlineButton, { borderColor: tintClr }]}
              onPress={handleBack}
              disabled={isSubmitting}
              testID="form-back-button"
            >
              <ThemedText style={[styles.navButtonText, { color: tintClr }]}>Back</ThemedText>
            </Pressable>
          ) : (
            <View style={styles.spacer} />
          )}

          {step < 3 ? (
            <Pressable
              style={[styles.navButton, { backgroundColor: tintClr }]}
              onPress={handleNext}
              testID="form-next-button"
            >
              <ThemedText style={styles.primaryButtonText}>Next</ThemedText>
            </Pressable>
          ) : (
            <Pressable
              style={[styles.navButton, { backgroundColor: tintClr }]}
              onPress={handleSave}
              disabled={isSubmitting}
              testID="form-save-button"
            >
              {isSubmitting ? (
                <ActivityIndicator size="small" color="#FFF" />
              ) : (
                <ThemedText style={styles.primaryButtonText}>{submitButtonText}</ThemedText>
              )}
            </Pressable>
          )}
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  keyboardContainer: {
    flex: 1,
  },
  container: {
    flex: 1,
  },
  progressHeader: {
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 8,
  },
  stepsTextRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  stepTitle: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  stepIndicator: {
    fontSize: 14,
    opacity: 0.6,
  },
  progressBar: {
    height: 6,
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    borderRadius: 3,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    padding: 20,
    paddingBottom: 40,
  },
  stepContainer: {
    flex: 1,
  },
  subText: {
    fontSize: 14,
    opacity: 0.6,
    marginBottom: 16,
  },
  inputGroup: {
    marginBottom: 20,
  },
  label: {
    fontSize: 15,
    fontWeight: '600',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 16,
  },
  textArea: {
    height: 90,
  },
  instructionsTextArea: {
    height: 250,
  },
  imagePickerCard: {
    borderWidth: 1,
    borderStyle: 'dashed',
    borderRadius: 12,
    height: 180,
    justifyContent: 'center',
    alignItems: 'center',
    overflow: 'hidden',
  },
  previewImageContainer: {
    width: '100%',
    height: '100%',
  },
  previewImage: {
    width: '100%',
    height: '100%',
  },
  imageOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  overlayText: {
    color: '#FFF',
    fontSize: 14,
    fontWeight: 'bold',
    marginTop: 4,
  },
  placeholderImageContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  placeholderImageText: {
    fontSize: 14,
    marginTop: 8,
    opacity: 0.8,
  },

  // Ingredients Adding Sub-form
  addIngCard: {
    borderWidth: 1,
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
  },
  cardHeader: {
    fontSize: 15,
    fontWeight: 'bold',
    marginBottom: 12,
  },
  ingInputsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  qtyCol: {
    width: '20%',
  },
  unitCol: {
    width: '25%',
  },
  nameCol: {
    width: '50%',
  },
  addIngButton: {
    flexDirection: 'row',
    height: 44,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
  },
  addIngButtonText: {
    color: '#FFF',
    fontWeight: 'bold',
    fontSize: 14,
    marginLeft: 6,
  },
  warningContainer: {
    flexDirection: 'row',
    backgroundColor: 'rgba(214, 158, 46, 0.15)',
    borderRadius: 8,
    padding: 10,
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  warningText: {
    fontSize: 13,
    color: '#D69E2E',
    flex: 1,
    marginLeft: 6,
    lineHeight: 18,
  },

  // Ingredients List UI
  listSection: {
    marginTop: 10,
  },
  emptyIngredients: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 30,
  },
  emptyIngredientsText: {
    marginTop: 8,
    fontSize: 14,
  },
  ingredientRowItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 8,
  },
  warningRowItem: {
    borderColor: '#D69E2E',
    borderWidth: 1,
  },
  ingRowInfo: {
    flex: 1,
  },
  ingLabel: {
    fontSize: 15,
  },
  ingRowWarningLabel: {
    fontSize: 11,
    color: '#D69E2E',
    marginTop: 2,
    fontWeight: '600',
  },
  removeIngBtn: {
    padding: 4,
    marginLeft: 8,
  },

  // Instructions step tabs
  tabBar: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    marginBottom: 16,
  },
  tab: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
  },
  tabText: {
    fontSize: 15,
  },
  previewBox: {
    borderWidth: 1,
    borderRadius: 10,
    padding: 16,
    minHeight: 250,
  },
  emptyPreviewText: {
    textAlign: 'center',
    marginTop: 80,
    fontSize: 14,
  },

  // Footer Navigation Bar
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 16,
    paddingBottom: Platform.OS === 'ios' ? 30 : 16,
    borderTopWidth: 1,
  },
  navButton: {
    height: 48,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    minWidth: 110,
  },
  outlineButton: {
    borderWidth: 1,
    backgroundColor: 'transparent',
  },
  navButtonText: {
    fontSize: 15,
    fontWeight: 'bold',
  },
  primaryButtonText: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#FFF',
  },
  spacer: {
    width: 110,
  },
});
