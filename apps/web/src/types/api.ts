// Re-export types from openapi-client
import type { components } from '@lexicon/openapi-client/backend';

// ===========================================
// RE-EXPORTED TYPES FROM OPENAPI-CLIENT
// ===========================================

export type AgentId = components['schemas']['AgentId'];
export type CaseType = components['schemas']['CouncilCaseType'];
export type InputType = components['schemas']['InputType'];
export type SessionStatus = components['schemas']['SessionStatus'];
export type MessageIntent = components['schemas']['MessageIntent'];
export type VerdictDecision = components['schemas']['VerdictDecision'];
export type NarcoticsIntent = components['schemas']['NarcoticsIntent'];

// Sender types
export type UserSender = components['schemas']['UserSender'];
export type AgentSender = components['schemas']['AgentSender'];
export type SystemSender = components['schemas']['SystemSender'];
export type MessageSender = components['schemas']['MessageSender'];

// Case input types
export type DefendantProfile = components['schemas']['CouncilDefendantProfile'];
export type NarcoticsDetails = components['schemas']['NarcoticsDetails'];
export type CorruptionDetails = components['schemas']['CorruptionDetails'];
export type ParsedCaseInput = components['schemas']['ParsedCaseInput'];
export type CaseInput = components['schemas']['CaseInput'];
export type StructuredCaseData = components['schemas']['StructuredCaseData'];

// Similar case type
export type SimilarCase = components['schemas']['CouncilSimilarCase'];

// Deliberation message
export type DeliberationMessage = components['schemas']['DeliberationMessage'];

// Deliberation session
export type DeliberationSession = components['schemas']['DeliberationSession'];
export type DeliberationPhase = components['schemas']['DeliberationPhase'];
export type PhaseMetadata = components['schemas']['PhaseMetadata'];
export type AgreementMap = components['schemas']['AgreementMap'];
export type AgentPosition = components['schemas']['AgentPosition'];
export type PositionStance = components['schemas']['PositionStance'];

// Legal opinion types
export type SentenceRange = components['schemas']['SentenceRange'];
export type VerdictRecommendation = components['schemas']['VerdictRecommendation'];
export type SentenceRecommendation = components['schemas']['SentenceRecommendation'];
export type ArgumentPoint = components['schemas']['ArgumentPoint'];
export type LegalArguments = components['schemas']['LegalArguments'];
export type CitedPrecedent = components['schemas']['CitedPrecedent'];
export type ApplicableLaw = components['schemas']['ApplicableLaw'];
export type LegalOpinionDraft = components['schemas']['LegalOpinionDraft'];

// Case record
export type CaseRecord = components['schemas']['CaseRecord'];

// Request types
export type CreateSessionRequest = components['schemas']['CreateSessionRequest'];
export type SendMessageRequest = components['schemas']['SendMessageRequest'];
export type ContinueDiscussionRequest = components['schemas']['ContinueDiscussionRequest'];
export type GenerateOpinionRequest = components['schemas']['GenerateOpinionRequest'];
export type SearchCasesRequest = components['schemas']['SearchCasesRequest'];
export type StreamMessageRequest = components['schemas']['StreamMessageRequest'];
export type StreamContinueRequest = components['schemas']['StreamContinueRequest'];

// Response types
export type CreateSessionResponse = components['schemas']['CreateSessionResponse'];
export type GetSessionResponse = components['schemas']['GetSessionResponse'];
export type ListSessionsResponse = components['schemas']['ListSessionsResponse'];
export type SendMessageResponse = components['schemas']['SendMessageResponse'];
export type ContinueDiscussionResponse = components['schemas']['ContinueDiscussionResponse'];
export type GetMessagesResponse = components['schemas']['GetMessagesResponse'];
export type GenerateOpinionResponse = components['schemas']['GenerateOpinionResponse'];
export type SearchCasesResponse = components['schemas']['SearchCasesResponse'];
export type GetCaseResponse = components['schemas']['GetCaseResponse'];
export type CaseStatisticsResponse = components['schemas']['CaseStatisticsResponse'];
export type StreamEventType = components['schemas']['StreamEventType'];
export type StreamEventData = components['schemas']['StreamEventData'];
export type CreateSessionStreamEventType = components['schemas']['CreateSessionStreamEventType'];
export type CreateSessionStreamEventData = components['schemas']['CreateSessionStreamEventData'];

// ===========================================
// SSE EVENT TYPES (Server Format)
// ===========================================

// Raw event structure from the server (matches StreamEventData from OpenAPI)
export type SSERawEvent = StreamEventData;

// ===========================================
// SSE EVENT TYPES (Normalized Frontend Format)
// ===========================================

export interface SSEAgentStartEvent {
  type: 'agent_start';
  agent_id: AgentId;
  agent_name: string;
}

export interface SSEChunkEvent {
  type: 'chunk';
  agent_id: AgentId;
  content: string;
}

export interface SSEAgentCompleteEvent {
  type: 'agent_complete';
  message: DeliberationMessage;
}

export interface SSEAgentErrorEvent {
  type: 'agent_error';
  agent_id: AgentId;
  error: string;
}

export interface SSEUserMessageEvent {
  type: 'user_message';
  message: DeliberationMessage;
}

export interface SSEDeliberationCompleteEvent {
  type: 'deliberation_complete';
  messages: DeliberationMessage[];
}

export interface SSESignalEvent {
  type: 'phase_transition' | 'convergence_suggestion' | 'summary_ready';
  content?: string;
  metadata?: Record<string, unknown>;
}

export type SSEEvent =
  | SSEAgentStartEvent
  | SSEChunkEvent
  | SSEAgentCompleteEvent
  | SSEAgentErrorEvent
  | SSEUserMessageEvent
  | SSEDeliberationCompleteEvent
  | SSESignalEvent;

// Legacy type alias for backwards compatibility
export type StreamChunk = SSEEvent;

// ===========================================
// HELPER FUNCTIONS FOR SENDER TYPE GUARDS
// ===========================================

export function isUserSender(sender: MessageSender): sender is UserSender {
  return sender.type === 'user';
}

export function isAgentSender(sender: MessageSender): sender is AgentSender {
  return sender.type === 'agent';
}

export function isSystemSender(sender: MessageSender): sender is SystemSender {
  return sender.type === 'system';
}

export function getAgentIdFromSender(sender: MessageSender): AgentId | null {
  if (isAgentSender(sender)) {
    return sender.agent_id;
  }
  return null;
}
