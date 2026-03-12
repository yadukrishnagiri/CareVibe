# PPT Content (CareVibe App)

## Background / Problem Statement
- Patients need simple access to health support and guidance
- Tracking wellness and habits is often inconsistent
- Health info is scattered across apps and notes
- Users want quick answers and self-service options

CareVibe addresses the need for an easy-to-use patient engagement experience by combining wellness tracking with self-service features, so users can stay informed and engaged without heavy manual effort.

## Gaps Identified
- Limited self-service and personalized guidance
- Low visibility into personal wellness trends
- Manual reminders lead to missed routines/medications
- Lack of one place for key health interactions

These gaps reduce adherence and engagement. Users benefit from a single experience that makes tracking, reminders, and basic guidance simple and consistent.

## Customer’s Domain / Industry
- Healthcare / patient engagement
- Wellness and preventive care support
- Digital health self-service
- Secure handling of user data

The solution fits healthcare-oriented programs where user engagement, timely reminders, and a clean digital experience are important.

## Proposed Solution**
- Flutter mobile app for patient-facing experience
- Secure login using Firebase Authentication
- Backend APIs (Node.js/Express) for data and features
- AI wellness/chat experience via Groq (LLM)

CareVibe provides a unified mobile experience connected to secure backend services, enabling users to access features, store data safely, and receive AI-assisted wellness guidance.

## User’s Impacted
- Patients / app users
- Care support staff (if used for assistance workflows)
- Admin/operations users (basic monitoring)
- Developers/support team maintaining the platform

The app improves the end-user experience through convenience and consistency, while the supporting teams benefit from a structured platform that is easier to operate and extend.

## Is this idea beneficial to HCL Team ?
- Strong demoable healthcare accelerator
- Reusable mobile + backend foundation for similar clients
- Builds capability in Firebase + AI integration
- Creates scope for enhancements and support

This provides a practical reference solution that can be adapted for multiple healthcare engagements with incremental customization.

## Benefits to the Customer**
- Improved patient engagement and satisfaction
- Better adherence via reminders and tracking
- Faster access to basic guidance through AI chat
- Centralized view of key user interactions/data

Customers gain a scalable digital channel that can reduce manual touchpoints and improve experience through self-service and timely nudges.

## Is this Idea Re-usable? **
- Reusable Flutter UI patterns and components
- Reusable auth + API structure
- Configurable modules (chat, reminders, metrics)
- Extendable for new programs/features

The solution can be reused as a base and tailored per client by adjusting workflows, UI content, integrations, and policy constraints.

## Words from the Customer / Approval Mail**
- “Approved to proceed with the CareVibe pilot”
- “UI is simple and user friendly”
- “AI chat adds value for quick guidance”
- Approval mail attached / pending

Add a short quote from the sponsor or a sentence from the approval email and attach it in the appendix slide.

## Tools and Technology Used
- Flutter (mobile)
- Node.js + Express (backend)
- MongoDB (data store)
- Firebase Auth + Groq LLM API

This stack supports fast iteration for mobile UX, secure authentication, scalable APIs, and AI-powered assistance.

## Technology Environment:
- Mobile app (Android; extendable to iOS)
- REST backend services
- Database (MongoDB local/Atlas)
- Cloud deployment for backend (as applicable)

The environment is designed for a standard mobile-to-API architecture that can run locally for development and be deployed for demos or production.

## Tools Used:
- VS Code / Cursor / Android Studio
- Git / GitHub
- Postman (API testing)
- CI pipeline (as applicable)

These tools support development, collaboration, testing, and repeatable builds for team delivery.

## Framework and Methodologies Used:
- Flutter + Provider (state management)
- Express.js REST APIs
- Agile / Scrum
- Secure coding + basic CI checks

The delivery follows iterative agile development with emphasis on secure auth, reliable APIs, and user-focused UX improvements.
