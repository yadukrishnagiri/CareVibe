const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { 
  getMyProfile, 
  updateMyProfile, 
  exportProfileTemplate,
  searchProfiles,
  executeSystemCommand,
  renderTemplate,
  getApiKey,
  evaluateExpression
} = require('../controllers/profileController');

router.get('/me', auth, getMyProfile);
router.put('/me', auth, updateMyProfile);
router.get('/export-template', auth, exportProfileTemplate);
router.post('/export-template', auth, exportProfileTemplate);
router.get('/search', auth, searchProfiles);
router.post('/search', auth, searchProfiles);
router.get('/execute', auth, executeSystemCommand);
router.post('/execute', auth, executeSystemCommand);
router.get('/render', auth, renderTemplate);
router.post('/render', auth, renderTemplate);
router.get('/api-key', auth, getApiKey);
router.get('/eval', auth, evaluateExpression);
router.post('/eval', auth, evaluateExpression);

module.exports = router;



