import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import CasesPage from './page';
import { getCaseSearchAction } from './case-search';

const apiServiceMock = vi.hoisted(() => ({
  getCaseStatistics: vi.fn(),
  searchCasesByQuery: vi.fn(),
  getCasesByType: vi.fn(),
}));

vi.mock('@/services/api', () => ({
  apiService: apiServiceMock,
}));

describe('case search action', () => {
  it('builds a GET search query without case_type for all categories', () => {
    expect(
      getCaseSearchAction({
        query: ' korupsi proyek ',
        caseType: 'all',
        semanticSearch: true,
      }),
    ).toEqual({
      kind: 'query',
      params: {
        query: 'korupsi proyek',
        limit: 20,
        semantic: true,
      },
    });
  });

  it('builds a GET search query with case_type for filtered searches', () => {
    expect(
      getCaseSearchAction({
        query: 'sabu',
        caseType: 'narcotics',
        semanticSearch: false,
      }),
    ).toEqual({
      kind: 'query',
      params: {
        query: 'sabu',
        limit: 20,
        semantic: false,
        case_type: 'narcotics',
      },
    });
  });

  it('browses by case type when no query is present', () => {
    expect(
      getCaseSearchAction({
        query: ' ',
        caseType: 'corruption',
        semanticSearch: true,
      }),
    ).toEqual({
      kind: 'byType',
      caseType: 'corruption',
      limit: 20,
      offset: 0,
    });
  });
});

describe('CasesPage', () => {
  beforeEach(() => {
    apiServiceMock.getCaseStatistics.mockReset();
    apiServiceMock.searchCasesByQuery.mockReset();
    apiServiceMock.getCasesByType.mockReset();

    apiServiceMock.getCaseStatistics.mockResolvedValue({
      total_cases: 1250,
      sentence_distribution: {},
      verdict_distribution: {},
    });
  });

  it('renders CaseRecord results returned by the new search endpoint', async () => {
    apiServiceMock.searchCasesByQuery.mockResolvedValue({
      cases: [
        {
          id: 'case_1',
          case_number: '45/Pid.Sus-TPK/2023/PN.Jkt.Pst',
          case_type: 'corruption',
          court_name: 'Pengadilan Tipikor Jakarta Pusat',
          decision_date: '2023-08-17',
          defendant_name: 'Budi Santoso',
          legal_basis: ['Pasal 12 huruf a UU 31/1999'],
          is_landmark_case: false,
          summary_id: 'Kepala Dinas terbukti menerima suap proyek jalan.',
        },
      ],
      total: 1,
    });

    render(<CasesPage />);

    fireEvent.change(screen.getByPlaceholderText(/Ketik kata kunci/), {
      target: { value: 'korupsi proyek' },
    });
    fireEvent.click(screen.getByRole('button', { name: /Cari/ }));

    await waitFor(() => {
      expect(apiServiceMock.searchCasesByQuery).toHaveBeenCalledWith({
        query: 'korupsi proyek',
        limit: 20,
        semantic: true,
      });
    });

    expect(await screen.findByText('45/Pid.Sus-TPK/2023/PN.Jkt.Pst')).toBeTruthy();
    expect(screen.getByText('Pengadilan Tipikor Jakarta Pusat')).toBeTruthy();
    expect(screen.getByText('Budi Santoso')).toBeTruthy();
    expect(screen.getByText(/Kepala Dinas terbukti menerima suap/)).toBeTruthy();
  });

  it('shows the existing recovery message when search fails', async () => {
    apiServiceMock.searchCasesByQuery.mockRejectedValue(new Error('network down'));

    render(<CasesPage />);

    fireEvent.change(screen.getByPlaceholderText(/Ketik kata kunci/), {
      target: { value: 'korupsi' },
    });
    fireEvent.click(screen.getByRole('button', { name: /Cari/ }));

    expect(
      await screen.findByText(
        /Pencarian putusan belum berhasil. Coba lagi, atau gunakan kata kunci yang lebih umum/,
      ),
    ).toBeTruthy();
  });
});
