# GEMINI.md - Developer Guide for Daylight Local Time

Welcome! This guide is designed to help future LLM agents and human developers
get up to speed quickly on the **Daylight Local Time** Flutter application.

---

## Developer Rules & Environment Configuration

All contributors and AI agents must follow the central rules defined in
`~/source/gemini/config/rules/`:

* **Task Management (`todo.md`)**: Project tasks and issues are tracked using
  `~/bin/todo.py`. When asked about tasks or what to work on next, execute:

  ```bash
  ~/bin/todo.py list
  ```

Before starting an item, mark it in progress (`~/bin/todo.py doing <N>`). Once
completed, mark it done (`~/bin/todo.py done <N>`). Do not archive completed
tasks until reviewed and verified.

* **Communication Style (`style.md`)**: Be blunt and direct. Avoid polite
  filler and superlatives. Keep responses concise, technical, and focused
  strictly on facts and instructions.

* **Documentation Formatting (`markdown.md`)**: Keep line lengths strictly
  under 80 characters. Always separate list items with a blank line. Always
  follow headers with a blank line. Visually align markdown table column
  borders (`|`).

* **Emacs Integration (`emacs.md`)**: When requested to send a file to Emacs,
  run `emacs-maybe-client -f <file>`.

* **Hardware & Testing (`devices.md`)**: On host `raven`, an Android device
  may be connected via `adb` for Android testing.

---

## 1. Project Purpose & Features

**Daylight Local Time** is a Flutter application that computes and displays
time according to solar longitude and daylight intervals rather than standard
political time zones.

### Key Features

* **Geographic Solar Time**: Determines current solar time using browser
  geolocation or manual GPS coordinates.

* **Daylight Proportional Hours**: Simulates historical daylight hours where
  daytime is divided into 12 daylight units, scaling the rate of second-hand
  movement.

* **Analog & Digital Display**: Displays an analog dial with custom layered
  hands alongside digital readouts of solar time, Julian date, and local
  coordinates.

---

## 2. Codebase Architecture

```text
lib/
├── clock.dart       # Analog clock widget, dial painter, and hand overlays
├── location.dart    # GPS geolocation integration and permission handlers
├── main.dart        # Application entry point and Material wrapper
└── time.dart        # Solar time calculations and epoch conversions
```

---

## 3. Build, Versioning & Deployment Workflow

### Build and Asset Automation (`Makefile`)

* `make docs`: Compiles user markdown docs from `doc/*.md` into
  `assets/*.html` and developer docs (`plan.md`, `README.md`, `GEMINI.md`)
  into `assets/dev/*.html` via `pandoc`.

* `make ASSETS`: Generates icons, favicons, version metadata, and docs.

* `make test`: Runs standard Flutter unit, widget, and ARB localization parity
  tests on every commit (`flutter test --exclude-tags release_audit`). Fast
  execution (~2-5 seconds).

* `make audit`: Runs exhaustive pre-release accessibility and multi-locale
  layout audits (`flutter test test/audit_test.dart`). Tests all supported
  locales, compact mobile/tablet/desktop viewports, 1.5x/2.0x font scaling,
  and WCAG AA guidelines (`labeledTapTargetGuideline`). Required automatically
  by `make stage-release` and `make release`.

* `make stage`: Builds web app and deploys to Firebase staging channel.

* `make release`: Deploys production bundle to Firebase
  (`daylight.gchouse.org`).

---

## 4. Code Style Guidelines

* **Markdown**: Keep line lengths strictly under 80 characters. Always
  separate list items with a blank line. Always follow headers with a blank
  line.

* **Dart**: Run `dart format .` after modifying any code. Keep static analysis
  clean (0 errors, 0 lints).
