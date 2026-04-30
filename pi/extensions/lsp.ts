import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { spawn, ChildProcessWithoutNullStreams } from "node:child_process";
import * as path from "node:path";
import * as fs from "node:fs";
import { homedir } from "node:os";

// ──────────────────────────────────────────
// LSP Extension for Pi
// Provides LLM-callable tools for language server operations.
// No npm dependencies — uses only Node.js built-ins.
// ──────────────────────────────────────────

// Basic LSP types we need inline (avoid external deps)
interface Diagnostic {
  range: { start: Position; end: Position };
  severity?: number; // 1=Error, 2=Warning, 3=Info, 4=Hint
  code?: string | number;
  source?: string;
  message: string;
  relatedInformation?: Array<{
    location: { uri: string; range: { start: Position; end: Position } };
    message: string;
  }>;
}

interface Position {
  line: number;
  character: number;
}

interface Location {
  uri: string;
  range: { start: Position; end: Position };
}

interface DocumentSymbol {
  name: string;
  detail?: string;
  kind: number;
  range: { start: Position; end: Position };
  selectionRange: { start: Position; end: Position };
  children?: DocumentSymbol[];
}

interface Hover {
  contents: string | Array<{ language: string; value: string }> | { kind: "markdown" | "plaintext"; value: string };
  range?: { start: Position; end: Position };
}

// ──────────────────────────────────────────
// JSON-RPC over stdio transport
// ──────────────────────────────────────────

type JsonRpcMessage = {
  jsonrpc: "2.0";
  id?: number | string;
  method?: string;
  params?: unknown;
  result?: unknown;
  error?: { code: number; message: string; data?: unknown };
};

class JsonRpcConnection {
  private buffer = Buffer.alloc(0);
  private nextId = 1;
  private pending = new Map<
    number,
    { resolve: (v: unknown) => void; reject: (e: Error) => void }
  >();
  private notifications = new Map<string, ((params: unknown) => void)[]>();
  private closed = false;

  constructor(private proc: ChildProcessWithoutNullStreams) {
    proc.stdout.on("data", (data: Buffer) => this.onData(data));
    proc.stdout.on("error", (err: Error) => this.onError(err));
    proc.on("close", (code: number | null) => this.onClose(code));
    proc.on("error", (err: Error) => this.onError(err));
  }

  private onData(data: Buffer) {
    this.buffer = Buffer.concat([this.buffer, data]);
    this.parseMessages();
  }

  private parseMessages() {
    while (true) {
      const headerEnd = this.buffer.indexOf("\r\n\r\n");
      if (headerEnd === -1) return;

      const headerStr = this.buffer.slice(0, headerEnd).toString();
      const match = headerStr.match(/Content-Length:\s*(\d+)/i);
      if (!match) {
        this.buffer = this.buffer.slice(headerEnd + 4);
        continue;
      }
      const length = parseInt(match[1], 10);
      const msgStart = headerEnd + 4;
      if (this.buffer.length < msgStart + length) return;

      const body = this.buffer.slice(msgStart, msgStart + length).toString();
      this.buffer = this.buffer.slice(msgStart + length);

      try {
        const msg = JSON.parse(body) as JsonRpcMessage;
        this.handleMessage(msg);
      } catch {
        // ignore malformed JSON
      }
    }
  }

  private handleMessage(msg: JsonRpcMessage) {
    if (msg.id !== undefined && this.pending.has(msg.id)) {
      const cb = this.pending.get(msg.id)!;
      this.pending.delete(msg.id);
      if (msg.error) cb.reject(new Error(msg.error.message));
      else cb.resolve(msg.result);
    } else if (msg.method) {
      const handlers = this.notifications.get(msg.method) || [];
      for (const h of handlers) h(msg.params);
    }
  }

