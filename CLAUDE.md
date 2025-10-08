# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI iOS application project named "LocalLLM" built with Xcode. The project is structured as a standard iOS app with:

- **Main target**: LocalLLM iOS app (bundle ID: com.shake.LocalLLM)
- **Deployment target**: iOS 26.0
- **Swift version**: 5.0
- **Architecture**: Standard SwiftUI App architecture with @main entry point

## Project Structure

```
LocalLLM.xcodeproj/          # Xcode project file
LocalLLM/                    # Main source directory
├── LocalLLMApp.swift        # App entry point (@main struct)
├── ContentView.swift        # Main view with "Hello, world!" placeholder
└── Assets.xcassets/         # Asset catalog (app icon, accent color)
```

## Development Commands

### Building and Running
- **Build**: Use Xcode's Product → Build (⌘+B) or `xcodebuild -project LocalLLM.xcodeproj -scheme LocalLLM build`
- **Run**: Use Xcode's Product → Run (⌘+R) or run from Xcode simulator/device
- **Clean**: Product → Clean Build Folder (⌘+Shift+K)

### Testing
- **Run tests**: Product → Test (⌘+U) or `xcodebuild test -project LocalLLM.xcodeproj -scheme LocalLLM -destination 'platform=iOS Simulator,name=iPhone 15'`

Note: This is a new project with minimal boilerplate code. No custom test suites, linting configurations, or build scripts have been set up yet.

## Architecture Notes

- **App Entry Point**: LocalLLMApp.swift contains the @main App struct using SwiftUI's WindowGroup
- **Main View**: ContentView.swift contains a simple SwiftUI view with globe icon and "Hello, world!" text
- **Project Configuration**: Uses FileSystemSynchronizedRootGroup (modern Xcode project structure)
- **Capabilities**: SwiftUI previews enabled, automatic code signing configured

## Key Configuration

- **Team ID**: TJ5Q4VG5ZF (configured for automatic code signing)
- **Swift Concurrency**: Approachable concurrency enabled with MainActor isolation by default
- **Features**: String catalog generation, symbol generation enabled
- **Device Support**: Universal (iPhone and iPad)