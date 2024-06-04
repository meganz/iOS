import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo

extension UsageViewController {
    private func setupTokenColors() {
        view.backgroundColor = TokenColors.Background.page
        pieChartView?.backgroundColor = TokenColors.Background.page
        usageStorageView?.backgroundColor = TokenColors.Background.page

        [cloudDriveLabel, backupsLabel, rubbishBinLabel, incomingSharesLabel].forEach { label in
            label?.textColor = TokenColors.Text.primary
        }

        [cloudDriveSizeLabel, backupsSizeLabel, rubbishBinSizeLabel, incomingSharesSizeLabel, usageTitleLabel].forEach { label in
            label?.textColor = TokenColors.Text.secondary
        }

        pieChartSecondaryLabel?.textColor = TokenColors.Text.primary
        pieChartTertiaryLabel?.textColor = TokenColors.Text.secondary

        usagePageControl?.currentPageIndicatorTintColor = TokenColors.Background.surface3
        usagePageControl?.pageIndicatorTintColor = TokenColors.Background.surface2

        [usageBottomSeparatorView, cloudDriveBottomSeparatorView, backupsBottomSeparatorView, rubbishBinBottomSeparatorView, incomingSharesBottomSeparatorView].forEach { view in
            view?.backgroundColor = TokenColors.Border.strong
        }

        usageSizeLabel?.textColor = TokenColors.Text.accent
    }
    
    private func setupColors() {
        view.backgroundColor = UIColor.systemBackground
        pieChartView?.backgroundColor = UIColor.systemBackground
        usageStorageView?.backgroundColor = UIColor.systemBackground

        let primaryTextColor = UIColor.mnz_primaryTextColor()
        let secondaryTextColor = UIColor.mnz_secondaryGray(for: traitCollection)

        [cloudDriveLabel, backupsLabel, rubbishBinLabel, incomingSharesLabel].forEach { label in
            label?.textColor = primaryTextColor
        }

        [cloudDriveSizeLabel, backupsSizeLabel, rubbishBinSizeLabel, incomingSharesSizeLabel, usageTitleLabel].forEach { label in
            label?.textColor = secondaryTextColor
        }

        pieChartSecondaryLabel?.textColor = UIColor.mnz_primaryGray(for: traitCollection)
        pieChartTertiaryLabel?.textColor = secondaryTextColor

        usagePageControl?.currentPageIndicatorTintColor = UIColor.mnz_turquoise(for: traitCollection)
        usagePageControl?.pageIndicatorTintColor = UIColor.mnz_secondaryGray(for: traitCollection)

        let separatorColor = UIColor.mnz_separator(for: traitCollection)
        [usageBottomSeparatorView, cloudDriveBottomSeparatorView, backupsBottomSeparatorView, rubbishBinBottomSeparatorView, incomingSharesBottomSeparatorView].forEach { view in
            view?.backgroundColor = separatorColor
        }
        
        usageSizeLabel?.textColor = UIColor.mnz_turquoise(for: traitCollection)
    }
    
    @objc func colorForSlice(at index: Int) -> UIColor {
        switch index {
        case 0: // Storage / Transfer Quota
            colorForPage(usagePageControl?.currentPage ?? 0, isDesignTokenEnabled: UIColor.isDesignTokenEnabled(), traitCollection: traitCollection)
        default: // Available storage/quota or default
            availableStorageColor(isDesignTokenEnabled: UIColor.isDesignTokenEnabled(), traitCollection: traitCollection)
        }
    }
    
    @objc func colorForPage(_ currentPage: Int, isDesignTokenEnabled: Bool, traitCollection: UITraitCollection) -> UIColor {
        guard isFull(currentPage: currentPage) else {
            return isDesignTokenEnabled ? TokenColors.Support.success : UIColor.mnz_turquoise(for: traitCollection)
        }
        return isDesignTokenEnabled ? TokenColors.Support.error : UIColor.mnz_red(for: traitCollection)
    }
    
    private func availableStorageColor(isDesignTokenEnabled: Bool, traitCollection: UITraitCollection) -> UIColor {
        isDesignTokenEnabled ? TokenColors.Border.strong : UIColor.mnz_tertiaryGray(for: traitCollection)
    }
    
    @objc func updateAppearance() {
        UIColor.isDesignTokenEnabled() ? setupTokenColors() : setupColors()
        
        pieChartMainLabel?.textColor = colorForPage(
            usagePageControl?.currentPage ?? 0,
            isDesignTokenEnabled: UIColor.isDesignTokenEnabled(),
            traitCollection: traitCollection
        )
        
        pieChartView?.reloadData()
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
        
        usagePageControl?.numberOfPages = showTransferQuota ? 2 : 0
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
    
    private func isStorageFull() -> Bool {
        usedStorage >= maxStorage
    }
    
    private func isTransferFull() -> Bool {
        transferOwnUsed >= transferMax
    }
    
    private func isFull(currentPage: Int) -> Bool {
        currentPage == 0 ? isStorageFull() : isTransferFull()
    }
    
    private func updatedPage(forGesture gesture: UIGestureRecognizer, currentPage: Int) -> Int? {
        var page = currentPage

        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if (swipeGesture.direction == .left && (page == 1 || !showTransferQuota)) ||
               (swipeGesture.direction == .right && page == 0) {
                return nil
            }
            
            switch swipeGesture.direction {
            case .left: page += 1
            case .right: page -= 1
            default: return nil
            }
        } else if gesture is UITapGestureRecognizer {
            if page == 1 {
                page = 0
            } else {
                guard showTransferQuota else {
                    return nil
                }
                page += 1
            }
        } else {
            return nil
        }

        return page
    }
    
    @objc func handleGesture(_ gesture: UIGestureRecognizer) {
        guard let updatedPage = updatedPage(forGesture: gesture, currentPage: usagePageControl?.currentPage ?? 0) else { return }
        usagePageControl?.currentPage = updatedPage
        reloadStorageContentView(forPage: updatedPage)
    }
}
