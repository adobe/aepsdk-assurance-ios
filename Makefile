
export EXTENSION_NAME = AEPAssurance
export APP_NAME = TestApp
export APP_NAME_OBJC = TestAppObjC
PROJECT_NAME = $(EXTENSION_NAME)
TARGET_NAME_XCFRAMEWORK = $(EXTENSION_NAME).xcframework
SCHEME_NAME_XCFRAMEWORK = $(EXTENSION_NAME)XCF

CURR_DIR := ${CURDIR}

SIMULATOR_ARCHIVE_PATH = ./build/ios_simulator.xcarchive/Products/Library/Frameworks/
SIMULATOR_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios_simulator.xcarchive/dSYMs/
IOS_ARCHIVE_PATH = ./build/ios.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios.xcarchive/dSYMs/

setup:
	(pod install)

setup-tools: install-githook

pod-repo-update:
	(pod repo update)

# pod repo update may fail if there is no repo (issue fixed in v1.8.4). Use pod install --repo-update instead
pod-install:
	(pod install --repo-update)

ci-pod-install:
	(bundle exec pod install --repo-update)

pod-update: pod-repo-update
	(pod update)

open:
	open $(PROJECT_NAME).xcworkspace

clean:
	(rm -rf build)

archive: clean pod-update
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(EXTENSION_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(EXTENSION_NAME).framework.dSYM -framework $(IOS_ARCHIVE_PATH)$(EXTENSION_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(EXTENSION_NAME).framework.dSYM -output ./build/$(TARGET_NAME_XCFRAMEWORK)

zip:
	cd build && zip -r $(EXTENSION_NAME).xcframework.zip $(EXTENSION_NAME).xcframework/
	swift package compute-checksum build/$(EXTENSION_NAME).xcframework.zip

test:
	@echo "######################################################################"
	@echo "### Testing iOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(PROJECT_NAME) -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath build/out -resultBundlePath build/$(EXTENSION_NAME)-ios.xcresult -enableCodeCoverage YES

install-githook:
	./tools/git-hooks/setup.sh

lint-autocorrect:
	(./Pods/SwiftLint/swiftlint --fix)

lint:
	(./Pods/SwiftLint/swiftlint lint Sources TestApp/)

# Builds the test apps
build-test-apps: pod-install
	xcodebuild -workspace $(PROJECT_NAME).xcworkspace -scheme $(APP_NAME) -derivedDataPath ./build -sdk iphonesimulator build
	xcodebuild -workspace $(PROJECT_NAME).xcworkspace -scheme $(APP_NAME_OBJC) -derivedDataPath ./build -sdk iphonesimulator build
	(cd build/Build/Products/Debug-iphonesimulator/ && zip -r AEPAssuranceTestApp.zip TestApp.app/)
	(cp build/Build/Products/Debug-iphonesimulator/AEPAssuranceTestApp.zip TestAppBinaries/)

swift-build:
	swift build -Xswiftc "-sdk" -Xswiftc "`xcrun --sdk iphonesimulator --show-sdk-path`" -Xswiftc "-target" -Xswiftc "x86_64-apple-ios10.0-simulator"

check-version:
	(sh ./Script/version.sh $(VERSION))

test-SPM-integration:
	(sh ./Script/test-SPM.sh)

test-podspec:
	(sh ./Script/test-podspec.sh)
