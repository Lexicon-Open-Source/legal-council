'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import {
  History,
  MessageSquare,
  FileText,
  Trash2,
  CheckCircle2,
  Archive,
  Loader2,
  AlertCircle,
  Play,
  Download,
  ArrowRight,
  Copy,
  Check,
  WifiOff,
} from 'lucide-react';
import {
  Button,
  Skeleton,
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  cn,
} from '@lexicon/design-system';
import { apiService } from '@/services/api';
import { DeliberationSession, LegalOpinionDraft, SessionStatus } from '@/types/api';
import { useJudgeCounsel } from '@/context/judge-counsel-context';
import { normalizeMessages } from '@/lib/mappers';

type FilterTab = 'all' | SessionStatus;

/**
 * Captures enough context from a failed load to give the user something
 * actionable: what kind of failure, the underlying message (truncated), and
 * a short id they can share with admin if it keeps happening.
 *
 * `kind` discriminates between offline (we can suggest reconnecting) and
 * server (we can offer the contact path). The id is base36-encoded epoch
 * time so two reports from the same minute don't collide.
 */
type LoadError = {
  kind: 'offline' | 'server';
  message: string;
  errorId: string;
};

const SUPPORT_EMAIL = 'lexicon.indonesia.shared@gmail.com';

function makeErrorId(): string {
  return Date.now().toString(36).slice(-6).toUpperCase();
}

function buildLoadError(err: unknown): LoadError {
  // navigator.onLine is a hint — false is reliable, true can lie. We treat
  // an explicit offline state as the highest-confidence signal and fall
  // back to "server" for everything else.
  const offline = typeof navigator !== 'undefined' && navigator.onLine === false;
  const message = err instanceof Error ? err.message : String(err ?? 'unknown error');
  return {
    kind: offline ? 'offline' : 'server',
    message: message.slice(0, 160),
    errorId: makeErrorId(),
  };
}

function sessionLegalOpinion(session: DeliberationSession): LegalOpinionDraft | null {
  const opinion = session.legal_opinion as unknown;
  if (!opinion || typeof opinion !== 'object') return null;
  if (!('verdict_recommendation' in opinion) || !('sentence_recommendation' in opinion)) {
    return null;
  }
  return opinion as LegalOpinionDraft;
}

const TABS: { value: FilterTab; label: string }[] = [
  { value: 'all', label: 'Semua sesi' },
  { value: 'active', label: 'Aktif' },
  { value: 'concluded', label: 'Selesai' },
  { value: 'archived', label: 'Diarsipkan' },
];

const STATUS_LABEL: Record<SessionStatus, { label: string; tone: string }> = {
  active: { label: 'Aktif', tone: 'text-green-6' },
  concluded: { label: 'Selesai', tone: 'text-blue-6' },
  archived: { label: 'Diarsipkan', tone: 'text-muted-foreground' },
};

const STATUS_ICON: Record<SessionStatus, typeof Play> = {
  active: Play,
  concluded: CheckCircle2,
  archived: Archive,
};

function SessionRowSkeleton() {
  return (
    <li className='grid grid-cols-1 gap-4 border-t border-paper-edge py-5 sm:grid-cols-[6rem_minmax(0,1fr)_auto] sm:items-center sm:gap-6'>
      <Skeleton className='h-4 w-20' />
      <div className='space-y-2'>
        <Skeleton className='h-4 w-3/4' />
        <Skeleton className='h-3 w-1/2' />
      </div>
      <Skeleton className='h-8 w-24 sm:justify-self-end' />
    </li>
  );
}

