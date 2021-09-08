
extension UpgradeTableViewController {
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeFooterToFit()
    }
}
