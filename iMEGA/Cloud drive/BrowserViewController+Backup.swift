
extension BrowserViewController {
    @objc func addItemToBackupNode(_ node: MEGANode, completion: @escaping () -> Void) {
        backup(node: node, action: .addFolder, confirmAction: .confirmAddFolder) {
            completion()
        }
    }
    
    @objc func moveBackupNode(_ node: MEGANode, completion: @escaping () -> Void) {
        backup(node: node, action: .move, confirmAction: .confirmMove) {
            completion()
        }
    }
}
