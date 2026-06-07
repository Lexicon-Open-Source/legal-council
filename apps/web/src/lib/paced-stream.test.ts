import { describe, expect, it, vi } from 'vitest';
import {
  createPacedMessageController,
  getMessageAgentId,
  takePacedStreamSegment,
} from './paced-stream';
import type { UIDeliberationMessage } from './mappers';
import type { DeliberationMessage } from '@/types/api';

describe('takePacedStreamSegment', () => {
  it('reveals text by readable word-sized segments', () => {
    const next = takePacedStreamSegment('Pertimbangan rehabilitasi penting.');

    expect(next.segment).toBe('Pertimbangan ');
    expect(next.rest).toBe('rehabilitasi penting.');
    expect(next.delayMs).toBeGreaterThan(0);
  });

  it('adds a longer pause after sentence punctuation', () => {
    const sentence = takePacedStreamSegment('Selesai. Berikutnya');
    const word = takePacedStreamSegment('Selesai berikutnya');

    expect(sentence.delayMs).toBeGreaterThan(word.delayMs);
  });
});

describe('getMessageAgentId', () => {
  it('reads agent ids from structured and legacy sender shapes', () => {
    expect(
      getMessageAgentId({
        id: 'msg_1',
        session_id: 'sess_1',
        sender: { type: 'agent', agent_id: 'humanist' },
        content: 'Pendapat',
        cited_cases: [],
        cited_laws: [],
        timestamp: '2026-04-29T00:00:00.000Z',
      }),
    ).toBe('humanist');

    expect(
      getMessageAgentId({
        id: 'msg_2',
        session_id: 'sess_1',
        sender: 'historian',
        content: 'Pendapat',
        cited_cases: [],
        cited_laws: [],
        timestamp: '2026-04-29T00:00:00.000Z',
      } as unknown as DeliberationMessage),
    ).toBe('historian');
  });
});

describe('createPacedMessageController', () => {
  it('paces chunks before replacing the placeholder with the final message', () => {
    vi.useFakeTimers();

    let messages: UIDeliberationMessage[] = [];
    const setMessages = (
      action:
        | UIDeliberationMessage[]
        | ((previous: UIDeliberationMessage[]) => UIDeliberationMessage[]),
    ) => {
      messages = typeof action === 'function' ? action(messages) : action;
    };
    const stateListener = vi.fn();
    const controller = createPacedMessageController(setMessages, stateListener);

    controller.start({
      agentId: 'humanist',
      sessionId: 'sess_1',
      senderName: 'Humanis',
    });
    controller.append('humanist', 'Pertimbangan rehabilitasi penting.');

    expect(messages).toHaveLength(1);
    expect(messages[0]?.content).toBe('');

    vi.advanceTimersToNextTimer();

    expect(messages[0]?.content).toBe('Pertimbangan ');

    controller.complete('humanist', {
      id: 'msg_1',
      session_id: 'sess_1',
      sender: { type: 'agent', agent_id: 'humanist' },
      content: 'Pertimbangan rehabilitasi penting.',
      cited_cases: [],
      cited_laws: [],
      timestamp: '2026-04-29T00:00:00.000Z',
    });

    vi.runAllTimers();

    expect(messages).toHaveLength(1);
    expect(messages[0]).toMatchObject({
      id: 'msg_1',
      sender: 'humanist',
      sender_name: 'Humanis',
      content: 'Pertimbangan rehabilitasi penting.',
    });
    expect(stateListener).toHaveBeenLastCalledWith({
      activeAgentId: null,
      isPacing: false,
    });

    vi.useRealTimers();
  });

  it('reveals concurrent judge streams one transcript turn at a time', () => {
    vi.useFakeTimers();

    let messages: UIDeliberationMessage[] = [];
    const setMessages = (
      action:
        | UIDeliberationMessage[]
        | ((previous: UIDeliberationMessage[]) => UIDeliberationMessage[]),
    ) => {
      messages = typeof action === 'function' ? action(messages) : action;
    };
    const controller = createPacedMessageController(setMessages);

    controller.start({
      agentId: 'humanist',
      sessionId: 'sess_1',
      senderName: 'Humanis',
    });
    controller.start({
      agentId: 'historian',
      sessionId: 'sess_1',
      senderName: 'Sejarawan',
    });
    controller.append('humanist', 'Pertimbangan rehabilitasi selesai.');
    controller.append('historian', 'Preseden sejenis perlu dibandingkan.');

    vi.advanceTimersToNextTimer();

    expect(messages.find((message) => message.sender === 'humanist')?.content).toBe(
      'Pertimbangan ',
    );
    expect(messages.find((message) => message.sender === 'historian')?.content).toBe('');

    controller.complete('humanist', {
      id: 'msg_humanist',
      session_id: 'sess_1',
      sender: { type: 'agent', agent_id: 'humanist' },
      content: 'Pertimbangan rehabilitasi selesai.',
      cited_cases: [],
      cited_laws: [],
      timestamp: '2026-04-29T00:00:00.000Z',
    });
    vi.advanceTimersToNextTimer();
    vi.advanceTimersToNextTimer();
    vi.advanceTimersToNextTimer();

    expect(messages.find((message) => message.sender === 'humanist')?.id).toBe('msg_humanist');
    expect(messages.find((message) => message.sender === 'historian')?.content).toBe('');

    vi.advanceTimersToNextTimer();

    expect(messages.find((message) => message.sender === 'historian')?.content).toBe('Preseden ');

    vi.useRealTimers();
  });
});
