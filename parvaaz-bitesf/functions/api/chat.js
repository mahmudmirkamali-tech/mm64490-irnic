// Cloudflare Pages Function — proxy API chat
const ALLOWED_ORIGINS = [
  'https://presf.ir',
  'https://www.presf.ir',
  'http://localhost:3000',
  'http://127.0.0.1:3000'
];

function resolveAllowedOrigins(env) {
  if (env.ALLOWED_ORIGINS) {
    return env.ALLOWED_ORIGINS.split(',').map(s => s.trim()).filter(Boolean);
  }
  return ALLOWED_ORIGINS;
}

function corsHeaders(request, env) {
  const origins = resolveAllowedOrigins(env || {});
  const origin = request.headers.get('Origin') || '';
  const allowed = origins.includes(origin) ? origin : origins[0];
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400'
  };
}

export async function onRequestOptions(context) {
  return new Response(null, { status: 204, headers: corsHeaders(context.request, context.env) });
}

export async function onRequestPost(context) {
  const apiKey = context.env.ANTHROPIC_API_KEY;
  const origins = resolveAllowedOrigins(context.env);
  const origin = context.request.headers.get('Origin') || '';
  const allowed = origins.includes(origin) ? origin : origins[0];
  const headers = {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json'
  };

  if (!apiKey) {
    return new Response(JSON.stringify({ error: 'API key not configured on cloud core' }), {
      status: 500,
      headers
    });
  }

  try {
    const body = await context.request.text();
    const upstream = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      },
      body
    });

    return new Response(await upstream.text(), {
      status: upstream.status,
      headers
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: 'Cloud core connection failed' }), {
      status: 502,
      headers
    });
  }
}
