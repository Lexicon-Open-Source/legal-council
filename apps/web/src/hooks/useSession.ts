import { useState, useCallback } from 'react';
import { apiService } from '@/services/api';
import { CreateSessionRequest, DeliberationSession } from '@/types/api';

export function useSession() {
  const [session, setSession] = useState<DeliberationSession | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const createSession = useCallback(async (data: CreateSessionRequest) => {
    setLoading(true);
    setError(null);
    try {
      const response = await apiService.createSession(data);
      return response;
    } catch (err) {
      setError('Failed to create session');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const loadSession = useCallback(async (sessionId: string) => {
    setLoading(true);
    setError(null);
    try {
      const response = await apiService.getSession(sessionId);
      setSession(response.session);
      return response.session;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load session');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const concludeSession = useCallback(async (sessionId: string) => {
    setLoading(true);
    setError(null);
    try {
      const response = await apiService.concludeSession(sessionId);
      setSession(response.session);
      return response.session;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to conclude session');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const deleteSession = useCallback(async (sessionId: string) => {
    setLoading(true);
    setError(null);
    try {
      await apiService.deleteSession(sessionId);
      setSession(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete session');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  return { session, loading, error, createSession, loadSession, concludeSession, deleteSession };
}
