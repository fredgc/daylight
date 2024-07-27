build_all:
	flutter build apk
	# Cannot deploy exectuables. hmm.
	# cp ./build/app/outputs/apk/release/app-release.apk web/daylight.apk
	flutter build web

release:
	make build_all
	firebase deploy


lib/firebase_options.dart: 
	flutterfire configure -y
