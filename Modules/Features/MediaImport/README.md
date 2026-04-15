# MediaImport

Self-contained module for importing media files from `NSItemProvider` sources (e.g. PHPicker, drag-and-drop, share extensions).

## Responsibilities

- **Load** file representations from `NSItemProvider` with byte-level progress reporting
- **Stage** files to a sandbox directory with unique, filesystem-safe names
- **Orchestrate** concurrent imports with bounded concurrency (max 3 simultaneous loads)
- **Report** aggregate progress, completion counts, and per-item errors

## Architecture

```
PrepareMediaImportUseCase          (orchestration — drives concurrency, streams progress)
  └─ MediaImportRepositoryProtocol (contract — load + stage a single item)
       └─ MediaImportRepository    (implementation — NSItemProvider + file staging)
            ├─ ContentTypeResolving    (selects preferred UTType per provider)
            └─ FileStagingServiceProtocol (moves/copies file to destination)
```

## Usage

```swift
let repo = MediaImportRepository(destinationDirectory: uploadDir)
let useCase = PrepareMediaImportUseCase(
    itemProviders: results.map(\.itemProvider),
    repository: repo
)

for await progress in useCase.prepareItems() {
    // progress.fractionCompleted  — 0.0 to 1.0 (smooth, byte-level)
    // progress.completedCount     — items fully staged
    // progress.latestPreparedURL  — staged file URL (non-nil on completion)
    // progress.latestError        — per-item error (non-nil on failure)
}
```

## Key Design Decisions

- **NSItemProvider over PHPickerResult** — keeps the module independent of PhotosUI. Works with any NSItemProvider source.
- **No Photos library access** — operates entirely through NSItemProvider, no PHAsset or photo library permissions required.
- **Event channel pattern** — child tasks post events to an internal AsyncStream; all state is managed sequentially in a single consumer loop. No shared mutable state or atomics.
- **UTType.isPublic filtering** — uses documented Apple API to exclude non-loadable internal types, with generic fallback for non-public formats (e.g. GIF).
