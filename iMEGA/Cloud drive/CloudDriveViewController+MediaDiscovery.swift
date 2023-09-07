import Foundation

extension CloudDriveViewController {
    @objc func shouldShowMediaDiscovery() -> Bool {
        guard let parent = parentNode else { return false }
        
        return parent.type != .root && hasMediaFiles && !isFromSharedItem
    }
    
    @objc func configureMediaDiscoveryViewMode() {
        clearViewModeChildren()
    }
}
