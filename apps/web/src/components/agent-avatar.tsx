import { Avatar, AvatarFallback, cn } from '@lexicon/design-system';
import { Gavel, Heart, BookOpen, User, Bot } from 'lucide-react';

type AgentKind = 'strict' | 'humanist' | 'historian' | 'user' | 'system';
type AvatarVariant = 'block' | 'marker' | 'dot';

interface AgentAvatarProps {
  agent: AgentKind;
  size?: 'sm' | 'md' | 'lg';
  variant?: AvatarVariant;
  thinking?: boolean;
  className?: string;
}

const AGENT_CONFIG: Record<
  AgentKind,
  {
    icon: typeof Gavel;
    bgClass: string;
    fgClass: string;
    dotClass: string;
    initial: string;
    label: string;
  }
> = {
  strict: {
    icon: Gavel,
    bgClass: 'bg-agent-legalis',
    fgClass: 'text-agent-legalis-foreground',
    dotClass: 'bg-agent-legalis',
    initial: 'L',
    label: 'Legalis',
  },
  humanist: {
    icon: Heart,
    bgClass: 'bg-agent-humanis',
    fgClass: 'text-agent-humanis-foreground',
    dotClass: 'bg-agent-humanis',
    initial: 'H',
    label: 'Humanis',
  },
  historian: {
    icon: BookOpen,
    bgClass: 'bg-agent-historian',
    fgClass: 'text-agent-historian-foreground',
    dotClass: 'bg-agent-historian',
    initial: 'S',
    label: 'Sejarawan',
  },
  user: {
    icon: User,
    bgClass: 'bg-foreground',
    fgClass: 'text-background',
    dotClass: 'bg-foreground',
    initial: 'K',
    label: 'Ketua',
  },
  system: {
    icon: Bot,
    bgClass: 'bg-neutral-9',
    fgClass: 'text-neutral-0',
    dotClass: 'bg-neutral-9',
    initial: '·',
    label: 'Sistem',
  },
};

const SIZE_CLASSES = {
  sm: 'size-6 text-[10px]',
  md: 'size-8 text-xs',
  lg: 'size-10 text-sm',
};

const ICON_SIZES = {
  sm: 'size-3',
  md: 'size-4',
  lg: 'size-5',
};

const DOT_SIZES = {
  sm: 'size-1.5',
  md: 'size-2',
  lg: 'size-2.5',
};

export function AgentAvatar({
  agent,
  size = 'md',
  variant = 'block',
  thinking = false,
  className,
}: AgentAvatarProps) {
  const config = AGENT_CONFIG[agent];
  const Icon = config.icon;

  // `dot` — a small identity marker, used in transcript lead rules and
  // anywhere we want presence without a full avatar block.
  if (variant === 'dot') {
    return (
      <span
        className={cn('relative inline-flex shrink-0 items-center justify-center', className)}
        aria-label={config.label}
      >
        <span
          className={cn(
            'rounded-full',
            config.dotClass,
            DOT_SIZES[size],
            thinking && 'anim-thinking-pulse',
          )}
        />
      </span>
    );
  }

  // `marker` — initial-on-tinted-paper, used for the council strip and
  // legal-opinion argument columns. Quieter than the block avatar.
  if (variant === 'marker') {
    return (
      <span
        className={cn(
          'relative inline-flex shrink-0 items-center justify-center rounded-full',
          'border border-paper-edge bg-paper font-rethink font-medium text-foreground/85',
          SIZE_CLASSES[size],
          className,
        )}
        aria-label={config.label}
      >
        <span
          className={cn(
            'absolute -bottom-0.5 -right-0.5 rounded-full ring-2 ring-background',
            config.dotClass,
            DOT_SIZES[size],
            thinking && 'anim-thinking-pulse',
          )}
        />
        <span aria-hidden>{config.initial}</span>
      </span>
    );
  }

  // `block` — full color avatar with icon, kept for the council debate
  // header strip where the avatar is the focal element.
  return (
    <Avatar
      className={cn(
        SIZE_CLASSES[size],
        config.bgClass,
        'ring-1 ring-background',
        thinking && 'anim-thinking-pulse',
        className,
      )}
    >
      <AvatarFallback className={cn(config.bgClass, config.fgClass)}>
        <Icon className={ICON_SIZES[size]} aria-label={config.label} />
      </AvatarFallback>
    </Avatar>
  );
}
