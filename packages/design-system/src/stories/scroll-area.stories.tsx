import type { Meta, StoryObj } from "@storybook/react";

import { ScrollArea, ScrollBar } from "../components/scroll-area";

const meta = {
  title: "Components/ScrollArea",
  component: ScrollArea,
  tags: ["autodocs"],
} satisfies Meta<typeof ScrollArea>;

export default meta;
type Story = StoryObj<typeof meta>;

const tags = Array.from({ length: 50 }, (_, i) => `Tag ${i + 1}`);

export const Vertical: Story = {
  render: () => (
    <ScrollArea className="h-72 w-48 rounded-md border">
      <div className="p-4">
        <h4 className="mb-4 text-sm leading-none font-medium">Tags</h4>
        {tags.map((tag) => (
          <div key={tag} className="border-b py-2 text-sm last:border-b-0">
            {tag}
          </div>
        ))}
      </div>
    </ScrollArea>
  ),
};

const items = Array.from({ length: 20 }, (_, i) => ({
  id: i + 1,
  title: `Item ${i + 1}`,
}));

export const Horizontal: Story = {
  render: () => (
    <ScrollArea className="w-96 rounded-md border whitespace-nowrap">
      <div className="flex w-max space-x-4 p-4">
        {items.map((item) => (
          <div
            key={item.id}
            className="flex h-20 w-36 shrink-0 items-center justify-center rounded-md border"
          >
            <span className="text-sm font-medium">{item.title}</span>
          </div>
        ))}
      </div>
      <ScrollBar orientation="horizontal" />
    </ScrollArea>
  ),
};
