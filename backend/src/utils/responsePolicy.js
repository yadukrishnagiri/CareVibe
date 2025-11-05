const Groq = require('groq-sdk');

/**
 * Response Policy and Question Classification
 * Determines reply style, length, and formatting based on question type
 */

/**
 * Classify message type using heuristics
 * @param {string} message - User message
 * @returns {string} Classification: 'simple_info', 'guidance', 'data_question', 'general'
 */
function classifyWithHeuristics(message) {
  if (!message || typeof message !== 'string') return 'general';
  
  const lower = message.toLowerCase();
  
  // Simple info queries (short factual questions)
  const simplePatterns = [
    /^what (is|was|are)/,
    /^how (much|many)/,
    /^when (did|was|is)/,
    /^where/,
    /^who/,
    /\b(latest|current|today|yesterday)\b/,
    /^(bmi|weight|sleep|steps|heart rate|stress)/,
  ];
  
  for (const pattern of simplePatterns) {
    if (pattern.test(lower)) {
      // If contains numbers/dates/metric names, likely data question
      if (/\d{1,4}|ago|last|past|average|trend/.test(lower)) {
        return 'data_question';
      }
      return 'simple_info';
    }
  }
  
  // Guidance requests (advice, recommendations, how-to)
  const guidancePatterns = [
    /how (can|do|should|to)/,
    /help me/,
    /improve|better|increase|decrease|reduce/,
    /advice|recommend|suggest/,
    /should i|can i/,
    /tips|ways|steps/,
  ];
  
  for (const pattern of guidancePatterns) {
    if (pattern.test(lower)) {
      return 'guidance';
    }
  }
  
  // Data questions (metrics, trends, analysis)
  const dataPatterns = [
    /average|mean|median/,
    /trend|pattern|change/,
    /increasing|decreasing|rising|falling/,
    /compare|comparison/,
    /[1-9][0-9]{0,2}\s*(day|week|month|year)/, // Bounded number to prevent ReDoS
    /last\s+[1-9][0-9]{0,2}/, // Bounded number to prevent ReDoS
  ];
  
  for (const pattern of dataPatterns) {
    if (pattern.test(lower)) {
      return 'data_question';
    }
  }
  
  return 'general';
}

/**
 * Classify message using LLM (fallback for ambiguous cases)
 * @param {string} message - User message
 * @returns {Promise<string>} Classification type
 */
async function classifyWithLLM(message) {
  try {
    const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
    
    const systemPrompt = `You are a message classifier. Classify user health questions into one of these types:
- "simple_info": Short factual questions (What is X? When was Y?)
- "guidance": Advice/recommendation requests (How do I improve? Help me with...)
- "data_question": Metric/trend analysis requests (What's my average? Is X increasing?)
- "general": Conversational or unclear intent

Return JSON: {"type": "simple_info|guidance|data_question|general", "confidence": 0.0-1.0}`;

    const completion = await groq.chat.completions.create({
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: message }
      ],
      model: 'llama-3.1-8b-instant',
      temperature: 0,
      max_tokens: 50,
      response_format: { type: 'json_object' }
    });

    const result = JSON.parse(completion.choices[0]?.message?.content || '{}');
    return result.type || 'general';
  } catch (e) {
    console.error('[responsePolicy] LLM classification failed:', e.message);
    return 'general';
  }
}

/**
 * Determine response style and constraints based on message classification
 * @param {string} message - User message
 * @param {number} messageLength - Length of user message
 * @param {boolean} hasData - Whether intent resolved to specific data
 * @param {string|null} userPref - User verbosity preference ('brief'|'standard'|'detailed')
 * @returns {Promise<Object>} Policy object with style constraints
 */
