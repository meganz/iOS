import FileProvider
import MEGAPickerFileProviderDomain

public struct FilesAppFavoriteRankRepository: FilesAppFavoriteRankRepositoryProtocol {
    public static var newRepo: FilesAppFavoriteRankRepository {
        guard let sharedUserDefaults =  UserDefaults(suiteName: Self.groupIdentifier) else {
            fatalError("Unable to access shared user defaults, terminating extension")
        }

        return FilesAppFavoriteRankRepository(storage: sharedUserDefaults)
    }

    // Not ideal, this should be in a package for shared use
    private static let groupIdentifier = "group.mega.ios"

    private let storage: UserDefaults

    public init(storage: UserDefaults) {
        self.storage = storage
    }

    public func favoriteRank(for identifier: NSFileProviderItemIdentifier) -> NSNumber? {
        guard let rank = storage.object(forKey: identifier.rawValue) as? NSNumber else {
            return nil
        }

        return rank
    }

    public func setFavoriteRank(for identifier: NSFileProviderItemIdentifier, with rank: NSNumber?) {
        storage.setValue(rank, forKey: identifier.rawValue)
    }
}
