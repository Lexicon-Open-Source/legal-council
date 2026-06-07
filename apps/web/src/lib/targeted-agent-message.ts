import type { AgentId, StreamMessageRequest } from '@/types/api';

type TargetAgent = NonNullable<StreamMessageRequest['target_agent']>;

const API_TARGET_AGENT: Record<AgentId, TargetAgent> = {
  strict: 'legalis',
  humanist: 'humanis',
  historian: 'sejarawan',
};

const TARGET_AGENT_ADDRESS: Record<AgentId, string> = {
  strict: 'Hakim Legalis',
  humanist: 'Hakim Humanis',
  historian: 'Hakim Sejarawan',
};

const TARGET_AGENT_PATTERN: Record<AgentId, RegExp> = {
  strict: /\b(hakim\s+(legalis|strict|ketat)|legalis|konstruksionis)\b/i,
  humanist: /\bhakim\s+(humanis|rehabilitatif?)\b/i,
  historian: /\bhakim\s+(sejarawan|historis|preseden)\b/i,
};

const DISPLAY_AGENT_PREFIX = /^(Legalis|Humanis|Sejarawan)\b\s*,?\s*/i;

export function formatTargetedAgentMessage(content: string, targetAgent?: AgentId): string {
  const trimmed = content.trim();
  if (!targetAgent || !trimmed || TARGET_AGENT_PATTERN[targetAgent].test(trimmed)) {
    return trimmed;
  }

  const address = TARGET_AGENT_ADDRESS[targetAgent];
  if (DISPLAY_AGENT_PREFIX.test(trimmed)) {
    return trimmed.replace(DISPLAY_AGENT_PREFIX, `${address}, `);
  }

  return `${address}, ${trimmed}`;
}

export function getApiTargetAgent(targetAgent?: AgentId): TargetAgent | undefined {
  return targetAgent ? API_TARGET_AGENT[targetAgent] : undefined;
}
