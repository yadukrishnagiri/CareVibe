/**
 * Intent detection for health metric queries, symptom reports, goals, and follow-ups
 * Parses natural language user messages to identify specific data requests and user needs
 */

const { resolveDate } = require('./dateResolver');

// Symptom keywords mapped to categories and urgency
const SYMPTOM_KEYWORDS = {
  pain: { category: 'pain', urgency: 'moderate' },
  ache: { category: 'pain', urgency: 'low' },
  'stomach pain': { category: 'gastrointestinal', urgency: 'moderate' },
  'chest pain': { category: 'cardiac', urgency: 'urgent' },
  headache: { category: 'neurological', urgency: 'low' },
  migraine: { category: 'neurological', urgency: 'moderate' },
  dizzy: { category: 'neurological', urgency: 'moderate' },
  dizziness: { category: 'neurological', urgency: 'moderate' },
  nausea: { category: 'gastrointestinal', urgency: 'moderate' },
  vomiting: { category: 'gastrointestinal', urgency: 'moderate' },
  fever: { category: 'infection', urgency: 'moderate' },
  cough: { category: 'respiratory', urgency: 'low' },
  'shortness of breath': { category: 'respiratory', urgency: 'urgent' },
  fatigue: { category: 'general', urgency: 'low' },
  tired: { category: 'general', urgency: 'low' },
  exhausted: { category: 'general', urgency: 'moderate' },
  'difficulty breathing': { category: 'respiratory', urgency: 'urgent' },
  rash: { category: 'dermatological', urgency: 'low' },
  itching: { category: 'dermatological', urgency: 'low' },
  swelling: { category: 'general', urgency: 'moderate' },
  anxiety: { category: 'mental_health', urgency: 'moderate' },
  depression: { category: 'mental_health', urgency: 'moderate' },
  'panic attack': { category: 'mental_health', urgency: 'urgent' },
};

// Lifestyle goal keywords
const GOAL_KEYWORDS = {
  'lose weight': { goal: 'weight_loss', metrics: ['weightKg', 'bmi', 'caloriesBurned'] },
  'weight loss': { goal: 'weight_loss', metrics: ['weightKg', 'bmi', 'caloriesBurned'] },
  'gain weight': { goal: 'weight_gain', metrics: ['weightKg', 'bmi', 'caloriesBurned'] },
  'better sleep': { goal: 'improve_sleep', metrics: ['sleepDurationHr', 'remSleepHr', 'sleepInterruptions'] },
  'sleep better': { goal: 'improve_sleep', metrics: ['sleepDurationHr', 'remSleepHr', 'sleepInterruptions'] },
  'improve sleep': { goal: 'improve_sleep', metrics: ['sleepDurationHr', 'remSleepHr', 'sleepInterruptions'] },
  'more active': { goal: 'increase_activity', metrics: ['stepCount', 'exerciseDurationMin', 'caloriesBurned'] },
  'be active': { goal: 'increase_activity', metrics: ['stepCount', 'exerciseDurationMin', 'caloriesBurned'] },
  'get fit': { goal: 'increase_activity', metrics: ['stepCount', 'exerciseDurationMin', 'caloriesBurned'] },
  'reduce stress': { goal: 'lower_stress', metrics: ['stressLevel', 'sleepDurationHr'] },
  'manage stress': { goal: 'lower_stress', metrics: ['stressLevel', 'sleepDurationHr'] },
  'lower stress': { goal: 'lower_stress', metrics: ['stressLevel', 'sleepDurationHr'] },
};

// Follow-up reference phrases
const FOLLOWUP_PHRASES = [
  'then',
  'that day',
  'that date',
  'same day',
  'same time',
  'what about',
  'how about',
  'also',
];

// Greeting keywords
const GREETING_KEYWORDS = [
  'hi',
  'hello',
  'hey',
  'good morning',
  'good afternoon',
  'good evening',
  'greetings',
  'howdy',
  "what's up",
  'whats up',
];

