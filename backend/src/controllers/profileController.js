const UserProfile = require('../models/UserProfile');
const fs = require('fs');
const path = require('path');

// Shared profile UID can be configured via environment
const DEMO_UID = process.env.DEMO_UID || 'demo-shared';
const SHOULD_SEED_DEMO_PROFILE = DEMO_UID === 'demo-shared';

// Auto-seed demo profile if it doesn't exist
async function ensureDemoProfile() {
  if (!SHOULD_SEED_DEMO_PROFILE) return;
  const profile = await UserProfile.findOne({ uid: DEMO_UID });
  if (profile) return; // Demo profile already exists

  console.log('Auto-seeding demo profile for shared UID: [redacted]');
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

exports.exportProfileTemplate = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const templateName = req.query.template || req.body.template;
    if (!templateName) {
      return res.status(400).json({ error: 'Template name is required' });
    }

    // Validate and sanitize template name to prevent path injection
    // Only allow alphanumeric characters, hyphens, underscores, and dots (for file extensions)
    const sanitizedTemplateName = String(templateName).replace(/[^a-zA-Z0-9._-]/g, '');
    
    // Reject if sanitization removed all characters or if original contained path traversal
    if (!sanitizedTemplateName || sanitizedTemplateName !== templateName) {
      return res.status(400).json({ error: 'Invalid template name. Only alphanumeric characters, dots, hyphens, and underscores are allowed.' });
    }

    // Reject path traversal sequences
    if (sanitizedTemplateName.includes('..') || sanitizedTemplateName.includes('/') || sanitizedTemplateName.includes('\\')) {
      return res.status(400).json({ error: 'Invalid template name. Path traversal sequences are not allowed.' });
    }

    // Get the absolute path of the templates directory
    const templatesDir = path.resolve(__dirname, '../../templates');
    
    // Construct the file path using sanitized input
    const templatePath = path.join(templatesDir, sanitizedTemplateName);
    
    // Check if file exists before resolving real path
    if (!fs.existsSync(templatePath)) {
      return res.status(404).json({ error: 'Template not found.' });
    }

    // Check if it's actually a file (not a directory) before resolving symlinks
    const stats = fs.statSync(templatePath);
    if (!stats.isFile()) {
      return res.status(400).json({ error: 'Template path is not a file.' });
    }

    // CRITICAL SECURITY: Resolve symlinks to get the real filesystem path
    // This prevents symlink attacks where an attacker creates a symlink
    // in templates/ pointing to sensitive files like /etc/passwd
    let realPath;
    try {
      realPath = fs.realpathSync(templatePath);
    } catch (err) {
      console.error('[exportProfileTemplate] Failed to resolve real path:', err.message);
      return res.status(500).json({ error: 'Failed to resolve template path.' });
    }
    
    // Security check: Ensure the REAL path is still within the templates directory
    // This prevents both path traversal and symlink attacks
    const realTemplatesDir = fs.realpathSync(templatesDir);
    if (!realPath.startsWith(realTemplatesDir + path.sep) && realPath !== realTemplatesDir) {
      console.warn('[exportProfileTemplate] Symlink attack detected:', {
        requested: sanitizedTemplateName,
        realPath: realPath,
        allowedDir: realTemplatesDir
      });
      return res.status(403).json({ error: 'Access denied: Invalid template location.' });
    }
    
    // Read template file securely using the validated real path
    const templateContent = fs.readFileSync(realPath, 'utf8');
    
    res.json({ template: templateContent });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load template', details: e.message });
  }
};



