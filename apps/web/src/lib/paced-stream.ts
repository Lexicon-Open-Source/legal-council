import type React from 'react';
import { normalizeMessage, type UIDeliberationMessage } from '@/lib/mappers';
import type { AgentId, DeliberationMessage } from '@/types/api';

const WORD_DELAY_MS = 58;
const CLAUSE_DELAY_MS = 100;
const SENTENCE_DELAY_MS = 155;
const LONG_TOKEN_CHARS = 18;

interface PacedDraft {
  messageId: string;
  buffer: string;
  displayed: string;
  finalMessage: DeliberationMessage | null;
}

export interface PacedStreamState {
  activeAgentId: AgentId | null;
  isPacing: boolean;
}

interface StartPacedMessageOptions {
  agentId: AgentId;
  sessionId: string;
  senderName: string;
}

type MessageSetter = React.Dispatch<React.SetStateAction<UIDeliberationMessage[]>>;
type StateListener = (state: PacedStreamState) => void;

const AGENT_IDS = new Set<AgentId>(['strict', 'humanist', 'historian']);

function isAgentId(value: string): value is AgentId {
  return AGENT_IDS.has(value as AgentId);
}

export function getMessageAgentId(message: DeliberationMessage): AgentId | null {
  if (typeof message.sender === 'string') {
    return isAgentId(message.sender) ? message.sender : null;
  }

  if (message.sender.type === 'agent') {
    return message.sender.agent_id;
  }

  return null;
}

export function takePacedStreamSegment(buffer: string): {
  segment: string;
  rest: string;
  delayMs: number;
} {
  if (!buffer) return { segment: '', rest: '', delayMs: WORD_DELAY_MS };

  const leadingWhitespace = buffer.match(/^\s+/)?.[0] ?? '';
  const source = buffer.slice(leadingWhitespace.length);
  const word = source.match(/^\S+\s*/)?.[0] ?? source;
  const segment =
    word.length > LONG_TOKEN_CHARS
      ? leadingWhitespace + word.slice(0, LONG_TOKEN_CHARS)
      : leadingWhitespace + word;
  const rest = buffer.slice(segment.length);
  const trimmed = segment.trimEnd();
  const delayMs = /[.!?]$/.test(trimmed)
    ? SENTENCE_DELAY_MS
    : /[,;:]$/.test(trimmed)
      ? CLAUSE_DELAY_MS
      : WORD_DELAY_MS;

  return { segment, rest, delayMs };
}

export function createPacedMessageController(
  setMessages: MessageSetter,
  onStateChange?: StateListener,
) {
  const drafts: Partial<Record<AgentId, PacedDraft>> = {};
  let order: AgentId[] = [];
  let timer: number | null = null;

  const nextAgentWithWork = () =>
    order.find((agentId) => {
      const draft = drafts[agentId];
      return Boolean(draft && (draft.buffer || draft.finalMessage));
    }) ?? null;

  const emitState = () => {
    const activeAgentId = nextAgentWithWork() ?? order.find((agentId) => drafts[agentId]) ?? null;
    onStateChange?.({
      activeAgentId,
      isPacing: activeAgentId !== null,
    });
  };

  const replaceWithFinalMessage = (draft: PacedDraft, finalMessage: DeliberationMessage) => {
    const normalized = normalizeMessage(finalMessage);
    setMessages((prev) => {
      const updated = [...prev];
      const finalIdx = updated.findIndex((message) => message.id === normalized.id);
      const draftIdx = updated.findIndex((message) => message.id === draft.messageId);

      if (finalIdx >= 0) {
        updated[finalIdx] = normalized;
        if (draftIdx >= 0 && draftIdx !== finalIdx) {
          updated.splice(draftIdx, 1);
        }
        return updated;
      }

      if (draftIdx >= 0) {
        updated[draftIdx] = normalized;
        return updated;
      }

      return [...updated, normalized];
    });
  };

  const deleteDraft = (agentId: AgentId) => {
    delete drafts[agentId];
    order = order.filter((item) => item !== agentId);
    emitState();
  };

  const tick = (agentId: AgentId) => {
    timer = null;
    const draft = drafts[agentId];
    if (!draft) {
      scheduleNext();
      return;
    }

    if (draft.buffer) {
      const next = takePacedStreamSegment(draft.buffer);
      draft.buffer = next.rest;
      draft.displayed += next.segment;
      setMessages((prev) =>
        prev.map((message) =>
          message.id === draft.messageId ? { ...message, content: draft.displayed } : message,
        ),
      );
      scheduleNext(next.delayMs);
      return;
    }

    if (draft.finalMessage) {
      replaceWithFinalMessage(draft, draft.finalMessage);
      deleteDraft(agentId);
      scheduleNext();
    }
  };

  function scheduleNext(delayMs = WORD_DELAY_MS) {
    if (timer) return;

    const agentId = nextAgentWithWork();
    if (!agentId) {
      emitState();
      return;
    }

    emitState();
    timer = window.setTimeout(() => tick(agentId), delayMs);
  }

  const start = ({ agentId, sessionId, senderName }: StartPacedMessageOptions) => {
    deleteDraft(agentId);

    const messageId = `streaming-${agentId}-${Date.now()}`;
    drafts[agentId] = {
      messageId,
      buffer: '',
      displayed: '',
      finalMessage: null,
    };
    order = [...order, agentId];
    setMessages((prev) => [
      ...prev,
      {
        id: messageId,
        session_id: sessionId,
        sender: agentId,
        sender_name: senderName,
        content: '',
        timestamp: new Date(),
      },
    ]);
    emitState();
  };

  const append = (agentId: AgentId, content: string) => {
    const draft = drafts[agentId];
    if (!draft) return;

    draft.buffer += content;
    scheduleNext();
    emitState();
  };

  const complete = (agentId: AgentId, finalMessage: DeliberationMessage) => {
    const draft = drafts[agentId];
    if (!draft) {
      const normalized = normalizeMessage(finalMessage);
      setMessages((prev) => {
        const existingIdx = prev.findIndex((message) => message.id === normalized.id);
        if (existingIdx >= 0) {
          const updated = [...prev];
          updated[existingIdx] = normalized;
          return updated;
        }
        return [...prev, normalized];
      });
      return;
    }

    const normalized = normalizeMessage(finalMessage);
    const pending = draft.displayed + draft.buffer;
    if (normalized.content.startsWith(pending)) {
      draft.buffer += normalized.content.slice(pending.length);
    } else {
      draft.displayed = '';
      draft.buffer = normalized.content;
      setMessages((prev) =>
        prev.map((message) =>
          message.id === draft.messageId ? { ...message, content: '' } : message,
        ),
      );
    }

    draft.finalMessage = finalMessage;
    scheduleNext();
    emitState();
  };

  const cancel = (agentId: AgentId, options: { removeMessage?: boolean } = {}) => {
    const draft = drafts[agentId];
    if (!draft) return;

    if (options.removeMessage) {
      setMessages((prev) => prev.filter((message) => message.id !== draft.messageId));
    }
    deleteDraft(agentId);
  };

  const cancelAll = (options: { removeMessages?: boolean } = {}) => {
    if (timer) {
      window.clearTimeout(timer);
      timer = null;
    }
    for (const agentId of [...order]) {
      cancel(agentId, { removeMessage: options.removeMessages });
    }
  };

  return {
    append,
    cancel,
    cancelAll,
    complete,
    start,
  };
}