// Metric name mappings (user-friendly → database field)
const METRIC_ALIASES = {
  weight: 'weightKg',
  'body weight': 'weightKg',
  'weight kg': 'weightKg',
  bmi: 'bmi',
  'body mass index': 'bmi',
  sleep: 'sleepDurationHr',
  'sleep duration': 'sleepDurationHr',
  'sleep hours': 'sleepDurationHr',
  'hours of sleep': 'sleepDurationHr',
  'rem sleep': 'remSleepHr',
  rem: 'remSleepHr',
  'sleep interruptions': 'sleepInterruptions',
  interruptions: 'sleepInterruptions',
  steps: 'stepCount',
  'step count': 'stepCount',
  'daily steps': 'stepCount',
  'steps count': 'stepCount',
  exercise: 'exerciseDurationMin',
  'exercise duration': 'exerciseDurationMin',
  'exercise time': 'exerciseDurationMin',
  'workout duration': 'exerciseDurationMin',
  stress: 'stressLevel',
  'stress level': 'stressLevel',
  'heart rate': 'restingHeartRateBpm',
  'resting heart rate': 'restingHeartRateBpm',
  hr: 'restingHeartRateBpm',
  bpm: 'restingHeartRateBpm',
  'blood pressure': 'bloodPressureMmHg',
  bp: 'bloodPressureMmHg',
  spo2: 'spo2Percent',
  'oxygen saturation': 'spo2Percent',
  'blood oxygen': 'spo2Percent',
  temperature: 'bodyTemperatureC',
  'body temperature': 'bodyTemperatureC',
  'body temp': 'bodyTemperatureC',
  calories: 'caloriesBurned',
  'calories burned': 'caloriesBurned',
  'activity level': 'physicalActivityLevel',
  smoking: 'smokingStatus',
  alcohol: 'alcoholConsumption',
};

// Extract metric name from user message
function extractMetric(text) {
  const lower = text.toLowerCase();
  for (const [alias, field] of Object.entries(METRIC_ALIASES)) {
    if (lower.includes(alias)) {
      return field;
    }
  }
  return null;
}

// Extract date from user message (YYYY-MM-DD format)
function extractDate(text) {
  // ISO date format: 2025-10-26
  const isoMatch = text.match(/\b(\d{4})-(\d{2})-(\d{2})\b/);
  if (isoMatch) {
    return isoMatch[0];
  }

  // Relative dates
  const lower = text.toLowerCase();
  const today = new Date();

  if (lower.includes('yesterday')) {
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    return yesterday.toISOString().split('T')[0];
  }

  if (lower.includes('today')) {
    return today.toISOString().split('T')[0];
  }

  // "N days ago"
  const daysAgoMatch = lower.match(/(\d+)\s*days?\s*ago/);
  if (daysAgoMatch) {
    const n = parseInt(daysAgoMatch[1], 10);
    const target = new Date(today);
    target.setDate(target.getDate() - n);
    return target.toISOString().split('T')[0];
  }

  // "last week", "last month" - approximate
  if (lower.includes('last week')) {
    const target = new Date(today);
    target.setDate(target.getDate() - 7);
    return target.toISOString().split('T')[0];
  }

  return null;
}

// Extract number of days for averages/trends
function extractDays(text) {
  const lower = text.toLowerCase();

  // "last N days"
  const lastDaysMatch = lower.match(/last\s+(\d+)\s+days?/);
  if (lastDaysMatch) return parseInt(lastDaysMatch[1], 10);

  // "past N days"
  const pastDaysMatch = lower.match(/past\s+(\d+)\s+days?/);
  if (pastDaysMatch) return parseInt(pastDaysMatch[1], 10);

  // "N day average"
  const avgMatch = lower.match(/(\d+)\s*day\s*average/);
  if (avgMatch) return parseInt(avgMatch[1], 10);

  // Common shortcuts
  if (lower.includes('last week') || lower.includes('past week')) return 7;
  if (lower.includes('last month') || lower.includes('past month')) return 30;
  if (lower.includes('last 2 weeks')) return 14;

  return null;
}

/**
 * Detect symptom mentions in message
 * @param {string} message - User's chat message
 * @returns {object|null} Symptom intent or null
 */
function detectSymptom(message) {
  if (!message || typeof message !== 'string') return null;
  const lower = message.toLowerCase();

  // Check for symptom keywords (longest match first)
  const sortedSymptoms = Object.entries(SYMPTOM_KEYWORDS).sort((a, b) => b[0].length - a[0].length);
  
  for (const [keyword, data] of sortedSymptoms) {
    if (lower.includes(keyword)) {
      return {
        type: 'symptom_report',
        symptom: keyword,
        category: data.category,
        urgency: data.urgency,
        raw: message,
      };
    }
  }
  return null;
}

/**
 * Detect lifestyle goal mentions in message
 * @param {string} message - User's chat message
 * @returns {object|null} Goal intent or null
 */
function detectGoal(message) {
  if (!message || typeof message !== 'string') return null;
  const lower = message.toLowerCase();

  for (const [phrase, data] of Object.entries(GOAL_KEYWORDS)) {
    if (lower.includes(phrase)) {
      return {
        type: 'lifestyle_goal',
        goal: data.goal,
        relevantMetrics: data.metrics,
        raw: message,
      };
    }
  }
  return null;
}

/**
 * Detect follow-up references in message
 * @param {string} message - User's chat message
 * @returns {boolean} True if message contains follow-up reference
 */