  request(method: string, params: unknown): Promise<unknown> {
    if (this.closed) return Promise.reject(new Error("Connection closed"));
    const id = this.nextId++;
    const msg = { jsonrpc: "2.0" as const, id, method, params };
    const json = JSON.stringify(msg);
    const bytes = Buffer.byteLength(json, "utf8");
    const data = `Content-Length: ${bytes}\r\n\r\n${json}`;

    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      const t = setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`${method} timed out`));
        }
      }, 30000);
      this.proc.stdin.write(data, (err) => {
        if (err) {
          clearTimeout(t);
          this.pending.delete(id);
          reject(err);
        }
      });
    });
  }

  notify(method: string, params: unknown): void {
    if (this.closed) return;
    const msg = { jsonrpc: "2.0" as const, method, params };
    const json = JSON.stringify(msg);
    const bytes = Buffer.byteLength(json, "utf8");
    this.proc.stdin.write(`Content-Length: ${bytes}\r\n\r\n${json}`);
  }

  onNotification(method: string, handler: (params: unknown) => void): void {
    const handlers = this.notifications.get(method) || [];
    handlers.push(handler);
    this.notifications.set(method, handlers);
  }

  private onError(err: Error) {
    for (const [, cb] of this.pending) cb.reject(err);
    this.pending.clear();
  }

  private onClose(code: number | null) {
    this.closed = true;
    for (const [, cb] of this.pending) {
      cb.reject(new Error(`LSP server exited with code ${code}`));
    }
    this.pending.clear();
  }

  dispose() {
    this.closed = true;
    try {
      this.proc.stdin.end();
    } catch {}
    try {
      this.proc.kill();
    } catch {}
  }
}

// ──────────────────────────────────────────
// Per-workspace LSP client
// ──────────────────────────────────────────

interface ServerSpec {
  command: string;
  args?: string[];
  initializationOptions?: unknown;
}

const EXT_TO_LANG: Record<string, string> = {
  ".ts": "typescript",
  ".tsx": "typescriptreact",
  ".mts": "typescript",
  ".cts": "typescript",
  ".js": "javascript",
  ".jsx": "javascriptreact",
  ".mjs": "javascript",
  ".cjs": "javascript",
  ".py": "python",
  ".pyi": "python",
  ".pyw": "python",
  ".rs": "rust",
  ".go": "go",
  ".c": "c",
  ".h": "c",
  ".cpp": "cpp",
  ".hpp": "cpp",
  ".cc": "cpp",
  ".cxx": "cpp",
  ".lua": "lua",
};

const DEFAULT_SERVERS: Record<string, ServerSpec> = {
  typescript: { command: "typescript-language-server", args: ["--stdio"] },
  typescriptreact: { command: "typescript-language-server", args: ["--stdio"] },
  javascript: { command: "typescript-language-server", args: ["--stdio"] },
  javascriptreact: { command: "typescript-language-server", args: ["--stdio"] },
  python: { command: "basedpyright-langserver", args: ["--stdio"] },
  rust: { command: "rust-analyzer" },
  go: { command: "gopls" },
  c: { command: "clangd", args: ["--background-index"] },
  cpp: { command: "clangd", args: ["--background-index"] },
  lua: { command: "lua-language-server", args: ["--stdio"] },
};

function pathToUri(p: string): string {
  if (p.startsWith("file://")) return p;
  const abs = path.resolve(p);
  return "file://" + (abs.startsWith("/") ? "" : "/") + abs;
}

function uriToPath(uri: string): string {
  if (uri.startsWith("file://")) return uri.slice(7);
  return uri;
}

function findWorkspaceRoot(filePath: string, languageId: string): string {
  const dir = path.dirname(path.resolve(filePath));
  const markers: Record<string, string[]> = {
    python: ["pyproject.toml", "setup.py", "setup.cfg", ".git"],
    typescript: ["package.json", "tsconfig.json", ".git"],
    typescriptreact: ["package.json", "tsconfig.json", ".git"],
    javascript: ["package.json", ".git"],
    javascriptreact: ["package.json", ".git"],
    rust: ["Cargo.toml", ".git"],
    go: ["go.mod", ".git"],
    c: [".git", "CMakeLists.txt", "compile_commands.json"],
    cpp: [".git", "CMakeLists.txt", "compile_commands.json"],
    lua: [".git"],
  };
  const checks = markers[languageId] || [".git"];
  let cur = dir;
  while (true) {
    for (const m of checks) {
      if (fs.existsSync(path.join(cur, m))) return cur;
    }
    const parent = path.dirname(cur);
    if (parent === cur) break;
    cur = parent;
  }
  return process.cwd();
}

