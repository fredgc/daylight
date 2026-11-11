# Daylight Local Time

An interactive Flutter clock application that displays solar time and daylight
hours based on exact geographical coordinates.

* **Live Web App**: [daylight.gchouse.org](https://daylight.gchouse.org)

* **Android Package**: `org.gchouse.daylight`

---

## Documentation

In-depth documentation and policies are located in `doc/`:

* [doc/privacy.md](doc/privacy.md) : Privacy policy detailing location
  permission usage and local storage.

* [doc/terms.md](doc/terms.md) : Terms of service.

---

## Core Features

* **Local Solar Time**: Calculates local time from geographic longitude rather
  than political time zone boundaries.

* **Variable Second Rates**: Animates custom clock hands calibrated to local
  daylight progression.

* **Location Permissions**: Requests browser or device location permissions
  with fallback to manual coordinate inputs.

---

## Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+
  recommended)

* `make` and [Pandoc](https://pandoc.org/) (for compiling documentation)

### Forking and Cloning

1. Fork the repository on GitHub to your account.

2. Clone your fork locally:

   ```bash
   git clone https://github.com/<your-username>/daylight.git
   cd daylight
   ```

3. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

4. Build documentation assets:

   ```bash
   make docs
   ```

### Running Locally

To launch the web app in Chrome:

```bash
flutter run -d chrome
```

To run on a connected Android device or emulator:

```bash
flutter run -d android
```

### Running Tests

Execute the unit and widget test suite:

```bash
flutter test
```

### Building Releases

Use the provided `Makefile` to generate release assets:

```bash
make build_all
```

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

---

## License

This project is open-source and licensed under the
[Apache 2.0 License](LICENSE) .

---

## Disclaimer

This project is not an official Google project. It is not supported by Google
and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.
