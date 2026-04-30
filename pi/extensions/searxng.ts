import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

const SEARXNG_URL = "http://localhost:10000";

interface SearxngResult {
  url: string;
  title: string;
  content: string;
  thumbnail?: string | null;
  engine: string;
  engines?: string[];
  score?: number;
  category?: string;
  publishedDate?: string | null;
}

interface SearxngResponse {
  query: string;
  number_of_results: number;
  results: SearxngResult[];
  answers?: Array<{ answer: string; url?: string }>;
  corrections?: string[];
  suggestions?: string[];
  infoboxes?: unknown[];
}

function truncateText(text: string | null | undefined, maxLen = 400): string {
  if (!text) return "";
  return text.length > maxLen ? text.slice(0, maxLen) + "…" : text;
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web via a self-hosted SearXNG instance. Use for current events, documentation lookups, factual verification, or any time recent/online information is needed.",
    promptSnippet: "Search the web for current or public information",
    promptGuidelines: [
      "Use web_search when the user asks about current events, recent news, or information likely to be found online.",
      "Use web_search when you need to verify facts that may have changed since your training cutoff.",
      "Use web_search when the user explicitly asks to search the web.",
      "Always cite URLs from search results.",
    ],
    parameters: Type.Object({
      query: Type.String({
        description: "The search query. Be concise and specific.",
      }),
      category: Type.Optional(
        Type.String({
          description:
            "Optional search category: general, images, news, videos, music, files, social_media. Defaults to general.",
        })
      ),
      language: Type.Optional(
        Type.String({
          description:
            'Optional language code (e.g., "en", "ru", "de"). Defaults to auto-detect.',
        })
      ),
      max_results: Type.Optional(
        Type.Number({
          description: "Maximum number of results to return (1–20). Default is 10.",
          minimum: 1,
          maximum: 20,
          default: 10,
        })
      ),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
      const url = new URL(`${SEARXNG_URL}/search`);
      url.searchParams.set("q", params.query);
      url.searchParams.set("format", "json");
      if (params.category) url.searchParams.set("categories", params.category);
      if (params.language) url.searchParams.set("language", params.language);

      const response = await fetch(url, { signal });
      if (!response.ok) {
        throw new Error(
          `SearXNG returned HTTP ${response.status}: ${await response.text()}`
        );
      }

      const data = (await response.json()) as SearxngResponse;
      const maxResults = params.max_results ?? 10;
      const results = (data.results ?? []).slice(0, maxResults);

      if (results.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: `No results found for "${data.query}".`,
            },
          ],
          details: { query: data.query, total: data.number_of_results, results: [] },
        };
      }

      // Build a readable text summary for the LLM
      const lines: string[] = [
        `Search: "${data.query}"`,
        `Total results found: ${data.number_of_results}`,
        "",
        `Top ${results.length} result${results.length === 1 ? "" : "s"}:\n`,
      ];

      for (let i = 0; i < results.length; i++) {
        const r = results[i];
        lines.push(`#${i + 1}. ${r.title}`);
        lines.push(`   URL: ${r.url}`);
        if (r.content) {
          lines.push(`   ${truncateText(r.content)}`);
        }
        if (r.engines && r.engines.length > 0) {
          lines.push(`   Sources: ${r.engines.join(", ")}`);
        }
        if (r.publishedDate) {
          lines.push(`   Date: ${r.publishedDate}`);
        }
        lines.push("");
      }

      if (data.suggestions && data.suggestions.length > 0) {
        lines.push(`Suggested queries: ${data.suggestions.join(", ")}`);
      }

      return {
        content: [{ type: "text" as const, text: lines.join("\n") }],
        details: {
          query: data.query,
          total: data.number_of_results,
          results: results.map((r) => ({
            url: r.url,
            title: r.title,
            content: r.content,
            engines: r.engines,
            score: r.score,
            category: r.category,
            publishedDate: r.publishedDate,
          })),
          suggestions: data.suggestions,
        },
      };
    },
  });

  // Also register a convenience command
  pi.registerCommand("web", {
    description: "Search the web via SearXNG",
    handler: async (args, ctx) => {
      if (!args || args.trim().length === 0) {
        ctx.ui.notify("Usage: /web <search query>", "warning");
        return;
      }

      try {
        const url = new URL(`${SEARXNG_URL}/search`);
        url.searchParams.set("q", args.trim());
        url.searchParams.set("format", "json");

        const res = await fetch(url);
        if (!res.ok) {
          ctx.ui.notify(
            `SearXNG error: HTTP ${res.status}`,
            "error"
          );
          return;
        }

        const data = (await res.json()) as SearxngResponse;
        const results = (data.results ?? []).slice(0, 10);

        if (results.length === 0) {
          ctx.ui.notify(`No results found for "${data.query}".`, "info");
          return;
        }

        for (const r of results) {
          ctx.ui.notify(`${r.title} — ${r.url}`, "info");
        }
      } catch (err) {
        ctx.ui.notify(
          `Failed to reach SearXNG: ${err instanceof Error ? err.message : String(err)}`,
          "error"
        );
      }
    },
  });
}
