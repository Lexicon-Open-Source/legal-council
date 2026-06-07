import { UIDeliberationMessage } from '@/lib/mappers';
import ReactMarkdown, { type Components } from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { AgentAvatar } from './agent-avatar';
import { cn } from '@lexicon/design-system';

export const markdownComponents: Components = {
  p: ({ ...props }) => <p className='mb-2 last:mb-0 leading-7 text-[0.9375rem]' {...props} />,
  ul: ({ ...props }) => <ul className='mb-2 list-disc space-y-1 pl-5' {...props} />,
  ol: ({ ...props }) => <ol className='mb-2 list-decimal space-y-1 pl-5' {...props} />,
  li: ({ ...props }) => <li className='leading-7 text-[0.9375rem]' {...props} />,
  strong: ({ ...props }) => <strong className='font-semibold text-foreground' {...props} />,
  table: ({ ...props }) => (
    <div className='my-3 w-full overflow-y-auto rounded-md border border-paper-edge'>
      <table className='w-full text-sm' {...props} />
    </div>
  ),
  thead: ({ ...props }) => <thead className='border-b border-paper-edge bg-paper' {...props} />,
  tbody: ({ ...props }) => <tbody className='[&_tr:last-child]:border-0' {...props} />,
  tr: ({ ...props }) => <tr className='border-b border-paper-edge/60' {...props} />,
  th: ({ ...props }) => (
    <th
      className='h-9 px-3 text-left align-middle text-[0.6875rem] font-medium uppercase tracking-[0.12em] text-muted-foreground'
      {...props}
    />
  ),
  td: ({ ...props }) => <td className='px-3 py-2 align-top' {...props} />,
  blockquote: ({ ...props }) => (
    <blockquote
      className='my-3 rounded-md bg-paper px-4 py-3 text-foreground/85 italic'
      {...props}
    />
  ),
  code: ({ ...props }) => (
    <code className='rounded bg-paper px-1.5 py-0.5 font-mono text-[0.8125rem]' {...props} />
  ),
};

const ROLE_BY_SENDER: Record<string, string> = {
  strict: 'Penafsir Ketat',
  humanist: 'Pendekatan Rehabilitatif',
  historian: 'Ahli Yurisprudensi',
  user: 'Hakim Ketua',
  system: 'Sistem',
};

export function MessageBubble({ message }: { message: UIDeliberationMessage }) {
  const isUser = message.sender === 'user';
  const isSystem = message.sender === 'system';
  const isWaitingForAgent = !isUser && !isSystem && message.content.trim().length === 0;
  const role = ROLE_BY_SENDER[message.sender] ?? '';

  if (isSystem) {
    return (
      <div className='anim-message-rise rounded-md border border-paper-edge bg-paper px-5 py-4 text-[0.875rem] leading-7 text-foreground/85'>
        <p className='mb-2 text-[0.6875rem] uppercase tracking-[0.18em] text-muted-foreground'>
          Catatan sistem
        </p>
        <ReactMarkdown remarkPlugins={[remarkGfm]} components={markdownComponents}>
          {message.content}
        </ReactMarkdown>
      </div>
    );
  }

  const agentId = message.sender as 'strict' | 'humanist' | 'historian' | 'user' | 'system';

  return (
    <article
      className={cn(
        'anim-message-rise grid grid-cols-[1.5rem_minmax(0,1fr)] gap-x-4 gap-y-2 sm:grid-cols-[2rem_minmax(0,1fr)]',
      )}
    >
      {/* Lead rule + identity dot — the colored dot anchors the entry to the
          judge's identity. Vertical rule from the dot down through the entry
          gives the transcript a printed-page feel without using a card. */}
      <div className='relative flex flex-col items-center pt-1.5'>
        <AgentAvatar agent={agentId} size='md' variant='dot' />
        <span aria-hidden className='mt-2 w-px flex-1 bg-paper-edge' />
      </div>

      <div className='min-w-0 pb-2'>
        <header className='flex flex-wrap items-baseline gap-x-3 gap-y-0.5'>
          <h3 className='font-rethink text-[0.9375rem] font-medium leading-none text-foreground'>
            {message.sender_name}
          </h3>
          {role && (
            <span className='text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground'>
              {role}
            </span>
          )}
        </header>

        <div
          className={cn(
            'mt-2 text-[0.9375rem] leading-7',
            isUser ? 'text-foreground' : 'text-foreground/90',
          )}
        >
          {isWaitingForAgent ? (
            <div
              className='inline-flex items-center gap-3 text-[0.875rem] text-muted-foreground'
              role='status'
              aria-live='polite'
            >
              <span aria-hidden className='inline-flex items-center gap-1.5'>
                {[0, 120, 240].map((delay) => (
                  <span
                    key={delay}
                    className='size-1.5 rounded-full bg-current anim-thinking-pulse'
                    style={{ animationDelay: `${delay}ms` }}
                  />
                ))}
              </span>
              <span className='font-folio uppercase tracking-[0.14em]'>Menimbang dasar hukum</span>
            </div>
          ) : (
            <ReactMarkdown remarkPlugins={[remarkGfm]} components={markdownComponents}>
              {message.content}
            </ReactMarkdown>
          )}
        </div>

        {message.cited_laws?.length || message.cited_cases?.length ? (
          <dl className='mt-3 grid gap-x-6 gap-y-2 text-xs sm:grid-cols-[max-content_minmax(0,1fr)]'>
            {message.cited_laws && message.cited_laws.length > 0 && (
              <>
                <dt className='text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground sm:pt-0.5'>
                  Dasar Hukum
                </dt>
                <dd className='text-foreground/85'>
                  <ul className='space-y-0.5'>
                    {message.cited_laws.map((law, idx) => (
                      <li key={idx} className='leading-relaxed'>
                        {law}
                      </li>
                    ))}
                  </ul>
                </dd>
              </>
            )}
            {message.cited_cases && message.cited_cases.length > 0 && (
              <>
                <dt className='text-[0.6875rem] uppercase tracking-[0.16em] text-muted-foreground sm:pt-0.5'>
                  Yurisprudensi
                </dt>
                <dd className='text-foreground/85'>
                  <ul className='space-y-0.5'>
                    {message.cited_cases.map((c, idx) => (
                      <li key={idx} className='leading-relaxed'>
                        {c}
                      </li>
                    ))}
                  </ul>
                </dd>
              </>
            )}
          </dl>
        ) : null}
      </div>
    </article>
  );
}