class LSPClient {
  private conn: JsonRpcConnection;
  private caps: Record<string, unknown> = {};
  private openFiles = new Set<string>();
  private diagnostics = new Map<string, Diagnostic[]>();
  private serverInfo?: { name: string; version?: string };
  private disposed = false;

  constructor(
    proc: ChildProcessWithoutNullStreams,
    private workspaceRoot: string,
    private languageId: string
  ) {
    this.conn = new JsonRpcConnection(proc);
  }

  async initialize(spec: ServerSpec): Promise<void> {
    const rootUri = pathToUri(this.workspaceRoot);
    const result = (await this.conn.request("initialize", {
      processId: process.pid,
      rootUri,
      capabilities: {
        textDocumentSync: {
          openClose: true,
          change: 1, // full document sync for simplicity
        },
        hover: {
          dynamicRegistration: false,
          contentFormat: ["markdown", "plaintext"],
        },
        definition: {
          dynamicRegistration: false,
          linkSupport: true,
        },
        references: { dynamicRegistration: false },
        documentSymbol: {
          dynamicRegistration: false,
          hierarchicalDocumentSymbolSupport: true,
        },
        workspaceSymbol: { dynamicRegistration: false },
      },
      initializationOptions: spec.initializationOptions ?? {},
      trace: "off",
      workspaceFolders: [
        { uri: rootUri, name: path.basename(this.workspaceRoot) },
      ],
    })) as {
      capabilities: Record<string, unknown>;
      serverInfo?: { name: string; version?: string };
    };

    this.caps = result.capabilities;
    this.serverInfo = result.serverInfo;
    this.conn.notify("initialized", {});
  }

  async openFile(filePath: string): Promise<void> {
    const uri = pathToUri(filePath);
    if (this.openFiles.has(uri)) return;
    const content = fs.readFileSync(path.resolve(filePath), "utf-8");
    this.conn.notify("textDocument/didOpen", {
      textDocument: {
        uri,
        languageId: this.languageId,
        version: 1,
        text: content,
      },
    });
    this.openFiles.add(uri);
    // give server a moment to process
    await new Promise((r) => setTimeout(r, 300));
  }

  async getDiagnostics(filePath: string): Promise<Diagnostic[]> {
    await this.openFile(filePath);
    const uri = pathToUri(filePath);
    // start listening
    const listener = (params: unknown) => {
      const p = params as { uri: string; diagnostics: Diagnostic[] };
      if (p.uri === uri) {
        this.diagnostics.set(uri, p.diagnostics);
      }
    };
    this.conn.onNotification("textDocument/publishDiagnostics", listener);
    // wait for push
    await new Promise((r) => setTimeout(r, 800));
    return this.diagnostics.get(uri) || [];
  }

  async hover(filePath: string, line: number, character: number): Promise<Hover | null> {
    if (!this.caps.hoverProvider) return null;
    await this.openFile(filePath);
    const uri = pathToUri(filePath);
    const result = (await this.conn.request("textDocument/hover", {
      textDocument: { uri },
      position: { line, character },
    })) as Hover | null;
    return result;
  }

  async definition(filePath: string, line: number, character: number): Promise<Location[] | null> {
    const linkCap = this.caps.definitionProvider as boolean | { linkSupport?: boolean };
    if (!linkCap) return null;
    await this.openFile(filePath);
    const uri = pathToUri(filePath);
    const result = (await this.conn.request("textDocument/definition", {
      textDocument: { uri },
      position: { line, character },
    })) as Location | Location[] | null;
    if (!result) return null;
    return Array.isArray(result) ? result : [result];
  }

  async references(filePath: string, line: number, character: number): Promise<Location[] | null> {
    if (!this.caps.referencesProvider) return null;
    await this.openFile(filePath);
    const uri = pathToUri(filePath);
    const result = (await this.conn.request("textDocument/references", {
      textDocument: { uri },
      position: { line, character },
      context: { includeDeclaration: true },
    })) as Location[] | null;
    return result;
  }

  async documentSymbols(filePath: string): Promise<DocumentSymbol[] | null> {
    if (!this.caps.documentSymbolProvider) return null;
    await this.openFile(filePath);
    const uri = pathToUri(filePath);
    const result = (await this.conn.request("textDocument/documentSymbol", {
      textDocument: { uri },
    })) as DocumentSymbol[] | null;
    return result;
  }

