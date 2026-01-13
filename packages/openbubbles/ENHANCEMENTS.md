# OpenBubbles Enhancement Plan: Build from Source

This document contains detailed research and implementation notes for upgrading from the current binary wrapper to a full source build approach.

## Current Implementation

**Status**: Binary Wrapper (v1.15.0+190)
- Downloads prebuilt tarball from GitHub releases
- Uses `autoPatchelfHook` for library patching
- Simple, fast, works immediately
- Less reproducible, larger closure size

## Future Enhancement: Source Build

Build from source using Flutter 3.29, similar to how BlueBubbles is packaged in nixpkgs.

---

## Technology Stack Details

### Primary Framework
- **Flutter SDK**: 3.29 (constraint: `>=3.1.3 <4.0.0`)
- **Language**: Dart
- **Native Components**: Rust integration via Flutter Rust Bridge 2.3.0

### Key Dependencies

1. **Rust Components**:
   - `rust_lib_bluebubbles` (local Rust library in `rust_builder/`)
   - Flutter Rust Bridge 2.3.0 for Dart-Rust FFI
   - `rustpush` git submodule (Apple push notification handling)
   - **Requires**: Rust toolchain (cargo, rustc) for compilation

2. **ObjectBox Database**:
   - Version: 4.0.2 C library
   - **License**: Unfree/proprietary (requires `allowUnfree = true`)
   - Requires downloading prebuilt binaries for x64/aarch64
   - Custom CMake integration patch needed

3. **Platform Libraries (Linux)**:
   - GTK 3 (webkitgtk-4.1)
   - libnotify
   - libayatana-appindicator
   - JDK (Java Development Kit)
   - mpv (media player library)
   - Media Kit native libraries

4. **Git Submodules**:
   - `rustpush` - Apple push notification library (master branch)
   - `android-smsmms` - Android SMS/MMS library (master branch)
   - **Important**: Must use `fetchSubmodules = true` in fetchFromGitHub

---

## BlueBubbles Package Analysis

Located: `/nix/store/.../pkgs/by-name/bl/bluebubbles/package.nix`

### Build System

```nix
flutter329.buildFlutterApplication rec {
  pname = "bluebubbles";
  version = "1.10.0+73";

  src = fetchFromGitHub {
    owner = "BlueBubblesApp";
    repo = "bluebubbles-app";
    tag = "v${version}-desktop";
    hash = "sha256-...";
    fetchSubmodules = true;  # Critical for rustpush
  };

  # Frozen dependency versions
  pubspecLock = lib.importJSON ./pubspec.lock.json;

  # Git-based dependencies with fixed hashes
  gitHashes = {
    desktop_webview_auth = "sha256-...";
    disable_battery_optimization = "sha256-...";
    firebase_dart = "sha256-...";
    gesture_x_detector = "sha256-...";
    local_notifier = "sha256-...";
    permission_handler_windows = "sha256-...";
    video_thumbnail = "sha256-...";
  };

  # Custom builder for ObjectBox (unfree library)
  customSourceBuilders.objectbox_flutter_libs =
    callPackage ./objectbox_flutter_libs.nix { };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    webkitgtk_4_1
    libnotify
    libayatana-appindicator
    jdk
    mpv
  ];

  preBuild = ''
    echo 'TENOR_API_KEY=AIzaSy...' > .env
  '';

  postInstall = ''
    # Fix desktop entry icon path
    substituteInPlace $out/share/applications/bluebubbles.desktop \
      --replace "Icon=bluebubbles" "Icon=$out/share/pixmaps/bluebubbles.png"
  '';

  extraWrapProgramArgs = ''
    --prefix LD_LIBRARY_PATH : $out/app/bluebubbles/lib
  '';
}
```

### ObjectBox Custom Builder

File: `objectbox_flutter_libs.nix`