function SessionRow({
  session,
  index,
  onContinue,
  onDelete,
  onViewOpinion,
  onDownload,
  downloadingId,
}: {
  session: DeliberationSession;
  index: number;
  onContinue: (s: DeliberationSession) => void;
  onDelete: (id: string) => void;
  onViewOpinion: (s: DeliberationSession) => void;
  onDownload: (id: string) => void;
  downloadingId: string | null;
}) {
  const status = STATUS_LABEL[session.status];
  const StatusIcon = STATUS_ICON[session.status];
  const messageCount = session.messages?.length || 0;
  const hasOpinion = !!session.legal_opinion;
  const isDownloading = downloadingId === session.id;
  const created = new Date(session.created_at);
  const dateLabel = created.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
  });
  const timeLabel = created.toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
  });

  return (
    <li
      className='anim-list-row group grid grid-cols-1 items-start gap-4 border-t border-paper-edge py-5 transition-snap hover:bg-paper/60 sm:grid-cols-[6rem_minmax(0,1fr)_auto] sm:items-center sm:gap-6'
      style={{ '--stagger-i': index } as React.CSSProperties}
    >
      <div className='font-folio text-sm tabular-nums text-foreground/80'>
        {dateLabel}
        <span className='ml-2 text-xs text-muted-foreground'>{timeLabel}</span>
      </div>

      <div className='min-w-0'>
        <p className='font-rethink text-[0.9375rem] font-medium leading-tight text-foreground line-clamp-1'>
          {session.case_input.parsed_case.summary.slice(0, 120)}
          {session.case_input.parsed_case.summary.length > 120 ? '…' : ''}
        </p>
        <div className='mt-1.5 flex flex-wrap items-center gap-x-4 gap-y-1 text-[0.6875rem] uppercase tracking-[0.14em] text-muted-foreground'>
          <span className={cn('inline-flex items-center gap-1.5', status.tone)}>
            <StatusIcon className='size-3' />
            {status.label}
          </span>
          <span className='inline-flex items-center gap-1.5'>
            <MessageSquare className='size-3' />
            {messageCount} pesan
          </span>
          {hasOpinion && (
            <span className='inline-flex items-center gap-1.5'>
              <FileText className='size-3' />
              Pendapat tersedia
            </span>
          )}
        </div>
      </div>

      <div className='flex flex-wrap items-center gap-1 sm:justify-end'>
        {session.status === 'active' && (
          <Button size='sm' className='press h-8 px-3 text-xs' onClick={() => onContinue(session)}>
            Lanjutkan
            <ArrowRight className='size-3' />
          </Button>
        )}
        {(session.status === 'concluded' || hasOpinion) && (
          <button
            type='button'
            onClick={() => onViewOpinion(session)}
            className='press inline-flex items-center gap-1 rounded-sm px-2 py-1.5 text-xs text-foreground/80 transition-snap hover:text-foreground'
          >
            Lihat pendapat
            <ArrowRight className='size-3' />
          </button>
        )}
        <button
          type='button'
          onClick={() => onDownload(session.id)}
          disabled={isDownloading}
          className='press inline-flex items-center gap-1 rounded-sm px-2 py-1.5 text-xs text-muted-foreground transition-snap hover:text-foreground disabled:opacity-50'
        >
          {isDownloading ? (
            <Loader2 className='size-3 animate-spin' />
          ) : (
            <Download className='size-3' />
          )}
          PDF
        </button>
        <button
          type='button'
          onClick={() => onDelete(session.id)}
          className='press inline-flex items-center gap-1 rounded-sm px-2 py-1.5 text-xs text-muted-foreground transition-snap hover:text-destructive'
          aria-label='Hapus sesi'
        >
          <Trash2 className='size-3' />
        </button>
      </div>
    </li>
  );
}

