import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASdk
import SwiftUI
import UIKit

extension FileManagementTableViewController {
    @objc func updateLabelAppearance() {
        clearOfflineFilesLabel.textColor = TokenColors.Text.primary
        clearCacheLabel.textColor = TokenColors.Text.primary
        fileVersioningLabel.textColor = TokenColors.Text.primary
        fileVersioningDetail.textColor = TokenColors.Text.primary
        useMobileDataLabel.textColor = TokenColors.Text.primary
    }
    
    open override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerFooterView = view as? UITableViewHeaderFooterView else { return }
        
        headerFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }
    
    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let headerFooterView = view as? UITableViewHeaderFooterView else { return }
        
        headerFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }
    
    @objc func isNewFileManagementSettingsEnabled() -> Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newSetting)
    }

    /// Returns the FileService cache allocation summed across the
    /// authenticated SDK and the folder-link SDK.
    ///
    /// - Returns: The total bytes currently allocated by the FileService
    ///   cache across both SDK instances.
    @objc nonisolated func videoCacheAllocatedSize() -> UInt64 {
        let authInfo = MEGASdk.shared.fileServiceStorageInfo(with: nil)
        let authAllocated = authInfo?.allocatedSize ?? 0
        let authReclaimable = authInfo?.reclaimableSize ?? 0

        let folderInfo = MEGASdk.sharedFolderLinkSdk.fileServiceStorageInfo(with: nil)
        let folderAllocated = folderInfo?.allocatedSize ?? 0
        let folderReclaimable = folderInfo?.reclaimableSize ?? 0

        let totalAllocated = authAllocated + folderAllocated
        let totalReclaimable = authReclaimable + folderReclaimable
        MEGALogInfo("[FileService] cache allocated=\(totalAllocated) reclaimable=\(totalReclaimable) (auth=\(authAllocated)/\(authReclaimable) folderLink=\(folderAllocated)/\(folderReclaimable))")
        return totalAllocated
    }

    /// Reclaims the entire FileService cache regardless of file age or
    /// current size
    ///
    /// - Parameter completion: Closure invoked on the main queue once both
    ///   SDK reclaims have finished.
    @objc func reclaimVideoCache(completion: @escaping @Sendable () -> Void) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await Self.reclaim(on: .shared, label: "auth") }
                group.addTask { await Self.reclaim(on: .sharedFolderLinkSdk, label: "folderLink") }
            }
            completion()
        }
    }

    private nonisolated static func reclaim(on sdk: MEGASdk, label: String) async {
        let options = MEGAFileServiceReclaimOptions()
        options.ageThreshold = 0       // any file age qualifies
        options.reclaimTarget = 0      // reduce used space to 0
        options.reclaimThreshold = 0   // no minimum trigger threshold (clear regardless of size)

        let result: Result<MEGARequest, MEGAError> = await withCheckedContinuation { continuation in
            sdk.fileServiceReclaim(with: options, delegate: RequestDelegate { result in
                continuation.resume(returning: result)
            })
        }

        let after = sdk.fileServiceStorageInfo(with: nil)?.allocatedSize ?? 0
        switch result {
        case .success(let request):
            MEGALogInfo("[FileService] reclaim(\(label)) done: after=\(after) reclaimed=\(request.totalBytes)")
        case .failure(let error):
            MEGALogError("[FileService] reclaim(\(label)) failed: code=\(error.type.rawValue) after=\(after)")
        }
    }
}
