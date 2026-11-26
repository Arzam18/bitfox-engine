PYTHON ?= python3
PROJECT := $(PYTHON) tools/bitfox.py
ENGINE := engine
BIN := $(ENGINE)/target/release/bitfox
FEATURES :=
FEATFLAG := $(if $(FEATURES),--features $(FEATURES))
WIN_TARGET := x86_64-pc-windows-gnu
EXE :=
RUST_TOOLCHAIN ?= 1.96.0
ANDROID_API_LEVEL ?= 24
ANDROID_NDK_HOST ?= linux-x86_64
ANDROID_TARGET := aarch64-linux-android
ANDROID_LINKER := $(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(ANDROID_NDK_HOST)/bin/aarch64-linux-android$(ANDROID_API_LEVEL)-clang
ANDROID_BIN := $(ENGINE)/target/$(ANDROID_TARGET)/release/bitfox
ANDROID_OUT := release/bitfox-arm64-android-neon

.PHONY: release pgo build test check tools-test gui perft divide run windows android-arm64 version fmt clippy clean help

release:
	$(PROJECT) build $(FEATFLAG)
	$(if $(EXE),cp $(BIN) $(EXE))

pgo:
	tools/pgo-build.sh "$(CPU)" $(ENGINE)/target/bitfox-pgo
	$(if $(EXE),cp $(ENGINE)/target/bitfox-pgo $(EXE))

windows:
	$(PROJECT) build --target $(WIN_TARGET) $(FEATFLAG)
	@echo "built $(ENGINE)/target/$(WIN_TARGET)/release/bitfox.exe"

# Android ARM64 uses the NDK's API-level clang wrapper as the Rust linker.
# NEON is enabled by the aarch64-linux-android target configuration.
android-arm64:
	@test -n "$(ANDROID_NDK_HOME)" || { echo "Set ANDROID_NDK_HOME to the Android NDK directory" >&2; exit 1; }
	@test -x "$(ANDROID_LINKER)" || { echo "Android linker not found: $(ANDROID_LINKER)" >&2; exit 1; }
	cd $(ENGINE) && CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$(ANDROID_LINKER)" cargo +$(RUST_TOOLCHAIN) build --release --locked --target $(ANDROID_TARGET) $(FEATFLAG)
	mkdir -p release
	cp "$(ANDROID_BIN)" "$(ANDROID_OUT)"
	@echo "built $(ANDROID_OUT)"

version:
	@$(PROJECT) version

build:
	$(PROJECT) build --profile dev $(FEATFLAG)

test:
	$(PROJECT) test $(FEATFLAG)

check:
	$(PROJECT) check

tools-test:
	$(PYTHON) -B -m unittest discover -s tools -p 'test_*.py'

gui:
	$(PROJECT) gui configure
	$(PROJECT) gui build

perft:
	$(PROJECT) perft 6

divide: release
	$(BIN) divide 1

run: release
	$(BIN) uci

fmt:
	cd $(ENGINE) && cargo fmt

clippy:
	cd $(ENGINE) && cargo clippy --release --locked $(FEATFLAG) -- -D warnings

clean:
	cd $(ENGINE) && cargo clean
	rm -rf gui-qt/build gui-qt/build-arm64 gui-qt/build-strict \
		gui-qt/build-linux gui-qt/build-macos gui-qt/build-windows build

help:
	@echo "release  build the optimized engine binary and cdylib"
	@echo "pgo      profile-guided release build (CPU=x86-64-v3 for AVX2)"
	@echo "build    debug build"
	@echo "test     run the perft + correctness suite"
	@echo "check    verify shared version, network, ABI and training dependency contracts"
	@echo "tools-test  run the Python tool tests"
	@echo "gui      configure and build the Qt application in build/gui"
	@echo "perft    perft(6) from startpos"
	@echo "divide   perft divide at the root"
	@echo "run      start the engine in UCI mode"
	@echo "windows  cross-compile the Windows engine binary (bitfox.exe)"
	@echo "android-arm64  cross-compile the Android ARM64/NEON UCI engine"
	@echo "version  print the current engine version"
	@echo "fmt      cargo fmt"
	@echo "clippy   cargo clippy (deny warnings)"
	@echo "clean    remove engine, Qt, and native build artifacts"
