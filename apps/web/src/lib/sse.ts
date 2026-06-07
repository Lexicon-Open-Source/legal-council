import { SSEEvent, SSERawEvent, AgentId, DeliberationMessage } from '@/types/api';

export interface SSEOptions {
  onEvent: (event: SSEEvent) => void;
  onComplete: () => void;
  onError: (error: Error) => void;
  sessionId?: string;
}

export interface RawSSEOptions<TEvent> {
  onEvent: (event: TEvent) => void;
  onComplete: () => void;
  onError: (error: Error) => void;
}

// Agent display name mapping
const AGENT_DISPLAY_NAMES: Record<AgentId, string> = {
  strict: 'Legalis',
  humanist: 'Humanis',
  historian: 'Sejarawan',
};

function parseSignalMetadata(content?: string): Record<string, unknown> | undefined {
  if (!content) return undefined;

  try {
    const parsed = JSON.parse(content) as unknown;
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
      return parsed as Record<string, unknown>;
    }
  } catch {
    return undefined;
  }

  return undefined;
}

/**
 * Transform raw server SSE events to the normalized frontend format.
 * Handles the mismatch between server's flat structure and frontend's expected structure.
 */
export function normalizeSSEEvent(raw: SSERawEvent, sessionId?: string): SSEEvent | null {
  if (!raw.event_type) {
    console.warn('SSE event missing event_type');
    return null;
  }

  switch (raw.event_type) {
    case 'user_message': {
      if (!raw.content) {
        console.warn('user_message event missing content');
        return null;
      }

      const message: DeliberationMessage = {
        id: raw.message_id || `user-${Date.now()}`,
        session_id: sessionId || '',
        sender: { type: 'user' },
        content: raw.content,
        cited_cases: [],
        cited_laws: [],
        timestamp: new Date().toISOString(),
      };
      return { type: 'user_message', message };
    }

    case 'agent_start': {
      if (!raw.agent_id) {
        console.warn('agent_start event missing agent_id');
        return null;
      }
      return {
        type: 'agent_start',
        agent_id: raw.agent_id,
        agent_name: AGENT_DISPLAY_NAMES[raw.agent_id] || raw.agent_id,
      };
    }

    case 'chunk': {
      if (!raw.agent_id) {
        console.warn('chunk event missing agent_id');
        return null;
      }
      if (!raw.content) {
        console.warn('chunk event missing content');
        return null;
      }
      return {
        type: 'chunk',
        agent_id: raw.agent_id,
        content: raw.content,
      };
    }

    case 'agent_complete': {
      if (!raw.agent_id) {
        console.warn('agent_complete event missing agent_id');
        return null;
      }
      const content = raw.full_content || raw.content;
      if (!content) {
        console.warn('agent_complete event missing content');
        return null;
      }
      const message: DeliberationMessage = {
        id: raw.message_id || `agent-${raw.agent_id}-${Date.now()}`,
        session_id: sessionId || '',
        sender: { type: 'agent', agent_id: raw.agent_id },
        content,
        cited_cases: [],
        cited_laws: [],
        timestamp: new Date().toISOString(),
      };
      return { type: 'agent_complete', message };
    }

    case 'agent_error': {
      if (!raw.agent_id) {
        console.warn('agent_error event missing agent_id');
        return null;
      }
      return {
        type: 'agent_error',
        agent_id: raw.agent_id,
        error: raw.content || 'Unknown error',
      };
    }

    case 'deliberation_complete': {
      return {
        type: 'deliberation_complete',
        messages: [], // Server doesn't send messages array, handled by prior events
      };
    }

    case 'phase_transition':
    case 'convergence_suggestion':
    case 'summary_ready': {
      return {
        type: raw.event_type,
        content: raw.content,
        metadata: parseSignalMetadata(raw.content),
      };
    }

    default:
      console.warn('Unknown SSE event type:', raw.event_type);
      return null;
  }
}

