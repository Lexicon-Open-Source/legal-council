import { act, render, screen, waitFor } from '@testing-library/react';
import { useEffect } from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { JudgeCounselProvider, useJudgeCounsel } from '@/context/judge-counsel-context';
import type { SSEEvent } from '@/types/api';
import { useDeliberation } from './useDeliberation';

const apiServiceMock = vi.hoisted(() => ({
  streamInitialOpinions: vi.fn(),
  streamMessage: vi.fn(),
  streamContinueDiscussion: vi.fn(),
  getSession: vi.fn(),
  getMessages: vi.fn(),
}));

vi.mock('@/services/api', () => ({
  apiService: apiServiceMock,
}));

const userMessage = {
  id: 'user_1',
  session_id: 'sess_1',
  sender: { type: 'user' as const },
  content: 'Mohon pendapat dewan.',
  cited_cases: [],
  cited_laws: [],
  timestamp: '2026-04-29T00:00:00.000Z',
};

const refreshedSession = {
  id: 'sess_1',
  status: 'active',
  current_phase: 'debate',
  phase_metadata: {
    phase_history: [{ phase: 'debate', round: 2 }],
  },
  case_input: {
    input_type: 'text_summary',
    raw_input: 'Ringkasan perkara',
    parsed_case: {
      case_type: 'corruption',
      summary: 'Kasus korupsi',
      key_facts: [],
      charges: [],
    },
  },
  similar_cases: [],
  messages: [userMessage],
  created_at: '2026-04-29T00:00:00.000Z',
  updated_at: '2026-04-29T00:00:00.000Z',
};

function renderUseDeliberation() {
  let controls: ReturnType<typeof useDeliberation> | undefined;

  function Probe({
    onControls,
  }: {
    onControls: (next: ReturnType<typeof useDeliberation>) => void;
  }) {
    const { messages, setMessages, currentPhase, phaseMetadata } = useJudgeCounsel();
    const hookControls = useDeliberation('sess_1', messages, setMessages);

    useEffect(() => {
      onControls(hookControls);
    }, [hookControls, onControls]);

    return (
      <>
        <output data-testid='phase'>{currentPhase ?? 'none'}</output>
        <output data-testid='phase-history'>{phaseMetadata?.phase_history.length ?? 0}</output>
        <output data-testid='message-count'>{messages.length}</output>
      </>
    );
  }

  const handleControls = (next: ReturnType<typeof useDeliberation>) => {
    controls = next;
  };

  render(
    <JudgeCounselProvider>
      <Probe onControls={handleControls} />
    </JudgeCounselProvider>,
  );

  return {
    get controls() {
      if (!controls) throw new Error('Hook controls not initialized');
      return controls;
    },
  };
}

describe('useDeliberation', () => {
  beforeEach(() => {
    apiServiceMock.streamInitialOpinions.mockReset();
    apiServiceMock.streamMessage.mockReset();
    apiServiceMock.streamContinueDiscussion.mockReset();
    apiServiceMock.getSession.mockReset();
    apiServiceMock.getMessages.mockReset();

    apiServiceMock.getSession.mockResolvedValue({ session: refreshedSession });
  });

  it('refreshes phase state once after a completed message stream without duplicating messages', async () => {
    apiServiceMock.streamMessage.mockImplementation(async (...args: unknown[]) => {
      const onEvent = args[2] as (event: SSEEvent) => void;
      const onComplete = args[3] as () => void;

      onEvent({ type: 'user_message', message: userMessage });
      onEvent({ type: 'phase_transition', content: '{"phase":"debate"}' });
      onComplete();
    });

    const view = renderUseDeliberation();

    await act(async () => {
      await view.controls.sendMessageStreaming({ content: 'Mohon pendapat dewan.' });
    });

    await waitFor(() => {
      expect(screen.getByTestId('phase').textContent).toBe('debate');
    });

    expect(apiServiceMock.getSession).toHaveBeenCalledTimes(1);
    expect(apiServiceMock.getSession).toHaveBeenCalledWith('sess_1');
    expect(screen.getByTestId('phase-history').textContent).toBe('1');
    expect(screen.getByTestId('message-count').textContent).toBe('1');
  });

  it('refreshes phase state after a completed continue-discussion stream', async () => {
    apiServiceMock.streamContinueDiscussion.mockImplementation(async (...args: unknown[]) => {
      const onComplete = args[3] as () => void;
      onComplete();
    });

    const view = renderUseDeliberation();

    await act(async () => {
      await view.controls.continueDiscussionStreaming(1);
    });

    await waitFor(() => {
      expect(screen.getByTestId('phase').textContent).toBe('debate');
    });

    expect(apiServiceMock.streamContinueDiscussion).toHaveBeenCalledWith(
      'sess_1',
      { num_rounds: 1 },
      expect.any(Function),
      expect.any(Function),
      expect.any(Function),
    );
    expect(apiServiceMock.getSession).toHaveBeenCalledTimes(1);
  });

  it('streams remaining opening opinions and refreshes phase state when complete', async () => {
    apiServiceMock.streamInitialOpinions.mockImplementation(async (...args: unknown[]) => {
      const onEvent = args[1] as (event: SSEEvent) => void;
      const onComplete = args[2] as () => void;

      onEvent({ type: 'agent_start', agent_id: 'humanist', agent_name: 'Humanis' });
      onEvent({ type: 'chunk', agent_id: 'humanist', content: 'Pertimbangan rehabilitasi' });
      onEvent({
        type: 'agent_complete',
        message: {
          id: 'agent_1',
          session_id: 'sess_1',
          sender: { type: 'agent', agent_id: 'humanist' },
          content: 'Pertimbangan rehabilitasi',
          cited_cases: [],
          cited_laws: [],
          timestamp: '2026-04-29T00:00:00.000Z',
        },
      });
      onComplete();
    });

    const view = renderUseDeliberation();

    await act(async () => {
      await view.controls.streamInitialOpinions();
    });

    await waitFor(() => {
      expect(screen.getByTestId('phase').textContent).toBe('debate');
    });

    expect(apiServiceMock.streamInitialOpinions).toHaveBeenCalledWith(
      'sess_1',
      expect.any(Function),
      expect.any(Function),
      expect.any(Function),
    );
    expect(apiServiceMock.getSession).toHaveBeenCalledTimes(1);
    expect(screen.getByTestId('message-count').textContent).toBe('1');
  });
});
