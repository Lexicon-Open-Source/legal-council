import {
  DeliberationMessage as ApiDeliberationMessage,
  MessageSender,
  isUserSender,
  isAgentSender,
  isSystemSender,
  AgentId,
} from '@/types/api';

export interface UIDeliberationMessage {
  id: string;
  session_id: string;
  sender: 'user' | 'system' | AgentId;
  sender_name: string;
  content: string;
  intent?: string | null;
  cited_cases?: string[];
  cited_laws?: string[];
  timestamp: Date;
}

const AGENT_NAMES: Record<AgentId, string> = {
  strict: 'Legalis',
  humanist: 'Humanis',
  historian: 'Sejarawan',
};

function getSenderName(sender: MessageSender): string {
  if (isUserSender(sender)) {
    return 'You (Presiding Judge)';
  }
  if (isSystemSender(sender)) {
    return 'System';
  }
  if (isAgentSender(sender)) {
    return AGENT_NAMES[sender.agent_id] || sender.agent_id;
  }
  return 'Unknown';
}

function getSenderId(sender: MessageSender): 'user' | 'system' | AgentId {
  if (isUserSender(sender)) {
    return 'user';
  }
  if (isSystemSender(sender)) {
    return 'system';
  }
  if (isAgentSender(sender)) {
    return sender.agent_id;
  }
  return 'system'; // fallback
}

export function normalizeMessage(message: ApiDeliberationMessage): UIDeliberationMessage {
  if (typeof message.sender === 'string') {
    return {
      id: message.id,
      session_id: message.session_id,
      sender: message.sender as 'user' | 'system' | AgentId,
      sender_name: getSenderNameFromString(message.sender),
      content: message.content,
      intent: message.intent,
      cited_cases: message.cited_cases,
      cited_laws: message.cited_laws,
      timestamp: message.timestamp ? new Date(message.timestamp) : new Date(),
    };
  }

  const sender = message.sender as MessageSender;

  return {
    id: message.id,
    session_id: message.session_id,
    sender: getSenderId(sender),
    sender_name: getSenderName(sender),
    content: message.content,
    intent: message.intent,
    cited_cases: message.cited_cases,
    cited_laws: message.cited_laws,
    timestamp: message.timestamp ? new Date(message.timestamp) : new Date(),
  };
}

function getSenderNameFromString(sender: string): string {
  switch (sender) {
    case 'user':
      return 'You (Presiding Judge)';
    case 'system':
      return 'System';
    case 'strict':
      return 'Legalis';
    case 'humanist':
      return 'Humanis';
    case 'historian':
      return 'Sejarawan';
    default:
      return sender;
  }
}

export function normalizeMessages(messages: ApiDeliberationMessage[]): UIDeliberationMessage[] {
  return messages.map(normalizeMessage);
}

export function toApiMessage(message: UIDeliberationMessage): ApiDeliberationMessage {
  let sender: MessageSender;

  switch (message.sender) {
    case 'user':
      sender = { type: 'user' };
      break;
    case 'system':
      sender = { type: 'system' };
      break;
    default:
      sender = { type: 'agent', agent_id: message.sender as AgentId };
  }

  return {
    id: message.id,
    session_id: message.session_id,
    sender,
    content: message.content,
    intent: message.intent,
    cited_cases: message.cited_cases ?? [],
    cited_laws: message.cited_laws ?? [],
    timestamp: message.timestamp.toISOString(),
  };
}
