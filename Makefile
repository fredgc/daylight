USER_DOCS_MD := $(wildcard doc/*.md)
USER_DOCS_HTML := $(patsubst doc/%.md,assets/%.html,$(USER_DOCS_MD))

# Developer documentation files built from *.md to assets/dev/*.html
DEV_DOCS_MD := $(wildcard plan.md README.md GEMINI.md)
DEV_DOCS_HTML := $(patsubst %.md,assets/dev/%.html,$(DEV_DOCS_MD))

FIREBASE_FILES := lib/firebase_options.dart android/app/google-services.json firebase.json

ASSETS := web/favicon.png web/favicon.ico web/privacy.html web/terms.html web/privacy_es.html web/terms_es.html $(USER_DOCS_HTML) $(FIREBASE_FILES)

.PHONY: docs build_all stage stage-release test release ASSETS audit

docs: $(USER_DOCS_HTML) $(DEV_DOCS_HTML) web/privacy.html web/terms.html web/privacy_es.html web/terms_es.html

assets/%.html: doc/%.md
	@mkdir -p assets
	pandoc $< -s --mathml --css=css/doc_style.css -o $@

assets/dev/%.html: %.md
	@mkdir -p assets/dev
	pandoc $< -f markdown-yaml_metadata_block -s --mathml --metadata pagetitle="$*" --css=../css/doc_style.css -o $@

web/%.html: assets/%.html
	@mkdir -p web/css
	cp -f assets/css/doc_style.css web/css/doc_style.css 2>/dev/null || true
	cp -f $< $@

build_all: $(ASSETS)
	echo XXX flutter build apk
	flutter build web

web/favicon.png: assets/icons/icon.png
	convert $< -background transparent -colorspace RGB -filter Lanczos -resize 32x32 -colorspace sRGB $@

web/favicon.ico: assets/icons/icon.png
	convert $< -define icon:auto-resize=64,48,32,16 -background transparent $@
	dart run flutter_launcher_icons

assets/icons/icon.png assets/icons/foreground.png assets/icons/background.png: icon.xcf
	icon-generate icon.xcf

ASSETS: $(ASSETS)

test:
	flutter test --exclude-tags release_audit

audit: $(ASSETS)
	flutter test test/audit_test.dart

stage:  $(ASSETS)
	flutter build web --dart-define=DEBUG_ENABLED=true
	echo "PURPLE: Beginning push to staging."
	firebase_stage.pl

stage-release: $(ASSETS) audit
	flutter build web
	echo "PURPLE: Beginning push to staging."
	firebase_stage.pl

release: $(ASSETS) audit
	./roll_build_number.sh --release
	make build_all
	firebase deploy


# To add the configuration files, you first need to install firebase,
# and then run firebase login or `firebase login --no-localhost`
# and then run `dart pub global activate flutterfire_cli`.
$(FIREBASE_FILES):
	flutterfire configure -y
