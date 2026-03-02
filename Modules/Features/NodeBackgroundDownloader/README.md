# NodeBackgroundDownloaderManager

A Swift Package for handling background downloads using iOS BackgroundTasks framework.

## Overview

NodeBackgroundDownloaderManager provides a comprehensive solution for downloading files in the background using `BGContinuedProcessingTask`. It manages task scheduling, progress tracking, and handles task expiration gracefully with user notifications.

## Requirements

- iOS 26.0+
- Swift 6.0+

## Features

- Background download support using BackgroundTasks framework
- Progress tracking and reporting
- Task expiration handling with notifications
- Swift Concurrency (async/await) support
- Actor-based progress tracking for thread safety

## Package Structure

```
NodeBackgroundDownloaderManager/
├── Sources/
│   ├── NodeBackgroundDownloaderManager/
│   │   ├── BackgroundDownloadHandler.swift
│   │   ├── BackgroundTaskExpirationNotifier.swift
│   │   ├── BackgroundTaskProgressMonitor.swift
│   │   ├── BackgroundTaskScheduler.swift
└── Package.swift
```

## Usage

### Basic Usage

```swift
BackgroundDownloadHandler.shared.handleBackgroundDownload(for: node)
```

## Architecture

### Core Components

#### BackgroundDownloadHandler
Main coordinator that orchestrates the background download process.

#### BackgroundTaskExpirationNotifier
Tirgger a local notification when background task expires

#### BackgroundTaskProgressMonitor
Monitor the progress updates related to a node

#### BackgroundTaskScheduler
Handles registration and submission of background tasks to the system.

## Dependencies

- **MEGADomain**: Core domain models and entities
- **MEGARepo**: Repository protocols and implementations
- **MEGAL10n**: Localization strings
- **BackgroundTasks**: Apple's framework for background task scheduling

## Registering Background Tasks in Info.plist

Don't forget to register your background task identifiers in your app's `Info.plist`:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER).transfers.BGContinuedProcessingTask</string>
</array>
```
