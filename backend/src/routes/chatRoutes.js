const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { chatWithAI } = require('../controllers/chatController');

router.post('/chat', auth, chatWithAI);

module.exports = router;


