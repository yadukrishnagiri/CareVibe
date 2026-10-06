# CareVibe — AI Prompts

This file contains the **Master Prompt** and sample prompts used while building CareVibe with AI assistance.

## Project Files

CareVibe uses the following project documentation:

* `todo.md` — project tasks and development progress
* `design.md` — UI/UX and visual design specification
* `rule.md` — development rules and AI behavior guidelines
* `prompt.md` — master prompt and reusable development prompts

---

# Master Prompt

You are the **lead software engineer helping me build CareVibe**, an existing patient engagement application.

CareVibe uses:

* **Flutter** — frontend
* **Node.js + Express** — backend
* **MongoDB + Mongoose** — database
* **Firebase Authentication** — authentication
* **Groq API** — AI health assistant
* **Render** — backend hosting

You are working on an **existing project**, not starting from scratch.

Before doing any development work, always inspect the project and follow the project documentation.

### Required files

First read:

* `todo.md`
* `design.md`
* `rule.md`

### `todo.md`

Use `todo.md` to understand:

* What has already been completed
* What is currently being developed
* What needs to be done
* The current project progress

Do not redo completed work.

### `design.md`

Use `design.md` as the source of truth for:

* UI
* UX
* Colors
* Typography
* Spacing
* Layout
* Components
* Visual consistency

When working on the frontend, follow the existing design system instead of creating an unrelated design.

### `rule.md`

Read `rule.md` before making changes.

It contains the project's development rules, coding practices, architecture guidelines, security requirements, and AI behavior instructions.

---

## Development Approach

Treat CareVibe as an existing application.

Before making changes:

**Read → Inspect → Understand → Plan → Implement → Test**

Always inspect the existing implementation before creating or changing anything.

If a feature, component, service, API, model, or configuration already exists, use the existing implementation instead of creating a duplicate.

Do not repeat setup steps, explanations, or solutions that have already been completed.

If something has already been completed, continue from the current state.

Do not restart the project from scratch unless explicitly asked.

Keep the existing architecture and functionality intact unless a change is actually required.

When a task is completed, keep `todo.md` consistent with the current project state.

---

# Sample Prompts

## 1. Start / Continue Development

> Read `todo.md`, `design.md`, and `rule.md` first. Inspect the current CareVibe project and continue development from the current state. Do not repeat or redo anything that has already been completed.

## 2. Implement the Next Task

> Read `todo.md` and identify the current incomplete task. Inspect the related existing code before making changes. Follow `design.md` for UI and `rule.md` for development rules. Implement only the required task.

## 3. Build a New Screen

> Create the `[SCREEN NAME]` screen for CareVibe. Read `design.md` first and inspect the existing Flutter screens and reusable components. Follow the existing design system and reuse components wherever possible.

## 4. Redesign an Existing Screen

> Redesign the `[SCREEN NAME]` screen according to `design.md`. Keep the existing functionality, API integration, and navigation unchanged. Only improve the UI and UX.

## 5. Create the CareVibe Dashboard

> Build the CareVibe dashboard based on the requirements in `todo.md` and the visual system in `design.md`. Inspect existing Flutter components before creating new ones. The dashboard should feel like a polished modern healthcare application while remaining consistent with the existing CareVibe design.

## 6. Implement Firebase Authentication

> Set up Firebase Authentication for CareVibe using the existing project structure. Configure Google Sign-In and make sure the Flutter frontend uses the existing Firebase project. Follow `rule.md` and do not expose any private credentials.

## 7. Connect Authentication to the Backend

> Connect the existing Firebase Authentication flow with the Node.js backend. Inspect the current authentication and API structure first. Use the existing architecture instead of creating a separate authentication system.

## 8. Set Up MongoDB

> Set up the CareVibe MongoDB database using MongoDB Atlas and Mongoose. Inspect the existing backend structure first and create the database connection in the appropriate existing location. Keep credentials in environment variables.

## 9. Create a New Backend Feature

> Add `[FEATURE]` to the CareVibe Node.js backend. Inspect the existing routes, controllers, models, middleware, and database connection first. Follow the existing backend structure and create only the files required for this feature.

## 10. Connect Flutter to an Existing API

> Connect the `[SCREEN/FEATURE]` Flutter implementation to the existing CareVibe backend API. Inspect the current API service, authentication flow, and request patterns first. Reuse the existing API architecture rather than creating another API client.

## 11. Add Groq AI Assistant

> Implement the Groq-powered AI health assistant for CareVibe. Inspect the existing backend and AI architecture first. The Groq API key must remain on the backend and must never be exposed in the Flutter application. Follow the existing project design and safety requirements.

## 12. Improve the AI Assistant

> Improve the existing CareVibe AI assistant for `[FEATURE]`. Do not create a second AI service. Inspect the current Groq integration and modify the existing implementation. Keep the API architecture and security model unchanged.

## 13. Add Loading and Empty States

> Add loading, empty, success, and appropriate error states to the `[SCREEN NAME]` screen. Follow `design.md` and reuse existing CareVibe components. Do not change the backend behavior.

## 14. Configure Local and Production Backend

> Configure CareVibe so Flutter can use the local Node.js backend during development and the Render backend in production. Inspect the existing API configuration first and use the current configuration pattern instead of introducing unnecessary changes.

## 15. Deploy Backend to Render

> Prepare the existing CareVibe Node.js backend for Render deployment. Inspect the current backend structure, `package.json`, environment variables, start command, and database configuration. Do not recreate anything that already exists.

## 16. Prepare the Flutter App for Release

> Prepare the current CareVibe Flutter application for a release APK. Inspect the existing Android and Flutter configuration first. Only change SDK, Gradle, Java, dependency, or Android configuration if it is actually required for the build.

## 17. Improve UI Consistency

> Audit the `[SCREEN NAME]` screen against `design.md`. Identify and fix visual inconsistencies in spacing, typography, colors, buttons, cards, icons, and layout. Keep the existing functionality unchanged.

## 18. Review the Current Architecture

> Review the current CareVibe Flutter and Node.js architecture. Inspect the actual project structure and identify unnecessary duplication or architectural inconsistencies. Do not rewrite working code. Recommend improvements only where they provide a real benefit.

## 19. Prepare CareVibe for Demo

> Review the current CareVibe project using `todo.md`, `design.md`, and `rule.md`. Check the major user flows from authentication through the main application features and identify anything that must be completed or polished before a demo.

## 20. Continue From the Current State

> Continue working on CareVibe from the current project state. Do not repeat previous setup, explanations, or completed features. Read `todo.md`, inspect the existing implementation, and determine exactly what remains for `[FEATURE]`. Complete only the remaining work and keep the project consistent with `design.md` and `rule.md`.
