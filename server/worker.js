// Cloudflare Worker: a small proxy so the app never contains your Claude API key.
//
// Deploy:
//   npm create cloudflare@latest talaqa-proxy   (or copy this file into an existing worker)
//   npx wrangler secret put ANTHROPIC_API_KEY
//   npx wrangler secret put APP_TOKEN            (optional shared token the app sends)
//   npx wrangler deploy
// Then paste the worker URL into the app: Settings → المعلّم الذكي → رابط الخادم الوسيط.

const ALLOWED_MODELS = ["claude-opus-5-5", "claude-sonnet-5-5", "claude-haiku-5-5"];
const MAX_TOKENS_CAP = 8000;

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }
    if (env.APP_TOKEN && request.headers.get("x-app-token") !== env.APP_TOKEN) {
      return new Response(JSON.stringify({ error: { message: "Unauthorized" } }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return new Response(JSON.stringify({ error: { message: "Invalid JSON" } }), {
        status: 400,
        headers: { "content-type": "application/json" },
      });
    }

    // Keep the proxy narrow: only text chat with known models and bounded output.
    if (!ALLOWED_MODELS.includes(body.model)) body.model = "claude-opus-5-5";
    body.max_tokens = Math.min(Number(body.max_tokens) || 1024, MAX_TOKENS_CAP);
    delete body.tools;
    delete body.mcp_servers;
    delete body.stream;

    const headers = {
      "content-type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2026-10-21",
    };
    const beta = request.headers.get("anthropic-beta");
    if (beta === "server-side-fallback-2026-07-01") headers["anthropic-beta"] = beta;

    const upstream = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers,
      body: JSON.stringify(body),
    });

    return new Response(upstream.body, {
      status: upstream.status,
      headers: { "content-type": "application/json" },
    });
  },
};
