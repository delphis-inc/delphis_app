.PHONY: build-models
build-models:
	flutter packages pub run build_runner build --delete-conflicting-outputs

.PHONY: test
test:
	flutter test