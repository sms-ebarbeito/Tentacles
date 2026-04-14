---
name: Tentacle project structure and asset issues
description: Structure of the Tentacle/BuddyApp Swift project and missing asset files
type: project
---

Swift Package Manager project for a macOS menu bar app (octopus buddy). Key structure:

- `Sources/BuddyApp/` — main app target (SwiftUI + Cocoa)
- `Sources/BuddyCore/` — core logic
- `build-app.sh` — assembles `.app` bundle manually after `swift build`

**Asset issues identified:**
- `tentacles-sprites.png` only exists in `.build/`, NOT in source. The sprite is actually hardcoded in `Sprite.swift` as ASCII pixel arrays — the PNG in `.build` is compiler-generated.
- `AppIcon.icns` is NOT in the repo. `build-app.sh` looks for it at `/tmp/AppIcon.icns` (line 20).
- `Sources/BuddyApp/Resources/` directory does not exist yet but should.

**Plan agreed with user:**
- Create `Sources/BuddyApp/Resources/` and put the PNG and icns there
- Declare resources in `Package.swift` with `.resources: [.process(...)]`
- Update `build-app.sh` to copy from `Sources/BuddyApp/Resources/` instead of `/tmp/`

**Why:** Assets should be tracked in the repo, not floating in /tmp or only in build artifacts.
**How to apply:** When touching build or resource loading code, follow this plan.