function isFollowUp(message) {
  if (!message || typeof message !== 'string') return false;
  const lower = message.toLowerCase();
  return FOLLOWUP_PHRASES.some(phrase => lower.includes(phrase));
}

/**
 * Detect greeting messages
 * @param {string} message - User's chat message
 * @returns {boolean} True if message is a greeting
 */
function isGreeting(message) {
  if (!message || typeof message !== 'string') return false;
  const lower = message.toLowerCase().trim();
  
  // Check if entire message is just a greeting (allow punctuation)
  const cleanMessage = lower.replace(/[!?.]/g, '').trim();
  if (GREETING_KEYWORDS.includes(cleanMessage)) return true;
  
  // Check if message starts with greeting and is short (< 20 chars)
  if (cleanMessage.length < 20) {
    for (const greeting of GREETING_KEYWORDS) {
      if (lower.startsWith(greeting)) return true;
    }
  }
  
  return false;
}

/**
 * Detect user intent from message (with context support)
 * @param {string} message - User's chat message
 * @param {object|null} context - Previous conversation context
 * @returns {Promise<object|null>} Intent object or null if no specific intent detected
 */
async function detectIntent(message, context = null) {
  if (!message || typeof message !== 'string') return null;

  const lower = message.toLowerCase();
  
  // Priority 0: Check for greetings
  if (isGreeting(message)) {
    return {
      type: 'greeting',
      raw: message,
    };
  }
  
  // Priority 1: Check for symptom reports
  const symptom = detectSymptom(message);
  if (symptom) return symptom;
  
  // Priority 2: Check for lifestyle goals
  const goal = detectGoal(message);
  if (goal) return goal;
  
  // Priority 3: Check for follow-up references using context
  if (context && isFollowUp(message)) {
    // Reuse date/metric from previous intent
    const metric = extractMetric(message) || context.lastMetric;
    const date = extractDate(message) || context.lastDate;
    
    if (metric && date) {
      return {
        type: 'metric_on_date',
        metric,
        date,
        raw: message,
        followUp: true,
      };
    } else if (metric) {
      return {
        type: 'latest_metric',
        metric,
        raw: message,
        followUp: true,
      };
    }
  }

  const metric = extractMetric(message);

  // Intent: latest metric
  if (
    metric &&
    (lower.includes('latest') ||
      lower.includes('current') ||
      lower.includes('today') ||
      lower.includes('most recent') ||
      lower.includes("today's"))
  ) {
    return {
      type: 'latest_metric',
      metric,
      raw: message,
    };
  }

  // Intent: metric on specific date or relative date using dateResolver
  let dateResolved = null;
  const simpleDateMatch = extractDate(message); // Try simple patterns first
  
  if (metric && simpleDateMatch) {
    return {
      type: 'metric_on_date',
      metric,
      date: simpleDateMatch,
      raw: message,
    };
  }
  
  // Try advanced date resolution for natural language
  if (metric) {
    dateResolved = await resolveDate(message);
    if (dateResolved && dateResolved.kind === 'point') {
      return {
        type: 'metric_on_date',
        metric,
        date: dateResolved.start.toISOString().split('T')[0],
        raw: message,
        dateStrategy: dateResolved.strategy,
      };
    } else if (dateResolved && dateResolved.kind === 'range') {
      return {
        type: 'metric_in_range',
        metric,
        startDate: dateResolved.start.toISOString().split('T')[0],
        endDate: dateResolved.end.toISOString().split('T')[0],
        raw: message,
        dateStrategy: dateResolved.strategy,
      };
    }
  }

  // Intent: average over N days
  const days = extractDays(message);
  if (
    metric &&
    days &&
    (lower.includes('average') || lower.includes('avg') || lower.includes('mean'))
  ) {
    return {
      type: 'metric_average',
      metric,
      days,
      raw: message,
    };
  }

  // Intent: trend analysis
  if (
    metric &&
    (lower.includes('trend') ||
      lower.includes('trending') ||
      lower.includes('increasing') ||
      lower.includes('decreasing') ||
      lower.includes('rising') ||
      lower.includes('falling') ||
      lower.includes('going up') ||
      lower.includes('going down') ||
      lower.includes('change'))
  ) {
    const trendDays = days || 30; // default to 30 days if not specified
    return {
      type: 'metric_trend',
      metric,
      days: trendDays,
      raw: message,
    };
  }

  return null;
}

module.exports = {
  detectIntent,
  detectSymptom,
  detectGoal,
  isFollowUp,
  isGreeting,
  extractMetric,
  extractDate,
  extractDays,
  METRIC_ALIASES,
  SYMPTOM_KEYWORDS,
  GOAL_KEYWORDS,
  GREETING_KEYWORDS,
};

