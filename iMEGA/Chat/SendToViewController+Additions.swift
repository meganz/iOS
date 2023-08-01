import UIKit

extension SendToViewController {
    @objc
    func syncSelectionState(for section: Int,
                            dataSourceArray: NSMutableArray,
                            item: AnyObject,
                            isSelected: Bool) {
        if let chatListItem = item as? MEGAChatListItem {
            let indexOfItem = dataSourceArray.indexOfObject { obj, _, _ in
                if let tempChatListItem = obj as? MEGAChatListItem {
                    return tempChatListItem.chatId == chatListItem.chatId
                } else {
                    return false
                }
            }
            if indexOfItem != NSNotFound {
                let indexPath = IndexPath(row: indexOfItem, section: section)
                changeSelection(for: indexPath, isSelected: isSelected)
            }
        } else {
            let indexOfItem = dataSourceArray.index(of: item)
            if indexOfItem != NSNotFound {
                let indexPath = IndexPath(row: indexOfItem, section: section)
                changeSelection(for: indexPath, isSelected: isSelected)
            }
        }
    }
    
    private func changeSelection(for indexPath: IndexPath, isSelected: Bool) {
        if isSelected {
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        } else {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
