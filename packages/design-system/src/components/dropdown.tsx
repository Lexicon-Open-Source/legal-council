"use client";

import * as React from "react";
import * as DropdownMenuPrimitive from "@radix-ui/react-dropdown-menu";
import { Check } from "lucide-react";
import { cn } from "../lib/utils/cn";

// Context for tracking selection
interface DropdownContextValue {
  selectionMode?: "single" | "multiple";
  selectedKeys: Set<string>;
  onSelectionChange?: (keys: Set<string>) => void;
}

const DropdownContext = React.createContext<DropdownContextValue>({
  selectedKeys: new Set(),
});

// Dropdown Root
const DropdownRoot: React.FC<{
  children: React.ReactNode;
}> = ({ children }) => {
  return <DropdownMenuPrimitive.Root>{children}</DropdownMenuPrimitive.Root>;
};

// Dropdown Trigger
const DropdownTrigger = React.forwardRef<
  React.ComponentRef<typeof DropdownMenuPrimitive.Trigger>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Trigger>
>(({ className, ...props }, ref) => (
  <DropdownMenuPrimitive.Trigger
    ref={ref}
    className={cn("outline-none", className)}
    {...props}
  />
));
DropdownTrigger.displayName = "DropdownTrigger";

// Dropdown Popover (Content wrapper)
const DropdownPopover = React.forwardRef<
  React.ComponentRef<typeof DropdownMenuPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Content>
>(({ className, sideOffset = 4, ...props }, ref) => (
  <DropdownMenuPrimitive.Portal>
    <DropdownMenuPrimitive.Content
      ref={ref}
      sideOffset={sideOffset}
      className={cn(
        "z-50 min-w-32 overflow-hidden rounded-md border bg-white p-1 shadow-md",
        "data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
        className
      )}
      {...props}
    />
  </DropdownMenuPrimitive.Portal>
));
DropdownPopover.displayName = "DropdownPopover";

// Dropdown Menu (wraps items with selection context)
interface DropdownMenuProps {
  children: React.ReactNode;
  selectionMode?: "single" | "multiple";
  selectedKeys?: Set<string>;
  onSelectionChange?: (keys: Set<string>) => void;
  "aria-label"?: string;
}

const DropdownMenu: React.FC<DropdownMenuProps> = ({
  children,
  selectionMode,
  selectedKeys = new Set(),
  onSelectionChange,
}) => {
  return (
    <DropdownContext.Provider
      value={{ selectionMode, selectedKeys, onSelectionChange }}
    >
      <div className="py-1">{children}</div>
    </DropdownContext.Provider>
  );
};

// Dropdown Item
interface DropdownItemProps {
  id?: string;
  textValue?: string;
  children: React.ReactNode;
  className?: string;
}

const DropdownItem = React.forwardRef<HTMLDivElement, DropdownItemProps>(
  ({ id, children, className }, ref) => {
    const { selectionMode, selectedKeys, onSelectionChange } =
      React.useContext(DropdownContext);

    const isSelected = id ? selectedKeys.has(id) : false;

    const handleClick = () => {
      if (!id || !onSelectionChange) return;

      const newKeys = new Set(selectedKeys);
      if (selectionMode === "multiple") {
        if (isSelected) {
          newKeys.delete(id);
        } else {
          newKeys.add(id);
        }
      } else {
        newKeys.clear();
        newKeys.add(id);
      }
      onSelectionChange(newKeys);
    };

    return (
      <div
        ref={ref}
        role="menuitemcheckbox"
        aria-checked={isSelected}
        data-state={isSelected ? "checked" : "unchecked"}
        onClick={handleClick}
        className={cn(
          "relative flex cursor-pointer items-center rounded-sm px-2 py-1.5 text-sm transition-colors outline-none select-none hover:bg-gray-100 focus:bg-gray-100",
          className
        )}
      >
        {children}
      </div>
    );
  }
);
DropdownItem.displayName = "DropdownItem";

// Dropdown Item Indicator
const DropdownItemIndicator: React.FC<{ className?: string }> = ({
  className,
}) => {
  return (
    <span
      className={cn("mr-2 flex h-4 w-4 items-center justify-center", className)}
    >
      <Check className="text-colorPrimary h-4 w-4 [[data-state=checked]>&]:block [[data-state=unchecked]>&]:hidden" />
    </span>
  );
};

// Label component
const Label: React.FC<{ children: React.ReactNode; className?: string }> = ({
  children,
  className,
}) => <span className={cn("flex-1", className)}>{children}</span>;

// Compound component interface
interface DropdownComponent extends React.FC<{ children: React.ReactNode }> {
  Trigger: typeof DropdownTrigger;
  Popover: typeof DropdownPopover;
  Menu: typeof DropdownMenu;
  Item: typeof DropdownItem;
  ItemIndicator: typeof DropdownItemIndicator;
}

// Create compound component
const Dropdown = DropdownRoot as DropdownComponent;
Dropdown.Trigger = DropdownTrigger;
Dropdown.Popover = DropdownPopover;
Dropdown.Menu = DropdownMenu;
Dropdown.Item = DropdownItem;
Dropdown.ItemIndicator = DropdownItemIndicator;

export {
  Dropdown,
  DropdownTrigger,
  DropdownPopover,
  DropdownMenu,
  DropdownItem,
  DropdownItemIndicator,
  Label,
};
