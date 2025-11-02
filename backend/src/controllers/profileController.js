const UserProfile = require('../models/UserProfile');

exports.getMyProfile = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });
    const doc = await UserProfile.findOne({ uid }).lean();
    res.json(doc || {});
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch profile', details: e.message });
  }
};

exports.updateMyProfile = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const { age, gender, heightCm } = req.body || {};
    const payload = {};
    if (age !== undefined) payload.age = Number(age);
    if (gender !== undefined) payload.gender = String(gender);
    if (heightCm !== undefined) payload.heightCm = Number(heightCm);

    await UserProfile.updateOne(
      { uid },
      { uid, ...payload },
      { upsert: true }
    );
    const updated = await UserProfile.findOne({ uid }).lean();
    res.json({ ok: true, profile: updated });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update profile', details: e.message });
  }
};



