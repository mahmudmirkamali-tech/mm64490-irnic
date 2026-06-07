// Vercel Serverless â€” ط¬ط§غŒع¯ط²غŒظ† ط±ط§غŒع¯ط§ظ† (ط§ع¯ط± Cloudflare ظ†ط¨ظˆط¯)
const ALLOWED = ['https://presf.ir',
  'https://www.presf.ir'];

module.exports = async function handler(req, res) {
  const origin = req.headers.origin || '';
  const cors = ALLOWED.includes(origin) ? origin : ALLOWED[0];
  res.setHeader('Access-Control-Allow-Origin', cors);
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'API key not configured' });

  try {
    const upstream = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify(req.body)
    });
    const text = await upstream.text();
    res.status(upstream.status).setHeader('Content-Type', 'application/json').send(text);
  } catch (e) {
    res.status(502).json({ error: 'Upstream failed' });
  }
};
