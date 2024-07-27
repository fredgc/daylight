# Daylight Local Time

This project creates a clock using the Daylight Local Time zone.

As a Dart / Flutter project, it has two interesting things:

1. It uses the package location.dart to get the users location. For this reason,
   it has to ask for some special permissions.

2. It uses flutter_analog_clock.dart to draw a clock. However, since our clock
   does not move the second hand at the same rate as a normal clock, we have to
   set the normal clock's second hand length to zero, and then use some stacking
   widgets to draw our own second hand.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.

## Disclaimer

This project is not an official Google project. It is not supported by
Google and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.
