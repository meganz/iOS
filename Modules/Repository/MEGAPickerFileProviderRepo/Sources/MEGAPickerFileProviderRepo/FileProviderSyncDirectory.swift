import Foundation
import MEGAAppSDKRepo

enum FileProviderSyncDirectory {
    /// Where the extension keeps the snapshots and the change queue. The app deletes it on logout with the rest of
    /// the app group container; only the extension writes it.
    static var url: URL {
        AppGroupContainer(fileManager: .default).url(for: .fileProviderSync)
    }
}
