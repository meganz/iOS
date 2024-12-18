import Foundation

protocol StorageFullModalAlertViewRouting: Sendable {
    func startIfNeeded()
}

@MainActor
final class StorageFullModalAlertViewModel {
    private let userDefaultsKey = "MEGAStorageFullNotification"

    private let routing: any StorageFullModalAlertViewRouting

    // We use this to show how much storage needed for the app to run smoothly
    private let requiredStorage: Int64
    // The amount of storage to compare with available disk space.
    // We use this to calculate whether the Storage Full should be show to users or not
    private let limitedSpace: Int64
    // The amount of days apart for the Storage Full page to show
    private let duration = 2

    private let userDefaults: UserDefaults
    private let fileManager: FileManager

    var requiredStorageMemoryStyleString: String {
        String.memoryStyleString(fromByteCount: requiredStorage)
    }

    init(
        routing: some StorageFullModalAlertViewRouting,
        requiredStorage: Int64,
        limitedSpace: Int64,
        fileManager: FileManager = .default,
        userDefaults: UserDefaults = .standard
    ) {
        self.routing = routing
        self.requiredStorage = requiredStorage
        self.limitedSpace = limitedSpace
        self.fileManager = fileManager
        self.userDefaults = userDefaults
    }

    nonisolated func shouldShowAlert() async -> Bool {
        guard limitedSpace <= requiredStorage else { return false }
        let lastStoredDate = Date(
            timeIntervalSince1970: TimeInterval(
                userDefaults.double(
                    forKey: userDefaultsKey
                )
            )
        )
        guard fileManager.mnz_fileSystemFreeSize < limitedSpace,
              lastStoredDate.daysEarlier(than: .now) > duration else {
            return false
        }

        return true
    }

    func update(lastStoredDate: Date) {
        userDefaults.set(
            lastStoredDate.timeIntervalSince1970,
            forKey: userDefaultsKey
        )
    }
}
