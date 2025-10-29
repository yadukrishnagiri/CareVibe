Backend (Node.js / Express)

Setup

1) Copy env example and edit values (Windows path for Firebase key):
copy env.example .env

2) Install dependencies:
npm i express mongoose firebase-admin jsonwebtoken bcryptjs multer helmet cors dotenv axios express-rate-limit morgan
npm i -D nodemon

3) Run dev server:
npm run dev

4) Health check:
http://localhost:5000/health

Endpoints

- POST /auth/firebase (body: { idToken }) → returns { token }
- POST /ai/chat (Authorization: Bearer <token>; body: { message })
- GET /doctors (public)
- GET /appointments/:userId (Authorization: Bearer <token>)

Notes

- MongoDB must be running locally (MONGO_URI in .env)
- GOOGLE_APPLICATION_CREDENTIALS must point to Firebase Admin SDK JSON
- GROQ_API_KEY needed for /ai/chat
- Test Groq connectivity: `npm run test:groq`


