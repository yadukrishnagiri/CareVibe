const axios = require('axios');
const HealthMetric = require('../models/HealthMetric');
const UserProfile = require('../models/UserProfile');
const { detectIntent } = require('../utils/chatIntents');
const metricsService = require('../services/metricsService');
const templateBuilder = require('../services/templateBuilder');
const { determineResponseStyle, formatPromptInstructions, enforceConstraints } = require('../utils/responsePolicy');

// In-memory per-user conversation memory (demo use only)
// Key: user uid, Value: Array of { role: 'user'|'assistant', content: string }
const conversations = new Map();
const advancedConsent = new Map();

// Context memory for follow-ups and personalization
// Key: user uid, Value: { lastIntent, lastMetric, lastDate, lastGoal, lastSymptom, timestamp }
const sessionContext = new Map();

const DEFAULT_SHARED_UID = process.env.DEMO_UID || 'demo-shared';
let cachedSharedUid;

// Helper to update session context
function updateSessionContext(uid, intent) {
  const existing = sessionContext.get(uid) || {};
  const updated = {
    ...existing,
    lastIntent: intent?.type,
    timestamp: Date.now(),
  };

  if (intent?.metric) updated.lastMetric = intent.metric;
  if (intent?.date) updated.lastDate = intent.date;
  if (intent?.goal) updated.lastGoal = intent.goal;
  if (intent?.symptom) updated.lastSymptom = intent.symptom;
  if (intent?.category) updated.lastSymptomCategory = intent.category;
  if (intent?.urgency) updated.lastUrgency = intent.urgency;

  sessionContext.set(uid, updated);
}

// Helper to get session context (pruned if stale)
function getSessionContext(uid) {
  const context = sessionContext.get(uid);
  if (!context) return null;

  // Expire context after 10 minutes of inactivity
  const TEN_MINUTES = 10 * 60 * 1000;
  if (Date.now() - context.timestamp > TEN_MINUTES) {
    sessionContext.delete(uid);
    return null;
  }

  return context;
}

function enforceBriefStyle(text) {
  // Updated to allow longer, more structured responses
  if (!text) return '';
  let out = String(text).trim();
  
  // Remove excessive length limit - allow up to 1500 chars for detailed responses
  if (out.length > 1500) {
    out = out.slice(0, 1500).replace(/[^\w)\]}]*$/, '').trim();
  }
  return out;
}

