const HealthMetric = require('../models/HealthMetric');

// Shared data UID can be configured through environment (defaults to demo)
const DEMO_UID = process.env.DEMO_UID || 'demo-shared';
const SHOULD_SEED_DEMO_DATA = DEMO_UID === 'demo-shared';

// Auto-seed demo data if it doesn't exist
async function ensureDemoData() {
  if (!SHOULD_SEED_DEMO_DATA) return;
  const count = await HealthMetric.countDocuments({ userUid: DEMO_UID });
  if (count > 0) return; // Demo data already exists

  console.log('Auto-seeding demo data for shared UID:', DEMO_UID);
  const docs = [];
  const base = new Date();
  for (let i = 0; i < 30; i++) {
    const d = new Date(base);
    d.setDate(d.getDate() - i);
    const weight = 68 + Math.sin(i) * 0.8;
    const bmi = 22.5 + Math.cos(i) * 0.3;
    const steps = 5000 + (i % 3) * 1200;
    const sleep = 6.5 + ((i + 1) % 4) * 0.4;
    const rem = Math.max(1.0, sleep * 0.22 + ((i % 2) ? 0.2 : -0.1));
    docs.push({
      userUid: DEMO_UID,
      date: d,
      weightKg: Number(weight.toFixed(1)),
      remSleepHr: Number(rem.toFixed(1)),
      stressLevel: 30 + (i % 5) * 5,
      bmi: Number(bmi.toFixed(1)),
      sleepInterruptions: (i % 3),
      bloodPressureMmHg: '118/76',
      stepCount: steps,
      restingHeartRateBpm: 72 - (i % 3),
      spo2Percent: 97,
      exerciseDurationMin: 20 + (i % 4) * 10,
      bodyTemperatureC: 36.6,
      physicalActivityLevel: steps > 7000 ? 'active' : 'light',
      caloriesBurned: 1800 + (i % 4) * 120,
      sleepDurationHr: Number(sleep.toFixed(1)),
      smokingStatus: 'non-smoker',
      alcoholConsumption: 'none',
    });
  }
  await HealthMetric.insertMany(docs);
  console.log(`Demo data seeded: ${docs.length} records`);
}

exports.getMyMetrics = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });
    
    // Ensure demo data exists
    await ensureDemoData();
    
    // Build query with date range or day count
    const query = { userUid: DEMO_UID };
    
    // Priority 1: Use startDate and endDate if provided
    if (req.query.startDate && req.query.endDate) {
      const startDate = new Date(req.query.startDate);
      const endDate = new Date(req.query.endDate);
      
      // Validate dates
      if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
        return res.status(400).json({ error: 'Invalid date format. Use ISO 8601 (YYYY-MM-DD).' });
      }
      if (startDate > endDate) {
        return res.status(400).json({ error: 'startDate must be before or equal to endDate.' });
      }
      
      query.date = { $gte: startDate, $lte: endDate };
      
      const items = await HealthMetric.find(query)
        .sort({ date: -1 })
        .lean();
      return res.json(items);
    }
    
    // Priority 2: Fallback to day count (backward compatible)
    const days = Math.min(parseInt(req.query.days || '7', 10), 120);
    const items = await HealthMetric.find(query)
      .sort({ date: -1 })
      .limit(days)
      .lean();
    res.json(items);
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch metrics', details: e.message });
  }
};

exports.seedMyMetrics = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const count = Math.min(parseInt(req.body?.days || '7', 10), 30);
    const base = new Date();
    const docs = [];
    for (let i = 0; i < count; i++) {
      const d = new Date(base);
      d.setDate(d.getDate() - i);
      const weight = 68 + Math.sin(i) * 0.8;
      const bmi = 22.5 + Math.cos(i) * 0.3;
      const steps = 5000 + (i % 3) * 1200;
      const sleep = 6.5 + ((i + 1) % 4) * 0.4;
      const rem = Math.max(1.0, sleep * 0.22 + ((i % 2) ? 0.2 : -0.1));
      docs.push({
        userUid: uid,
        date: d,
        weightKg: Number(weight.toFixed(1)),
        remSleepHr: Number(rem.toFixed(1)),
        stressLevel: 30 + (i % 5) * 5,
        bmi: Number(bmi.toFixed(1)),
        sleepInterruptions: (i % 3),
        bloodPressureMmHg: '118/76',
        stepCount: steps,
        restingHeartRateBpm: 72 - (i % 3),
        spo2Percent: 97,
        exerciseDurationMin: 20 + (i % 4) * 10,
        bodyTemperatureC: 36.6,
        physicalActivityLevel: steps > 7000 ? 'active' : 'light',
        caloriesBurned: 1800 + (i % 4) * 120,
        sleepDurationHr: Number(sleep.toFixed(1)),
        smokingStatus: 'non-smoker',
        alcoholConsumption: 'none',
      });
    }

    await HealthMetric.deleteMany({ userUid: uid });
    await HealthMetric.insertMany(docs);
    res.json({ ok: true, inserted: docs.length });
  } catch (e) {
    res.status(500).json({ error: 'Failed to seed metrics', details: e.message });
  }
};

