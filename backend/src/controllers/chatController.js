const axios = require('axios');

// In-memory per-user conversation memory (demo use only)
// Key: user uid, Value: Array of { role: 'user'|'assistant', content: string }
const conversations = new Map();

function enforceBriefStyle(text) {
  if (!text) return '';
  let out = String(text).trim();
  const lines = out
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean);
  out = (lines.length ? lines.slice(0, 4).join('\n') : out);
  if (out.length > 450) {
    out = out.slice(0, 450).replace(/[^\w)\]}]*$/, '').trim();
  }
  return out;
}

function sanitizePhrases(text) {
  if (!text) return '';
  let out = text;
  const banned = [
    /i\s*can(?:not|'t)\s*diagnose/gi,
    /i'?m\s*not\s*here\s*to\s*identify/gi,
    /as\s*an\s*ai/gi,
    /i\s*am\s*an\s*ai/gi,
    /i\s*am\s*not\s*a\s*doctor/gi,
    /language\s*model/gi,
  ];
  for (const pattern of banned) out = out.replace(pattern, '').trim();
  // Remove leftover extra spaces and punctuation artifacts
  out = out.replace(/\s{2,}/g, ' ').replace(/\s*\.(\s*\.)+/g, '.');
  return out.trim();
}

exports.chatWithAI = async (req, res) => {
  const fallbackReply =
    'I am experiencing a slow connection right now. Please try again in a moment or consult a healthcare professional for urgent concerns.';

  const { message } = req.body ?? {};
  if (!message || !message.trim()) {
    return res.status(400).json({ error: 'message is required' });
  }

  const uid = req.user?.uid || 'anonymous';
  const history = conversations.get(uid) || [];

  if (!process.env.GROQ_API_KEY) {
    console.error('[chatWithAI] Missing GROQ_API_KEY');
    return res.status(503).json({ reply: fallbackReply, warning: 'Chat service is not configured' });
  }

  const models = [
    ...(process.env.GROQ_MODEL ? [process.env.GROQ_MODEL] : []),
    'llama-3.1-8b-instant',
    'llama-3.1-70b-versatile',
    'mixtral-8x7b-32768',
  ];

  let lastError;

  for (const model of models) {
    try {
      const response = await axios.post(
        'https://api.groq.com/openai/v1/chat/completions',
        {
          model,
          temperature: 0.2,
          max_tokens: 180,
          messages: [
            {
              role: 'system',
              content:
                'You are CareVibe, a calm and reliable wellness assistant. Respond in 2–4 short lines. Reference earlier symptoms briefly when relevant (e.g., "With fever and stomach pain..."). Give only essential wellness steps. Do not diagnose. If symptoms sound serious or persist, suggest seeking medical care. Use simple, natural language. Avoid marketing tone and disclaimers like "I can\'t diagnose". You may add up to 2 very short bullet recommendations at the end only if they clarify next steps (use "- "). Ask one short follow-up only when truly helpful.',
            },
            ...history,
            { role: 'user', content: message.trim() },
          ],
        },
        {
          timeout: 12000,
          headers: {
            Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
            'Content-Type': 'application/json',
          },
        }
      );

      const reply = response.data?.choices?.[0]?.message?.content?.trim();
      if (!reply) {
        console.warn('[chatWithAI] Empty response from Groq for model', model);
        continue;
      }

      let formatted = enforceBriefStyle(reply);
      formatted = sanitizePhrases(formatted);

      // Update conversation memory: keep last 12 turns (24 messages)
      const updated = [
        ...history,
        { role: 'user', content: message.trim() },
        { role: 'assistant', content: formatted },
      ];
      const maxMessages = 24;
      const pruned = updated.length > maxMessages ? updated.slice(updated.length - maxMessages) : updated;
      conversations.set(uid, pruned);

      return res.json({ reply: formatted });
    } catch (err) {
      lastError = err;
      const status = err.response?.status;
      const message = err.response?.data?.error?.message || err.message || 'Unknown Groq error';
      console.error(`[chatWithAI] Groq error for model ${model}:`, status, message);

      const shouldRetry =
        status === 429 ||
        status === 503 ||
        (typeof message === 'string' &&
          (message.toLowerCase().includes('over capacity') ||
            message.toLowerCase().includes('temporarily unavailable') ||
            message.toLowerCase().includes('model') ||
            message.toLowerCase().includes('try again')));

      if (!shouldRetry) {
        break;
      }
    }
  }

  const warningMessage =
    lastError?.response?.data?.error?.message || lastError?.message || 'AI service unavailable';
  const status = lastError?.response?.status;
  res.status(200).json({ reply: fallbackReply, warning: warningMessage, status });
};


