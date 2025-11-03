const admin = require('firebase-admin');

if (!admin.apps.length) {
  // Prefer FIREBASE_SERVICE_ACCOUNT env (JSON content). Fallback to GOOGLE_APPLICATION_CREDENTIALS file.
  const saJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (saJson) {
    try {
      const creds = JSON.parse(saJson);
      admin.initializeApp({ credential: admin.credential.cert(creds) });
    } catch (e) {
      // If JSON parse fails, fallback to application default so service can still start
      console.error('[firebaseAdmin] Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:', e.message);
      admin.initializeApp({ credential: admin.credential.applicationDefault() });
    }
  } else {
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
  }
}

module.exports = admin;