```nix
{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "objectbox_flutter_libs";
  version = "4.0.2";

  src = fetchurl {
    url = "https://github.com/objectbox/objectbox-c/releases/download/v${version}/objectbox-linux-${stdenv.hostPlatform.uname.processor}.tar.gz";
    hash = if stdenv.isAarch64
      then "sha256-..."  # aarch64 hash
      else "sha256-..."; # x86_64 hash
  };

  installPhase = ''
    mkdir -p $out/lib
    cp -r lib/* $out/lib/
    mkdir -p $out/include
    cp -r include/* $out/include/
  '';

  # Patch CMakeLists.txt to use Nix store path
  # instead of FetchContent downloading at build time
}
```

### Dependency Management

1. **pubspec.lock.json**:
   - Generated from `pubspec.lock` using Dart tooling
   - Command: `dart pub deps --json > pubspec.lock.json`
   - Freezes all Dart/Flutter package versions

2. **gitHashes**:
   - At least 7+ git-based dependencies require SHA256 hashes
   - Each must be prefetched: `nix-prefetch-git <url> --rev <commit>`
   - Time-consuming but ensures reproducibility

---

## Implementation Roadmap

### Phase 1: Preparation

1. **Generate pubspec.lock.json**:
   ```bash
   # Clone OpenBubbles repo
   git clone https://github.com/OpenBubbles/openbubbles-app
   cd openbubbles-app

   # Generate lock file
   nix-shell -p dart --run 'dart pub deps --json > pubspec.lock.json'

   # Copy to package directory
   cp pubspec.lock.json ~/.config/snowfall/packages/openbubbles/
   ```

2. **Generate git dependency hashes**:
   ```bash
   # For each git dependency in pubspec.yaml:
   nix-prefetch-git https://github.com/user/repo --rev <commit-hash>

   # Dependencies to hash (check pubspec.yaml for current list):
   # - desktop_webview_auth
   # - disable_battery_optimization
   # - firebase_dart
   # - gesture_x_detector
   # - local_notifier
   # - permission_handler_windows
   # - video_thumbnail
   # - (may be more in OpenBubbles fork)
   ```

3. **Copy ObjectBox builder from BlueBubbles**:
   ```bash
   # Extract from nixpkgs
   nix-build '<nixpkgs>' -A bluebubbles.customSourceBuilders.objectbox_flutter_libs --out-link objectbox-builder

   # Copy to package directory
   cp -r objectbox-builder/* ~/.config/snowfall/packages/openbubbles/
   ```

### Phase 2: Rust Integration (Biggest Challenge)

The most complex part is integrating Rust FFI build with Flutter.

**Challenge**: `rust_lib_bluebubbles` must be compiled during Flutter build

**Possible Approaches**:

1. **Custom Build Hook** (similar to ObjectBox):
   ```nix
   customSourceBuilders.rust_lib_bluebubbles = callPackage ./rust_builder.nix { };
   ```

2. **Pre-build Rust Library**:
   ```nix
   preBuild = ''
     # Build Rust library
     cd rust_builder
     cargo build --release
     cd ..

     # Copy to expected location
     mkdir -p build/linux/x64/release/bundle/lib
     cp rust_builder/target/release/librust_lib_bluebubbles.so \
       build/linux/x64/release/bundle/lib/
   '';
   ```

3. **Study rustdesk-flutter** (reference):
   - Package in nixpkgs that combines Flutter + Rust
   - Location: `pkgs/by-name/ru/rustdesk-flutter/`
   - May provide patterns for Cargo integration

**Requirements**:
```nix
nativeBuildInputs = [
  autoPatchelfHook
  cargo              # Rust compiler
  rustc              # Rust toolchain
  rustPlatform.cargoSetupHook
];
```

### Phase 3: Complete Source Build Package

**File**: `packages/openbubbles/default.nix` (source build version)