export async function parseSSEStream(response: Response, options: SSEOptions): Promise<void> {
  const { onEvent, onComplete, onError, sessionId } = options;

  if (!response.body) {
    throw new Error('No response body');
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');

      // Keep the last line in buffer (might be incomplete)
      buffer = lines.pop() || '';

      for (const line of lines) {
        const trimmedLine = line.trim();

        // Skip empty lines and ping comments
        if (!trimmedLine || trimmedLine === ': ping' || trimmedLine.startsWith(':')) {
          continue;
        }

        // Parse data lines
        if (trimmedLine.startsWith('data: ')) {
          try {
            const jsonStr = trimmedLine.slice(6);
            const rawData = JSON.parse(jsonStr) as SSERawEvent;

            // Normalize the raw server event to frontend format
            const normalizedEvent = normalizeSSEEvent(rawData, sessionId);
            if (normalizedEvent) {
              onEvent(normalizedEvent);
            }
          } catch (e) {
            console.warn('Failed to parse SSE data:', trimmedLine, e);
          }
        }
      }
    }

    // Process any remaining buffer
    if (buffer.trim().startsWith('data: ')) {
      try {
        const jsonStr = buffer.trim().slice(6);
        const rawData = JSON.parse(jsonStr) as SSERawEvent;
        const normalizedEvent = normalizeSSEEvent(rawData, sessionId);
        if (normalizedEvent) {
          onEvent(normalizedEvent);
        }
      } catch {
        // Ignore trailing incomplete data
      }
    }

    onComplete();
  } catch (error) {
    console.error('SSE stream error:', error);
    onError(error instanceof Error ? error : new Error(String(error)));
  }
}

export async function parseRawSSEStream<TEvent>(
  response: Response,
  options: RawSSEOptions<TEvent>,
): Promise<void> {
  const { onEvent, onComplete, onError } = options;

  if (!response.body) {
    throw new Error('No response body');
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  const processDataLine = (line: string) => {
    const jsonStr = line.slice(6);
    let event: TEvent;
    try {
      event = JSON.parse(jsonStr) as TEvent;
    } catch (e) {
      console.warn('Failed to parse SSE data:', line, e);
      throw e;
    }
    onEvent(event);
  };

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');

      buffer = lines.pop() || '';

      for (const line of lines) {
        const trimmedLine = line.trim();
        if (!trimmedLine || trimmedLine === ': ping' || trimmedLine.startsWith(':')) {
          continue;
        }
        if (trimmedLine.startsWith('data: ')) {
          processDataLine(trimmedLine);
        }
      }
    }

    const trailingLine = buffer.trim();
    if (trailingLine.startsWith('data: ')) {
      processDataLine(trailingLine);
    }

    onComplete();
  } catch (error) {
    console.error('SSE stream error:', error);
    onError(error instanceof Error ? error : new Error(String(error)));
  }
}

export async function fetchSSE(
  url: string,
  options: RequestInit,
  sseOptions: SSEOptions,
): Promise<void> {
  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        Accept: 'text/event-stream',
      },
    });

    if (!response.ok) {
      const errorText = await response.text().catch(() => 'Unknown error');
      throw new Error(`HTTP ${response.status}: ${errorText}`);
    }

    await parseSSEStream(response, sseOptions);
  } catch (error) {
    console.error('SSE fetch error:', error);
    sseOptions.onError(error instanceof Error ? error : new Error(String(error)));
  }
}

export async function fetchRawSSE<TEvent>(
  url: string,
  options: RequestInit,
  sseOptions: RawSSEOptions<TEvent>,
): Promise<void> {
  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        Accept: 'text/event-stream',
      },
    });

    if (!response.ok) {
      const errorText = await response.text().catch(() => 'Unknown error');
      throw new Error(`HTTP ${response.status}: ${errorText}`);
    }

    await parseRawSSEStream(response, sseOptions);
  } catch (error) {
    console.error('SSE fetch error:', error);
    sseOptions.onError(error instanceof Error ? error : new Error(String(error)));
  }
}