  getInfo(): { languageId: string; root: string; server?: string; capabilities: string[] } {
    const capList: string[] = [];
    if (this.caps.hoverProvider) capList.push("hover");
    if (this.caps.definitionProvider) capList.push("definition");
    if (this.caps.referencesProvider) capList.push("references");
    if (this.caps.documentSymbolProvider) capList.push("documentSymbol");
    if (this.caps.textDocumentSync) capList.push("sync");
    return {
      languageId: this.languageId,
      root: this.workspaceRoot,
      server: this.serverInfo?.name,
      capabilities: capList,
    };
  }

  dispose() {
    if (this.disposed) return;
    this.disposed = true;
    try {
      this.conn.notify("shutdown", {});
    } catch {}
    try {
      this.conn.notify("exit", {});
    } catch {}
    setTimeout(() => this.conn.dispose(), 500);
  }
}

// ──────────────────────────────────────────
// Global manager: one client per (workspace, language)
// ──────────────────────────────────────────

class LSPManager {
  private clients = new Map<string, LSPClient>(); // key = `${workspaceRoot}|${languageId}`
  private userConfig: Record<string, ServerSpec> = {};

  constructor() {
    this.loadConfig();
  }

  private loadConfig() {
    try {
      const cfgPath = path.join(homedir(), ".pi/agent/lsp-config.json");
      if (fs.existsSync(cfgPath)) {
        const raw = fs.readFileSync(cfgPath, "utf-8");
        const parsed = JSON.parse(raw) as { servers?: Record<string, ServerSpec> };
        this.userConfig = parsed.servers || {};
      }
    } catch {
      // no config or malformed
    }
  }

  private getKey(filePath: string, languageId: string): string {
    const root = findWorkspaceRoot(filePath, languageId);
    return `${root}|${languageId}`;
  }

  private getSpec(languageId: string): ServerSpec | null {
    if (this.userConfig[languageId]) return this.userConfig[languageId];
    if (DEFAULT_SERVERS[languageId]) return DEFAULT_SERVERS[languageId];
    return null;
  }

  async getClient(filePath: string): Promise<LSPClient | null> {
    const ext = path.extname(filePath).toLowerCase();
    const languageId = EXT_TO_LANG[ext];
    if (!languageId) return null;

    const key = this.getKey(filePath, languageId);
    if (this.clients.has(key)) return this.clients.get(key)!;

    const spec = this.getSpec(languageId);
    if (!spec) return null;

    // verify command exists
    try {
      // best-effort check; we'll still try to spawn
      const which = spawn("which", [spec.command], { stdio: "pipe" });
      const found = await new Promise<boolean>((resolve) => {
        which.on("close", (code) => resolve(code === 0));
        which.on("error", () => resolve(false));
      });
      if (!found) return null;
    } catch {
      return null;
    }

    const workspaceRoot = findWorkspaceRoot(filePath, languageId);
    const proc = spawn(spec.command, spec.args || [], {
      cwd: workspaceRoot,
      stdio: ["pipe", "pipe", "pipe"],
    });

    proc.stderr.on("data", (data: Buffer) => {
      // suppress stderr noise; servers often log non-errors here
      const text = data.toString().trim();
      if (text.length > 0 && text.length < 200) {
        // optional: log minimal diagnostics
      }
    });

    const client = new LSPClient(proc, workspaceRoot, languageId);
    try {
      await client.initialize(spec);
      this.clients.set(key, client);
      return client;
    } catch (err) {
      client.dispose();
      throw err;
    }
  }

  async withClient<T>(
    filePath: string,
    fn: (client: LSPClient) => Promise<T | null>
  ): Promise<T | null> {
    const client = await this.getClient(filePath);
    if (!client) return null;
    try {
      return await fn(client);
    } catch (err) {
      throw err;
    }
  }

  async shutdown(): Promise<void> {
    for (const [, client] of this.clients) {
      client.dispose();
    }
    this.clients.clear();
  }

  listActive(): Array<{
    languageId: string;
    root: string;
    server?: string;
    capabilities: string[];
  }> {
    return Array.from(this.clients.values()).map((c) => c.getInfo());
  }

