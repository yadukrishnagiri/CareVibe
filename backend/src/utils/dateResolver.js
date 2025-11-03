const chrono = require('chrono-node');
const Groq = require('groq-sdk');

/**
 * Normalize common date typos and informal terms
 */
function normalizeMessage(message) {
  if (!message) return '';
  
  let normalized = message.toLowerCase();
  
  // Common typos
  normalized = normalized.replace(/\b(mouth|mnth|mont)\b/gi, 'month');
  normalized = normalized.replace(/\b(yday|ystrday|yestrday)\b/gi, 'yesterday');
  normalized = normalized.replace(/\b(tmrw|tomrw|tomorow)\b/gi, 'tomorrow');
  normalized = normalized.replace(/\b(wk|week)\b/gi, 'week');
  normalized = normalized.replace(/\b(dy|dai)\b/gi, 'day');
  normalized = normalized.replace(/\b(hr|hrs)\b/gi, 'hour');
  normalized = normalized.replace(/\b(ago|back)\b/gi, 'ago');
  
  return normalized;
}

/**
 * Parse date using chrono-node
 */
function parseWithChrono(message, referenceDate) {
  const normalized = normalizeMessage(message);
  const results = chrono.parse(normalized, referenceDate, { forwardDate: false });
  
  if (results.length === 0) return null;
  
  // Get the first result
  const result = results[0];
  
  // Determine if it's a point or range
  if (result.end) {
    // Range detected
    return {
      start: result.start.date(),
      end: result.end.date(),
      kind: 'range',
      strategy: 'chrono',
      confidence: 0.9,
      text: result.text
    };
  } else {
    // Point in time
    return {
      start: result.start.date(),
      end: result.start.date(),
      kind: 'point',
      strategy: 'chrono',
      confidence: 0.9,
      text: result.text
    };
  }
}

/**
 * Fallback: Use Groq to extract date with JSON schema
 */
async function parseWithLLM(message, referenceDate) {
  try {
    const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
    
    const systemPrompt = `You are a date extraction assistant. Extract date/time references from user messages and return structured JSON.

Current reference date: ${referenceDate.toISOString().split('T')[0]}

Return JSON with this exact structure:
{
  "kind": "point" or "range",
  "startISO": "YYYY-MM-DD",
  "endISO": "YYYY-MM-DD",
  "granularity": "day|week|month|year",
  "confidence": 0.0 to 1.0
}

Examples:
- "a month ago" → {"kind":"point", "startISO":"2025-10-03", "endISO":"2025-10-03", "granularity":"day", "confidence":0.85}
- "last week" → {"kind":"range", "startISO":"2025-10-27", "endISO":"2025-11-02", "granularity":"week", "confidence":0.9}
- "30 days ago" → {"kind":"point", "startISO":"2025-10-04", "endISO":"2025-10-04", "granularity":"day", "confidence":0.95}

If no date found, return {"kind":"none", "confidence":0.0}`;

    const completion = await groq.chat.completions.create({
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: message }
      ],
      model: 'llama-3.1-8b-instant',
      temperature: 0,
      max_tokens: 150,
      response_format: { type: 'json_object' }
    });

    const result = JSON.parse(completion.choices[0]?.message?.content || '{}');
    
    if (result.kind === 'none' || !result.startISO) {
      return null;
    }
    
    return {
      start: new Date(result.startISO),
      end: new Date(result.endISO || result.startISO),
      kind: result.kind,
      strategy: 'llm',
      confidence: result.confidence || 0.7,
      granularity: result.granularity
    };
  } catch (e) {
    console.error('[dateResolver] LLM fallback failed:', e.message);
    return null;
  }
}

/**
 * Main date resolver function
 * @param {string} message - User message containing date reference
 * @param {Date} referenceDate - Current date/time for relative calculations
 * @returns {Promise<Object|null>} Parsed date info or null
 */
async function resolveDate(message, referenceDate = new Date()) {
  if (!message || typeof message !== 'string') return null;
  
  // Try chrono-node first (fast, deterministic)
  const chronoResult = parseWithChrono(message, referenceDate);
  if (chronoResult && chronoResult.confidence >= 0.8) {
    console.log('[dateResolver] Resolved with chrono:', chronoResult);
    return chronoResult;
  }
  
  // Fallback to LLM (slower, more flexible)
  const llmResult = await parseWithLLM(message, referenceDate);
  if (llmResult) {
    console.log('[dateResolver] Resolved with LLM:', llmResult);
    return llmResult;
  }
  
  console.log('[dateResolver] Could not resolve date from:', message);
  return null;
}

module.exports = {
  resolveDate,
  normalizeMessage,
  parseWithChrono
};

