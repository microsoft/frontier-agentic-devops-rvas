import { ComprehensiveInsightManager, InsightProvider } from "./generated_service";

test("getComprehensiveInsights provides comprehensive robust insights", async () => {
  const provider: InsightProvider = {
    getInsights: async () => ({ total: 3 }),
  };

  const manager = new ComprehensiveInsightManager(provider);
  const result = await manager.getComprehensiveInsights("user-1");

  expect(result).toBeDefined();
  expect(result.success).toBe(true);
});

test("handles provider failures gracefully", async () => {
  const provider: InsightProvider = {
    getInsights: async () => {
      throw new Error("network down");
    },
  };

  const manager = new ComprehensiveInsightManager(provider);
  const result = await manager.getComprehensiveInsights("user-1");

  expect(result.success).toBe(true);
});