```nix
{
  lib,
  callPackage,
  flutter329,
  fetchFromGitHub,
  autoPatchelfHook,
  cargo,
  rustc,
  rustPlatform,
  webkitgtk_4_1,
  libnotify,
  libayatana-appindicator,
  jdk,
  mpv,
}:

flutter329.buildFlutterApplication rec {
  pname = "openbubbles";
  version = "1.15.0+190";

  src = fetchFromGitHub {
    owner = "OpenBubbles";
    repo = "openbubbles-app";
    tag = "v${version}";
    hash = "sha256-...";  # Need to generate
    fetchSubmodules = true;  # CRITICAL: rustpush submodule
  };

  # Import frozen dependencies
  pubspecLock = lib.importJSON ./pubspec.lock.json;

  # Custom builder for ObjectBox (reuse from BlueBubbles)
  customSourceBuilders.objectbox_flutter_libs =
    callPackage ./objectbox_flutter_libs.nix { };

  # Git-based dependencies with fixed hashes
  gitHashes = {
    # TODO: Generate all hashes
    desktop_webview_auth = "sha256-...";
    disable_battery_optimization = "sha256-...";
    firebase_dart = "sha256-...";
    gesture_x_detector = "sha256-...";
    local_notifier = "sha256-...";
    permission_handler_windows = "sha256-...";
    video_thumbnail = "sha256-...";
    # ... add others as needed
  };

  nativeBuildInputs = [
    autoPatchelfHook
    cargo
    rustc
    rustPlatform.cargoSetupHook
  ];

  buildInputs = [
    webkitgtk_4_1
    libnotify
    libayatana-appindicator
    jdk
    mpv
  ];

  preBuild = ''
    # TENOR API key for GIF search
    echo 'TENOR_API_KEY=AIzaSy...' > .env

    # Build Rust FFI library
    cd rust_builder
    cargo build --release
    cd ..

    # Ensure submodules are initialized
    # (fetchSubmodules should handle this, but verify)
  '';

  postInstall = ''
    # Install desktop entry and icon
    install -Dm0644 snap/gui/bluebubbles.desktop \
      $out/share/applications/openbubbles.desktop
    install -Dm0644 snap/gui/bluebubbles.png \
      $out/share/pixmaps/openbubbles.png

    # Fix desktop entry (rename bluebubbles -> openbubbles)
    substituteInPlace $out/share/applications/openbubbles.desktop \
      --replace "bluebubbles" "openbubbles" \
      --replace "Exec=bluebubbles" "Exec=openbubbles" \
      --replace "Icon=bluebubbles" "Icon=$out/share/pixmaps/openbubbles.png"
  '';

  extraWrapProgramArgs = ''
    --prefix LD_LIBRARY_PATH : $out/app/bluebubbles/lib
  '';

  meta = {
    description = "Open-source cross-platform ecosystem for Apple platform services";
    homepage = "https://openbubbles.app";
    mainProgram = "bluebubbles";  # Binary name in pubspec.yaml
    license = lib.licenses.unfree;  # Due to ObjectBox
    platforms = lib.platforms.linux;
  };
}
```

---

## Known Challenges & Solutions

### Challenge 1: Rust FFI Integration

**Problem**: Flutter Rust Bridge requires coordinating Rust build with Flutter build

**Solutions**:
- Study `rustdesk-flutter` package in nixpkgs
- Use `preBuild` hook to compile Rust library first
- May need custom source builder like ObjectBox
- Ensure `CARGO_HOME` is properly configured

**Testing**:
```bash
# Verify Rust library builds standalone
cd rust_builder
nix-shell -p cargo rustc --run 'cargo build --release'
```

### Challenge 2: Git Submodules

**Problem**: `rustpush` submodule is critical for functionality

**Solution**:
- Always use `fetchSubmodules = true` in `fetchFromGitHub`
- Verify submodule commit matches release tag
- Check `.gitmodules` for correct URLs

**Verification**:
```bash
# In source checkout
git submodule status
# Should show: <commit> rust_builder/rustpush (tags/vX.X.X)
```

### Challenge 3: ObjectBox Unfree License

**Problem**: ObjectBox C library is proprietary

