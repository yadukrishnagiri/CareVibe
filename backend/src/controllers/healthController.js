const HealthMetric = require('../models/HealthMetric');

exports.getMyMetrics = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });
    const days = Math.min(parseInt(req.query.days || '7', 10), 120);
    const items = await HealthMetric.find({ userUid: uid })
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



