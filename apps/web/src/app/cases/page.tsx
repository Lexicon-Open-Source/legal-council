'use client';

import { useState, useCallback, useEffect } from 'react';
import {
  Search,
  FileText,
  Calendar,
  User,
  Scale,
  Loader2,
  ArrowRight,
  AlertCircle,
} from 'lucide-react';
import {
  Alert,
  AlertDescription,
  Button,
  Input,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  Skeleton,
  cn,
} from '@lexicon/design-system';
import { apiService } from '@/services/api';
import { CaseRecord, CaseType, CaseStatisticsResponse } from '@/types/api';
import { getCaseSearchAction } from './case-search';
import ReactMarkdown, { type Components } from 'react-markdown';
import remarkGfm from 'remark-gfm';

const cardMarkdownComponents: Components = {
  p: ({ ...props }) => <span {...props} />,
  ul: ({ ...props }) => <span className='inline' {...props} />,
  ol: ({ ...props }) => <span className='inline' {...props} />,
  li: ({ ...props }) => <span {...props}>{' • '}</span>,
  strong: ({ ...props }) => <strong className='font-semibold' {...props} />,
  em: ({ ...props }) => <em {...props} />,
  a: ({ ...props }) => <span className='text-primary underline' {...props} />,
  h1: ({ ...props }) => <span className='font-bold' {...props} />,
  h2: ({ ...props }) => <span className='font-bold' {...props} />,
  h3: ({ ...props }) => <span className='font-semibold' {...props} />,
  blockquote: ({ ...props }) => <span className='italic' {...props} />,
  code: ({ ...props }) => <code className='bg-paper px-1 rounded text-xs' {...props} />,
  pre: ({ ...props }) => <span {...props} />,
};

const CASE_TYPE_LABELS: Record<CaseType, string> = {
  narcotics: 'Narkotika',
  corruption: 'Korupsi',
  general_criminal: 'Pidana Umum',
  other: 'Lainnya',
};

function CaseRowSkeleton() {
  return (
    <li className='grid grid-cols-1 gap-3 border-t border-paper-edge py-5 sm:grid-cols-[10rem_minmax(0,1fr)] sm:gap-6'>
      <Skeleton className='h-4 w-32' />
      <div className='space-y-2'>
        <Skeleton className='h-4 w-3/4' />
        <Skeleton className='h-3 w-full' />
        <Skeleton className='h-3 w-2/3' />
      </div>
    </li>
  );
}

function CaseRow({ caseItem, index }: { caseItem: CaseRecord; index: number }) {
  const caseType = (caseItem.case_type || 'other') as CaseType;

  return (
    <li
      className='anim-list-row group grid grid-cols-1 gap-3 border-t border-paper-edge py-5 transition-snap hover:bg-paper/60 sm:grid-cols-[10rem_minmax(0,1fr)] sm:gap-6'
      style={{ '--stagger-i': index } as React.CSSProperties}
    >
      <div className='space-y-1.5'>
        <span className='font-folio text-sm font-medium text-foreground'>
          {caseItem.case_number || 'No. Tidak Tersedia'}
        </span>
        <p className='text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
          {CASE_TYPE_LABELS[caseType]}
        </p>
      </div>

      <div className='min-w-0'>
        <div className='flex items-baseline gap-2 text-[0.8125rem] text-muted-foreground'>
          <Scale className='size-3 shrink-0' />
          <span className='truncate'>{caseItem.court_name || 'Pengadilan tidak diketahui'}</span>
          {caseItem.decision_date && (
            <>
              <span aria-hidden className='text-muted-foreground/50'>
                ·
              </span>
              <span className='inline-flex items-center gap-1 whitespace-nowrap'>
                <Calendar className='size-3 shrink-0' />
                {new Date(caseItem.decision_date).toLocaleDateString('id-ID', {
                  year: 'numeric',
                  month: 'short',
                  day: 'numeric',
                })}
              </span>
            </>
          )}
        </div>

        <p className='mt-2 line-clamp-2 text-[0.875rem] leading-relaxed text-foreground/90'>
          <ReactMarkdown remarkPlugins={[remarkGfm]} components={cardMarkdownComponents}>
            {caseItem.summary_id || caseItem.summary_en || 'Ringkasan tidak tersedia'}
          </ReactMarkdown>
        </p>

        <div className='mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-[0.6875rem] uppercase tracking-[0.14em] text-muted-foreground'>
          {caseItem.defendant_name && (
            <span className='inline-flex items-center gap-1'>
              <User className='size-3' />
              {caseItem.defendant_name}
            </span>
          )}
          {caseItem.legal_basis &&
            caseItem.legal_basis.slice(0, 2).map((law, i) => (
              <span key={i} className='font-folio text-foreground/70'>
                {law}
              </span>
            ))}
          {caseItem.legal_basis && caseItem.legal_basis.length > 2 && (
            <span>+{caseItem.legal_basis.length - 2}</span>
          )}
        </div>
      </div>
    </li>
  );
}

