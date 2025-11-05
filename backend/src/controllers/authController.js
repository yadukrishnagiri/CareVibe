const admin = require('../utils/firebaseAdmin');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

exports.verifyFirebaseAndIssueJwt = async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ error: 'idToken is required' });
    const decoded = await admin.auth().verifyIdToken(idToken);
    const { uid, email, name } = decoded;
    await User.updateOne(
      { uid },
      { uid, email: email || null, displayName: name || null },
      { upsert: true }
    );
    const token = jwt.sign({ uid, email: email || undefined }, process.env.JWT_SECRET, {
      expiresIn: '1h',
    });
    res.json({ token });
  } catch (e) {
    res.status(401).json({ error: 'Firebase verification failed', details: e.message });
  }
};

// Demo authentication endpoint (bypasses Firebase)
exports.demoAuth = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Demo credentials check
    const DEMO_EMAIL = 'yadukrishnagirikg@gmail.com';
    const DEMO_PASSWORD = '123456789';
    
    if (email !== DEMO_EMAIL || password !== DEMO_PASSWORD) {
      return res.status(401).json({ error: 'Invalid demo credentials' });
    }
    
    // Create a demo UID
    const demoUid = 'demo-user-' + DEMO_EMAIL.replace(/[^a-zA-Z0-9]/g, '');
    
    // Update or create demo user
    await User.updateOne(
      { uid: demoUid },
      { uid: demoUid, email: DEMO_EMAIL, displayName: 'Demo User' },
      { upsert: true }
    );
    
    // Issue JWT token
    const token = jwt.sign(
      { uid: demoUid, email: DEMO_EMAIL, demo: true },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.json({
      token,
      demo: true,
      user: {
        uid: demoUid,
        email: DEMO_EMAIL,
        displayName: 'Demo User',
      },
    });
  } catch (e) {
    res.status(500).json({ error: 'Demo auth failed', details: e.message });
  }
};