export default function SessionsPage() {
  const router = useRouter();
  const {
    setSessionId,
    setCaseFacts,
    setParsedCase,
    setSimilarCases,
    setMessages,
    setOpinion,
    setCurrentPhase,
    setPhaseMetadata,
  } = useJudgeCounsel();

  const [sessions, setSessions] = useState<DeliberationSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<LoadError | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [sessionToDelete, setSessionToDelete] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [activeTab, setActiveTab] = useState<FilterTab>('all');
  const [downloadingId, setDownloadingId] = useState<string | null>(null);

  const loadSessions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const status = activeTab === 'all' ? undefined : activeTab;
      const response = await apiService.listSessions(status, 50, 0);
      setSessions(response.sessions ?? []);
    } catch (err) {
      setError(buildLoadError(err));
    } finally {
      setLoading(false);
    }
  }, [activeTab]);

  useEffect(() => {
    loadSessions();
  }, [loadSessions]);

  const handleContinue = useCallback(
    async (session: DeliberationSession) => {
      try {
        const response = await apiService.getSession(session.id);
        const fullSession = response.session;
        setSessionId(fullSession.id);
        setCaseFacts(fullSession.case_input.raw_input);
        setParsedCase(fullSession.case_input.parsed_case);
        setSimilarCases(fullSession.similar_cases ?? []);
        setOpinion(sessionLegalOpinion(fullSession));
        setCurrentPhase(fullSession.current_phase ?? null);
        setPhaseMetadata(fullSession.phase_metadata ?? null);
        if (fullSession.messages) setMessages(normalizeMessages(fullSession.messages));
        router.push('/deliberation');
      } catch (err) {
        console.error('Failed to load session:', err);
      }
    },
    [
      router,
      setSessionId,
      setCaseFacts,
      setParsedCase,
      setSimilarCases,
      setMessages,
      setOpinion,
      setCurrentPhase,
      setPhaseMetadata,
    ],
  );

  const handleViewOpinion = useCallback(
    async (session: DeliberationSession) => {
      try {
        const response = await apiService.getSession(session.id);
        const fullSession = response.session;
        setSessionId(fullSession.id);
        setCaseFacts(fullSession.case_input.raw_input);
        setParsedCase(fullSession.case_input.parsed_case);
        setSimilarCases(fullSession.similar_cases ?? []);
        setOpinion(sessionLegalOpinion(fullSession));
        setCurrentPhase(fullSession.current_phase ?? null);
        setPhaseMetadata(fullSession.phase_metadata ?? null);
        if (fullSession.messages) setMessages(normalizeMessages(fullSession.messages));
        router.push('/opinion');
      } catch (err) {
        console.error('Failed to load session:', err);
      }
    },
    [
      router,
      setSessionId,
      setCaseFacts,
      setParsedCase,
      setSimilarCases,
      setMessages,
      setOpinion,
      setCurrentPhase,
      setPhaseMetadata,
    ],
  );

  const handleDownload = useCallback(async (sessionId: string) => {
    setDownloadingId(sessionId);
    try {
      const blob = await apiService.downloadDeliberationPdf(sessionId);
      const timestamp = new Date().toISOString().split('T')[0];
      apiService.triggerDownload(blob, `musyawarah-${sessionId.slice(0, 8)}-${timestamp}.pdf`);
    } catch (error) {
      console.error('Download failed:', error);
    } finally {
      setDownloadingId(null);
    }
  }, []);

  const handleDeleteClick = (sessionId: string) => {
    setSessionToDelete(sessionId);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!sessionToDelete) return;
    setDeleting(true);
    try {
      await apiService.deleteSession(sessionToDelete);
      setSessions((prev) => prev.filter((s) => s.id !== sessionToDelete));
      setDeleteDialogOpen(false);
      setSessionToDelete(null);
    } catch (err) {
      console.error('Failed to delete session:', err);
    } finally {
      setDeleting(false);
    }
  };

  const totalCount = sessions.length;
  const activeCount = sessions.filter((s) => s.status === 'active').length;
  const concludedCount = sessions.filter((s) => s.status === 'concluded').length;
  const opinionCount = sessions.filter((s) => s.legal_opinion).length;

  return (
    <div className='space-y-10'>
      <header className='anim-folio-rise flex flex-col gap-3 border-b border-paper-edge pb-4 sm:flex-row sm:items-end sm:justify-between sm:gap-6'>
        <div className='min-w-0'>
          <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
            Riwayat Sesi
          </p>
          <h1 className='mt-1 font-rethink text-[1.625rem] font-semibold leading-tight tracking-tight text-foreground sm:text-[1.875rem]'>
            Musyawarah yang pernah Anda pimpin
          </h1>
          <p className='mt-2 max-w-prose text-sm leading-relaxed text-muted-foreground'>
            Lanjutkan sesi yang masih berjalan, baca kembali pendapat hukum yang sudah dirumuskan,
            atau unduh transkrip lengkap musyawarah.
          </p>
        </div>
        <div className='flex flex-wrap items-center gap-x-6 gap-y-1 text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
          <Stat label='Total' value={totalCount} />
          <Stat label='Aktif' value={activeCount} />
          <Stat label='Selesai' value={concludedCount} />
          <Stat label='Pendapat' value={opinionCount} />
        </div>
      </header>

      <nav className='anim-folio-rise-delay-1 flex flex-wrap items-center gap-x-1 gap-y-2 border-b border-paper-edge'>
        {TABS.map((tab) => {
          const isActive = activeTab === tab.value;
          return (
            <button
              key={tab.value}
              type='button'
              onClick={() => setActiveTab(tab.value)}
              className={cn(
                'press relative px-3 py-2 text-sm transition-snap',
                isActive ? 'text-foreground' : 'text-muted-foreground hover:text-foreground',
              )}
            >
              {tab.label}
              <span
                aria-hidden
                className={cn(
                  'pointer-events-none absolute inset-x-2 -bottom-px h-px origin-center transition-flow',
                  isActive ? 'scale-x-100 bg-foreground' : 'scale-x-0 bg-foreground/40',
                )}
              />
            </button>
          );
        })}
      </nav>

      {/* key on activeTab so the content panel remounts when filter changes,
          giving the new list a fresh folio-rise instead of a snap. */}
      <section key={activeTab} className='anim-folio-rise-delay-2'>
        {loading ? (
          <ul>
            {Array.from({ length: 4 }).map((_, i) => (
              <SessionRowSkeleton key={i} />
            ))}
          </ul>
        ) : error ? (
          <ErrorPanel error={error} onRetry={loadSessions} />
        ) : sessions.length === 0 ? (
          <div className='border-t border-paper-edge py-20 text-center'>
            <History className='anim-drift mx-auto size-8 text-muted-foreground/60' />
            <p className='mt-3 font-rethink text-base font-medium text-foreground'>
              {activeTab === 'all'
                ? 'Belum ada sesi musyawarah'
                : `Belum ada sesi yang ${
                    activeTab === 'active'
                      ? 'sedang berjalan'
                      : activeTab === 'concluded'
                        ? 'sudah selesai'
                        : 'diarsipkan'
                  }`}
            </p>
            <p className='mt-1 mx-auto max-w-md text-sm leading-relaxed text-muted-foreground'>
              {activeTab === 'all'
                ? 'Setiap perkara yang Anda buka di Dewan Hakim akan tersimpan di sini — Anda bisa melanjutkan musyawarah, melihat draf pendapat, atau mengunduhnya sebagai PDF kapan saja.'
                : 'Coba ganti tab untuk melihat sesi dalam status lain.'}
            </p>
            {activeTab === 'all' && (
              <Button onClick={() => router.push('/')} className='press mt-6'>
                Mulai musyawarah pertama
                <ArrowRight className='size-3.5' />
              </Button>
            )}
          </div>
        ) : (
          <ul className='border-b border-paper-edge'>
            {sessions.map((session, i) => (
              <SessionRow
                key={session.id}
                index={i}
                session={session}
                onContinue={handleContinue}
                onDelete={handleDeleteClick}
                onViewOpinion={handleViewOpinion}
                onDownload={handleDownload}
                downloadingId={downloadingId}
              />
            ))}
          </ul>
        )}
      </section>

      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Hapus sesi musyawarah?</DialogTitle>
            <DialogDescription>
              Tindakan ini tidak dapat dibatalkan. Sesi musyawarah dan semua pesan akan dihapus
              secara permanen.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant='outline'
              onClick={() => setDeleteDialogOpen(false)}
              disabled={deleting}
            >
              Batal
            </Button>
            <Button variant='destructive' onClick={handleConfirmDelete} disabled={deleting}>
              {deleting ? (
                <>
                  <Loader2 className='size-4 animate-spin' />
                  Menghapus…
                </>
              ) : (
                <>
                  <Trash2 className='size-4' />
                  Hapus
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <span className='inline-flex items-baseline gap-1.5'>
      <span className='font-folio text-base tabular-nums text-foreground'>{value}</span>
      <span>{label}</span>
    </span>
  );
}

function ErrorPanel({ error, onRetry }: { error: LoadError; onRetry: () => void }) {
  const [copied, setCopied] = useState(false);
  const Icon = error.kind === 'offline' ? WifiOff : AlertCircle;
  const heading =
    error.kind === 'offline' ? 'Tidak ada koneksi internet' : 'Riwayat sesi belum bisa dimuat';
  const body =
    error.kind === 'offline'
      ? 'Periksa koneksi Anda — riwayat akan kembali muncul begitu perangkat tersambung lagi.'
      : 'Server tidak merespons saat ini. Coba beberapa saat lagi, atau hubungi admin jika terus berulang.';

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(`Error ${error.errorId}: ${error.message}`);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1600);
    } catch {
      // Clipboard can fail in non-secure contexts. The id is still visible
      // in the page so the user can hand-copy it as a last resort.
    }
  };

  return (
    <div className='border-t border-paper-edge py-16 text-center'>
      <Icon className='anim-drift mx-auto size-8 text-destructive/60' />
      <p className='mt-3 font-rethink text-base font-medium text-foreground'>{heading}</p>
      <p className='mx-auto mt-1 max-w-md text-sm leading-relaxed text-muted-foreground'>{body}</p>

      <div className='mt-5 flex flex-wrap items-center justify-center gap-x-3 gap-y-2 text-xs text-muted-foreground'>
        <span className='font-folio'>
          Kode kesalahan <span className='text-foreground/85'>{error.errorId}</span>
        </span>
        <button
          type='button'
          onClick={handleCopy}
          className='press inline-flex items-center gap-1 rounded-sm border border-paper-edge bg-paper px-2 py-1 transition-snap hover:border-foreground/30 hover:text-foreground'
          aria-label='Salin kode kesalahan'
        >
          {copied ? (
            <>
              <Check className='size-3' />
              Tersalin
            </>
          ) : (
            <>
              <Copy className='size-3' />
              Salin kode
            </>
          )}
        </button>
      </div>

      <div className='mt-6 flex flex-wrap items-center justify-center gap-3'>
        <Button onClick={onRetry} variant='outline' className='press'>
          Coba lagi
        </Button>
        {error.kind === 'server' && (
          <a
            href={`mailto:${SUPPORT_EMAIL}?subject=Bantuan%20Dewan%20Hakim%20${error.errorId}&body=Halo%20admin%2C%0A%0ASaya%20tidak%20bisa%20memuat%20riwayat%20sesi%20di%20Dewan%20Hakim.%20Berikut%20kode%20kesalahannya%3A%20${error.errorId}%0A%0ATerima%20kasih.`}
            className='press text-sm text-muted-foreground transition-snap hover:text-foreground'
          >
            Hubungi admin →
          </a>
        )}
      </div>
    </div>
  );
}