function stripMarkdown(text) {
  if (!text) return '';
  let out = text;
  
  // Remove bold/italic with asterisks and underscores
  out = out.replace(/\*\*\*(.+?)\*\*\*/g, '$1'); // bold+italic
  out = out.replace(/\*\*(.+?)\*\*/g, '$1');      // bold
  out = out.replace(/\*(.+?)\*/g, '$1');          // italic
  out = out.replace(/___(.+?)___/g, '$1');        // bold+italic underscore
  out = out.replace(/__(.+?)__/g, '$1');          // bold underscore
  out = out.replace(/_(.+?)_/g, '$1');            // italic underscore
  
  // Remove inline code ticks
  out = out.replace(/`([^`]+)`/g, '$1');
  
  // PRESERVE bullet points with hyphen (- ) and numbered lists (1. 2. etc)
  // Only remove other bullet markers like * and •
  out = out.replace(/^\s*[*•]\s+/gm, '- '); // Convert * and • to -
  
  // Remove heading markers
  out = out.replace(/^#+\s+/gm, '');
  
  // Clean up extra spaces (but preserve single newlines for formatting)
  out = out.replace(/ {2,}/g, ' ');
  
  return out.trim();
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

async function resolveSharedUid() {
  if (cachedSharedUid) return cachedSharedUid;

  if (DEFAULT_SHARED_UID) {
    const existing = await HealthMetric.findOne({ userUid: DEFAULT_SHARED_UID }).select({ userUid: 1 }).lean();
    if (existing?.userUid) {
      cachedSharedUid = existing.userUid;
      return cachedSharedUid;
    }
  }

  const fallback = await HealthMetric.findOne({}).sort({ date: -1 }).select({ userUid: 1 }).lean();
  if (fallback?.userUid) {
    cachedSharedUid = fallback.userUid;
    return cachedSharedUid;
  }

  cachedSharedUid = DEFAULT_SHARED_UID;
  return cachedSharedUid;
}

function formatNumber(value, decimals = 1) {
  if (value === null || value === undefined) return null;
  const num = Number(value);
  if (!Number.isFinite(num)) return null;
  return num.toFixed(decimals);
}

function formatInteger(value) {
  if (value === null || value === undefined) return null;
  const num = Number(value);
  if (!Number.isFinite(num)) return null;
  return Math.round(num).toLocaleString('en-US');
}

function formatDate(value) {
  if (!value) return 'recently';
  try {
    return new Date(value).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  } catch (_err) {
    return new Date(value).toISOString().slice(0, 10);
  }
}

function average(values) {
  if (!values.length) return null;
  const sum = values.reduce((acc, val) => acc + val, 0);
  return sum / values.length;
}

function summarizeNumericMetric(metrics, field, options) {
  const { label, unit = '', decimals = 1, trendThreshold = 0.3 } = options;
  const values = metrics
    .map((m) => Number(m?.[field]))
    .filter((val) => Number.isFinite(val));
  if (!values.length) return null;

  const latestVal = values[0];
  const oldestVal = values[values.length - 1];
  const avgVal = average(values);
  const minVal = Math.min(...values);
  const maxVal = Math.max(...values);
  let trend = 'stable';
  if (Number.isFinite(latestVal) && Number.isFinite(oldestVal)) {
    const delta = latestVal - oldestVal;
    if (Math.abs(delta) > trendThreshold) {
      trend = delta > 0 ? 'rising' : 'declining';
    }
  }

  const format = (val) => formatNumber(val, decimals);
  const latestText = format(latestVal);
  const avgText = format(avgVal);
  const minText = format(minVal);
  const maxText = format(maxVal);
  if (!latestText || !avgText || !minText || !maxText) return null;

  const parts = [
    `${label}: latest ${latestText}${unit}`,
    `avg ${avgText}${unit}`,
    `range ${minText}-${maxText}${unit}`,
    `(${trend})`,
  ];
  return parts.join(', ');
}

function summarizeActivityLevel(metrics) {
  const levels = metrics
    .map((m) => m?.physicalActivityLevel)
    .filter((val) => typeof val === 'string' && val.trim().length > 0);
  if (!levels.length) return null;
  const counts = new Map();
  for (const level of levels) counts.set(level, (counts.get(level) || 0) + 1);
  let top = levels[0];
  for (const [level, count] of counts.entries()) {
    if ((counts.get(top) || 0) < count) top = level;
  }
  return `${top} (${levels.length} entries)`;
}

async function buildBasicHealthContext(sharedUid) {
  try {
    const [profile, latestMetric] = await Promise.all([
      UserProfile.findOne({ uid: sharedUid }).lean(),
      HealthMetric.findOne({ userUid: sharedUid }).sort({ date: -1 }).lean(),
    ]);

    if (!profile && !latestMetric) return null;

    const profileParts = [];
    if (Number.isFinite(profile?.age)) profileParts.push(`${profile.age}-year-old`);
    if (profile?.gender) profileParts.push(profile.gender);
    if (Number.isFinite(profile?.heightCm)) profileParts.push(`${profile.heightCm}cm tall`);
    const profileSummary = profileParts.length
      ? `User profile: ${profileParts.join(' ')}.`
      : 'User profile: age/gender/height not provided.';

    if (!latestMetric) return profileSummary;

    const snapshotParts = [];
    const weight = formatNumber(latestMetric.weightKg);
    const bmi = formatNumber(latestMetric.bmi);
    if (weight) snapshotParts.push(`weight ${weight}kg${bmi ? ` (BMI ${bmi})` : ''}`);
    const sleep = formatNumber(latestMetric.sleepDurationHr);
    const rem = formatNumber(latestMetric.remSleepHr);
    if (sleep) {
      snapshotParts.push(`sleep ${sleep}h${rem ? ` (REM ${rem}h)` : ''}`);
      const interruptions = formatInteger(latestMetric.sleepInterruptions);
      if (interruptions !== null) snapshotParts.push(`${interruptions} sleep interruptions`);
    }
    const steps = formatInteger(latestMetric.stepCount);
    if (steps) snapshotParts.push(`${steps} steps`);
    const exercise = formatInteger(latestMetric.exerciseDurationMin);
    if (exercise) snapshotParts.push(`${exercise} min exercise`);
    const stress = formatInteger(latestMetric.stressLevel);
    if (stress) snapshotParts.push(`stress level ${stress}`);
    const heart = formatInteger(latestMetric.restingHeartRateBpm);
    if (heart) snapshotParts.push(`resting heart rate ${heart} bpm`);
    if (latestMetric.bloodPressureMmHg) snapshotParts.push(`BP ${latestMetric.bloodPressureMmHg}`);
    if (Number.isFinite(latestMetric.spo2Percent)) snapshotParts.push(`SpO₂ ${formatInteger(latestMetric.spo2Percent)}%`);
    if (Number.isFinite(latestMetric.bodyTemperatureC)) snapshotParts.push(`temperature ${formatNumber(latestMetric.bodyTemperatureC)}°C`);
    if (Number.isFinite(latestMetric.caloriesBurned)) snapshotParts.push(`${formatInteger(latestMetric.caloriesBurned)} kcal burned`);
    if (latestMetric.physicalActivityLevel)
      snapshotParts.push(`activity level ${latestMetric.physicalActivityLevel}`);
    if (latestMetric.smokingStatus) snapshotParts.push(`smoking: ${latestMetric.smokingStatus}`);
    if (latestMetric.alcoholConsumption) snapshotParts.push(`alcohol: ${latestMetric.alcoholConsumption}`);

    const dateLabel = formatDate(latestMetric.date);
    const snapshotSummary = snapshotParts.length
      ? `Latest day (${dateLabel}): ${snapshotParts.join(', ')}.`
      : `Latest day (${dateLabel}): no vitals recorded.`;

    return `${profileSummary}\n${snapshotSummary}`;
  } catch (err) {
    console.error('[chatWithAI] Failed to build basic health context:', err.message);
    return null;
  }
}

async function buildAdvancedHealthContext(sharedUid) {
  try {
    const metrics = await HealthMetric.find({ userUid: sharedUid })
      .sort({ date: -1 })
      .limit(100)
      .lean();
    if (!metrics.length) return null;

    const lines = [];

    const weightLine = summarizeNumericMetric(metrics, 'weightKg', {
      label: 'Weight',
      unit: 'kg',
      decimals: 1,
      trendThreshold: 0.4,
    });
    const bmiLine = summarizeNumericMetric(metrics, 'bmi', {
      label: 'BMI',
      decimals: 1,
      trendThreshold: 0.2,
    });
    if (weightLine || bmiLine) {
      lines.push(`- ${[weightLine, bmiLine].filter(Boolean).join(' | ')}`);
    }

    const sleepLine = summarizeNumericMetric(metrics, 'sleepDurationHr', {
      label: 'Sleep duration',
      unit: 'h',
      decimals: 1,
      trendThreshold: 0.4,
    });
    const remLine = summarizeNumericMetric(metrics, 'remSleepHr', {
      label: 'REM sleep',
      unit: 'h',
      decimals: 1,
      trendThreshold: 0.3,
    });
    const interruptions = summarizeNumericMetric(metrics, 'sleepInterruptions', {
      label: 'Sleep interruptions',
      unit: '',
      decimals: 0,
      trendThreshold: 0.6,
    });
    if (sleepLine || remLine || interruptions) {
      lines.push(`- ${[sleepLine, remLine, interruptions].filter(Boolean).join(' | ')}`);
    }

    const stepsLine = summarizeNumericMetric(metrics, 'stepCount', {
      label: 'Daily steps',
      unit: '',
      decimals: 0,
      trendThreshold: 400,
    });
    const exerciseLine = summarizeNumericMetric(metrics, 'exerciseDurationMin', {
      label: 'Exercise',
      unit: ' min',
      decimals: 0,
      trendThreshold: 5,
    });
    const caloriesLine = summarizeNumericMetric(metrics, 'caloriesBurned', {
      label: 'Calories burned',
      unit: '',
      decimals: 0,
      trendThreshold: 80,
    });
    const activityLevel = summarizeActivityLevel(metrics);
    const activityLine = activityLevel ? `Activity level mode: ${activityLevel}` : null;
    if (stepsLine || exerciseLine || caloriesLine || activityLine) {
      lines.push(`- ${[stepsLine, exerciseLine, caloriesLine, activityLine].filter(Boolean).join(' | ')}`);
    }

    const heartLine = summarizeNumericMetric(metrics, 'restingHeartRateBpm', {
      label: 'Resting heart rate',
      unit: ' bpm',
      decimals: 0,
      trendThreshold: 2,
    });
    const spoLine = summarizeNumericMetric(metrics, 'spo2Percent', {
      label: 'SpO₂',
      unit: '%',
      decimals: 0,
      trendThreshold: 1,
    });
    const tempLine = summarizeNumericMetric(metrics, 'bodyTemperatureC', {
      label: 'Body temperature',
      unit: '°C',
      decimals: 1,
      trendThreshold: 0.2,
    });
    const bpLatest = metrics.find((m) => m?.bloodPressureMmHg)?.bloodPressureMmHg;
    const bpLine = bpLatest ? `Blood pressure readings mostly ${bpLatest}` : null;
    if (heartLine || spoLine || tempLine || bpLine) {
      lines.push(`- ${[heartLine, spoLine, tempLine, bpLine].filter(Boolean).join(' | ')}`);
    }

    const stressLine = summarizeNumericMetric(metrics, 'stressLevel', {
      label: 'Stress level',
      unit: '',
      decimals: 0,
      trendThreshold: 3,
    });
    if (stressLine) lines.push(`- ${stressLine}`);

    const latest = metrics[0] || {};
    const lifestyleParts = [];
    if (latest.smokingStatus) lifestyleParts.push(`smoking: ${latest.smokingStatus}`);
    if (latest.alcoholConsumption) lifestyleParts.push(`alcohol: ${latest.alcoholConsumption}`);
    if (lifestyleParts.length) lines.push(`- Lifestyle: ${lifestyleParts.join(' | ')}`);

    return lines.length ? lines.join('\n') : null;
  } catch (err) {
    console.error('[chatWithAI] Failed to build advanced health context:', err.message);
    return null;
  }
}

function detectConsent(message, history) {
  if (!message) return false;
  const text = message.toLowerCase();
  const has100Day = text.includes('100') && text.includes('day');
  const hasAnalysisKeyword =
    text.includes('analy') ||
    text.includes('pattern') ||
    text.includes('trend') ||
    text.includes('history');
  const hasPositive =
    text.includes('yes') ||
    text.includes('sure') ||
    text.includes('ok') ||
    text.includes('okay') ||
    text.includes('go ahead') ||
    text.includes('please') ||
    text.includes('do it') ||
    text.includes('sounds good');

  if (has100Day && (hasPositive || hasAnalysisKeyword)) return true;
  if (hasAnalysisKeyword && hasPositive) return true;

  const lastAssistant = [...history]
    .reverse()
    .find((msg) => msg?.role === 'assistant')
    ?.content?.toLowerCase?.();
  if (lastAssistant) {
    const assistantAskedPermission =
      lastAssistant.includes('analy') ||
      lastAssistant.includes('pattern') ||
      lastAssistant.includes('trend') ||
      lastAssistant.includes('100');
    if (assistantAskedPermission && hasPositive) return true;
  }

  if (text.includes('use all data') || text.includes('full history') || text.includes('entire history')) return true;
  return false;
}

function detectDenial(message, history) {
  if (!message) return false;
  const text = message.toLowerCase();
  const hardStopKeywords = ['stop analyzing', 'stop analysis', 'cancel analysis', 'no more trends', 'no thanks'];
  if (hardStopKeywords.some((phrase) => text.includes(phrase))) return true;

  const containsNegative = text.includes('no') || text.includes('not now') || text.includes("don't") || text.includes('dont');
  if (!containsNegative) return false;

  const referencesAnalysis =
    text.includes('analy') || text.includes('pattern') || text.includes('trend') || text.includes('100');
  if (referencesAnalysis) return true;

  const lastAssistant = [...history]
    .reverse()
    .find((msg) => msg?.role === 'assistant')
    ?.content?.toLowerCase?.();
  if (lastAssistant && (lastAssistant.includes('analy') || lastAssistant.includes('trend') || lastAssistant.includes('100'))) {
    return true;
  }

  return false;
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
  const trimmedMessage = message.trim();

  if (detectDenial(trimmedMessage, history)) {
    advancedConsent.set(uid, false);
  } else if (detectConsent(trimmedMessage, history)) {
    advancedConsent.set(uid, true);
  }

  const allowAdvanced = advancedConsent.get(uid) === true;

  let sharedUid = DEFAULT_SHARED_UID;
  try {
    sharedUid = await resolveSharedUid();
  } catch (err) {
    console.warn('[chatWithAI] Failed to resolve shared UID:', err.message);
  }

  // Retrieve session context for follow-up support
  const context = getSessionContext(uid);
  if (context) {
    console.log('[chatWithAI] Using session context:', JSON.stringify(context));
  }
  
  // Detect specific data intents before building general context (pass context for follow-ups)
  const intent = detectIntent(trimmedMessage, context);
  let intentResult = null;
  
  // Update session context with new intent
  if (intent) {
    updateSessionContext(uid, intent);
    console.log('[chatWithAI] Updated session context for UID:', uid);
  }

  if (intent) {
    console.log('[chatWithAI] Detected intent:', intent.type, 'for metric:', intent.metric);
    console.log('[chatWithAI] Using shared UID:', sharedUid);
    console.log('[chatWithAI] Intent details:', JSON.stringify(intent));
    try {
      switch (intent.type) {
        case 'latest_metric':
          intentResult = await metricsService.getLatestMetric(intent.metric, sharedUid);
          console.log('[chatWithAI] Latest metric result:', intentResult ? 'Found' : 'NULL');
          if (intentResult) {
            intentResult.type = 'latest_metric';
            intentResult.metric = intent.metric;
          }
          break;
        case 'metric_on_date':
          // Try nearest-day query with 3-day window
          intentResult = await metricsService.getMetricNearestToDate(intent.metric, intent.date, sharedUid, 3);
          console.log('[chatWithAI] Metric on date result:', intentResult ? `Found (offset: ${intentResult.offset} days)` : 'NULL');
          if (intentResult) {
            intentResult.type = 'metric_on_date';
            intentResult.metric = intent.metric;
            intentResult.requestedDate = intent.date;
          }
          break;
        case 'metric_in_range':
          // Handle date range queries (new intent type from dateResolver)
          intentResult = await metricsService.getMetricInRange(intent.metric, intent.startDate, intent.endDate, sharedUid);
          console.log('[chatWithAI] Metric in range result:', intentResult ? `Found ${intentResult.length} days` : 'NULL');
          if (intentResult && intentResult.length > 0) {
            // Compute aggregate for template
            const values = intentResult.map(r => Number(r.value)).filter(v => Number.isFinite(v));
            const avg = values.reduce((sum, v) => sum + v, 0) / values.length;
            intentResult = {
              type: 'metric_in_range',
              metric: intent.metric,
              startDate: intent.startDate,
              endDate: intent.endDate,
              value: avg,
              count: values.length,
              min: Math.min(...values),
              max: Math.max(...values),
            };
          }
          break;
        case 'metric_average':
          intentResult = await metricsService.getMetricAverage(intent.metric, intent.days, sharedUid);
          console.log('[chatWithAI] Average metric result:', intentResult ? 'Found' : 'NULL');
          if (intentResult) {
            intentResult.type = 'metric_average';
            intentResult.metric = intent.metric;
          }
          break;
        case 'metric_trend':
          intentResult = await metricsService.getMetricTrend(intent.metric, intent.days, sharedUid);
          console.log('[chatWithAI] Trend metric result:', intentResult ? 'Found' : 'NULL');
          if (intentResult) {
            intentResult.type = 'metric_trend';
            intentResult.metric = intent.metric;
          }
          break;
      }
      if (intentResult) {
        console.log('[chatWithAI] Intent result data:', JSON.stringify(intentResult));
      }
    } catch (err) {
      console.error('[chatWithAI] Error processing intent:', err.message);
    }
  }

  let basicContext = null;
  let advancedContext = null;
  try {
    const basicPromise = buildBasicHealthContext(sharedUid);
    const advancedPromise = allowAdvanced ? buildAdvancedHealthContext(sharedUid) : Promise.resolve(null);
    [basicContext, advancedContext] = await Promise.all([basicPromise, advancedPromise]);
  } catch (err) {
    console.error('[chatWithAI] Error building health context:', err.message);
  }

  // Determine response style based on message type
  const userPref = req.query.verbosity || req.headers['x-verbosity'] || null;
  const policy = await determineResponseStyle(trimmedMessage, trimmedMessage.length, Boolean(intentResult), userPref);
  const dynamicInstructions = formatPromptInstructions(policy);
  
  console.log('[chatWithAI] Response policy:', policy.classification, 'maxChars:', policy.maxChars);

  const basePrompt =
    `You are CareVibe, a wellness assistant. ${dynamicInstructions}

