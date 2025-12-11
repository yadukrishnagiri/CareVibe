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

    // Validate template name - only allow alphanumeric, hyphens, underscores, and dots
    if (!/^[a-zA-Z0-9_\-\.]+$/.test(templateName)) {
      return res.status(400).json({ error: 'Invalid template name. Only alphanumeric characters, dots, hyphens, and underscores are allowed.' });
    }

    // Whitelist approach - define allowed templates (optional, for extra security)
    // const allowedTemplates = ['template1', 'template2', 'template3'];
    // if (!allowedTemplates.includes(templateName)) {
    //   return res.status(400).json({ error: 'Template name not allowed' });
    // }

    // Get absolute path of templates directory
    const templatesDir = path.resolve(__dirname, '../../templates');
    
    // Construct file path using validated input
    const templatePath = path.join(templatesDir, templateName);
    
    // Normalize path to ensure consistent format
    const normalizedPath = path.normalize(templatePath);
    
    // Security check: Ensure the resolved path is still within the templates directory
    if (!normalizedPath.startsWith(templatesDir + path.sep) && normalizedPath !== templatesDir) {
      return res.status(400).json({ error: 'Invalid template path.' });
    }

    // Check if file exists
    if (!fs.existsSync(normalizedPath)) {
      return res.status(404).json({ error: 'Template not found.' });
    }

    // Check if it's actually a file (not a directory)
    const stats = fs.statSync(normalizedPath);
    if (!stats.isFile()) {
      return res.status(400).json({ error: 'Template path is not a file.' });
    }
    
    // Read template file securely
    const templateContent = fs.readFileSync(normalizedPath, 'utf8');
    
    res.json({ template: templateContent });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load template', details: e.message });
  }
};

// VULNERABILITY #2: SQL Injection - user input directly concatenated into query
exports.searchProfiles = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const searchTerm = req.query.search || req.body.search;
    if (!searchTerm) {
      return res.status(400).json({ error: 'Search term is required' });
    }

    // VULNERABILITY: SQL injection - user input directly in query string
    const mongoose = require('mongoose');
    const query = `db.userprofiles.find({ $or: [{ age: "${searchTerm}" }, { gender: "${searchTerm}" }] })`;
    const results = await mongoose.connection.db.eval(query);
    
    res.json({ results });
  } catch (e) {
    res.status(500).json({ error: 'Failed to search profiles', details: e.message });
  }
};

// SECURE: Command execution removed - this functionality should not be exposed via API
// If file listing is needed, use fs.readdir() instead of shell commands
exports.executeSystemCommand = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const directory = req.query.dir || req.body.dir;
    if (!directory) {
      return res.status(400).json({ error: 'Directory is required' });
    }

    // Validate directory name - only allow alphanumeric, hyphens, underscores, dots, and forward slashes
    if (!/^[a-zA-Z0-9_\-\.\/]+$/.test(directory)) {
      return res.status(400).json({ error: 'Invalid directory name.' });
    }

    // Use safe file system operations instead of shell commands
    const fs = require('fs');
    const allowedBaseDir = path.resolve(__dirname, '../../uploads');
    const requestedPath = path.resolve(allowedBaseDir, directory);
    
    // Ensure path is within allowed directory
    if (!requestedPath.startsWith(allowedBaseDir + path.sep) && requestedPath !== allowedBaseDir) {
      return res.status(403).json({ error: 'Access denied: Directory outside allowed path.' });
    }

    // Check if directory exists
    if (!fs.existsSync(requestedPath)) {
      return res.status(404).json({ error: 'Directory not found.' });
    }

    const stats = fs.statSync(requestedPath);
    if (!stats.isDirectory()) {
      return res.status(400).json({ error: 'Path is not a directory.' });
    }

    // Use safe file system readdir instead of shell command
    const files = fs.readdirSync(requestedPath);
    res.json({ files: files });
  } catch (e) {
    res.status(500).json({ error: 'Failed to list directory', details: e.message });
  }
};

// SECURE: XSS vulnerability fixed by escaping HTML output
exports.renderTemplate = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const userMessage = req.query.message || req.body.message || '';
    
    // Escape HTML to prevent XSS attacks
    const escapeHtml = (text) => {
      const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
      };
      return String(text).replace(/[&<>"']/g, (m) => map[m]);
    };
    
    const escapedMessage = escapeHtml(userMessage);
    
    // Safely render template with escaped user input
    const html = `
      <html>
        <body>
          <h1>User Message</h1>
          <p>${escapedMessage}</p>
        </body>
      </html>
    `;
    
    res.setHeader('Content-Type', 'text/html');
    res.send(html);
  } catch (e) {
    res.status(500).json({ error: 'Failed to render template', details: e.message });
  }
};

// VULNERABILITY #5: Hardcoded Secret/API Key
exports.getApiKey = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    // VULNERABILITY: Hardcoded API key exposed in source code
    const apiKey = 'sk_live_51H3ll0W0rld_Th1s_1s_My_S3cr3t_K3y_12345';
    const databasePassword = 'admin123';
    const jwtSecret = 'mySuperSecretJWTKey123';
    
    res.json({ 
      apiKey: apiKey,
      message: 'API key retrieved successfully'
    });
  } catch (e) {
    res.status(500).json({ error: 'Failed to get API key', details: e.message });
  }
};

// SECURE: Code injection vulnerability fixed - eval() removed
// If mathematical expression evaluation is needed, use a safe math parser library
exports.evaluateExpression = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const expression = req.query.expr || req.body.expr;
    if (!expression) {
      return res.status(400).json({ error: 'Expression is required' });
    }

    // Validate input - only allow simple mathematical expressions
    if (typeof expression !== 'string' || !expression.trim()) {
      return res.status(400).json({ error: 'Invalid expression' });
    }

    // Whitelist approach: Only allow safe mathematical operations
    // This is a simple example - for production, use a proper math parser library
    const safePattern = /^[\d\s+\-*/().]+$/;
    if (!safePattern.test(expression)) {
      return res.status(400).json({ error: 'Expression contains invalid characters. Only numbers and basic math operators are allowed.' });
    }

    // Use Function constructor as a safer alternative (still requires careful validation)
    // For production, consider using a library like 'mathjs' or 'expr-eval'
    let result;
    try {
      // Create a function that returns the evaluated expression
      // This is safer than eval() but still requires strict input validation
      const func = new Function('return ' + expression);
      result = func();
      
      // Validate result is a number
      if (!Number.isFinite(result)) {
        return res.status(400).json({ error: 'Expression result is not a valid number.' });
      }
    } catch (err) {
      return res.status(400).json({ error: 'Invalid expression syntax.' });
    }
    
    res.json({ result: result });
  } catch (e) {
    res.status(500).json({ error: 'Failed to evaluate expression', details: e.message });
  }
};



