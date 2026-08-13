import Foundation

/// How much room the device has left.
///
/// A plain reading of system state with no business meaning attached, so it lives here rather than
/// behind a repository: anything that needs the figure can ask for it directly, and the layers that
/// want it injectable are free to wrap it.
public struct DeviceStorage: Sendable {
    /// The volume the app itself lives on, which is where downloads, caches and the offline store land.
    public static let current = DeviceStorage()

    private let volumeURL: URL
    private let systemFreeSize: @Sendable (String) -> UInt64?

    init(
        volumeURL: URL = URL(fileURLWithPath: NSHomeDirectory()),
        systemFreeSize: @escaping @Sendable (String) -> UInt64? = DeviceStorage.readSystemFreeSize
    ) {
        self.volumeURL = volumeURL
        self.systemFreeSize = systemFreeSize
    }

    /// - Returns: The bytes the device can still make available for content the user expects to keep
    ///   around, or `nil` when the volume cannot be queried at all.
    public func availableCapacity() -> UInt64? {
        importantUsageCapacity() ?? systemFreeSize(volumeURL.path)
    }

    /// `volumeAvailableCapacityForImportantUsage` is the figure the system is willing to free up for
    /// content the user expects to keep, which is what a download lands as — unlike the raw free size,
    /// it accounts for purgeable space.
    private func importantUsageCapacity() -> UInt64? {
        do {
            let values = try volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            guard let capacity = values.volumeAvailableCapacityForImportantUsage else { return nil }
            return capacity > 0 ? UInt64(capacity) : 0
        } catch {
            return nil
        }
    }

    /// Kept to match what the ObjC `mnz_fileSystemFreeSize` has relied on for years: the volume query
    /// does occasionally fail, and a raw free size beats having no answer at all — without this, a
    /// failed query reads as "cannot tell" and every caller has to invent a policy for that.
    ///
    /// Injected rather than called inline so the fallback can be exercised while the query above it is
    /// failing, which no real path lets us arrange.
    private static let readSystemFreeSize: @Sendable (String) -> UInt64? = { path in
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: path),
              let freeSize = attributes[.systemFreeSize] as? NSNumber else {
            return nil
        }
        return freeSize.uint64Value
    }
}
