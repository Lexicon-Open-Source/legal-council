import type { Meta, StoryObj } from "@storybook/react";

import { Badge, badgeVariants } from "../components/badge";

const meta = {
  title: "Components/Badge",
  component: Badge,
  tags: ["autodocs"],
  args: {
    children: "Badge",
  },
} satisfies Meta<typeof Badge>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const Secondary: Story = {
  args: {
    variant: "secondary",
    children: "Secondary",
  },
};

export const Outline: Story = {
  args: {
    variant: "outline",
    children: "Outline",
  },
};

export const Destructive: Story = {
  args: {
    variant: "destructive",
    children: "Destructive",
  },
};

export const Rounded: Story = {
  args: {
    rounded: true,
    children: "Rounded",
  },
};

export const Small: Story = {
  args: {
    size: "sm",
    children: "Small",
  },
};

export const Large: Story = {
  args: {
    size: "lg",
    children: "Large",
  },
};

export const AllVariants: Story = {
  render: () => (
    <div className="grid grid-cols-4 items-center gap-4">
      <Badge variant="default">Default</Badge>
      <Badge variant="secondary">Secondary</Badge>
      <Badge variant="outline">Outline</Badge>
      <Badge variant="destructive">Destructive</Badge>

      <Badge variant="default" size="sm">
        Small
      </Badge>
      <Badge variant="secondary" size="sm">
        Small
      </Badge>
      <Badge variant="outline" size="sm">
        Small
      </Badge>
      <Badge variant="destructive" size="sm">
        Small
      </Badge>

      <Badge variant="default" size="lg">
        Large
      </Badge>
      <Badge variant="secondary" size="lg">
        Large
      </Badge>
      <Badge variant="outline" size="lg">
        Large
      </Badge>
      <Badge variant="destructive" size="lg">
        Large
      </Badge>

      <Badge variant="default" rounded>
        Rounded
      </Badge>
      <Badge variant="secondary" rounded>
        Rounded
      </Badge>
      <Badge variant="outline" rounded>
        Rounded
      </Badge>
      <Badge variant="destructive" rounded>
        Rounded
      </Badge>
    </div>
  ),
};