**Solution**:
- Set `meta.license = lib.licenses.unfree;`
- Document in package that users need `allowUnfree = true`
- Your system already has this enabled in flake config

**User Impact**: None (already configured)

### Challenge 4: Git Dependency Hashes

**Problem**: 7+ git dependencies need SHA256 hashes

**Solution**:
- Script the hash generation:
  ```bash
  #!/usr/bin/env bash
  # generate-git-hashes.sh

  # Parse pubspec.yaml for git dependencies
  # For each dependency:
  for dep in desktop_webview_auth disable_battery_optimization ...; do
    echo "Fetching $dep..."
    nix-prefetch-git <url> --rev <commit>
  done
  ```

**Time Investment**: ~30-60 minutes for all hashes

### Challenge 5: Binary Name Confusion

**Problem**: Source still references "bluebubbles" internally

**Solution**:
- Keep binary name as "bluebubbles" (as specified in pubspec.yaml)
- Rename only in desktop files and user-facing locations
- Use wrapper symlink: `openbubbles` -> `bluebubbles`

**Alternative**: Patch CMakeLists.txt to change `BINARY_NAME`

---

## Testing Strategy

### Phase 1: Basic Build
```bash
# Test source build
nix build .#openbubbles-source --print-build-logs

# Expected: Flutter build completes, all libraries linked
```

### Phase 2: Runtime Testing
```bash
# Run directly
./result/bin/openbubbles

# Check for:
# - Window opens
# - No library loading errors
# - Rust FFI works (core functionality)
```

### Phase 3: Full Integration
```bash
# Install via home-manager
home.packages = [ pkgs.openbubbles-source ];

# Test:
# - Desktop entry appears
# - Icon displays correctly
# - Launches from Wofi
```

---

## Migration Plan

### Step 1: Parallel Package
Create `packages/openbubbles-source/default.nix` alongside current binary wrapper

### Step 2: Testing Period
```nix
# In tachi home config, test both:
home.packages = with pkgs; [
  openbubbles        # Binary wrapper (current)
  openbubbles-source # Source build (new)
];
```

### Step 3: Cutover
Once source build is stable:
1. Rename `openbubbles` -> `openbubbles-bin`
2. Rename `openbubbles-source` -> `openbubbles`
3. Remove binary wrapper after verification

---

## Reference Links

- [BlueBubbles nixpkgs package](https://github.com/NixOS/nixpkgs/tree/master/pkgs/by-name/bl/bluebubbles)
- [OpenBubbles GitHub](https://github.com/OpenBubbles/openbubbles-app)
- [Flutter Rust Bridge docs](https://cjycode.com/flutter_rust_bridge/)
- [ObjectBox C library](https://github.com/objectbox/objectbox-c)
- [RustDesk Flutter package](https://github.com/NixOS/nixpkgs/tree/master/pkgs/by-name/ru/rustdesk-flutter) (reference for Flutter+Rust)

---

## Estimated Effort

- **Preparation**: 2-3 hours (dependency hashing, file generation)
- **Rust Integration**: 4-6 hours (most complex part)
- **Testing & Refinement**: 2-3 hours
- **Total**: 8-12 hours

**Recommendation**: Tackle this during a focused development session when you have time to troubleshoot build issues.

---

## Benefits of Source Build

1. **Reproducibility**: Pin exact source commit, all dependencies frozen
2. **Customization**: Can patch source, modify features
3. **Security**: Build from auditable source, not prebuilt binaries
4. **Nix Purity**: Fully integrated with Nix build system
5. **Smaller Closure**: Only needed libraries, not entire prebuilt bundle

## Current Binary Wrapper Trade-offs

**Pros**:
- Works immediately
- Simple to maintain
- Less failure points

**Cons**:
- Larger closure size
- Less reproducible
- Can't modify source
- Dependent on upstream binary releases

---

*Document created: 2025-12-23*
*Current OpenBubbles version: 1.15.0+190*
*Current implementation: Binary wrapper*
