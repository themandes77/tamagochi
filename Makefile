.PHONY: run

run:
	flutter emulators --launch Flutter_Emulator

update:
	flutter run -d emulator-5554 --hot

build:
	flutter build apk --split-per-abi
