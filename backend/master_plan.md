
# 🧠 **MASTER PROMPT — Patient Engagement & AI Chat Demo (Local Version)**

> **Goal:**
> Build a **working demo version** of the *Patient Engagement & Self-Service App* using:
>
> * **Frontend:** Flutter (Android only)
> * **Backend:** Node.js (RESTful APIs)
> * **Database:** MongoDB
> * **Authentication:** Firebase (Google Sign-in + Email/Password)
> * **AI:** Groq API for chatbot (no memory or document analysis)
> * **Location & Doctors:** Dummy data (static JSON for demo)
> * **Security:** AES-256 encryption for sensitive data
>
> **Main demo flow:**
>
> 1. Patient logs in using Firebase
> 2. Home screen shows basic dashboard & chatbot access
> 3. Patient chats with AI (Groq API) about general health questions
> 4. App shows static list of “nearby doctors” based on dummy data
>
> **Deliverables:**
>
> * Fully working local prototype (backend + frontend)
> * Firebase login + JWT auth flow
> * Chatbot connected to Groq API
> * Doctor list from dummy JSON
> * MongoDB for user and appointment data
> * Setup guide and Postman collection
>
> **Excluded:**
>
> * PDF upload and analysis
> * RAG or vector memory
> * Real maps or geolocation
> * Cloud or iOS deployment

---

# 🧩 **PHASE 1 — Environment Setup**

### 🎯 Goal

Create local development setup for Flutter + Node.js + MongoDB + Firebase.

### ✅ Do-To List

1. Install:

   * Node.js (v18+)
   * Flutter SDK
   * MongoDB (local)
   * Firebase CLI (`npm install -g firebase-tools`)
   * Android Studio (for emulator)

2. Create Firebase project:

   * Enable **Email/Password** and **Google Sign-in**.
   * Download `google-services.json` and place in
     `frontend/android/app/`.

3. Folder structure:

   ```
   patient-ai-demo/
    ├── backend/
    ├── frontend/
    ├── uploads/
    ├── .env
    └── README.md
   ```

---

# 🧱 **PHASE 2 — Database Setup (MongoDB)**

### 🎯 Goal

Define core collections for basic app data.

### ✅ Do-To List

1. Start MongoDB service:

   ```bash
   mongod
   ```

2. Create database and collections:

   ```bash
   mongosh
   use patient_ai_demo;
   db.createCollection("users");
   db.createCollection("appointments");
   db.createCollection("doctors");
   ```

3. Sample data:

   ```js
   db.doctors.insertMany([
     { name: "Dr. Priya Menon", specialty: "Cardiologist", location: "Kochi" },
     { name: "Dr. Vivek Rao", specialty: "Dermatologist", location: "Bangalore" },
     { name: "Dr. Asha Thomas", specialty: "Neurologist", location: "Chennai" }
   ]);
   ```

4. `.env` file:

   ```
   MONGO_URI=mongodb://127.0.0.1:27017/patient_ai_demo
   JWT_SECRET=local_jwt_secret
   AES_KEY=replace_with_32_characters_key
   GROQ_API_KEY=your_groq_api_key
   PORT=5000
   ```

---

# ⚙️ **PHASE 3 — Backend Setup**

### 🎯 Goal

Set up Node.js REST backend with Firebase token validation and Groq chatbot integration.

### ✅ Do-To List

1. Install dependencies:

   ```bash
   cd backend
   npm init -y
   npm install express mongoose firebase-admin jsonwebtoken bcryptjs multer helmet cors dotenv crypto axios
   ```

2. Project structure:

   ```
   backend/
    ├── src/
    │   ├── server.js
    │   ├── routes/
    │   │   ├── authRoutes.js
    │   │   ├── chatRoutes.js
    │   │   ├── doctorRoutes.js
    │   │   └── appointmentRoutes.js
    │   ├── controllers/
    │   │   ├── authController.js
    │   │   ├── chatController.js
    │   │   ├── doctorController.js
    │   │   └── appointmentController.js
    │   ├── models/
    │   ├── middleware/
    │   └── utils/
    ├── package.json
    └── .env
   ```

