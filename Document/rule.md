# CareVibe — Development Rules

These rules apply whenever AI is used to develop or modify CareVibe.

## 1. Check Before Changing

Always inspect the existing code before creating or modifying anything.

Do not assume a feature, file, component, API, or configuration is missing.

---

## 2. Do Not Repeat Work

Do not recreate or redo something that has already been completed.

Reuse existing:

* Components
* Services
* APIs
* Models
* Utilities
* Configurations

If something already exists, build on it.

---

## 3. Follow Project Documentation

Always respect:

* `todo.md` — tasks and progress
* `design.md` — UI/UX and design
* `rule.md` — development rules

Do not ignore existing project decisions without a reason.

---

## 4. Keep Changes Focused

Only change what is required for the current task.

Avoid unnecessary changes to unrelated files or features.

---

## 5. Follow the Existing Architecture

Keep the current Flutter and Node.js architecture consistent.

Do not introduce a new architecture, library, pattern, or dependency unless it is actually needed.

---

## 6. UI Must Follow `design.md`

When working on UI:

* Follow the existing colors
* Follow typography
* Follow spacing
* Reuse existing components
* Keep screens visually consistent

Do not invent a completely different design.

---

## 7. Protect Secrets

Never hardcode or expose:

* API keys
* Passwords
* JWT secrets
* Firebase private keys
* MongoDB credentials
* Groq API keys
* Service account credentials

Use environment variables or secure configuration.

---

## 8. Backend Rules

For Node.js/Express development:

* Reuse existing routes and middleware where possible.
* Follow the existing API structure.
* Validate user input.
* Handle errors properly.
* Keep database credentials secure.
* Do not expose sensitive information in API responses.

---

## 9. Flutter Rules

For Flutter development:

* Reuse existing widgets and services.
* Keep UI and business logic reasonably separated.
* Handle loading and empty states.
* Handle API failures gracefully.
* Keep the existing navigation and application structure unless a change is required.

---

## 10. Database Rules

For MongoDB/Mongoose:

* Reuse existing models where possible.
* Do not change schemas unnecessarily.
* Avoid duplicate collections or models.
* Keep database credentials out of source code.

---

## 11. AI Assistant Rules

For the Groq-powered CareVibe assistant:

* Keep the Groq API key on the backend.
* Never expose the API key in Flutter.
* Use the existing AI service when available.
* Do not create duplicate AI integrations.
* Keep responses appropriate for a patient engagement application.

---

## 12. Testing

After making a change:

1. Run the relevant application or service.
2. Test the changed functionality.
3. Check that existing functionality still works.
4. Fix any issues caused by the change.

Do not assume a change works without testing it when testing is possible.

---

## 13. Documentation

Keep project documentation consistent with the actual implementation.

When a task from `todo.md` is completed, update its status if appropriate.

Do not add unnecessary documentation for simple changes.

---

## 14. Communication

Keep explanations clear and practical.

When solving a task, prefer:

**What → Why → Change → Test**

Do not repeat information that has already been established.

If something is unclear or requires a major architectural decision, ask before making the change.

---

# Core Principle

**Inspect first. Reuse existing work. Make focused changes. Follow the design. Protect secrets. Test before considering the task complete.**
