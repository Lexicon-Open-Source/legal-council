import { createBackendClient } from '@lexicon/openapi-client/backend';
import type { components, operations } from '@lexicon/openapi-client/backend';
import { config } from '@/lib/config';
import { fetchRawSSE, fetchSSE } from '@/lib/sse';
import type { CreateSessionStreamEventData, SSEEvent } from '@/types/api';

const client = createBackendClient({
  baseUrl: config.api.baseUrl,
});

export type CouncilCaseType = components['schemas']['CouncilCaseType'];
export type SessionStatus = components['schemas']['SessionStatus'];
export type CreateSessionRequest = components['schemas']['CreateSessionRequest'];
export type CreateSessionResponse = components['schemas']['CreateSessionResponse'];
export type GetSessionResponse = components['schemas']['GetSessionResponse'];
export type ListSessionsResponse = components['schemas']['ListSessionsResponse'];
export type SendMessageRequest = components['schemas']['SendMessageRequest'];
export type SendMessageResponse = components['schemas']['SendMessageResponse'];
export type ContinueDiscussionRequest = components['schemas']['ContinueDiscussionRequest'];
export type ContinueDiscussionResponse = components['schemas']['ContinueDiscussionResponse'];
export type GetMessagesResponse = components['schemas']['GetMessagesResponse'];
export type GenerateOpinionRequest = components['schemas']['GenerateOpinionRequest'];
export type GenerateOpinionResponse = components['schemas']['GenerateOpinionResponse'];
export type SearchCasesRequest = components['schemas']['SearchCasesRequest'];
export type SearchCasesResponse = components['schemas']['SearchCasesResponse'];
export type SearchCasesQuery = operations['searchCouncilCasesGet']['parameters']['query'];
export type GetCaseResponse = components['schemas']['GetCaseResponse'];
export type CaseStatisticsResponse = components['schemas']['CaseStatisticsResponse'];
export type DeliberationSession = components['schemas']['DeliberationSession'];
export type DeliberationMessage = components['schemas']['DeliberationMessage'];
export type CouncilSimilarCase = components['schemas']['CouncilSimilarCase'];

class ApiService {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  private getHeaders(additionalHeaders: HeadersInit = {}): HeadersInit {
    return {
      'Content-Type': 'application/json',
      ...additionalHeaders,
    };
  }

  async getHealth() {
    const { data, error } = await client.GET('/health');
    if (error) throw new Error('Failed to check health');
    return data;
  }

  async createSession(requestData: CreateSessionRequest): Promise<CreateSessionResponse> {
    const { data, error } = await client.POST('/v1/council/sessions', {
      headers: this.getHeaders({ Accept: 'application/json' }),
      body: requestData,
    });

    if (error) {
      console.error('Create session failed:', error);
      throw new Error('Failed to create session');
    }

    return data as CreateSessionResponse;
  }

  async streamCreateSession(
    requestData: CreateSessionRequest,
    onEvent: (event: CreateSessionStreamEventData) => void,
    onComplete: () => void,
    onError: (error: Error) => void,
  ): Promise<void> {
    const url = this.getSSEUrl('/v1/council/sessions');

    await fetchRawSSE<CreateSessionStreamEventData>(
      url,
      {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify(requestData),
      },
      { onEvent, onComplete, onError },
    );
  }

  async getSession(sessionId: string): Promise<GetSessionResponse> {
    const { data, error } = await client.GET('/v1/council/sessions/{session_id}', {
      params: { path: { session_id: sessionId } },
    });
    if (error) throw new Error('Failed to get session');
    return data!;
  }

  async listSessions(status?: SessionStatus, limit = 20, offset = 0) {
    const { data, error } = await client.GET('/v1/council/sessions', {
      params: { query: { status, limit, offset } },
    });
    if (error) throw new Error('Failed to list sessions');
    return data!;
  }

  async deleteSession(sessionId: string) {
    const { data, error } = await client.DELETE('/v1/council/sessions/{session_id}', {
      params: { path: { session_id: sessionId } },
    });
    if (error) throw new Error('Failed to delete session');
    return data;
  }

  async concludeSession(sessionId: string): Promise<GetSessionResponse> {
    const { data, error } = await client.POST('/v1/council/sessions/{session_id}/conclude', {
      params: { path: { session_id: sessionId } },
    });
    if (error) throw new Error('Failed to conclude session');
    return data!;
  }

  async sendMessage(sessionId: string, requestData: SendMessageRequest) {
    const { data, error } = await client.POST('/v1/council/deliberation/{session_id}/message', {
      params: { path: { session_id: sessionId } },
      body: requestData,
    });
    if (error) throw new Error('Failed to send message');
    return data!;
  }

