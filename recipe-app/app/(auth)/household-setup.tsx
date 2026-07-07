import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { supabase } from '../../src/lib/supabase';
import { useAuth } from '../../src/contexts/AuthContext';
import { generateInviteCode } from '../../src/utils/household';

export default function HouseholdSetupScreen() {
  const [inviteCode, setInviteCode] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const { user, refreshProfile } = useAuth();

  const createHousehold = async () => {
    if (!user) return;
    setLoading(true);
    const newInviteCode = generateInviteCode();

    const { data: household, error: householdError } = await supabase
      .from('households')
      .insert({ invite_code: newInviteCode })
      .select()
      .single();

    if (householdError) {
      Alert.alert('Error', 'Failed to create household. Please try again.');
      setLoading(false);
      return;
    }

    const { error: profileError } = await supabase
      .from('profiles')
      .update({ household_id: household.id })
      .eq('id', user.id);

    if (profileError) {
      Alert.alert('Error', 'Failed to update profile.');
      setLoading(false);
      return;
    }

    await refreshProfile();
    router.replace('/');
  };

  const joinHousehold = async () => {
    if (!user) return;
    if (inviteCode.length !== 6) {
      Alert.alert('Invalid Code', 'Please enter a valid 6-character invite code.');
      return;
    }

    setLoading(true);

    const { data: household, error: queryError } = await supabase
      .from('households')
      .select('id')
      .eq('invite_code', inviteCode.toUpperCase())
      .single();

    if (queryError || !household) {
      Alert.alert('Not Found', 'Could not find a household with that invite code.');
      setLoading(false);
      return;
    }

    const { error: profileError } = await supabase
      .from('profiles')
      .update({ household_id: household.id })
      .eq('id', user.id);

    if (profileError) {
      Alert.alert('Error', 'Failed to update profile.');
      setLoading(false);
      return;
    }

    await refreshProfile();
    router.replace('/');
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Set Up Your Household</Text>
      
      <View style={styles.section}>
        <Text style={styles.subtitle}>Create a New Household</Text>
        <Text style={styles.description}>
          Start fresh and invite others to join your meal plan.
        </Text>
        <TouchableOpacity style={styles.createButton} onPress={createHousehold} disabled={loading}>
          {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.buttonText}>Create Household</Text>}
        </TouchableOpacity>
      </View>

      <View style={styles.divider}>
        <View style={styles.line} />
        <Text style={styles.orText}>OR</Text>
        <View style={styles.line} />
      </View>

      <View style={styles.section}>
        <Text style={styles.subtitle}>Join an Existing Household</Text>
        <TextInput
          style={styles.input}
          placeholder="Enter 6-digit invite code"
          value={inviteCode}
          onChangeText={setInviteCode}
          autoCapitalize="characters"
          maxLength={6}
        />
        <TouchableOpacity style={styles.joinButton} onPress={joinHousehold} disabled={loading}>
          {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.buttonText}>Join Household</Text>}
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    justifyContent: 'center',
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 40,
    textAlign: 'center',
  },
  section: {
    marginBottom: 20,
  },
  subtitle: {
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 10,
  },
  description: {
    fontSize: 14,
    color: '#666',
    marginBottom: 15,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    padding: 15,
    borderRadius: 8,
    marginBottom: 15,
    fontSize: 16,
    textTransform: 'uppercase',
  },
  createButton: {
    backgroundColor: '#007AFF',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  joinButton: {
    backgroundColor: '#34C759',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 30,
  },
  line: {
    flex: 1,
    height: 1,
    backgroundColor: '#ddd',
  },
  orText: {
    marginHorizontal: 15,
    color: '#666',
    fontWeight: '600',
  },
});
