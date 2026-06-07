import type { Meta, StoryObj } from "@storybook/react";

import { Combobox, type ComboboxOption } from "../components/combobox";

const frameworks: ComboboxOption[] = [
  { value: "nextjs", label: "Next.js" },
  { value: "remix", label: "Remix" },
  { value: "astro", label: "Astro" },
  { value: "nuxt", label: "Nuxt" },
];

const meta = {
  title: "Components/Combobox",
  component: Combobox,
  tags: ["autodocs"],
  args: {
    options: frameworks,
    placeholder: "Select framework...",
    searchPlaceholder: "Search framework...",
    emptyMessage: "No framework found.",
  },
} satisfies Meta<typeof Combobox>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const WithPreselectedValue: Story = {
  args: {
    value: "nextjs",
  },
};

export const Disabled: Story = {
  args: {
    disabled: true,
  },
};

export const CustomPlaceholder: Story = {
  args: {
    placeholder: "Pick your favorite...",
    searchPlaceholder: "Type to search...",
    emptyMessage: "Nothing matches your search.",
  },
};
