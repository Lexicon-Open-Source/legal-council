import { beforeEach, describe, expect, it, vi } from 'vitest';

const { clientMock, createBackendClientMock } = vi.hoisted(() => {
  const clientMock = {
    GET: vi.fn(),
    POST: vi.fn(),
    DELETE: vi.fn(),
  };

  return {
    clientMock,
    createBackendClientMock: vi.fn(() => clientMock),
  };
});

vi.mock('@lexicon/openapi-client/backend', () => ({
  createBackendClient: createBackendClientMock,
}));

import { apiService } from './api';

const session = {
  id: 'sess_1',
  status: 'active',
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
  messages: [],
  created_at: '2026-04-29T00:00:00.000Z',
  updated_at: '2026-04-29T00:00:00.000Z',
};

describe('apiService', () => {
  beforeEach(() => {
    clientMock.GET.mockReset();
    clientMock.POST.mockReset();
    clientMock.DELETE.mockReset();
    createBackendClientMock.mockReturnValue(clientMock);
  });

  it('creates a session through the JSON response contract', async () => {
    const response = {
      session_id: 'sess_1',
      parsed_case: {
        case_type: 'corruption',
        summary: 'Kasus korupsi',
        key_facts: [],
        charges: [],
      },
      similar_cases: [],
    };
    clientMock.POST.mockResolvedValue({ data: response, error: undefined });

    await expect(
      apiService.createSession({
        case_summary: 'Ringkasan perkara korupsi yang cukup panjang untuk diproses.',
        case_type: 'corruption',
        input_type: 'text_summary',
      }),
    ).resolves.toBe(response);

    expect(clientMock.POST).toHaveBeenCalledWith('/v1/council/sessions', {
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: {
        case_summary: 'Ringkasan perkara korupsi yang cukup panjang untuk diproses.',
        case_type: 'corruption',
        input_type: 'text_summary',
      },
    });
  });

  it('returns getSession response without double wrapping the session envelope', async () => {
    const response = { session };
    clientMock.GET.mockResolvedValue({ data: response, error: undefined });

    await expect(apiService.getSession('sess_1')).resolves.toBe(response);

    expect(clientMock.GET).toHaveBeenCalledWith('/v1/council/sessions/{session_id}', {
      params: { path: { session_id: 'sess_1' } },
    });
  });

  it('returns concludeSession response without double wrapping the session envelope', async () => {
    const response = { session: { ...session, status: 'concluded' } };
    clientMock.POST.mockResolvedValue({ data: response, error: undefined });

    await expect(apiService.concludeSession('sess_1')).resolves.toBe(response);

    expect(clientMock.POST).toHaveBeenCalledWith('/v1/council/sessions/{session_id}/conclude', {
      params: { path: { session_id: 'sess_1' } },
    });
  });

  it('searches cases through the GET endpoint with semantic and case type query params', async () => {
    const response = { cases: [], total: 0 };
    clientMock.GET.mockResolvedValue({ data: response, error: undefined });

    await expect(
      apiService.searchCasesByQuery({
        query: 'korupsi proyek',
        limit: 20,
        semantic: true,
        case_type: 'corruption',
      }),
    ).resolves.toBe(response);

    expect(clientMock.GET).toHaveBeenCalledWith('/v1/council/cases/search', {
      params: {
        query: {
          query: 'korupsi proyek',
          limit: 20,
          semantic: true,
          case_type: 'corruption',
        },
      },
    });
  });

  it('gets cases by type with path and pagination params', async () => {
    const response = { cases: [], total: 0 };
    clientMock.GET.mockResolvedValue({ data: response, error: undefined });

    await expect(apiService.getCasesByType('narcotics', 25, 5)).resolves.toBe(response);

    expect(clientMock.GET).toHaveBeenCalledWith('/v1/council/cases/by-type/{case_type}', {
      params: {
        path: { case_type: 'narcotics' },
        query: { limit: 25, offset: 5 },
      },
    });
  });

  it('throws when the generated client returns an error', async () => {
    clientMock.GET.mockResolvedValue({ data: undefined, error: { message: 'nope' } });

    await expect(apiService.getCasesByType('other')).rejects.toThrow('Failed to get cases by type');
  });
});