  async continueDiscussion(
    sessionId: string,
    requestData: Partial<ContinueDiscussionRequest> = {},
  ) {
    const { data, error } = await client.POST('/v1/council/deliberation/{session_id}/continue', {
      params: { path: { session_id: sessionId } },
      body: { num_rounds: requestData.num_rounds ?? 1 },
    });
    if (error) throw new Error('Failed to continue discussion');
    return data!;
  }

  async getMessages(sessionId: string, limit = 50) {
    const { data, error } = await client.GET('/v1/council/deliberation/{session_id}/messages', {
      params: { path: { session_id: sessionId }, query: { limit } },
    });
    if (error) throw new Error('Failed to get messages');
    return data!;
  }

  async generateOpinion(sessionId: string) {
    const { data, error } = await client.POST('/v1/council/deliberation/{session_id}/opinion', {
      params: { path: { session_id: sessionId } },
    });
    if (error) throw new Error('Failed to generate opinion');
    return data!;
  }

  async getOpinion(sessionId: string) {
    const { data, error } = await client.GET('/v1/council/deliberation/{session_id}/opinion', {
      params: { path: { session_id: sessionId } },
    });
    if (error) throw new Error('Failed to get opinion');
    return data;
  }

  private getSSEUrl(endpoint: string): string {
    const normalizedBase = this.baseUrl.endsWith('/') ? this.baseUrl.slice(0, -1) : this.baseUrl;
    const normalizedEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
    return `${normalizedBase}${normalizedEndpoint}`;
  }

  async streamInitialOpinions(
    sessionId: string,
    onEvent: (event: SSEEvent) => void,
    onComplete: () => void,
    onError: (error: Error) => void,
  ): Promise<void> {
    const url = this.getSSEUrl(`/v1/council/deliberation/${sessionId}/stream/initial`);

    await fetchSSE(
      url,
      {
        method: 'POST',
        headers: this.getHeaders(),
      },
      { onEvent, onComplete, onError, sessionId },
    );
  }

  async streamMessage(
    sessionId: string,
    data: { content: string; target_agent?: string | null },
    onEvent: (event: SSEEvent) => void,
    onComplete: () => void,
    onError: (error: Error) => void,
  ): Promise<void> {
    const url = this.getSSEUrl(`/v1/council/deliberation/${sessionId}/stream/message`);

    await fetchSSE(
      url,
      {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify(data),
      },
      { onEvent, onComplete, onError, sessionId },
    );
  }

  async streamContinueDiscussion(
    sessionId: string,
    data: { num_rounds?: number } = {},
    onEvent: (event: SSEEvent) => void,
    onComplete: () => void,
    onError: (error: Error) => void,
  ): Promise<void> {
    const url = this.getSSEUrl(`/v1/council/deliberation/${sessionId}/stream/continue`);

    await fetchSSE(
      url,
      {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify(data),
      },
      { onEvent, onComplete, onError, sessionId },
    );
  }

  async searchCases(requestData: SearchCasesRequest) {
    const { data, error } = await client.POST('/v1/council/cases/search', {
      body: requestData,
    });
    if (error) throw new Error('Failed to search cases');
    return data!;
  }

  async searchCasesByQuery(params: SearchCasesQuery) {
    const { data, error } = await client.GET('/v1/council/cases/search', {
      params: { query: params },
    });
    if (error) throw new Error('Failed to search cases');
    return data!;
  }

  async getCasesByType(caseType: CouncilCaseType, limit = 20, offset = 0) {
    const { data, error } = await client.GET('/v1/council/cases/by-type/{case_type}', {
      params: { path: { case_type: caseType }, query: { limit, offset } },
    });
    if (error) throw new Error('Failed to get cases by type');
    return data!;
  }

  async getCase(caseId: string) {
    const { data, error } = await client.GET('/v1/council/cases/{case_id}', {
      params: { path: { case_id: caseId } },
    });
    if (error) throw new Error('Failed to get case');
    return data!;
  }

  async getCaseStatistics() {
    const { data, error } = await client.GET('/v1/council/cases/statistics');
    if (error) throw new Error('Failed to get case statistics');
    return data!;
  }

  async downloadDeliberationPdf(sessionId: string): Promise<Blob> {
    const url = this.getSSEUrl(`/v1/council/deliberation/${sessionId}/download/pdf`);
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'application/pdf',
      },
    });

    if (!response.ok) {
      throw new Error(`Download failed: ${response.status}`);
    }

    return response.blob();
  }

  triggerDownload(blob: Blob, filename: string): void {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }
}

export const apiService = new ApiService(config.api.baseUrl);