3. **Groq Chat API example**

   ```js
   // src/controllers/chatController.js
   import axios from "axios";

   export const chatWithAI = async (req, res) => {
     try {
       const { message } = req.body;
       const response = await axios.post(
         "https://api.groq.com/v1/chat/completions",
         {
           model: "mixtral-8x7b",
           messages: [
             { role: "system", content: "You are a friendly health chatbot." },
             { role: "user", content: message },
           ],
         },
         { headers: { Authorization: `Bearer ${process.env.GROQ_API_KEY}` } }
       );
       const reply = response.data.choices[0].message.content;
       res.json({ reply });
     } catch (err) {
       res.status(500).json({ error: "Chatbot failed", details: err.message });
     }
   };
   ```

4. **Dummy doctor list route**

   ```js
   // src/controllers/doctorController.js
   export const getDoctors = async (req, res) => {
     const doctors = [
       { name: "Dr. Priya Menon", specialty: "Cardiologist", distance: "2.1 km" },
       { name: "Dr. Vivek Rao", specialty: "Dermatologist", distance: "3.4 km" },
       { name: "Dr. Asha Thomas", specialty: "Neurologist", distance: "4.0 km" }
     ];
     res.json(doctors);
   };
   ```

5. **API Paths**

   | Method | Endpoint                | Purpose                                 |
   | ------ | ----------------------- | --------------------------------------- |
   | POST   | `/auth/firebase`        | Verify Firebase token, issue JWT        |
   | GET    | `/doctors`              | Return dummy doctor data                |
   | POST   | `/ai/chat`              | Send user question → Groq chatbot reply |
   | GET    | `/appointments/:userId` | Get mock appointments                   |

---

# 📱 **PHASE 4 — Frontend (Flutter)**

### 🎯 Goal

Create a minimal, functional mobile UI for the demo.

### ✅ Do-To List

1. Install dependencies:

   ```bash
   flutter pub add firebase_core firebase_auth google_sign_in http provider
   ```

2. **Screens to build**

   | Screen  | Purpose                              |
   | ------- | ------------------------------------ |
   | Login   | Firebase Google login                |
   | Home    | Dashboard buttons for Chat & Doctors |
   | Chat    | Send messages to Groq AI chatbot     |
   | Doctors | Show static doctor list (dummy data) |

3. **Chat integration**

   ```dart
   final res = await http.post(
     Uri.parse('$apiBase/ai/chat'),
     headers: {'Content-Type': 'application/json'},
     body: jsonEncode({'message': userMessage}),
   );
   final data = jsonDecode(res.body);
   setState(() => chatMessages.add({'sender': 'AI', 'text': data['reply']}));
   ```

4. **Doctor list (dummy data)**

   * Fetch from `/doctors` and display in a simple `ListView` with name, specialty, distance.

---

# 🔐 **PHASE 5 — Security & Testing**

### 🎯 Goal

Secure the demo app and confirm basic functionality.

### ✅ Do-To List

1. Use `helmet()` for headers in backend.
2. Validate JWT for protected endpoints.
3. Store AES key securely in `.env`.
4. Test:

   * Google login success
   * AI chat working
   * Doctor list visible
   * No app crash or delay >3s

---

# 🚀 **PHASE 6 — Demo Delivery**

### 🎯 Goal

Prepare for presentation.

### ✅ Do-To List

* Add sample walkthrough data:

  * 2 test users
  * 3 dummy doctors
* Record short video or live demo:

  * Login → Chatbot → Doctor List
* Create README:

  * Backend: how to run server
  * Frontend: how to run Flutter app
  * Environment setup instructions
  * API documentation (in short bullets)

---

# 📋 **SUMMARY OF FINAL DELIVERABLES**

✅ Local backend + frontend
✅ Firebase login (Google only)
✅ Groq chatbot (simple Q&A)
✅ Dummy doctor list
✅ MongoDB with sample users and appointments
✅ Full setup guide and Postman collection