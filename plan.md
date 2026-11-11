# Daylight Local Time Plan

This document outlines the strategic roadmap, mathematical foundations, and
milestones for the **Daylight Local Time** project.

> **Note**: Active day-to-day tasks and issue tracking are managed dynamically
> using `~/bin/todo.py`. Run `~/bin/todo.py list` to view active tasks.

---

## 1. Astronomical Time Calculation & Physics

* **True Solar Time vs Mean Solar Time**: Incorporate the equation of time
  (orbital eccentricity and axial obliquity) to accurately compute true local
  solar noon based on geographic longitude.

* **Variable Second Rates**: Dynamically calculate local daylight hours
  between sunrise and sunset, adjusting daylight seconds so 12 daylight hours
  divide solar daytime proportionally throughout the year.

---

## 2. Clock Face & UI Rendering

* **Custom Vector Clock Face**: Replace third-party widget dependencies with a
  custom `CustomPainter` clock face supporting:

  - Custom dial markers and numerical typography.

  - Distinctive hour, minute, and daylight second hands.

  - Embedded solar position / elevation indicators.

* **Responsive Sizing & Dark Mode**: Implement responsive scaling for mobile
  screens and support dark mode themes.

---

## 3. Platform Distribution & Android Package

* Package Android APK and deploy to Google Play (`org.gchouse.daylight`).

* Test GPS permissions and location fallback flows across Android versions.

---

## 4. Visual & Accessibility Verification Checklist

Perform these manual checks across supported locales (`en`, `es`, `de`, `fr`,
`ja`, `lt`, `pt`, `zh`) on mobile and desktop viewports:

* **Clock Dial & Solar Arcs**:

  * [ ] Verify the Daylight Local Time clock dial, sunrise/sunset arcs, and
        twilight shading render accurately in both light and dark themes.

  * [ ] Verify the clock hands (hour, minute, solar position) rotate smoothly
        and do not obscure numeric markings.

* **Date, Time & Location Controls**:

  * [ ] Test the date picker, timezone selector, and latitude/longitude inputs
        to ensure text fields and labels do not clip in longer languages.

  * [ ] Confirm that GPS permission requests and location fallback dialogs
        display translated strings for all supported languages.

* **Language Menu & Settings**:

  * [ ] Switch to each language from the top bar language menu and confirm all
        UI labels, clock metrics, and dialog titles update immediately.

  * [ ] Switch to **Auto** and verify the app reverts cleanly to the system
        default locale.

* **Touch Targets & Screen Readers**:

  * [ ] Verify date/time buttons, search triggers, and settings icons meet the
        48x48 dp minimum touch target requirement on mobile devices.

  * [ ] Enable TalkBack (Android) or VoiceOver (iOS/macOS) and confirm that
        the current daylight time and solar events are announced clearly.
