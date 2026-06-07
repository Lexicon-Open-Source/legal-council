'use client';

import Link from 'next/link';
import { useState } from 'react';
import {
  Alert,
  AlertDescription,
  Button,
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  cn,
} from '@lexicon/design-system';
import { AgentAvatar } from './agent-avatar';
import { ArrowLeft, RotateCcw, Download, CheckCircle2, AlertCircle, Loader2 } from 'lucide-react';
import { UIDeliberationMessage } from '@/lib/mappers';
import { AgentId, LegalOpinionDraft, ParsedCaseInput, SentenceRange } from '@/types/api';
import { apiService } from '@/services/api';

interface LegalOpinionProps {
  opinion: LegalOpinionDraft;
  messages: UIDeliberationMessage[];
  onReset: () => void;
  sessionId?: string | null;
  parsedCase?: ParsedCaseInput | null;
}

const CASE_TYPE_DISPLAY: Record<string, string> = {
  narcotics: 'Perkara Narkotika',
  corruption: 'Perkara Korupsi',
  general_criminal: 'Perkara Pidana Umum',
  other: 'Perkara',
};

const AGENT_LABEL: Record<string, { name: string; role: string }> = {
  strict: { name: 'Legalis', role: 'Penafsir Ketat' },
  humanist: { name: 'Humanis', role: 'Pendekatan Rehabilitatif' },
  historian: { name: 'Sejarawan', role: 'Ahli Yurisprudensi' },
};

const VERDICT_LABEL: Record<string, string> = {
  guilty: 'Bersalah',
  not_guilty: 'Tidak bersalah',
  acquitted: 'Bebas',
};

const CONFIDENCE_LABEL: Record<string, string> = {
  high: 'tinggi',
  medium: 'sedang',
  low: 'rendah',
};

const AGENT_ORDER = ['strict', 'humanist', 'historian'] as const;

const SOURCE_AGENT_ALIAS: Record<string, AgentId> = {
  legalis: 'strict',
  strict: 'strict',
  humanis: 'humanist',
  humanist: 'humanist',
  sejarawan: 'historian',
  historian: 'historian',
};

function cleanArgumentText(text: string) {
  return text
    .replace(/^\s{0,3}#{1,6}\s+/gm, '')
    .replace(/^[-*•]\s+/, '')
    .replace(/^\d+[.)]\s+/, '')
    .replace(/\*\*([^*]+)\*\*/g, '$1')
    .replace(/\*([^*]+)\*/g, '$1')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .replace(/__DOT__/g, '.')
    .replace(/\s+/g, ' ')
    .trim();
}

function hasLegalSignal(text: string) {
  return /\b(unsur|pasal|terdakwa|pidana|korupsi|kerugian|negara|dana desa|bpkp|rehabilitasi|proporsional|putusan|yurisprudensi|preseden|memberat|meringan|terbukti|melawan hukum|kewenangan|kepercayaan publik|hukuman|denda|penjara|keseriusan|kejahatan)\b/i.test(
    text,
  );
}

function isConversationalLeadIn(text: string) {
  return /^(baik[, ]|selamat\s|terima kasih|rekan hakim|saya menghargai|perkenankan|mari kita)\b/i.test(
    text,
  );
}

function splitIntoArgumentCandidates(content: string) {
  const protectedContent = content.replace(/(\d)\.(?=\d)/g, '$1__DOT__');
  const lines = protectedContent
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);
  const bullets = lines
    .filter((line) => /^[-*•]\s+/.test(line) || /^\d+[.)]\s+/.test(line))
    .map(cleanArgumentText);

  if (bullets.length > 0) return bullets;

  return (protectedContent.match(/[^.!?]+(?:[.!?]+|$)/g) ?? []).map(cleanArgumentText);
}

function extractArgumentSnippets(content: string) {
  return splitIntoArgumentCandidates(content)
    .filter((text) => text.length >= 32)
    .filter((text) => !isConversationalLeadIn(text))
    .filter(hasLegalSignal)
    .slice(0, 3);
}

