import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { supabase } from '../../src/lib/supabase';
import { useAuth } from '../../src/contexts/AuthContext';
import { generateInviteCode } from '../../src/utils/household';

export default function HouseholdSetupScreen() {
  const [inviteCode, setInviteCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const router = useRouter();
  const { user, refreshProfile } = useAuth();

  // Link the household to the current user's profile, then continue into the app.
  // Uses upsert so it also works when no profile row exists yet (e.g. no signup
  // trigger created one). Returns true on success.
  const linkProfileAndContinue = async (householdId: string): Promise<boolean> => {
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .upsert({ id: user!.id, household_id: householdId })
      .select()
      .single();

    if (profileError || !profile) {
      console.error('Link profile failed:', profileError);
      setErrorMsg(profileError?.message ?? 'Failed to update your profile.');
      setLoading(false);
      return false;
    }

    await refreshProfile();
    router.replace('/');
    return true;
  };

  const createHousehold = async () => {
    if (!user) return;
    setLoading(true);
    setErrorMsg(null);
    const newInviteCode = generateInviteCode();

    const { data: household, error: householdError } = await supabase
      .from('households')
      .insert({ invite_code: newInviteCode })
      .select()
      .single();

    if (householdError || !household) {
      console.error('Create household failed:', householdError);
      setErrorMsg(householdError?.message ?? 'Failed to create household. Please try again.');
      setLoading(false);
      return;
    }

    await linkProfileAndContinue(household.id);
  };

  const joinHousehold = async () => {
    if (!user) return;
    if (inviteCode.length !== 6) {
      setErrorMsg('Please enter a valid 6-character invite code.');
      return;
    }

    setLoading(true);
    setErrorMsg(null);

    const { data: household, error: queryError } = await supabase
      .from('households')
      .select('id')
      .eq('invite_code', inviteCode.toUpperCase())
      .maybeSingle();

    if (queryError || !household) {
      console.error('Join household lookup failed:', queryError);
      setErrorMsg('Could not find a household with that invite code.');
      setLoading(false);
      return;
    }

    await linkProfileAndContinue(household.id);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Set Up Your Household</Text>

      {errorMsg && <Text style={styles.errorText}>{errorMsg}</Text>}

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
  errorText: {
    color: '#e63946',
    textAlign: 'center',
    marginBottom: 20,
    fontSize: 14,
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
