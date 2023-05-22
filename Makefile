PRODUCT_NAME := $(notdir $(shell pwd))

BUILD_TARGET := $(shell xcodebuild -list | sed -n '/Targets:/,/Build Configurations:/p' | grep -v ':' | sed 's/^ *//g' | grep -v '2$$' | grep -v 'Test' | sort -r | head -1)

GIT_HEAD_TAG       := $(shell git tag --points-at HEAD | head -1)
GIT_HEAD_COMMIT_ID := $(shell git rev-parse --short HEAD)
GIT_HEAD_COMMITISH := $(if $(GIT_HEAD_TAG),$(GIT_HEAD_TAG),$(GIT_HEAD_COMMIT_ID))

XCODEBUILD_SETTINGS  := $(shell mktemp)
$(shell xcodebuild -showBuildSettings > "$(XCODEBUILD_SETTINGS)")
FULL_PRODUCT_NAME    := $(shell cat "$(XCODEBUILD_SETTINGS)" | grep -m 1 -E '^\s+FULL_PRODUCT_NAME = '    | sed -E 's/ = /:/' | cut -d ':' -f2-)
DWARF_DSYM_FILE_NAME := $(shell cat "$(XCODEBUILD_SETTINGS)" | grep -m 1 -E '^\s+DWARF_DSYM_FILE_NAME = ' | sed -E 's/ = /:/' | cut -d ':' -f2-)
ARCHS                := $(shell cat "$(XCODEBUILD_SETTINGS)" | grep -m 1 -E '^\s+ARCHS = '                | sed -E 's/ = /:/' | cut -d ':' -f2- | tr ' ' '\n' | sort | xargs | tr ' ' '-')
$(shell rm "$(XCODEBUILD_SETTINGS)")

ifeq ($(ARCHS),arm64-x86_64)
ARCHS := universal2
else ifeq ($(ARCHS),i386-x86_64)
ARCHS := universal
endif

.PHONY: all
all:
	xcodebuild clean && xcodebuild -target "$(BUILD_TARGET)" CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE="Automatic" DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER=""
	command -v postbuild-codesign >/dev/null 2>&1 && postbuild-codesign
	command -v postbuild-notarize >/dev/null 2>&1 && postbuild-notarize
	[ -e "$(FULL_PRODUCT_NAME)" ] && rm -rf "$(FULL_PRODUCT_NAME)"
	cp -R build/Release/$(FULL_PRODUCT_NAME) .

.PHONY: dist
dist: all
	mkdir -p dist
	ditto -c -k --sequesterRsrc --keepParent build/Release/$(FULL_PRODUCT_NAME) dist/$(PRODUCT_NAME)-$(GIT_HEAD_COMMITISH)-darwin-$(ARCHS).zip
	ditto -c -k --sequesterRsrc --keepParent build/Release/$(DWARF_DSYM_FILE_NAME) dist/$(PRODUCT_NAME)-$(GIT_HEAD_COMMITISH)-darwin-$(ARCHS)-dsym.zip

.PHONY: archive
archive:
	mkdir -p "build/Release"
	git archive -o "build/Release/$(PRODUCT_NAME)-$(GIT_HEAD_COMMITISH)-src.zip" HEAD

.PHONY: test
test:
	xcodebuild test -scheme $(shell xcodebuild -list | grep -A1 'Schemes:' | tail -1 | xargs)

.PHONY: clean
clean:
	rm -rf build dist $(FULL_PRODUCT_NAME)
