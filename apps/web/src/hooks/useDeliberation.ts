import React, { useCallback, useEffect, useRef, useState } from 'react';
import { apiService } from '@/services/api';
import { SendMessageRequest, SSEEvent, AgentId, StreamMessageRequest } from '@/types/api';
import { UIDeliberationMessage, normalizeMessage, normalizeMessages } from '@/lib/mappers';
import { useJudgeCounsel } from '@/context/judge-counsel-context';
import {
  createPacedMessageController,
  getMessageAgentId,
  type PacedStreamState,
} from '@/lib/paced-stream';

// Helper to get agent display name
const getAgentDisplayName = (agentId: AgentId): string => {
  const names: Record<AgentId, string> = {
    strict: 'Legalis',
    humanist: 'Humanis',
    historian: 'Sejarawan',
  };
  return names[agentId] || agentId;
};

export function useDeliberation(
  sessionId: string,
  messages: UIDeliberationMessage[],
  setMessages: React.Dispatch<React.SetStateAction<UIDeliberationMessage[]>>,
) {
  const [loading, setLoading] = useState(false);
  const [streaming, setStreaming] = useState(false);
  const [streamingAgentId, setStreamingAgentId] = useState<AgentId | null>(null);
  const [pacedState, setPacedState] = useState<PacedStreamState>({
    activeAgentId: null,
    isPacing: false,
  });
  const [error, setError] = useState<string | null>(null);
  const { setCurrentPhase, setPhaseMetadata } = useJudgeCounsel();

  const currentAgentRef = useRef<AgentId | null>(null);
  const pacedMessagesRef = useRef<ReturnType<typeof createPacedMessageController> | null>(null);

  if (!pacedMessagesRef.current) {
    pacedMessagesRef.current = createPacedMessageController(setMessages, setPacedState);
  }

  useEffect(() => {
    const pacedMessages = pacedMessagesRef.current;
    return () => pacedMessages?.cancelAll();
  }, []);

  const refreshSessionPhase = useCallback(async () => {
    if (!sessionId) return;

    try {
      const response = await apiService.getSession(sessionId);
      setCurrentPhase(response.session.current_phase ?? null);
      setPhaseMetadata(response.session.phase_metadata ?? null);
    } catch (err) {
      console.warn('Failed to refresh session phase:', err);
    }
  }, [sessionId, setCurrentPhase, setPhaseMetadata]);

  // Common SSE event handler
  const handleSSEEvent = useCallback(
    (event: SSEEvent) => {
      switch (event.type) {
        case 'user_message':
          // Add user message from the server
          setMessages((prev) => [...prev, normalizeMessage(event.message)]);
          break;

        case 'agent_start':
          // Start a new agent message with empty content
          currentAgentRef.current = event.agent_id;
          setStreamingAgentId(event.agent_id);
          pacedMessagesRef.current?.start({
            agentId: event.agent_id,
            sessionId,
            senderName: event.agent_name || getAgentDisplayName(event.agent_id),
          });
          break;

        case 'chunk':
          // Append chunk to the current streaming message
          if (currentAgentRef.current === event.agent_id) {
            pacedMessagesRef.current?.append(event.agent_id, event.content);
          }
          break;

        case 'agent_complete':
          // Replace the streaming message with the final message from server
          {
            const completedAgentId = getMessageAgentId(event.message) ?? currentAgentRef.current;
            if (completedAgentId) {
              pacedMessagesRef.current?.complete(completedAgentId, event.message);
            } else {
              setMessages((prev) => [...prev, normalizeMessage(event.message)]);
            }
          }
          currentAgentRef.current = null;
          break;

        case 'agent_error':
          console.error(`Agent ${event.agent_id} error:`, event.error);
          pacedMessagesRef.current?.cancel(event.agent_id, { removeMessage: true });
          currentAgentRef.current = null;
          setStreamingAgentId(null);
          break;

        case 'deliberation_complete':
          // All agents have finished - messages should already be updated
          currentAgentRef.current = null;
          setStreamingAgentId(null);
          break;

        case 'phase_transition':
        case 'convergence_suggestion':
        case 'summary_ready':
          break;
      }
    },
    [sessionId, setMessages],
  );

  const sendMessage = useCallback(
    async (data: SendMessageRequest) => {
      setLoading(true);
      setError(null);
      try {
        const response = await apiService.sendMessage(sessionId, data);
        setMessages((prev) => [
          ...prev,
          normalizeMessage(response.user_message),
          ...normalizeMessages(response.agent_responses),
        ]);
        return response;
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to send message');
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [sessionId, setMessages],
  );

  const continueDiscussion = useCallback(
    async (numRounds: number = 1) => {
      setLoading(true);
      setError(null);
      try {
        const response = await apiService.continueDiscussion(sessionId, { num_rounds: numRounds });
        setMessages((prev) => [...prev, ...normalizeMessages(response.new_messages)]);
        return response;
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to continue discussion');
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [sessionId, setMessages],
  );

  const sendMessageStreaming = useCallback(
    async (data: StreamMessageRequest) => {
      setStreaming(true);
      setError(null);
      currentAgentRef.current = null;
      let completed = false;

      try {
        await apiService.streamMessage(
          sessionId,
          data,
          handleSSEEvent,
          () => {
            completed = true;
          },
          (err) => {
            setError(err.message);
          },
        );

        if (completed) {
          await refreshSessionPhase();
        }
      } finally {
        setStreaming(false);
        setStreamingAgentId(null);
      }
    },
    [sessionId, handleSSEEvent, refreshSessionPhase],
  );

  const continueDiscussionStreaming = useCallback(
    async (numRounds: number = 1) => {
      setStreaming(true);
      setError(null);
      currentAgentRef.current = null;
      let completed = false;

      try {
        await apiService.streamContinueDiscussion(
          sessionId,
          { num_rounds: numRounds },
          handleSSEEvent,
          () => {
            completed = true;
          },
          (err) => {
            setError(err.message);
          },
        );

        if (completed) {
          await refreshSessionPhase();
        }
      } finally {
        setStreaming(false);
        setStreamingAgentId(null);
      }
    },
    [sessionId, handleSSEEvent, refreshSessionPhase],
  );

  const streamInitialOpinions = useCallback(async () => {
    setStreaming(true);
    setError(null);
    currentAgentRef.current = null;
    let completed = false;

    try {
      await apiService.streamInitialOpinions(
        sessionId,
        handleSSEEvent,
        () => {
          completed = true;
        },
        (err) => {
          setError(err.message);
        },
      );

      if (completed) {
        await refreshSessionPhase();
      }
    } finally {
      setStreaming(false);
      setStreamingAgentId(null);
    }
  }, [sessionId, handleSSEEvent, refreshSessionPhase]);

  const loadMessages = useCallback(async () => {
    setLoading(true);
    try {
      const response = await apiService.getMessages(sessionId, 50);
      setMessages(normalizeMessages(response.messages ?? []));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load messages');
    } finally {
      setLoading(false);
    }
  }, [sessionId, setMessages]);

  return {
    messages,
    loading,
    streaming,
    streamingAgentId,
    error,
    sendMessage,
    streamInitialOpinions,
    sendMessageStreaming,
    continueDiscussion,
    continueDiscussionStreaming,
    loadMessages,
    pacing: pacedState.isPacing,
    pacingAgentId: pacedState.activeAgentId,
  };
}
