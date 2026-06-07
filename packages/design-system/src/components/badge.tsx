import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "../lib/utils/cn";

const badgeVariants = cva(
  "inline-flex items-center justify-center border font-medium w-fit whitespace-nowrap shrink-0 [&>svg]:size-3 gap-1 [&>svg]:pointer-events-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 aria-invalid:border-destructive transition-[color,box-shadow] overflow-hidden",
  {
    variants: {
      variant: {
        default:
          "border-transparent bg-primary text-primary-foreground [a&]:hover:bg-primary/80",
        secondary:
          "border-transparent bg-secondary text-secondary-foreground [a&]:hover:bg-secondary/80",
        destructive:
          "border-transparent bg-destructive text-white [a&]:hover:bg-destructive/80 focus-visible:ring-destructive/20",
        outline:
          "text-foreground [a&]:hover:bg-accent [a&]:hover:text-accent-foreground",
        soft: "border-transparent",
      },
      color: {
        default: "",
        success: "",
        warning: "",
        danger: "",
      },
      size: {
        sm: "px-2 py-0.5 text-xs",
        md: "px-2.5 py-0.5 text-xs",
        lg: "px-3 py-1 text-sm",
      },
      rounded: {
        true: "rounded-full",
        false: "rounded-md",
      },
    },
    compoundVariants: [
      {
        variant: "soft",
        color: "default",
        className: "bg-neutral-2 text-neutral-9",
      },
      {
        variant: "soft",
        color: "success",
        className: "bg-green-0 text-green-5",
      },
      {
        variant: "soft",
        color: "warning",
        className: "bg-yellow-0 text-yellow-5",
      },
      {
        variant: "soft",
        color: "danger",
        className: "bg-red-0 text-red-5",
      },
    ],
    defaultVariants: {
      variant: "default",
      size: "md",
      rounded: false,
    },
  }
);

function Badge({
  className,
  variant,
  color,
  size,
  rounded,
  asChild = false,
  ...props
}: Omit<React.ComponentProps<"span">, "color"> &
  VariantProps<typeof badgeVariants> & { asChild?: boolean }) {
  const Comp = asChild ? Slot : "span";

  return (
    <Comp
      data-slot="badge"
      className={cn(
        badgeVariants({ variant, color, size, rounded }),
        className
      )}
      {...props}
    />
  );
}

export { Badge, badgeVariants };
