const admin = require('firebase-admin');

if (!admin.apps.length) {
  // Relies on GOOGLE_APPLICATION_CREDENTIALS env var
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

module.exports = admin;


