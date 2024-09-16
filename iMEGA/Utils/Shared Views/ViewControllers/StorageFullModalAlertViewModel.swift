import Foundation

protocol StorageFullModalAlertViewRouting: Sendable {
    func startIfNeeded()
}

@MainActor
final class StorageFullModalAlertViewModel {
    private let userDefaultsKey = "MEGAStorageFullNotification"
    private let limitedSpace = 100 * 1024 * 1024
    private let duration = 2
    private let routing: any StorageFullModalAlertViewRouting
    private let requiredStorage: Int64
    private let userDefaults: UserDefaults
    private let fileManager: FileManager

    var requiredStorageMemoryStyleString: String {
        String.memoryStyleString(fromByteCount: requiredStorage)
    }

    init(
        routing: some StorageFullModalAlertViewRouting,
        requiredStorage: Int64,
        fileManager: FileManager = .default,
        userDefaults: UserDefaults = .standard
    ) {
        self.routing = routing
        self.requiredStorage = requiredStorage
        self.fileManager = fileManager
        self.userDefaults = userDefaults
    }

    nonisolated func shouldShowAlert() async -> Bool {
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
