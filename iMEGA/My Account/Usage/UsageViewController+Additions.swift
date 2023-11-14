import MEGADomain
import MEGAL10n
import MEGASDKRepo

extension UsageViewController {
     
    @objc func storageColor(traitCollection: UITraitCollection, isStorageFull: Bool, currentPage: Int) -> UIColor {
        guard currentPage == 0, isStorageFull else {
            return UIColor.mnz_turquoise(for: traitCollection)
        }
        return UIColor.mnz_red(for: traitCollection)
    }
    
    @objc func updateAppearance() {
        view.backgroundColor = UIColor.mnz_background()
        
        pieChartView?.backgroundColor = UIColor.mnz_background()
        
        pieChartMainLabel?.textColor = storageColor(traitCollection: traitCollection,
                                                   isStorageFull: isStorageFull(),
                                                   currentPage: usagePageControl?.currentPage ?? 0)
        
        pieChartSecondaryLabel?.textColor = UIColor.mnz_primaryGray(for: traitCollection)
        pieChartTertiaryLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        
        pieChartView?.reloadData()
        
        usagePageControl?.currentPageIndicatorTintColor = UIColor.mnz_turquoise(for: traitCollection)
        usagePageControl?.pageIndicatorTintColor = UIColor.mnz_secondaryGray(for: traitCollection)
        usageBottomSeparatorView?.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        
        cloudDriveSizeLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        backupsSizeLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        rubbishBinSizeLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        incomingSharesSizeLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        
        cloudDriveBottomSeparatorView?.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        backupsBottomSeparatorView?.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        rubbishBinBottomSeparatorView?.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        incomingSharesBottomSeparatorView?.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        
        usageStorageView?.backgroundColor = UIColor.mnz_background()
        usageTitleLabel?.textColor = UIColor.mnz_primaryGray(for: traitCollection)
        usageSizeLabel?.textColor = UIColor.mnz_turquoise(for: traitCollection)
    }
    
    @objc func initializeStorageInfo() {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails else { return }
        
        if let rootNode = MEGASdk.shared.rootNode {
            cloudDriveSize = accountDetails.storageUsed(forHandle: rootNode.handle)
        }
        
        cloudDriveSizeLabel?.text = text(forSizeLabels: cloudDriveSize)
        
        backupsActivityIndicator?.isHidden = false
        backupsActivityIndicator?.startAnimating()
        
        Task {
            let backupSize = await BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).backupsRootNodeSize()
            backupsSizeLabel?.text = self.text(forSizeLabels: Int64(backupSize))
            backupsActivityIndicator?.stopAnimating()
            backupsActivityIndicator?.isHidden = true
        }
        
        if let rubbishNode = MEGASdk.shared.rubbishNode {
            rubbishBinSize = accountDetails.storageUsed(forHandle: rubbishNode.handle)
        }
        
        rubbishBinSizeLabel?.text = text(forSizeLabels: rubbishBinSize)
        
        var incomingSharedSizeSum: Int64 = 0
        
        MEGASdk.shared.inShares().toNodeArray().forEach { node in
            incomingSharedSizeSum += MEGASdk.shared.size(for: node).int64Value
        }
        
        incomingSharesSizeLabel?.text = text(forSizeLabels: incomingSharedSizeSum)
        
        usedStorage = accountDetails.storageUsed
        maxStorage = accountDetails.storageMax
        
        transferOwnUsed = accountDetails.transferOwnUsed
        transferMax = accountDetails.transferMax
    }
    
    @objc func configView() {
        numberFormatter = NumberFormatter()
        numberFormatter?.numberStyle = .none
        numberFormatter?.roundingMode = .floor
        numberFormatter?.locale = .current

        cloudDriveLabel?.text = Strings.Localizable.cloudDrive
        backupsLabel?.text = Strings.Localizable.Backups.title
        rubbishBinLabel?.text = Strings.Localizable.rubbishBinLabel
        incomingSharesLabel?.text = Strings.Localizable.incomingShares
    }
    
    var isShowPieChartView: Bool {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails else {
            return true
        }
        return !(accountDetails.type == .business || accountDetails.type == .proFlexi)
    }
    
    @objc var showTransferQuota: Bool {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails else {
            return false
        }
        return Self.shouldShowTransferQuota(accountType: accountDetails.type.toAccountTypeEntity())
    }
    
    static func shouldShowTransferQuota(accountType: AccountTypeEntity) -> Bool {
        // Transfer Quota should be hidden on free accounts due to
        // different transfer limits in different countries and also it is subject to change.
        accountType != .free
    }
    
    @objc func configStorageContentView() {
        let isShowPieChartView = isShowPieChartView
        pieChartView?.isHidden = !isShowPieChartView
        usageStorageView?.isHidden = isShowPieChartView

        if isShowPieChartView {
            setUpPieChartView()
        } else {
            setUsageViewContent()
        }
    }
    
    @objc func reloadStorageContentView(forPage page: Int) {
        if isShowPieChartView {
            reloadPieChart(page)
        } else {
            setUsageViewContent(forPage: page)
        }
    }
    
    @objc func setUsageViewContent(forPage page: Int = 0) {
        switch page {
        case 0:
            usageTitleLabel?.text = Strings.Localizable.Account.Storage.StorageUsed.title
            guard usedStorage != 0 else {
                usageSizeLabel?.text = "-"
                return
            }
            usageSizeLabel?.text = String.memoryStyleString(fromByteCount: usedStorage)
            
        case 1:
            usageTitleLabel?.text = Strings.Localizable.Account.Storage.TransferUsed.title
            guard transferOwnUsed != 0 else {
                usageSizeLabel?.text = "-"
                return
            }
            usageSizeLabel?.text = String.memoryStyleString(fromByteCount: transferOwnUsed)
            
        default: return
        }
    }
}
