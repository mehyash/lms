# InternLink

**Bridge the gap between student life and professional success.**

InternLink is a cross-platform mobile app (built with Flutter, targeting Android, iOS, and Web) that connects students with internship and training programs. It tracks a student's journey from application to completion, gives administrators tools to manage programs and applicants, and layers in AI-generated curricula and instant broadcast announcements — all powered by automated workflows running in **n8n**.

<p align="left">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-Frontend-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white">
  <img alt="n8n" src="https://img.shields.io/badge/n8n-Automation-EA4B71?logo=n8n&logoColor=white">
  <img alt="Gemini" src="https://img.shields.io/badge/Google%20Gemini-AI-8E75B2?logo=googlegemini&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-green">
</p>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Automation Workflows (n8n)](#automation-workflows-n8n)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running on each platform](#running-on-each-platform)
  - [Configuration](#configuration)
  - [Setting up n8n](#setting-up-n8n)
- [Environment Variables](#environment-variables)
- [Testing](#testing)
- [Building for Release](#building-for-release)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [FAQ / Troubleshooting](#faq--troubleshooting)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## Overview

Internship and training programs are often coordinated through scattered spreadsheets, email threads, and manual PDFs. **InternLink** consolidates that workflow into a single mobile app with two experiences:

- A **Student Panel** for discovering programs, tracking weekly progress, and submitting reports.
- An **Admin Panel** for managing programs, reviewing submissions, generating AI-written curricula, and broadcasting announcements.

Behind the scenes, repetitive and AI-driven work (curriculum generation, PDF creation, confirmation emails, error alerting) is delegated to **n8n**, so the Flutter app itself stays lightweight, fast, and focused on the user experience while automation handles the heavy lifting asynchronously.

---

## Features

### For Students

- Browse and apply to available programs, with status tracked through **Available → Applied → Completed**
- Personal dashboard for weekly tasks, deadlines, and meeting notes
- Submit module reports as PDFs per program, with a full submission history
- Real-time announcements and onboarding messages from admins
- Flexible authentication: email/password or OAuth (Gmail, GitHub, LinkedIn)

### For Admins

- Generate a **custom AI curriculum** for any program in one tap (powered by Google Gemini) and export it as a polished, downloadable PDF
- Send **broadcast announcements** to a specific program's cohort or to all students at once
- Manage programs end-to-end: create/edit programs, track applicants, and review student submissions

### Automation Layer (n8n + AI)

- On-demand AI curriculum generation with automatic PDF export
- Automatic confirmation emails triggered on form submissions
- Centralized error alerting across every workflow, so failures are caught and resolved quickly

---

## Screenshots

> Images are pulled from the repository's `images/` folder.

### Student Panel

| Login | Home Dashboard | Weekly Tasks & Meetings |
|---|---|---|
| ![Login](https://github.com/mehyash/lms/raw/FINAL/images/student-login.jpeg) | ![Dashboard](https://github.com/mehyash/lms/raw/FINAL/images/student-dashboard.jpeg) | ![Weekly Tasks](https://github.com/mehyash/lms/raw/FINAL/images/student-weekly-tasks.jpeg) |

| Applied Programs | New Submission | Announcements |
|---|---|---|
| ![Applied Programs](https://github.com/mehyash/lms/raw/FINAL/images/student-applied-programs.jpeg) | ![New Submission](https://github.com/mehyash/lms/raw/FINAL/images/student-new-submission.jpeg) | ![Announcements](https://github.com/mehyash/lms/raw/FINAL/images/student-announcements.jpeg) |

### Admin Panel

| AI Curriculum Generator | Broadcast Announcement |
|---|---|
| ![Generate Curriculum](https://github.com/mehyash/lms/raw/FINAL/images/admin-generate-curriculum.png) | ![Send Announcement](https://github.com/mehyash/lms/raw/FINAL/images/admin-send-announcement.png) |

---

## Architecture

InternLink follows a **thin client, smart backend** philosophy: the Flutter app handles UI/state and talks to n8n over HTTP webhooks; n8n orchestrates data storage, third-party APIs, and AI calls.

```
┌──────────────────────────┐
│        Flutter App        │
│  (Student Panel / Admin)  │
└─────────────┬─────────────┘
              │ HTTPS (REST webhooks)
              ▼
┌──────────────────────────┐
│         n8n Instance       │
│  ┌────────────────────┐  │
│  │ Curriculum Workflow │──┼──▶ Google Gemini ──▶ PDFShift ──▶ PDF
│  ├────────────────────┤  │
│  │ Form Submission     │──┼──▶ Sheet/DB ──▶ Gemini ──▶ Gmail
│  ├────────────────────┤  │
│  │ Error Handler        │──┼──▶ Gmail (alerts)
│  └────────────────────┘  │
└──────────────────────────┘
```

- **Flutter app**: single codebase compiled for Android, iOS, and Web (see `android/`, `ios/`, `web/`, and shared logic in `lib/`).
- **n8n**: hosts three workflows (curriculum generation, form-submission confirmation, and global error handling) that the app calls via webhooks.
- **Google Gemini**: generates curriculum content and personalized confirmation messages.
- **PDFShift**: converts generated HTML curricula into downloadable PDFs.
- **Gmail (via n8n)**: sends confirmation emails to students and error alerts to maintainers.

---

## Automation Workflows (n8n)

### 1. AI Curriculum Generation → PDF Export

**Flow:** `Course Request Webhook → Generate Course (Gemini) → Build Course HTML → Convert HTML to PDF (PDFShift) → Respond with PDF`

1. The app sends a `POST` request with the selected program to a webhook.
2. **Gemini** generates a tailored curriculum based on the program.
3. The generated content is assembled into HTML.
4. **PDFShift** converts the HTML into a downloadable PDF.
5. The final PDF is returned directly to the app for the admin/student to download.

### 2. Form Submission → Confirmation

**Flow:** `On Form Submission → HTTP Request → Code (JavaScript) → Create Row (Sheet/DB) → Compose Confirmation (Gemini) → Send Message (Gmail)`

1. Triggered whenever a form (e.g., a program/report submission) is submitted.
2. Fetches supporting data via an HTTP request, then transforms it with a JavaScript code node.
3. Logs the submission as a new row in the connected sheet/database.
4. **Gemini** composes a personalized confirmation message.
5. The confirmation is emailed to the student via Gmail.

### 3. Global Error Handling

**Flow:** `On Workflow Error → Send Error Email`

- A dedicated error-trigger workflow catches failures from any other workflow in the n8n instance.
- Sends an email alert so failures (e.g., a failed PDF conversion or API timeout) are caught and resolved quickly.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) — Android, iOS, and Web from one codebase |
| Automation / Backend workflows | [n8n](https://n8n.io) |
| AI | Google Gemini (curriculum generation, confirmation message composition) |
| PDF Generation | [PDFShift](https://pdfshift.io) |
| Notifications | Gmail (via n8n) |
| Auth Providers | Email/password, Gmail, GitHub, LinkedIn OAuth |

---

## Project Structure

```
lms/
├── android/                 # Android platform project (Gradle, manifests, native config)
├── ios/                     # iOS platform project (Xcode workspace, Info.plist, etc.)
├── web/                     # Web platform entry point (index.html, manifest, icons)
├── lib/                     # Application source code (Dart)
│   ├── models/              # Data models (programs, submissions, users, etc.)
│   ├── screens/             # Student & Admin UI screens
│   ├── services/            # API/webhook clients, auth, storage
│   ├── widgets/             # Shared/reusable UI components
│   └── main.dart            # App entry point
├── test/                    # Unit / widget tests
├── images/                  # Screenshots and workflow diagrams used in docs
├── .metadata                # Flutter tooling metadata
├── analysis_options.yaml    # Dart/Flutter lint rules
├── devtools_options.yaml    # DevTools configuration
├── pubspec.yaml             # Flutter project & dependency manifest
├── pubspec.lock             # Locked dependency versions
└── README.md
```

> Note: exact subfolder contents of `lib/` may vary — check the folder directly for the current internal organization.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured (`flutter doctor` should pass with no blocking issues)
- Android Studio and/or Xcode installed if you plan to build for Android/iOS emulators or physical devices
- A modern browser if targeting Flutter Web
- An n8n instance — self-hosted or [n8n Cloud](https://n8n.io) — with the three workflows described above imported and active
- API credentials for **Google Gemini**, **PDFShift**, and **Gmail**, configured inside your n8n credentials store

### Installation

```bash
# Clone the repository
git clone https://github.com/mehyash/lms.git
cd lms

# Install Flutter dependencies
flutter pub get
```

### Running on each platform

```bash
# List available devices/emulators
flutter devices

# Run on a connected Android device/emulator
flutter run -d android

# Run on iOS simulator (macOS only)
flutter run -d ios

# Run in a browser (Flutter Web)
flutter run -d chrome
```

### Configuration

1. Point the app's API base URL to your n8n webhook endpoints — look for a config/environment file under `lib/` (e.g. `lib/config/`) and update it with your n8n instance's base URL and the three webhook paths (curriculum generation, form submission, and any others exposed by the app).
2. Import the n8n workflow JSON files into your n8n instance (Workflows → Import from File/URL) and **activate** each one.
3. Add credentials for Gemini, PDFShift, and Gmail inside n8n's Credentials manager, then attach them to the relevant nodes in each workflow.
4. If using OAuth sign-in (Gmail, GitHub, LinkedIn), register OAuth apps with each provider and add the client ID/secret to your app configuration and/or n8n, depending on where auth is handled.

### Setting up n8n

If you don't already have an n8n instance:

```bash
# Quick local instance via Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

Then open `http://localhost:5678`, create the three workflows described in [Automation Workflows](#automation-workflows-n8n) (or import them if workflow export files are provided in the repo), wire up credentials, and copy each workflow's webhook URL into the app's configuration.

---

## Environment Variables

Configuration is primarily handled on the **n8n side** via node credentials, and on the **app side** via a config file pointing to your webhook base URL. Typical values you'll need to supply somewhere in the stack:

| Variable | Used by | Description |
|---|---|---|
| `N8N_BASE_URL` | Flutter app | Base URL of your n8n instance's webhook endpoints |
| `GEMINI_API_KEY` | n8n (Gemini nodes) | Google Gemini API key for curriculum & message generation |
| `PDFSHIFT_API_KEY` | n8n (PDFShift node) | API key for HTML → PDF conversion |
| `GMAIL_OAUTH_CREDENTIALS` | n8n (Gmail node) | OAuth credentials for sending confirmation/alert emails |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` | App auth | GitHub OAuth sign-in |
| `LINKEDIN_CLIENT_ID` / `LINKEDIN_CLIENT_SECRET` | App auth | LinkedIn OAuth sign-in |

> Exact variable names may differ depending on how the app's config file and n8n credentials are structured — treat this table as a checklist of secrets you'll need to obtain rather than literal file contents.

---

## Testing

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/<file_name>_test.dart

# Analyze code for lint/style issues
flutter analyze
```

---

## Building for Release

```bash
# Android (APK)
flutter build apk --release

# Android (App Bundle, for Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode, then archive via Xcode)
flutter build ios --release

# Web
flutter build web --release
```

---

## Roadmap

- [ ] Push notifications for announcements
- [ ] In-app grading/feedback on submissions
- [ ] Admin analytics dashboard

---

## Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push to your branch: `git push origin feature/my-feature`
5. Open a Pull Request describing your change

Please run `flutter analyze` and `flutter test` before submitting a PR.

---

## FAQ / Troubleshooting

**The app can't reach n8n / requests time out.**
Confirm your n8n instance is running and reachable from your device/emulator, that the webhook workflows are **activated** (not just saved), and that the base URL in your app config matches your n8n instance's address exactly (including protocol and port).

**Curriculum generation returns an error or empty PDF.**
Check the Gemini and PDFShift credentials attached to the curriculum workflow's nodes in n8n, and review that workflow's execution log for the failing node.

**I'm not receiving confirmation emails.**
Verify the Gmail credential in n8n is authorized and not expired, and check the workflow's execution history for errors on the "Send Message" node.

**OAuth sign-in isn't working.**
Double-check the redirect URIs registered with Gmail/GitHub/LinkedIn match what the app sends, and that client IDs/secrets are correctly set in the app/n8n configuration.

---

## License

This project is licensed under the **MIT License** — feel free to use and adapt it.

---

## Acknowledgements

- [Flutter](https://flutter.dev) for the cross-platform app framework
- [n8n](https://n8n.io) for workflow automation
- [Google Gemini](https://ai.google.dev) for AI-generated content
- [PDFShift](https://pdfshift.io) for HTML-to-PDF conversion
