const axios = require('axios');

exports.chatWithAI = async (req, res) => {
  const fallbackReply =
    'I am experiencing a slow connection right now. Please try again in a moment or consult a healthcare professional for urgent concerns.';

  const { message } = req.body ?? {};
  if (!message || !message.trim()) {
    return res.status(400).json({ error: 'message is required' });
  }

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
          temperature: 0.6,
          max_tokens: 512,
          messages: [
            {
              role: 'system',
              content:
                'You are CareVibe, a warm and supportive virtual health assistant. Share general wellness tips and always recommend consulting licensed professionals for emergencies.',
            },
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

      return res.json({ reply });
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


