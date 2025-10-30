🎨 OVERALL DESIGN SYSTEM

Theme: Modern healthcare — soft blue and white, accent mint green.

Primary color: #3A7AFE (calm blue)

Secondary: #4ADE80 (mint green)

Background: #F9FAFB (light grey)

Typography:

Headings — Poppins SemiBold

Body — Inter Regular

Icons: Use Lucide or Material Symbols

Layout style: Rounded corners (borderRadius = 20), soft shadows, minimal clutter.

Animations: Use Framer Motion-like transitions (AnimatedOpacity, SlideTransition, Hero in Flutter).

Navigation: Bottom navigation bar with four main icons:

🏠 Home

💬 Chat

👩‍⚕️ Doctors

📊 Dashboard

🏠 1. Splash + Login Screen
Layout

Full-screen background: soft gradient from blue → white.

Center logo (animated heartbeat icon inside circle).

Underneath: “Patient Connect” text in bold, fading in.

Two buttons:

Google Sign-In — primary button with Google logo.

Email Sign-In — outlined button.

Animation

Logo pulses 3×, then transitions upward with ease-in-out.

Buttons slide up from bottom using SlideTransition.

On successful login → fade transition into Home screen (PageRouteBuilder).

🏡 2. Home Screen
Structure

Top app bar:

Left: user profile avatar (tap → profile details).

Center: “Welcome, [Name]”.

Right: notification bell (for reminders).

Main sections (as cards in vertical scroll):

Quick Actions Row (horizontal scroll):

Book Appointment

Upload Record (future use, greyed out)

Chat with AI

View Doctors

View Dashboard

Each icon animates with a subtle “pop” when tapped.

Upcoming Appointments Card:

Doctor photo, specialty, time, and location.

Swipe right → mark as completed; swipe left → cancel.

Health Snapshot Card:

4 mini circular progress bars: Steps, Sleep, Heart Rate, SpO₂.

Animated with TweenAnimationBuilder (smooth percentage growth).

AI Tip Banner (Bottom):

A small friendly bubble: “🧠 Did you know? Regular walks reduce BP by 20%.”

Fades in after 2 seconds with bounce.

Animation

Cards slide in sequentially on load.

Pull-to-refresh rotates a small heartbeat icon.

💬 3. AI Chat Screen (Groq Chatbot)
Layout

Top bar: “AI Health Assistant” title + status indicator (green dot “Online”).

Chat area: full-height ListView with alternating message bubbles:

Patient messages right-aligned (blue bubble).

AI replies left-aligned (white bubble with slight shadow).

Smooth fade + slide animation per message.

Message composer:

Rounded input field (TextField with hint: “Ask about your symptoms…”).

Send button (PaperPlane icon in mint green).

Button scales slightly when pressed (ScaleTransition).

Animation

AI reply appears with a typing animation (three dots pulsing for 1.5 s).

On first open, AI sends “Hi [Name], I’m here to answer your health questions!”

Extra UI ideas

Top-right “Info” icon → shows pop-up explaining: “This chatbot provides general guidance, not medical advice.”

Optional mini avatar of AI on first message.

👩‍⚕️ 4. Doctors Screen (Dummy Data)
Layout

Top bar: “Nearby Specialists”.

Search bar: “Search specialty…” (filters the dummy list).

Doctor cards (scrollable list):

Left: circular avatar or icon

Middle: name, specialty, rating stars

Right: distance text (e.g., “2.1 km”)

Tap → open doctor detail bottom sheet with:

Specialty

Experience years

Call / Book Appointment buttons (for demo, show snackbar “Coming soon”).

Animation

Cards fade + slide from bottom on page load.

When tapping a card → bottom sheet slides up (showModalBottomSheet with CurvedAnimation).

📊 5. Dashboard Screen
Layout

Top bar: “Your Health Overview”.

Date selector: week/month toggle chips (highlight active).

Charts Section:

Line chart — Heart Rate trend

Bar chart — Sleep hours

Circular progress — Steps goal completion
(Use fl_chart package; animate with AnimatedSwitcher.)

Insight Card:

Text example: “You walked 5,400 steps yesterday — great job!”

Fade in with delayed animation.

Animation

Smooth value transition on chart load.

Cards appear with FadeTransition + ScaleTransition.

👤 6. Profile / Settings Drawer
Access

Tap avatar on home → slide-up profile sheet.

Content

Profile photo, name, email

Edit button (disabled for demo)

Settings toggle for dark mode (works locally)

Logout button (red, fades in on hover/tap)

Animation

Slide-up with blur background (BackdropFilter).

Each setting row animates from left sequentially.

📲 NAVIGATION FLOW SUMMARY
Login → Home
        ├─> Chat with AI
        ├─> Doctors List
        ├─> Dashboard
        └─> Profile Drawer


Transitions between main tabs use slide-in-from-right animation with 0.3 s easing.
Bottom navigation bar icons enlarge slightly when active (using AnimatedContainer).

🧠 MICRO-INTERACTIONS
Action	Animation
Button tap	Ripple + 2% scale-up
Card hover	Shadow intensifies slightly
Sending chat	Send button rotates briefly
AI typing	3-dot pulse
List refresh	Spinning heartbeat icon
Page change	Slide-in with 250 ms ease-in-out
Snackbar	Slide up with elastic easing
🌈 DEMO COLOR PALETTE
Element	Color	Description
Primary	#3A7AFE	Buttons / active icons
Secondary	#4ADE80	Accents (send, confirm)
Background	#F9FAFB	App background
Text Primary	#111827	Headlines
Text Secondary	#6B7280	Descriptive text
Card BG	#FFFFFF	Surfaces
Danger	#EF4444	Alerts / Logout
💡 FINAL TOUCHES FOR DEMO

App startup animation: show logo morph into heartbeat pulse → fade to login.

Hero animation: Between doctor list and detail view (doctor avatar zooms up).

Toast messages: use fluttertoast for “Coming soon” actions.

Dark mode toggle: optional, use Flutter’s built-in theme switch.