import type { Meta, StoryObj } from "@storybook/react";

import { Tabs, TabsList, TabsTrigger, TabsContent } from "../components/tabs";

const meta = {
  title: "Components/Tabs",
  component: Tabs,
  tags: ["autodocs"],
} satisfies Meta<typeof Tabs>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  render: () => (
    <Tabs defaultValue="account" className="w-[400px]">
      <TabsList>
        <TabsTrigger value="account">Account</TabsTrigger>
        <TabsTrigger value="password">Password</TabsTrigger>
        <TabsTrigger value="settings">Settings</TabsTrigger>
      </TabsList>
      <TabsContent value="account">
        <p className="text-muted-foreground text-sm">
          Make changes to your account here. Click save when you are done.
        </p>
      </TabsContent>
      <TabsContent value="password">
        <p className="text-muted-foreground text-sm">
          Change your password here. After saving, you will be logged out.
        </p>
      </TabsContent>
      <TabsContent value="settings">
        <p className="text-muted-foreground text-sm">
          Manage your application settings and preferences.
        </p>
      </TabsContent>
    </Tabs>
  ),
};

export const ManyTabs: Story = {
  render: () => (
    <Tabs defaultValue="tab-1" className="w-[400px]">
      <TabsList>
        <TabsTrigger value="tab-1">Overview</TabsTrigger>
        <TabsTrigger value="tab-2">Analytics</TabsTrigger>
        <TabsTrigger value="tab-3">Reports</TabsTrigger>
        <TabsTrigger value="tab-4">Notifications</TabsTrigger>
        <TabsTrigger value="tab-5">Integrations</TabsTrigger>
        <TabsTrigger value="tab-6">Billing</TabsTrigger>
        <TabsTrigger value="tab-7">Security</TabsTrigger>
      </TabsList>
      <TabsContent value="tab-1">
        <p className="text-muted-foreground text-sm">Overview content.</p>
      </TabsContent>
      <TabsContent value="tab-2">
        <p className="text-muted-foreground text-sm">Analytics content.</p>
      </TabsContent>
      <TabsContent value="tab-3">
        <p className="text-muted-foreground text-sm">Reports content.</p>
      </TabsContent>
      <TabsContent value="tab-4">
        <p className="text-muted-foreground text-sm">Notifications content.</p>
      </TabsContent>
      <TabsContent value="tab-5">
        <p className="text-muted-foreground text-sm">Integrations content.</p>
      </TabsContent>
      <TabsContent value="tab-6">
        <p className="text-muted-foreground text-sm">Billing content.</p>
      </TabsContent>
      <TabsContent value="tab-7">
        <p className="text-muted-foreground text-sm">Security content.</p>
      </TabsContent>
    </Tabs>
  ),
};
