import UIKit

public extension UITableView {
    @objc func hasRow(at indexPath: IndexPath) -> Bool {
        return indexPath.section < self.numberOfSections && indexPath.row < self.numberOfRows(inSection: indexPath.section)
    }
    
    @objc func sizeHeaderToFit() {
        guard let header = tableHeaderView else { return }
        header.setNeedsLayout()
        header.layoutIfNeeded()
        
        let height = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var frame = header.frame
        
        frame.size.height = height
        header.frame = frame
        
        tableHeaderView = header
    }
    
    @objc func sizeFooterToFit() {
        guard let footer = tableFooterView else { return }
        footer.setNeedsLayout()
        footer.layoutIfNeeded()
        
        let height = footer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var frame = footer.frame
        
        frame.size.height = height
        footer.frame = frame
        
        tableFooterView = footer
    }
}
