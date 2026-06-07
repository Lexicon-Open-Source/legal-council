import { describe, expect, it, vi } from 'vitest';
import { fetchRawSSE, normalizeSSEEvent, parseRawSSEStream } from './sse';
import type { SSERawEvent } from '@/types/api';

function createSseResponse(chunks: string[]): Response {
  const encoder = new TextEncoder();
  return new Response(
    new ReadableStream({
      start(controller) {
        for (const chunk of chunks) {
          controller.enqueue(encoder.encode(chunk));
        }
        controller.close();
      },
    }),
  );
}

describe('normalizeSSEEvent', () => {
  it('normalizes existing user message events', () => {
    const event = normalizeSSEEvent(
      {
        event_type: 'user_message',
        content: 'Mohon pertimbangan dewan.',
        message_id: 'msg_1',
      },
      'sess_1',
    );

    expect(event).toEqual({
      type: 'user_message',
      message: expect.objectContaining({
        id: 'msg_1',
        session_id: 'sess_1',
        sender: { type: 'user' },
        content: 'Mohon pertimbangan dewan.',
      }),
    });
  });

  it('normalizes existing agent completion events with full content', () => {
    const event = normalizeSSEEvent(
      {
        event_type: 'agent_complete',
        agent_id: 'strict',
        content: 'partial',
        full_content: 'final legal reasoning',
        message_id: 'msg_2',
      },
      'sess_1',
    );

    expect(event).toEqual({
      type: 'agent_complete',
      message: expect.objectContaining({
        id: 'msg_2',
        session_id: 'sess_1',
        sender: { type: 'agent', agent_id: 'strict' },
        content: 'final legal reasoning',
      }),
    });
  });

  it.each(['phase_transition', 'convergence_suggestion', 'summary_ready'] as const)(
    'tolerates new %s signal events without unknown-event warnings',
    (eventType) => {
      const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
      const event = normalizeSSEEvent({
        event_type: eventType,
        content: '{"phase":"debate"}',
      });

      expect(event).toEqual({
        type: eventType,
        content: '{"phase":"debate"}',
        metadata: { phase: 'debate' },
      });
      expect(warn).not.toHaveBeenCalled();
    },
  );

  it('ignores incomplete events safely', () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});

    expect(normalizeSSEEvent({} satisfies SSERawEvent)).toBeNull();
    expect(normalizeSSEEvent({ event_type: 'chunk', agent_id: 'strict' })).toBeNull();

    expect(warn).toHaveBeenCalledWith('SSE event missing event_type');
    expect(warn).toHaveBeenCalledWith('chunk event missing content');
  });
});

describe('parseRawSSEStream', () => {
  it('emits raw create-session events across chunk boundaries', async () => {
    const onEvent = vi.fn();
    const onComplete = vi.fn();
    const onError = vi.fn();

    await parseRawSSEStream(
      createSseResponse([
        'data: {"event_type":"status","status":"Membaca dakwaan"}\n',
        '\ndata: {"event_type":"session_created","session_id":"sess_1","similar_cases":[]}\n\n',
      ]),
      { onEvent, onComplete, onError },
    );

    expect(onEvent).toHaveBeenCalledWith({
      event_type: 'status',
      status: 'Membaca dakwaan',
    });
    expect(onEvent).toHaveBeenCalledWith({
      event_type: 'session_created',
      session_id: 'sess_1',
      similar_cases: [],
    });
    expect(onComplete).toHaveBeenCalledOnce();
    expect(onError).not.toHaveBeenCalled();
  });

  it('reports handler failures instead of swallowing terminal error events', async () => {
    const onComplete = vi.fn();
    const onError = vi.fn();
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {});

    await parseRawSSEStream(
      createSseResponse(['data: {"event_type":"error","content":"boom"}\n']),
      {
        onEvent(event: { event_type: string; content?: string }) {
          if (event.event_type === 'error') {
            throw new Error(event.content);
          }
        },
        onComplete,
        onError,
      },
    );

    expect(onError).toHaveBeenCalledWith(expect.objectContaining({ message: 'boom' }));
    expect(onComplete).not.toHaveBeenCalled();
    consoleError.mockRestore();
  });
});

describe('fetchRawSSE', () => {
  it('requests the create-session stream with text/event-stream negotiation', async () => {
    const fetchMock = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValue(createSseResponse(['data: {"event_type":"status"}\n']));

    await fetchRawSSE(
      'http://localhost:8000/v1/council/sessions',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: '{"case_summary":"Ringkasan perkara"}',
      },
      { onEvent: vi.fn(), onComplete: vi.fn(), onError: vi.fn() },
    );

    expect(fetchMock).toHaveBeenCalledWith(
      'http://localhost:8000/v1/council/sessions',
      expect.objectContaining({
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'text/event-stream',
        },
      }),
    );

    fetchMock.mockRestore();
  });
});
