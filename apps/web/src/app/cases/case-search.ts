import type { CaseType } from '@/types/api';
import type { SearchCasesQuery } from '@/services/api';

type CaseTypeFilter = CaseType | 'all';

export type CaseSearchAction =
  | { kind: 'none' }
  | { kind: 'query'; params: SearchCasesQuery }
  | { kind: 'byType'; caseType: CaseType; limit: number; offset: number };

interface GetCaseSearchActionParams {
  query: string;
  caseType: CaseTypeFilter;
  semanticSearch: boolean;
  limit?: number;
  offset?: number;
}

export function getCaseSearchAction({
  query,
  caseType,
  semanticSearch,
  limit = 20,
  offset = 0,
}: GetCaseSearchActionParams): CaseSearchAction {
  const trimmedQuery = query.trim();

  if (trimmedQuery) {
    const params: SearchCasesQuery = {
      query: trimmedQuery,
      limit,
      semantic: semanticSearch,
    };

    if (caseType !== 'all') {
      params.case_type = caseType;
    }

    return {
      kind: 'query',
      params,
    };
  }

  if (caseType !== 'all') {
    return {
      kind: 'byType',
      caseType,
      limit,
      offset,
    };
  }

  return { kind: 'none' };
}
