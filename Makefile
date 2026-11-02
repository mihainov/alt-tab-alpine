APP_NAME   := AltTabAlpine
IDENTITY   ?= AltTab Dev
BUILD_DIR  := .build/release
APP        := $(APP_NAME).app
INSTALL_DIR ?= $(HOME)/Applications

.PHONY: build bundle sign install run stop test clean reset-permission

build:
	swift build -c release

bundle: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp $(BUILD_DIR)/$(APP_NAME) $(APP)/Contents/MacOS/$(APP_NAME)
	cp Resources/Info.plist $(APP)/Contents/Info.plist

# A stable identity keeps the Accessibility grant across rebuilds; ad-hoc is a fallback. No -v: a self-signed identity is not trusted.
sign: bundle
	@if security find-identity -p codesigning | grep -q "\"$(IDENTITY)\""; then \
		codesign --force --sign "$(IDENTITY)" $(APP); \
	else \
		echo "warning: identity '$(IDENTITY)' not found, using ad-hoc signature"; \
		codesign --force --sign - $(APP); \
	fi

install: sign stop
	mkdir -p $(INSTALL_DIR)
	rm -rf $(INSTALL_DIR)/$(APP)
	cp -R $(APP) $(INSTALL_DIR)/$(APP)

run:
	open $(INSTALL_DIR)/$(APP)

stop:
	-pkill -f "$(INSTALL_DIR)/$(APP)/Contents/MacOS/$(APP_NAME)"

test:
	swift test

clean:
	rm -rf .build $(APP)

# Removes a stale Accessibility entry, for example one from an old signature.
reset-permission: stop
	tccutil reset Accessibility com.dvemar.alttab-alpine