FORMATTING RULES:
- Plain text only. Never use ** or __ for bold/italic.
- You MAY use bullet points with - prefix for lists.
- You MAY use numbered lists (1. 2. 3.).
- Add blank lines between sections for readability.
- Use clear wording for emphasis instead of styling.

When a "Core Response" template is provided, use its exact facts and numbers. Expand naturally with context and recommendations.

Few-shot examples:

User: "What was my BMI a month ago?"
Assistant: "Your BMI a month ago was 22.8, which falls within the normal weight range. This is healthy. To maintain it, keep up with balanced meals and regular activity."

User: "I have a headache today."
Assistant: "Headaches can come from dehydration, stress, or lack of sleep.

Try these steps:
- Drink water
- Rest in a quiet room
- Apply a cool compress

If it persists for more than a day or worsens, please consult a healthcare professional.

Key takeaway: Start with hydration and rest; see a doctor if symptoms continue."

User: "Help me lose weight."
Assistant: "Weight loss needs balanced nutrition and regular activity. Based on your data, I can give personalized tips.

Start with:
- Track daily calories
- Aim for a moderate calorie deficit
- Eat more vegetables, lean proteins, and whole grains
- Add 30 minutes of walking most days

Would you like me to analyze your activity trends over the past few months?

Key takeaway: Small, consistent changes in diet and activity lead to sustainable weight loss."`;

  const contextSegments = [];
  if (basicContext) {
    contextSegments.push(`Today\'s snapshot:\n${basicContext}`);
  } else {
    contextSegments.push("Today's snapshot is unavailable in the database. Offer guidance with general best practices.");
  }

  if (allowAdvanced) {
    if (advancedContext) {
      contextSegments.push(`100-day trends:\n${advancedContext}`);
    } else {
      contextSegments.push('100-day trends were requested, but not enough data was found.');
    }
  } else {
    contextSegments.push(
      'Advanced trends are not supplied yet. If deeper insight would help, ask briefly for permission to analyze the past 100 days before proceeding.'
    );
  }

  // Handle greetings with short response - bypass full LLM call
  if (intent && intent.type === 'greeting') {
    console.log('[chatWithAI] Detected greeting, returning short response');
    const greetingReply = 'Hi! How can I help with your symptoms or wellness today?';
    
    // Update conversation memory
    const updated = [
      ...history,
      { role: 'user', content: trimmedMessage },
      { role: 'assistant', content: greetingReply },
    ];
    const maxMessages = 24;
    const pruned = updated.length > maxMessages ? updated.slice(updated.length - maxMessages) : updated;
    conversations.set(uid, pruned);
    
    return res.json({ reply: greetingReply });
  }

  // Build deterministic templates for intents
  let deterministicTemplate = null;
  if (intentResult) {
    switch (intentResult.type) {
      case 'latest_metric':
        deterministicTemplate = templateBuilder.buildLatestMetricTemplate(intentResult, intentResult.metric);
        break;
      case 'metric_on_date':
        deterministicTemplate = templateBuilder.buildMetricOnDateTemplate(
          intentResult,
          intentResult.metric,
          intentResult.requestedDate
        );
        break;
      case 'metric_average':
        deterministicTemplate = templateBuilder.buildMetricAverageTemplate(intentResult, intentResult.metric);
        break;
      case 'metric_trend':
        deterministicTemplate = templateBuilder.buildMetricTrendTemplate(intentResult, intentResult.metric);
        break;
    }
    console.log('[chatWithAI] Generated template for intent:', intentResult.type);
  } else if (intent) {
    // Handle special intents without metric data
    if (intent.type === 'symptom_report') {
      deterministicTemplate = templateBuilder.buildSymptomTemplate(intent);
      console.log('[chatWithAI] Generated symptom template for:', intent.symptom, 'urgency:', intent.urgency);
    } else if (intent.type === 'lifestyle_goal') {
      deterministicTemplate = templateBuilder.buildGoalTemplate(intent);
      console.log('[chatWithAI] Generated goal template for:', intent.goal);
    } else if (intent.metric) {
      deterministicTemplate = `I could not find data for ${intent.metric}. That information may be outside the available data range.`;
      console.log('[chatWithAI] No data found for metric:', intent.metric);
    }
  }

  // Add deterministic template to context
  if (deterministicTemplate) {
    contextSegments.unshift(
      `=== Core Response (use exact wording, add context naturally) ===\n${deterministicTemplate}`
    );
    console.log('[chatWithAI] Injected deterministic template into prompt');
  }

  const systemMessage = `${basePrompt}\n\nPatient data context:\n${contextSegments.join('\n\n')}`;

  const messages = [
    { role: 'system', content: systemMessage },
    ...history,
    { role: 'user', content: trimmedMessage },
  ];

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
          temperature: 0.3,
          max_tokens: 600,
          messages: [
            ...messages,
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

      // Apply policy-based formatting
      let formatted = stripMarkdown(reply);
      formatted = sanitizePhrases(formatted);
      formatted = enforceConstraints(formatted, policy);

      // Update conversation memory: keep last 12 turns (24 messages)
      const updated = [
        ...history,
        { role: 'user', content: trimmedMessage },
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