  async detectAvailable(): Promise<
    Array<{ languageId: string; command: string; args?: string[]; found: boolean }>
  > {
    const all = Object.entries(DEFAULT_SERVERS);
    const results = await Promise.all(
      all.map(async ([languageId, spec]) => {
        const found = await new Promise<boolean>((resolve) => {
          const which = spawn("which", [spec.command], { stdio: "pipe" });
          which.on("close", (code) => resolve(code === 0));
          which.on("error", () => resolve(false));
        });
        return { languageId, command: spec.command, args: spec.args, found };
      })
    );
    return results;
  }

  async startForFile(filePath: string): Promise<string | null> {
    const client = await this.getClient(filePath);
    if (!client) return null;
    const info = client.getInfo();
    return `${info.languageId} @ ${info.root} (${info.server ?? "unknown"})`;
  }
}

// ──────────────────────────────────────────
// Severity helpers
// ──────────────────────────────────────────

function severityName(sev?: number): string {
  switch (sev) {
    case 1:
      return "Error";
    case 2:
      return "Warning";
    case 3:
      return "Info";
    case 4:
      return "Hint";
    default:
      return "Unknown";
  }
}

function formatHover(h: Hover): string {
  const c = h.contents;
  if (typeof c === "string") {
    return c;
  } else if (Array.isArray(c)) {
    return c
      .map((part) => {
        if (typeof part === "string") return part;
        return "```" + part.language + "\n" + part.value + "\n```";
      })
      .join("\n\n");
  } else {
    return c.value;
  }
}

function formatSymbols(symbols: DocumentSymbol[], indent = 0): string {
  const out: string[] = [];
  const kindNames: Record<number, string> = {
    1: "File",
    2: "Module",
    3: "Namespace",
    4: "Package",
    5: "Class",
    6: "Method",
    7: "Property",
    8: "Field",
    9: "Constructor",
    10: "Enum",
    11: "Interface",
    12: "Function",
    13: "Variable",
    14: "Constant",
    15: "String",
    16: "Number",
    17: "Boolean",
    18: "Array",
    19: "Object",
    20: "Key",
    21: "Null",
    22: "EnumMember",
    23: "Struct",
    24: "Event",
    25: "Operator",
    26: "TypeParameter",
  };
  const pad = "  ".repeat(indent);
  for (const s of symbols) {
    const kind = kindNames[s.kind] || "Symbol";
    const detail = s.detail ? ` (${s.detail})` : "";
    const range = `${s.range.start.line + 1}:${s.range.start.character}`;
    out.push(`${pad}${kind}: ${s.name}${detail} @ L${range}`);
    if (s.children) out.push(formatSymbols(s.children, indent + 1));
  }
  return out.join("\n");
}

// ──────────────────────────────────────────
// Extension entrypoint
// ──────────────────────────────────────────

const manager = new LSPManager();

