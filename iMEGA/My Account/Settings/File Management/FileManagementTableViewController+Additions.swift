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

    /// Returns the SDK's current FileService cache allocation.
    ///
    /// Also logs the allocated and reclaimable byte counts for diagnostics.
    ///
    /// - Returns: The number of bytes currently allocated by the FileService cache.
    @objc nonisolated func videoCacheAllocatedSize() -> UInt64 {
        let info = MEGASdk.shared.fileServiceStorageInfo(with: nil)
        let allocated = info?.allocatedSize ?? 0
        let reclaimable = info?.reclaimableSize ?? 0
        MEGALogInfo("[FileService] cache allocated=\(allocated) reclaimable=\(reclaimable)")
        return allocated
    }

    /// Reclaims the entire FileService cache regardless of file age or current size.
    ///
    /// Uses one-shot options (`ageThreshold`, `reclaimTarget`, `reclaimThreshold` all `0`)
    /// so the SDK's persistent reclaim configuration is left untouched.
    ///
    /// - Parameter completion: Closure invoked on the main queue once the SDK signals
    ///   the reclaim has finished, whether it succeeded or failed.
    @objc func reclaimVideoCache(completion: @escaping @Sendable () -> Void) {
        let options = MEGAFileServiceReclaimOptions()
        options.ageThreshold = 0       // any file age qualifies
        options.reclaimTarget = 0      // reduce used space to 0
        options.reclaimThreshold = 0   // no minimum trigger threshold (clear regardless of size)

        MEGASdk.shared.fileServiceReclaim(with: options, delegate: RequestDelegate { (result: Result<MEGARequest, MEGAError>) in
            let after = MEGASdk.shared.fileServiceStorageInfo(with: nil)?.allocatedSize ?? 0
            switch result {
            case .success(let request):
                MEGALogInfo("[FileService] reclaim done: after=\(after) reclaimed=\(request.totalBytes)")
            case .failure(let error):
                MEGALogError("[FileService] reclaim failed: code=\(error.type.rawValue) after=\(after)")
            }
            DispatchQueue.main.async {
                completion()
            }
        })
    }
}