export default function CasesPage() {
  const [query, setQuery] = useState('');
  const [caseType, setCaseType] = useState<CaseType | 'all'>('all');
  const [semanticSearch, setSemanticSearch] = useState(true);
  const [cases, setCases] = useState<CaseRecord[]>([]);
  const [stats, setStats] = useState<CaseStatisticsResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [statsLoading, setStatsLoading] = useState(true);
  const [searched, setSearched] = useState(false);
  const [searchError, setSearchError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const response = await apiService.getCaseStatistics();
        setStats({
          total_cases: response.total_cases ?? 0,
          sentence_distribution: {},
          verdict_distribution: {},
        });
      } catch {
        // Statistics are nice-to-have. The page remains usable when the API is
        // offline, so avoid turning this handled fallback into a dev overlay.
      } finally {
        setStatsLoading(false);
      }
    })();
  }, []);

  const handleSearch = useCallback(
    async (overrides?: {
      query?: string;
      caseType?: CaseType | 'all';
      semanticSearch?: boolean;
    }) => {
      const searchQuery = overrides?.query ?? query;
      const selectedCaseType = overrides?.caseType ?? caseType;
      const useSemanticSearch = overrides?.semanticSearch ?? semanticSearch;
      const action = getCaseSearchAction({
        query: searchQuery,
        caseType: selectedCaseType,
        semanticSearch: useSemanticSearch,
      });

      if (action.kind === 'none') return;
      setLoading(true);
      setSearched(true);
      setSearchError(null);

      try {
        const response =
          action.kind === 'query'
            ? await apiService.searchCasesByQuery(action.params)
            : await apiService.getCasesByType(action.caseType, action.limit, action.offset);

        setCases(response.cases ?? []);
      } catch {
        setCases([]);
        setSearchError(
          'Pencarian putusan belum berhasil. Coba lagi, atau gunakan kata kunci yang lebih umum jika jaringan sedang lambat.',
        );
      } finally {
        setLoading(false);
      }
    },
    [query, semanticSearch, caseType],
  );

  return (
    <div className='space-y-10'>
      {/* MASTHEAD */}
      <header className='anim-folio-rise flex flex-col gap-3 border-b border-paper-edge pb-4 sm:flex-row sm:items-end sm:justify-between sm:gap-6'>
        <div className='min-w-0'>
          <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
            Pencarian Yurisprudensi
          </p>
          <h1 className='mt-1 font-rethink text-[1.625rem] font-semibold leading-tight tracking-tight text-foreground sm:text-[1.875rem]'>
            Telusuri preseden dan putusan
          </h1>
          <p className='mt-2 max-w-prose text-sm leading-relaxed text-muted-foreground'>
            Cari putusan pengadilan yang serupa dengan perkara yang sedang Anda pertimbangkan —
            sebagai bahan banding, pertimbangan, atau referensi.
          </p>
        </div>
        <div className='font-folio text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
          {statsLoading ? (
            <Skeleton className='inline-block h-3 w-32' />
          ) : (
            <>
              <span className='text-foreground'>
                {stats?.total_cases?.toLocaleString('id-ID') ?? '—'}
              </span>{' '}
              kasus terindeks
            </>
          )}
        </div>
      </header>

      {/* SEARCH BAR — leads the page; no card containing it */}
      <section className='anim-folio-rise-delay-1'>
        <div className='flex flex-col gap-3 sm:flex-row sm:items-center'>
          <div className='relative flex-1'>
            <Search className='pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground' />
            <Input
              placeholder='Ketik kata kunci, nomor perkara, atau deskripsi singkat…'
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') void handleSearch();
              }}
              className='h-11 border-paper-edge bg-paper pl-9 text-[0.9375rem] focus-visible:border-foreground/30'
            />
          </div>
          <Select value={caseType} onValueChange={(v) => setCaseType(v as CaseType | 'all')}>
            <SelectTrigger className='h-11 w-full border-paper-edge bg-paper sm:w-[180px]'>
              <SelectValue placeholder='Kategori' />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value='all'>Semua kategori</SelectItem>
              <SelectItem value='narcotics'>Narkotika</SelectItem>
              <SelectItem value='corruption'>Korupsi</SelectItem>
              <SelectItem value='general_criminal'>Pidana Umum</SelectItem>
              <SelectItem value='other'>Lainnya</SelectItem>
            </SelectContent>
          </Select>
          <Button
            onClick={() => void handleSearch()}
            disabled={loading || (!query.trim() && caseType === 'all')}
            className='press h-11 px-5 disabled:bg-muted disabled:text-muted-foreground disabled:opacity-60'
          >
            {loading ? <Loader2 className='size-4 animate-spin' /> : <Search className='size-4' />}
            Cari
          </Button>
        </div>

        <button
          type='button'
          role='switch'
          aria-checked={semanticSearch}
          onClick={() => setSemanticSearch((v) => !v)}
          className='press mt-3 inline-flex min-h-8 items-center gap-2 rounded-full border border-paper-edge bg-paper px-3 text-xs text-muted-foreground transition-snap hover:border-foreground/30 hover:text-foreground'
        >
          <span
            aria-hidden
            className={cn(
              'relative inline-flex h-4 w-7 items-center rounded-full transition-flow',
              semanticSearch ? 'bg-primary/90' : 'bg-muted-foreground/25',
            )}
          >
            <span
              className={cn(
                'inline-block size-3 rounded-full bg-background shadow-sm transition-flow',
                semanticSearch ? 'translate-x-3.5' : 'translate-x-0.5',
              )}
            />
          </span>
          <span>Pencarian semantik</span>
          <span className='font-folio text-foreground/70'>{semanticSearch ? 'aktif' : 'mati'}</span>
        </button>

        <p className='mt-4 flex flex-wrap items-center gap-x-3 gap-y-1 text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
          <span>Cari cepat</span>
          {(['narcotics', 'corruption', 'general_criminal'] as const).map((type) => (
            <button
              key={type}
              type='button'
              onClick={() => {
                const nextQuery = CASE_TYPE_LABELS[type].toLowerCase();
                setQuery(nextQuery);
                setCaseType(type);
                void handleSearch({ query: nextQuery, caseType: type });
              }}
              className='inline-flex items-center gap-1 border-b border-dotted border-foreground/30 text-foreground/85 transition-snap hover:border-primary hover:text-primary'
            >
              {CASE_TYPE_LABELS[type]}
            </button>
          ))}
        </p>
      </section>

      {/* RESULTS */}
      <section className='anim-folio-rise-delay-2'>
        {searchError && (
          <Alert variant='destructive' className='mb-5'>
            <AlertCircle />
            <AlertDescription>{searchError}</AlertDescription>
          </Alert>
        )}

        {loading ? (
          <ul>
            {Array.from({ length: 3 }).map((_, i) => (
              <CaseRowSkeleton key={i} />
            ))}
          </ul>
        ) : searchError ? null : searched && cases.length === 0 ? (
          <div className='border-t border-paper-edge py-16 text-center'>
            <FileText className='anim-drift mx-auto size-8 text-muted-foreground/60' />
            <p className='mt-3 font-rethink text-base font-medium text-foreground'>
              Belum ada putusan yang cocok dengan pencarian ini
            </p>
            <p className='mt-1 mx-auto max-w-md text-sm leading-relaxed text-muted-foreground'>
              Coba pakai kata yang lebih umum, kurangi filter, atau matikan pencarian semantik untuk
              mencocokkan kata persis.
            </p>
          </div>
        ) : cases.length > 0 ? (
          <>
            <p className='mb-3 text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
              Hasil pencarian
              <span className='ml-2 font-folio text-foreground/80'>{cases.length} kasus</span>
            </p>
            <ul className='border-b border-paper-edge'>
              {cases.map((caseItem, i) => (
                <CaseRow key={caseItem.id} caseItem={caseItem} index={i} />
              ))}
            </ul>
          </>
        ) : (
          <div className='border-t border-paper-edge py-16 text-center'>
            <Search className='anim-drift mx-auto size-8 text-muted-foreground/60' />
            <p className='mt-3 font-rethink text-base font-medium text-foreground'>
              Cari putusan dan yurisprudensi yang serupa
            </p>
            <p className='mt-1 max-w-md mx-auto text-sm leading-relaxed text-muted-foreground'>
              Ketik beberapa kata — nomor perkara, nama terdakwa, atau ringkasan singkat tentang apa
              yang Anda cari. Pencarian semantik akan mencocokkan makna, bukan hanya kata persis.
            </p>
            <p className='mt-6 text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
              Coba pencarian
            </p>
            <button
              type='button'
              onClick={() => {
                const nextQuery = 'narkotika';
                setQuery(nextQuery);
                setCaseType('narcotics');
                void handleSearch({ query: nextQuery, caseType: 'narcotics' });
              }}
              className='mt-1 inline-flex items-center gap-1.5 border-b border-dotted border-foreground/40 pb-0.5 text-sm text-foreground transition-snap hover:border-primary hover:text-primary'
            >
              Contoh perkara narkotika
              <ArrowRight className='size-3.5' />
            </button>
          </div>
        )}
      </section>
    </div>
  );
}
