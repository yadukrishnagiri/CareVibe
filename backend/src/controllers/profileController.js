const UserProfile = require('../models/UserProfile');

// Shared profile UID can be configured via environment
const DEMO_UID = process.env.DEMO_UID ?? 'demo-shared';
const SHOULD_SEED_DEMO_PROFILE = DEMO_UID === 'demo-shared';

// Auto-seed demo profile if it doesn't exist
async function ensureDemoProfile() {
  if (!SHOULD_SEED_DEMO_PROFILE) return;
  const profile = await UserProfile.findOne({ uid: DEMO_UID });
  if (profile) return; // Demo profile already exists

  console.log('Auto-seeding demo profile...');
  await UserProfile.create({
    uid: DEMO_UID,
    age: 28,
    gender: 'male',
    heightCm: 175,
  });
  console.log('Demo profile seeded');
}

exports.getMyProfile = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });
    
    // Ensure demo profile exists
    await ensureDemoProfile();
    
    // Return shared demo profile for ALL users
    const doc = await UserProfile.findOne({ uid: DEMO_UID }).lean();
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

    // Update shared demo profile for ALL users
    await UserProfile.updateOne(
      { uid: DEMO_UID },
      { uid: DEMO_UID, ...payload },
      { upsert: true }
    );
    const updated = await UserProfile.findOne({ uid: DEMO_UID }).lean();
    res.json({ ok: true, profile: updated });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update profile', details: e.message });
  }
};



