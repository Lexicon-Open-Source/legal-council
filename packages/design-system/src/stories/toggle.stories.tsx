import type { Meta, StoryObj } from "@storybook/react";
import { Bold, Italic, Underline } from "lucide-react";

import { Toggle, toggleVariants } from "../components/toggle";

const meta = {
  title: "Components/Toggle",
  component: Toggle,
  tags: ["autodocs"],
  argTypes: {
    variant: {
      control: "select",
      options: ["default", "outline"],
    },
    size: {
      control: "select",
      options: ["default", "sm", "lg"],
    },
    disabled: {
      control: "boolean",
    },
  },
} satisfies Meta<typeof Toggle>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    children: <Bold className="size-4" />,
    "aria-label": "Toggle bold",
  },
};

export const Outline: Story = {
  args: {
    variant: "outline",
    children: <Italic className="size-4" />,
    "aria-label": "Toggle italic",
  },
};

export const Small: Story = {
  args: {
    size: "sm",
    children: <Bold className="size-4" />,
    "aria-label": "Toggle bold",
  },
};

export const Large: Story = {
  args: {
    size: "lg",
    children: <Bold className="size-4" />,
    "aria-label": "Toggle bold",
  },
};

export const WithText: Story = {
  render: () => (
    <Toggle aria-label="Toggle italic">
      <Italic className="size-4" />
      Toggle italic
    </Toggle>
  ),
};

export const Pressed: Story = {
  args: {
    defaultPressed: true,
    children: <Bold className="size-4" />,
    "aria-label": "Toggle bold",
  },
};
