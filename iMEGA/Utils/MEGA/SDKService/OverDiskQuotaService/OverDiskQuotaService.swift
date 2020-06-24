import Foundation

@objc final class OverDiskQuotaService: NSObject {

    // MARK: - Static

    @objc(sharedService) static var shared: OverDiskQuotaService = OverDiskQuotaService()

    @objc static func updateAPI(with api: MEGASdk) {
        shared.api = api
    }

    // MARK: - OverDiskQuotaService

    // MARK: - Instance

    private var blockedCommands: [OverDiskQuotaCommand] = []

    private var api: MEGASdk = MEGASdkManager.sharedMEGASdk()

    // MARK: - Lifecycle

    private override init() {}

    // MARK: - Instance Method

    @objc func invalidate() {
        blockedCommands = []
    }

    @objc func updateUserStorageUsed(_ stroageUsed: NSNumber) {
        blockedCommands.forEach { command in
            if command.storageUsed == nil {
                command.storageUsed = stroageUsed
                command.execute(with: api, completion: completion(ofCommand:result:))
            }
        }
    }

    @objc func send(_ command: OverDiskQuotaCommand) {
        blockedCommands.append(command)
        if command.storageUsed != nil {
            command.execute(with: api, completion: completion(ofCommand:result:))
        }
    }

    // MARK: - Privates

    func completion(
        ofCommand command: OverDiskQuotaCommand?,
        result: OverDiskQuotaCommand.OverDiskQuotaFetchResult) -> Void {
        if let command = command {
            remove(command)
        }
    }

    private func remove(_ completedCommand: OverDiskQuotaCommand) {
        blockedCommands.removeAll { command -> Bool in
            command == completedCommand
        }
    }

    // MARK: - Errors

    enum DataObtainingError: Error {
        /// User's email is `nil` after fetching user's data
        case invalidUserEmail
        /// SDK error of fetching data
        case unableToFetchMEGAPlans
        case unableToFetchUserData

        /// Programming error for unexpeded releasing fetching task object.
        case unexpectedlyCancellation
        /// Programming error that for scheduling `OverDiskQuotaCommand` without setting `strorageUsed` property in command.
        case illegaillyScheduling
    }
}