export default function (pi: ExtensionAPI) {
  // Clean up servers on session shutdown
  pi.on("session_shutdown", async () => {
    await manager.shutdown();
  });

  // ─── lsp_diagnostics ───
  pi.registerTool({
    name: "lsp_diagnostics",
    label: "LSP Diagnostics",
    description:
      "Get static analysis diagnostics (errors, warnings, hints) for a source file via an LSP language server. Runs the appropriate server for the file type (typescript-language-server, pylsp, rust-analyzer, clangd, etc.).",
    promptSnippet: "Get compile errors, warnings, or type diagnostics",
    promptGuidelines: [
      "Use lsp_diagnostics when asked to check a file for errors, warnings, type issues, or lint diagnostics.",
      "Prefer lsp_diagnostics over manual reading when the user wants to find problems in code.",
      "This is independent of the bash tool — it uses a persistent language server for real-time analysis.",
    ],
    parameters: Type.Object({
      file_path: Type.String({
        description: "Absolute or relative path to the source file to analyze.",
      }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const filePath = path.resolve(params.file_path);
      if (!fs.existsSync(filePath)) {
        return {
          content: [{ type: "text" as const, text: `File not found: ${filePath}` }],
          details: { error: "not_found" },
        };
      }
      const diags = await manager.withClient(filePath, (c) =>
        c.getDiagnostics(filePath)
      );
      if (diags === null) {
        return {
          content: [{ type: "text" as const, text: "No LSP server available for this file type." }],
          details: { noServer: true },
        };
      }
      if (diags.length === 0) {
        return {
          content: [{ type: "text" as const, text: "No diagnostics found — clean file." }],
          details: { diagnostics: [] },
        };
      }
      const lines: string[] = [`Found ${diags.length} diagnostic(s) for ${filePath}:", ""`];
      for (const d of diags) {
        const sev = severityName(d.severity);
        const loc = `L${d.range.start.line + 1}:${d.range.start.character}`;
        lines.push(`[${sev}] ${loc} — ${d.message}`);
        if (d.code) lines.push(`  code: ${d.code}`);
        if (d.source) lines.push(`  source: ${d.source}`);
        if (d.relatedInformation?.length) {
          for (const ri of d.relatedInformation) {
            const rloc = uriToPath(ri.location.uri);
            lines.push(`  related: ${rloc} L${ri.location.range.start.line + 1} — ${ri.message}`);
          }
        }
        lines.push("");
      }
      return {
        content: [{ type: "text" as const, text: lines.join("\n") }],
        details: { diagnostics: diags },
      };
    },
  });

  // ─── lsp_hover ───
  pi.registerTool({
    name: "lsp_hover",
    label: "LSP Hover",
    description:
      "Get type information, documentation, or hover hints for a specific position in a source file via LSP.",
    promptSnippet: "Get type/docs info at a position in source code",
    promptGuidelines: [
      "Use lsp_hover when asked 'what type is this' or 'what does this function do' at a specific location.",
      "lsp_hover provides accurate type information from the language server, prefer it over guessing from code.",
      "Requires an exact line and character position (zero-indexed).",
    ],
    parameters: Type.Object({
      file_path: Type.String({ description: "Path to the source file." }),
      line: Type.Number({ description: "Zero-based line number." }),
      character: Type.Number({ description: "Zero-based character position on the line." }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const filePath = path.resolve(params.file_path);
      const hover = await manager.withClient(filePath, (c) =>
        c.hover(filePath, params.line, params.character)
      );
      if (hover === null) {
        return {
          content: [{ type: "text" as const, text: "No hover info (server unavailable or no result)." }],
          details: { noResult: true },
        };
      }
      const text = formatHover(hover);
      return {
        content: [{ type: "text" as const, text }],
        details: { raw: hover },
      };
    },
  });

  // ─── lsp_definition ───
  pi.registerTool({
    name: "lsp_definition",
    label: "LSP Definition",
    description:
      "Jump to the definition of a symbol (function, variable, class, etc.) at a specific position via LSP.",
    promptSnippet: "Go-to-definition for a symbol",
    promptGuidelines: [
      "Use lsp_definition when asked 'where is this defined' or 'go to definition'.",
      "lsp_definition is precise and symbol-aware, prefer it over grep for finding definitions.",
      "Returns file paths and line numbers — read those files with the read tool afterward.",
    ],
    parameters: Type.Object({
      file_path: Type.String({ description: "Path to the source file." }),
      line: Type.Number({ description: "Zero-based line number." }),
      character: Type.Number({ description: "Zero-based character position." }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const filePath = path.resolve(params.file_path);
      const locs = await manager.withClient(filePath, (c) =>
        c.definition(filePath, params.line, params.character)
      );
      if (locs === null || locs.length === 0) {
        return {
          content: [{ type: "text" as const, text: "No definition found." }],
          details: { noResult: true },
        };
      }
      const lines: string[] = [`Found ${locs.length} definition location(s):", ""`];
      for (const loc of locs) {
        const p = uriToPath(loc.uri);
        lines.push(`  ${p} (L${loc.range.start.line + 1}:${loc.range.start.character})`);
      }
      return {
        content: [{ type: "text" as const, text: lines.join("\n") }],
        details: { locations: locs },
      };
    },
  });

  // ─── lsp_references ───
  pi.registerTool({
    name: "lsp_references",
    label: "LSP References",
    description:
      "Find all references (usages) of a symbol at a specific position via LSP.",
    promptSnippet: "Find all usages of a symbol",
    promptGuidelines: [
      "Use lsp_references when asked 'where is this used' or 'find references'.",
      "lsp_references understands symbol scope and is type-accurate, prefer it over grep for references.",
      "Returns file paths and line — read results with the read tool if needed.",
    ],
    parameters: Type.Object({
      file_path: Type.String({ description: "Path to the source file." }),
      line: Type.Number({ description: "Zero-based line number." }),
      character: Type.Number({ description: "Zero-based character position." }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const filePath = path.resolve(params.file_path);
      const locs = await manager.withClient(filePath, (c) =>
        c.references(filePath, params.line, params.character)
      );
      if (locs === null || locs.length === 0) {
        return {
          content: [{ type: "text" as const, text: "No references found." }],
          details: { noResult: true },
        };
      }
      const lines: string[] = [`Found ${locs.length} reference(s):", ""`];
      for (const loc of locs) {
        const p = uriToPath(loc.uri);
        lines.push(`  ${p} (L${loc.range.start.line + 1}:${loc.range.start.character})`);
      }
      return {
        content: [{ type: "text" as const, text: lines.join("\n") }],
        details: { locations: locs },
      };
    },
  });

  // ─── lsp_document_symbols ───
  pi.registerTool({
    name: "lsp_document_symbols",
    label: "LSP Document Symbols",
    description:
      "Get a structural outline (classes, functions, methods, variables) of a source file via LSP.",
    promptSnippet: "Get file outline / structure overview",
    promptGuidelines: [
      "Use lsp_document_symbols to get an overview of a file's structure before diving in.",
      "lsp_document_symbols gives a precise outline, faster than reading the whole file for layout understanding.",
      "Faster than reading the whole file when you just need to understand its layout.",
    ],
    parameters: Type.Object({
      file_path: Type.String({ description: "Path to the source file." }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const filePath = path.resolve(params.file_path);
      const symbols = await manager.withClient(filePath, (c) =>
        c.documentSymbols(filePath)
      );
      if (symbols === null) {
        return {
          content: [{ type: "text" as const, text: "No symbol outline available." }],
          details: { noResult: true },
        };
      }
      if (symbols.length === 0) {
        return {
          content: [{ type: "text" as const, text: "File is empty or contains no symbols." }],
          details: { symbols: [] },
        };
      }
      const text = formatSymbols(symbols);
      return {
        content: [{ type: "text" as const, text }],
        details: { symbols },
      };
    },
  });

  // ─── /lsp command ───
  pi.registerCommand("lsp", {
    description: "Show active and available LSP servers. Usage: /lsp [start <file>]",
    handler: async (args, ctx) => {
      const trimmed = args?.trim() ?? "";

      // Handle /lsp start <file>
      if (trimmed.startsWith("start ")) {
        const file = trimmed.slice(6).trim();
        if (!file) {
          ctx.ui.notify("Usage: /lsp start <file>", "warning");
          return;
        }
        const absPath = path.resolve(file);
        if (!fs.existsSync(absPath)) {
          ctx.ui.notify(`File not found: ${absPath}`, "error");
          return;
        }
        try {
          const info = await manager.startForFile(absPath);
          if (info) {
            ctx.ui.notify(`Started: ${info}`, "success");
          } else {
            ctx.ui.notify("No LSP server available for this file type.", "warning");
          }
        } catch (err) {
          ctx.ui.notify(
            `Failed to start server: ${err instanceof Error ? err.message : String(err)}`,
            "error"
          );
        }
        return;
      }

      // Show active servers
      const active = manager.listActive();
      if (active.length > 0) {
        ctx.ui.notify("Active LSP servers:", "info");
        for (const s of active) {
          ctx.ui.notify(
            `  ${s.languageId} @ ${s.root} (${s.server ?? "unknown"}): ${s.capabilities.join(", ")}`,
            "info"
          );
        }
      } else {
        ctx.ui.notify("No active LSP servers yet.", "info");
      }

      // Show available/detected servers
      const available = await manager.detectAvailable();
      const found = available.filter((a) => a.found);
      const missing = available.filter((a) => !a.found);

      if (found.length > 0) {
        ctx.ui.notify("Available in PATH:", "info");
        for (const s of found) {
          const argsStr = s.args ? ` ${s.args.join(" ")}` : "";
          ctx.ui.notify(`  ${s.languageId}: ${s.command}${argsStr}`, "info");
        }
      }

      if (missing.length > 0) {
        ctx.ui.notify("Not found in PATH (install to enable):", "info");
        for (const s of missing) {
          ctx.ui.notify(`  ${s.languageId}: ${s.command}`, "info");
        }
      }
    },
  });
}