async function determineResponseStyle(message, messageLength, hasData, userPref = null) {
  // Classify the message
  let classification = classifyWithHeuristics(message);
  
  // Use LLM fallback only if heuristics are uncertain (general)
  if (classification === 'general' && messageLength > 5) {
    classification = await classifyWithLLM(message);
  }
  
  console.log('[responsePolicy] Classification:', classification);
  
  // Map classification to response policy
  let policy = {
    classification,
    tone: 'supportive',
    maxChars: 500,
    maxSentences: 6,
    allowBullets: true,
    includeKeyTakeaway: true,
    formatBlocks: true,
    safetyLevel: 'standard',
  };
  
  // Adjust based on classification
  switch (classification) {
    case 'simple_info':
      policy.maxChars = 300;
      policy.maxSentences = 4;
      policy.allowBullets = false;
      policy.includeKeyTakeaway = false;
      policy.tone = 'direct';
      break;
      
    case 'guidance':
      policy.maxChars = 600;
      policy.maxSentences = 8;
      policy.allowBullets = true;
      policy.includeKeyTakeaway = true;
      policy.tone = 'coach';
      break;
      
    case 'data_question':
      policy.maxChars = 400;
      policy.maxSentences = 5;
      policy.allowBullets = false;
      policy.includeKeyTakeaway = true;
      policy.tone = 'analytical';
      break;
      
    case 'general':
    default:
      policy.maxChars = 450;
      policy.maxSentences = 6;
      break;
  }
  
  // Apply user preference overrides
  if (userPref === 'brief') {
    policy.maxChars = Math.floor(policy.maxChars * 0.7);
    policy.maxSentences = Math.floor(policy.maxSentences * 0.7);
    policy.includeKeyTakeaway = false;
  } else if (userPref === 'detailed') {
    policy.maxChars = Math.floor(policy.maxChars * 1.5);
    policy.maxSentences = Math.floor(policy.maxSentences * 1.5);
  }
  
  return policy;
}

/**
 * Format prompt instructions based on policy
 * @param {Object} policy - Response policy from determineResponseStyle
 * @returns {string} Formatted instructions for system prompt
 */
function formatPromptInstructions(policy) {
  let instructions = [];
  
  // Tone guidance
  const toneMap = {
    direct: 'Be direct and factual',
    supportive: 'Be friendly and supportive',
    coach: 'Be encouraging and motivational',
    analytical: 'Be clear and analytical',
  };
  instructions.push(toneMap[policy.tone] || toneMap.supportive);
  
  // Length constraints
  instructions.push(`Keep your answer under ${policy.maxSentences} sentences`);
  
  // Formatting
  if (policy.formatBlocks) {
    instructions.push('Use short paragraphs (2-3 sentences max per block)');
    instructions.push('Add blank lines between sections');
  }
  
  if (policy.allowBullets) {
    instructions.push('Use bullet points (with - prefix) for lists');
  }
  
  if (policy.includeKeyTakeaway) {
    instructions.push('End with one "Key takeaway:" line summarizing the main point');
  }
  
  // Safety
  instructions.push('Never diagnose or say "you have X"');
  instructions.push('Use phrases like "your data suggests" or "looks like"');
  instructions.push('Recommend seeing a doctor if anything is concerning or unclear');
  
  return instructions.join('. ') + '.';
}

/**
 * Enforce response length constraints post-generation
 * @param {string} response - Generated response text
 * @param {Object} policy - Response policy
 * @returns {string} Trimmed or summarized response
 */
function enforceConstraints(response, policy) {
  if (!response) return response;
  
  // Check character limit
  if (response.length <= policy.maxChars) {
    return response;
  }
  
  // Truncate to last complete sentence within limit
  const truncated = response.substring(0, policy.maxChars);
  const lastPeriod = truncated.lastIndexOf('.');
  const lastQuestion = truncated.lastIndexOf('?');
  const lastExclamation = truncated.lastIndexOf('!');
  
  const cutPoint = Math.max(lastPeriod, lastQuestion, lastExclamation);
  
  if (cutPoint > policy.maxChars * 0.6) {
    // Good cut point found
    return truncated.substring(0, cutPoint + 1).trim();
  }
  
  // No good cut point, hard truncate and add ellipsis
  return truncated.trim() + '...';
}

module.exports = {
  determineResponseStyle,
  formatPromptInstructions,
  enforceConstraints,
  classifyWithHeuristics,
};

