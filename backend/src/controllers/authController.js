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


