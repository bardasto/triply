/**
 * Test script for LangGraph Trip Generation
 *
 * Run with: npx tsx src/lib/agents/test-graph.ts
 */

import {
  createTripGraph,
  printGraphInfo,
  getGraphMermaidDiagram,
  getGraphASCII,
} from "./graph";
import type { TripState } from "./graph";

async function main() {
  console.log("\n🚀 LangGraph Trip Generation Test\n");

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Print graph visualization
  // ─────────────────────────────────────────────────────────────────────────
  printGraphInfo();

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Print Mermaid diagram (for docs/visualization tools)
  // ─────────────────────────────────────────────────────────────────────────
  console.log("\n📊 Mermaid Diagram (copy to https://mermaid.live):");
  console.log("─".repeat(50));
  console.log(getGraphMermaidDiagram());
  console.log("─".repeat(50));

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Run the graph with a test query
  // ─────────────────────────────────────────────────────────────────────────
  console.log("\n🧪 Running graph with test query...\n");

  const graph = createTripGraph();

  const input = {
    query: "massage in Bratislava for 2 days",
    maxRetries: 3,
  };

  console.log("Input:", JSON.stringify(input, null, 2));
  console.log("\n" + "─".repeat(50) + "\n");

  try {
    // Run the graph
    const result = await graph.invoke(input);

    console.log("\n" + "─".repeat(50));
    console.log("✅ Graph completed successfully!\n");

    // Print result summary
    console.log("📊 Result Summary:");
    console.log("─".repeat(30));
    console.log("  Phase:", result.currentPhase);
    console.log("  Progress:", result.progress + "%");
    console.log("  Retry count:", result.retryCount);
    console.log("  Errors:", result.errors.length > 0 ? result.errors : "None");
    console.log("\n📍 Intent:");
    console.log("  Type:", result.intent?.type);
    console.log("  Theme:", result.intent?.theme);
    console.log("  City:", result.intent?.city);
    console.log("  Strict mode:", result.intent?.strictMode);
    console.log("\n🏨 Trip:");
    console.log("  Title:", result.trip?.title);
    console.log("  Duration:", result.trip?.duration_days, "days");
    console.log("\n✅ Validation:");
    console.log("  Valid:", result.validation?.isValid);
    console.log("  Score:", result.validation?.score);
    console.log("  Theme match:", result.validation?.themeMatchPercent + "%");
    console.log("\n⏱️ Timestamps:");
    Object.entries(result.timestamps).forEach(([key, value]) => {
      console.log(`  ${key}: ${value}`);
    });

  } catch (error) {
    console.error("❌ Graph failed:", error);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Test streaming (for real-time updates)
  // ─────────────────────────────────────────────────────────────────────────
  console.log("\n\n🌊 Testing streaming...\n");

  try {
    const stream = await graph.stream(input);

    for await (const chunk of stream) {
      const [nodeName, nodeOutput] = Object.entries(chunk)[0];
      console.log(`📍 Node "${nodeName}" completed:`);
      console.log(`   Phase: ${(nodeOutput as Partial<TripState>).currentPhase}`);
      console.log(`   Progress: ${(nodeOutput as Partial<TripState>).progress}%`);
    }

    console.log("\n✅ Streaming test completed!");

  } catch (error) {
    console.error("❌ Streaming failed:", error);
  }
}

// Run the test
main().catch(console.error);
