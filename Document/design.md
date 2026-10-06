# CareVibe — Design Document

## Product Overview

**CareVibe** is a mobile-first patient engagement and self-service healthcare companion. It empowers patients to track daily vitals, get AI-driven health guidance, manage medications, and book specialist appointments — all from a single Flutter app with a Node.js backend.

**Target user:** Patients managing chronic conditions or those wanting proactive wellness tracking.

**Core value:** Personalized AI health guidance backed by the user's real daily metrics.

---

## Brand Identity

| Element | Value |
|---|---|
| Primary color | `#3A7AFE` (calm medical blue) |
| Secondary | `#4ADE80` (vitality green) |
| Background (dark) | `#0F172A` (deep navy) |
| Surface (dark) | `#111827` (slightly lighter navy) |
| Background (light) | `#F9FAFB` |
| Surface (light) | `#FFFFFF` |
| Danger | `#EF4444` |
| Success | `#10B981` |
| Typography | Poppins (headings), Inter (body) |

**Tone:** Calm, premium, trustworthy. Avoids the "sterile hospital" feel — feels like a wellness app, not a clinical EMR.

---

## Screens

### 1. Login / Sign Up (`login_screen.dart`)
- Hero gradient banner with logo + tagline
- "Sign in with Google" primary button (filled)
- "Sign in with Email" secondary button (outlined)
- Terms of service footer
- Demo mode banner if user is in demo session

### 2. Home Dashboard (`home_screen.dart`)
**Top to bottom:**
1. Hero greeting card ("Good to see you, {name}")
2. Profile section (avatar, name, email)
3. Appointments list
4. **Today vs Yesterday** — comparison panel (Steps, Sleep, Heart Rate, SpO₂)
5. Medication Reminders card
6. AI Tip banner ("Daily wellness insight from AI")
7. Bottom navigation: Home / Insights / Medications / Profile

### 3. Insights (`insights_screen.dart`)
- Trend charts for weekly metrics
- AI-generated health insights feed
- Export health report (PDF)

### 4. Medications (`medications_screen.dart`)
- Today's medication schedule
- Mark as taken / snooze
- Add new medication
- Reminder history

### 5. Profile (`profile_screen.dart`)
- User info
- Connected devices (Health Connect / Google Fit)
- Settings (theme, notifications)
- Sign out

### 6. Chat / AI Health Assistant (`chat_screen.dart`)
- Conversational AI powered by Groq (Llama 3 / Mixtral)
- Context-aware (knows user's recent vitals)
- Suggested questions
- Voice input (future)

### 7. Appointments (`appointments_screen.dart`)
- Upcoming visits with specialists
- Book new appointment
- Directions + call buttons

### 8. Doctor Directory (`doctors_screen.dart`)
- Search by specialty / location
- View profiles, book appointment
- Filter by insurance (future)

### 9. Weather + Air Quality (`weather_card.dart`)
- Current AQI + health advice
- Pollen count (future)
- UV index (future)

---

## Design Patterns

### Cards
- Rounded corners: 20px
- Surface color (dark: `#111827`, light: `#FFFFFF`)
- Soft shadow: `0 10 18 rgba(0,0,0,0.05)` (light) or `0 10 18 rgba(0,0,0,0.35)` (dark)
- Internal padding: 18–20px
- Avoid heavy borders — use shadows and dividers instead

### Typography Hierarchy
- **Display (h1):** 28px / Poppins Bold — page titles
- **Title (h2):** 20px / Poppins SemiBold — section titles
- **Heading (h3):** 16px / Inter SemiBold — card titles
- **Body large:** 16px / Inter Regular — primary text
- **Body medium:** 14px / Inter Regular — secondary text
- **Body small:** 12px / Inter Regular — captions, meta
- **Metric value:** 20–24px / Poppins Bold — today's vital numbers
- **Caption:** 11–12px / Inter Medium — labels, badges

### Spacing
- 4, 8, 12, 16, 20, 24, 32, 48 — multiples of 4
- Section spacing: 24px
- Within cards: 14–16px
- Row padding: 12–16px

### Colors for Change Indicators
- **Positive (improvement):** `#10B981` (green)
- **Negative (decline):** `#EF4444` (red/orange)
- **Flat (no change):** muted text color

For health metrics, "improvement" depends on direction:
- Steps ↑ = good
- Sleep ↑ = good
- Heart Rate ↓ = good (lower resting HR)
- SpO₂ ↑ = good

---

## Key Component: Today vs Yesterday

**Single cohesive panel** (not 4 separate cards).

**Layout:**
```
┌─────────────────────────────────────────┐
│ [🔄]  Today vs Yesterday                │  ← header with icon tile
│                                         │
│ • Today   • Yesterday                   │  ← legend
│                                         │
├─────────────────────────────────────────┤
│ [🚶] Steps                              │
│   5.0k   6.2k yesterday    ↓ 19%        │  ← row
├─────────────────────────────────────────┤
│ [😴] Sleep                              │
│   6.9h   7.3h yesterday    ↓ 5%         │
├─────────────────────────────────────────┤
│ [❤️] Heart Rate                         │
│   72 bpm  71 bpm yesterday  ↑ 1%        │
├─────────────────────────────────────────┤
│ [💨] SpO₂                               │
│   97%    97% yesterday    — 0%          │
└─────────────────────────────────────────┘
```

**Specs:**
- Container: rounded 20px, surface color, soft shadow
- Icon tile: 42×42 rounded square, primary with 12% opacity
- Today value: 20px bold, primary text color
- Yesterday value: 12px muted
- Change pill: rounded full (999), colored bg + colored text + arrow icon
- Divider between rows: 1px, 6% white/black opacity

---

## Animations

Use `flutter_animate` package consistently:
- Cards: `fadeIn(duration: 400ms).slideY(begin: 0.1)` with cascading delays (100ms, 200ms, 300ms, 400ms)
- Buttons: subtle scale on press
- List items: stagger fade

---

## Accessibility

- Minimum tap target: 48×48 dp
- Color is never the only signal (always pair with text/icon)
- Support both light and dark mode
- Semantic labels for screen readers
- Respect system font size

---

## Future Design Improvements

- [ ] Onboarding flow (3 screens with illustrations)
- [ ] Skeleton loaders instead of spinners
- [ ] Pull-to-refresh animations
- [ ] Haptic feedback on key actions
- [ ] Offline state UI
- [ ] Error illustrations (not just red text)