exports.analyzeMetrics = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    // Ensure demo data exists
    await ensureDemoData();

    // Get date range from query
    const { startDate, endDate } = req.query;
    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required' });
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      return res.status(400).json({ error: 'Invalid date format. Use ISO 8601 (YYYY-MM-DD).' });
    }

    // Fetch metrics for the date range
    const metrics = await HealthMetric.find({
      userUid: DEMO_UID,
      date: { $gte: start, $lte: end }
    })
      .sort({ date: -1 })
      .lean();

    if (metrics.length === 0) {
      return res.json({ summary: 'No health data available for the selected date range.' });
    }

    // Build data summary for AI
    const latest = metrics[0];
    const oldest = metrics[metrics.length - 1];
    
    // Calculate averages
    const avgSteps = metrics.reduce((sum, m) => sum + m.stepCount, 0) / metrics.length;
    const avgSleep = metrics.reduce((sum, m) => sum + m.sleepDurationHr, 0) / metrics.length;
    const avgStress = metrics.reduce((sum, m) => sum + (m.stressLevel || 0), 0) / metrics.length;
    const avgWeight = metrics.reduce((sum, m) => sum + (m.weightKg || 0), 0) / metrics.length;
    const avgHeartRate = metrics.reduce((sum, m) => sum + m.restingHeartRateBpm, 0) / metrics.length;

    // Format date range for prompt
    const dateRangeStr = `${start.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} - ${end.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`;

    const dataContext = `
Health Data Summary (${dateRangeStr}):
- Total days analyzed: ${metrics.length}
- Average daily steps: ${Math.round(avgSteps)}
- Average sleep duration: ${avgSleep.toFixed(1)} hours
- Average stress level: ${avgStress.toFixed(0)}/100
- Average weight: ${avgWeight.toFixed(1)} kg
- Average resting heart rate: ${Math.round(avgHeartRate)} bpm
- Latest blood pressure: ${latest.bloodPressureMmHg}
- Latest SpO2: ${latest.spo2Percent}%
- Smoking status: ${latest.smokingStatus}
- Alcohol consumption: ${latest.alcoholConsumption}
`.trim();

    // Call Groq API for analysis
    const Groq = require('groq-sdk');
    const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

    const systemPrompt = `You are a professional health analyst creating a concise wellness report for a PDF export. Analyze the provided health metrics and generate a 3-4 paragraph narrative summary. Include:
1. Overall wellness assessment
2. Key trends and patterns observed
3. Notable achievements or concerns
4. Brief actionable recommendations

Use professional but accessible language. DO NOT use any Markdown formatting (no asterisks, underscores, or special symbols). Write in plain text only. Keep the summary under 250 words.`;

    const completion = await groq.chat.completions.create({
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: `Analyze this health data and provide a professional wellness summary:\n\n${dataContext}` }
      ],
      model: 'llama-3.1-70b-versatile',
      temperature: 0.4,
      max_tokens: 400,
    });

    let summary = completion.choices[0]?.message?.content || 'Analysis unavailable.';

    // Strip any Markdown that might have slipped through
    summary = stripMarkdown(summary);

    res.json({ summary, dateRange: dateRangeStr, daysAnalyzed: metrics.length });
  } catch (e) {
    console.error('[analyzeMetrics] Error:', e.message);
    res.status(500).json({ error: 'Failed to analyze metrics', details: e.message });
  }
};

// Helper to strip Markdown formatting
function stripMarkdown(text) {
  if (!text) return '';
  let out = text;
  out = out.replace(/\*\*\*(.+?)\*\*\*/g, '$1');
  out = out.replace(/\*\*(.+?)\*\*/g, '$1');
  out = out.replace(/\*(.+?)\*/g, '$1');
  out = out.replace(/___(.+?)___/g, '$1');
  out = out.replace(/__(.+?)__/g, '$1');
  out = out.replace(/_(.+?)_/g, '$1');
  out = out.replace(/`([^`]+)`/g, '$1');
  out = out.replace(/^\s*[-*•]\s+/gm, '');
  out = out.replace(/^\s*\d+\.\s+/gm, '');
  out = out.replace(/^#+\s+/gm, '');
  out = out.replace(/\s{2,}/g, ' ');
  return out.trim();
}