export function LegalOpinion({
  opinion,
  messages,
  onReset,
  sessionId,
  parsedCase,
}: LegalOpinionProps) {
  const [downloading, setDownloading] = useState(false);
  const [downloadError, setDownloadError] = useState<string | null>(null);
  const [resetDialogOpen, setResetDialogOpen] = useState(false);

  const handleDownload = async () => {
    if (!sessionId) return;
    setDownloading(true);
    setDownloadError(null);
    try {
      const blob = await apiService.downloadDeliberationPdf(sessionId);
      const timestamp = new Date().toISOString().split('T')[0];
      apiService.triggerDownload(blob, `pendapat-hukum-${timestamp}.pdf`);
    } catch (error) {
      setDownloadError('Gagal mengunduh PDF. Silakan coba lagi.');
      console.error('Download failed:', error);
    } finally {
      setDownloading(false);
    }
  };

  const formatSentence = (range: SentenceRange | undefined) => {
    if (!range) return 'Tidak tersedia';
    return `${range.recommended} bulan`;
  };

  const formatRange = (range: SentenceRange | undefined) => {
    if (!range) return null;
    const hasMinimum = range.minimum > 0;
    const hasMaximum = range.maximum > 0;

    if (hasMinimum && hasMaximum && range.maximum >= range.minimum) {
      return `Rentang ${range.minimum}–${range.maximum} bulan`;
    }

    if (hasMinimum) {
      return `Minimum ${range.minimum} bulan`;
    }

    if (hasMaximum) {
      return `Maksimum ${range.maximum} bulan`;
    }

    return null;
  };

  const formatVerdict = (decision: string) => VERDICT_LABEL[decision] ?? decision;

  const formatConfidence = (confidence: string) =>
    CONFIDENCE_LABEL[confidence.toLowerCase()] ?? confidence;

  const getLegalArgumentsForAgent = (agentId: AgentId) => {
    const args: string[] = [];
    if (opinion.legal_arguments.for_conviction) {
      opinion.legal_arguments.for_conviction.forEach((arg) => {
        if (SOURCE_AGENT_ALIAS[arg.source_agent] === agentId) args.push(arg.argument);
      });
    }
    if (opinion.legal_arguments.for_leniency) {
      opinion.legal_arguments.for_leniency.forEach((arg) => {
        if (SOURCE_AGENT_ALIAS[arg.source_agent] === agentId) args.push(arg.argument);
      });
    }
    if (opinion.legal_arguments.for_severity) {
      opinion.legal_arguments.for_severity.forEach((arg) => {
        if (SOURCE_AGENT_ALIAS[arg.source_agent] === agentId) args.push(arg.argument);
      });
    }
    return args;
  };

  const getTranscriptArgumentsForAgent = (agentId: AgentId) =>
    messages
      .filter((message) => message.sender === agentId)
      .flatMap((message) => extractArgumentSnippets(message.content))
      .slice(0, 3);

  const legalArgsByAgent = Object.fromEntries(
    AGENT_ORDER.map((agentId) => [agentId, getLegalArgumentsForAgent(agentId)]),
  ) as Record<AgentId, string[]>;
  const transcriptArgsByAgent = Object.fromEntries(
    AGENT_ORDER.map((agentId) => [agentId, getTranscriptArgumentsForAgent(agentId)]),
  ) as Record<AgentId, string[]>;
  const legalArgsCoverMultipleAgents =
    AGENT_ORDER.filter((agentId) => legalArgsByAgent[agentId].length > 0).length > 1;
  const transcriptCoversMultipleAgents =
    AGENT_ORDER.filter((agentId) => transcriptArgsByAgent[agentId].length > 0).length > 1;
  const pickArgs = (primary: string[], fallback: string[]) =>
    primary.length > 0 ? primary : fallback;

  const agentColumns = AGENT_ORDER.map((id) => ({
    id,
    label: AGENT_LABEL[id]!,
    args: transcriptCoversMultipleAgents
      ? pickArgs(transcriptArgsByAgent[id], legalArgsByAgent[id])
      : legalArgsCoverMultipleAgents
        ? pickArgs(legalArgsByAgent[id], transcriptArgsByAgent[id])
        : pickArgs(transcriptArgsByAgent[id], legalArgsByAgent[id]),
  }));

  const today = new Date().toLocaleDateString('id-ID', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  return (
    <article className='mx-auto max-w-3xl space-y-12'>
      {/* MASTHEAD — the document opens like a printed opinion. Hero
          stagger: masthead → verdict/sentence → reasoning → perspectives →
          laws/precedents. Each step is 80ms apart so the eye reads the
          document settling onto the page rather than appearing whole. */}
      <header className='anim-hero border-b border-foreground/15 pb-6'>
        <div className='flex flex-wrap items-baseline justify-between gap-3 text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
          <span className='font-folio'>Draf Pendapat Hukum</span>
          <span className='font-folio tabular-nums'>{today}</span>
        </div>
        <h2 className='mt-3 font-rethink text-3xl font-semibold leading-tight tracking-tight text-foreground sm:text-4xl'>
          Pertimbangan dan Rekomendasi Dewan
        </h2>
        {/* Subtitle names what was actually deliberated. The case-type
            anchor turns "Pertimbangan dan Rekomendasi" from a template into
            a document about an actual matter. */}
        <p className='mt-3 max-w-prose text-sm leading-relaxed text-muted-foreground'>
          Setelah musyawarah tiga perspektif
          {parsedCase?.case_type && CASE_TYPE_DISPLAY[parsedCase.case_type] && (
            <>
              {' tentang '}
              <span className='text-foreground/85'>{CASE_TYPE_DISPLAY[parsedCase.case_type]}</span>
            </>
          )}
          .
        </p>
        {opinion.case_summary && (
          <p className='mt-4 max-w-prose text-[0.9375rem] leading-7 text-foreground/85'>
            {opinion.case_summary}
          </p>
        )}
      </header>

      {/* VERDICT + SENTENCE — a quiet two-up. Numbers in folio styling
          rather than "huge stat" template. */}
      <section className='anim-hero-1 grid gap-8 sm:grid-cols-2'>
        <div>
          <p className='flex items-center gap-2 text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
            <CheckCircle2 className='size-3' />
            Rekomendasi Putusan
          </p>
          <p className='mt-2 font-rethink text-2xl font-semibold tracking-tight text-foreground'>
            {formatVerdict(opinion.verdict_recommendation.decision)}
          </p>
          <p className='mt-1 text-xs text-muted-foreground'>
            Tingkat keyakinan{' '}
            <span className='font-folio text-foreground/80'>
              {formatConfidence(opinion.verdict_recommendation.confidence)}
            </span>
          </p>
        </div>
        <div className='sm:border-l sm:border-paper-edge sm:pl-8'>
          <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
            Rekomendasi Pidana
          </p>
          <p className='mt-2 font-rethink text-2xl font-semibold tracking-tight text-foreground'>
            {formatSentence(opinion.sentence_recommendation.imprisonment_months)}
          </p>
          <p className='mt-1 text-xs text-muted-foreground'>
            {formatRange(opinion.sentence_recommendation.imprisonment_months)}
            {(opinion.sentence_recommendation.fine_idr?.recommended ?? 0) > 0 && (
              <>
                {' '}
                <span aria-hidden className='mx-1 text-muted-foreground/60'>
                  ·
                </span>
                Denda Rp{' '}
                <span className='font-folio'>
                  {opinion.sentence_recommendation.fine_idr.recommended.toLocaleString('id-ID')}
                </span>
              </>
            )}
          </p>
        </div>
      </section>

      {/* REASONING */}
      <section className='anim-hero-2'>
        <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
          Pertimbangan
        </p>
        <p className='mt-3 max-w-prose text-[0.9375rem] leading-7 text-foreground/90'>
          {opinion.verdict_recommendation.reasoning}
        </p>
      </section>

      {/* THREE PERSPECTIVES — column for each judge with identity dot
          replacing the old "card per agent" stack. */}
      <section className='anim-hero-3'>
        <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
          Argumen utama dari tiga perspektif
        </p>
        <div className='mt-5 grid gap-8 md:grid-cols-3'>
          {agentColumns.map(({ id, label, args }) =>
            args.length === 0 ? null : (
              <div key={id} className='space-y-3'>
                <div className='flex items-center gap-2'>
                  <AgentAvatar agent={id} size='sm' variant='dot' />
                  <h3 className='font-rethink text-sm font-medium text-foreground'>{label.name}</h3>
                </div>
                <p className='text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
                  {label.role}
                </p>
                <ul className='space-y-2 text-[0.875rem] leading-relaxed text-foreground/85'>
                  {args.map((arg, i) => (
                    <li key={i} className='flex gap-2'>
                      <span
                        aria-hidden
                        className='mt-2.5 size-1 shrink-0 rounded-full bg-foreground/40'
                      />
                      <span>{arg}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ),
          )}
        </div>
      </section>

      {/* APPLICABLE LAWS */}
      {opinion.applicable_laws && opinion.applicable_laws.length > 0 && (
        <section className='anim-hero-4'>
          <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
            Dasar Hukum
          </p>
          <dl className='mt-4 divide-y divide-paper-edge border-t border-paper-edge'>
            {opinion.applicable_laws.map((law, index) => (
              <div
                key={index}
                className='grid gap-3 py-5 md:grid-cols-[minmax(14rem,0.72fr)_minmax(0,1.28fr)] md:gap-10'
              >
                <dt className='max-w-[34ch] font-rethink text-[0.9375rem] font-semibold leading-6 text-foreground'>
                  {law.law_reference}
                </dt>
                <dd className='space-y-1 text-[0.875rem] leading-relaxed'>
                  <p className='text-foreground/90'>{law.description}</p>
                  <p className='text-muted-foreground'>{law.how_it_applies}</p>
                </dd>
              </div>
            ))}
          </dl>
        </section>
      )}

      {/* PRECEDENTS */}
      {opinion.cited_precedents && opinion.cited_precedents.length > 0 && (
        <section className='anim-hero-5'>
          <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
            Yurisprudensi terkait
          </p>
          <ul className='mt-3 flex flex-wrap gap-x-4 gap-y-2'>
            {opinion.cited_precedents.map((precedent, index) => (
              <li
                key={index}
                title={`${precedent.verdict_summary} — ${precedent.how_it_applies}`}
                className='inline-flex items-baseline gap-2 border-b border-dotted border-foreground/30 text-[0.8125rem] text-foreground/85 transition-snap hover:border-primary hover:text-primary'
              >
                <span aria-hidden className='size-1 rounded-full bg-foreground/40' />
                <span className='font-folio'>{precedent.case_number}</span>
              </li>
            ))}
          </ul>
        </section>
      )}

      {/* DISSENTING VIEWS */}
      {opinion.dissenting_views && opinion.dissenting_views.length > 0 && (
        <section className='rounded-md border border-paper-edge bg-paper px-6 py-5'>
          <p className='text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground'>
            Pendapat berbeda
          </p>
          <ul className='mt-3 space-y-3 text-[0.9375rem] leading-7 text-foreground/85'>
            {opinion.dissenting_views.map((view, index) => (
              <li key={index} className='flex gap-3'>
                <span
                  aria-hidden
                  className='mt-2.5 size-1 shrink-0 rounded-full bg-foreground/50'
                />
                <span>{view}</span>
              </li>
            ))}
          </ul>
        </section>
      )}

      {/* TRANSCRIPT — collapsed-by-default footnote-style log */}
      {messages.length > 0 && (
        <details className='group border-t border-paper-edge pt-6'>
          <summary className='flex cursor-pointer items-center justify-between gap-3 text-[0.6875rem] uppercase tracking-[0.2em] text-muted-foreground transition-snap hover:text-foreground'>
            <span>Catatan musyawarah ({messages.length} pesan)</span>
            <span
              aria-hidden
              className='font-folio text-muted-foreground/70 transition-flow group-open:rotate-90'
            >
              ›
            </span>
          </summary>
          <ol className='mt-5 space-y-5'>
            {messages.map((message) => (
              <li key={message.id} className='grid grid-cols-[1.25rem_minmax(0,1fr)] gap-3'>
                <AgentAvatar agent={message.sender} size='sm' variant='dot' className='mt-1.5' />
                <div className='min-w-0'>
                  <p className='font-rethink text-sm font-medium text-foreground'>
                    {message.sender_name}
                  </p>
                  <p
                    className={cn(
                      'mt-0.5 text-[0.8125rem] leading-relaxed text-muted-foreground',
                      'line-clamp-3',
                    )}
                  >
                    {message.content}
                  </p>
                </div>
              </li>
            ))}
          </ol>
        </details>
      )}

      {/* ACTIONS */}
      {downloadError && (
        <Alert variant='destructive'>
          <AlertCircle />
          <AlertDescription>{downloadError}</AlertDescription>
        </Alert>
      )}

      <footer className='flex flex-col-reverse gap-3 border-t border-foreground/15 pt-6 sm:flex-row sm:items-center sm:justify-between'>
        <div className='flex flex-wrap items-center gap-x-5 gap-y-2'>
          {sessionId && (
            <Link
              href='/deliberation'
              className='press inline-flex items-center gap-2 text-sm text-muted-foreground transition-snap hover:text-foreground'
            >
              <ArrowLeft className='size-3.5' />
              Kembali ke musyawarah
            </Link>
          )}
          <button
            type='button'
            onClick={() => setResetDialogOpen(true)}
            className='press inline-flex items-center gap-2 text-sm text-muted-foreground transition-snap hover:text-foreground'
          >
            <RotateCcw className='size-3.5' />
            Mulai perkara baru
          </button>
        </div>
        <Button
          onClick={handleDownload}
          disabled={downloading || !sessionId}
          className='press h-10 px-4'
        >
          {downloading ? (
            <>
              <Loader2 className='size-4 animate-spin' />
              Mengunduh…
            </>
          ) : (
            <>
              <Download className='size-4' />
              Unduh sebagai PDF
            </>
          )}
        </Button>
      </footer>

      <Dialog open={resetDialogOpen} onOpenChange={setResetDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Mulai perkara baru?</DialogTitle>
            <DialogDescription>
              Anda akan meninggalkan draf pendapat ini dan kembali ke lembar fakta perkara. Unduh
              PDF terlebih dahulu jika ingin menyimpan salinan dokumen.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant='outline' onClick={() => setResetDialogOpen(false)}>
              Tetap di draf
            </Button>
            <Button
              variant='destructive'
              onClick={() => {
                setResetDialogOpen(false);
                onReset();
              }}
            >
              Mulai perkara baru
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </article>
  );
}
