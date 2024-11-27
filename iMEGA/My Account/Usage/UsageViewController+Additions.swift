import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo

extension UsageViewController {
    private enum ColorType {
        case text, background
    }
    
    @objc var showTransferQuota: Bool {
        guard let viewModel else { return false }
        // Transfer Quota should be hidden on free accounts due to
        // different transfer limits in different countries and also it is subject to change.
        return !viewModel.isFreeAccount
    }
    
    var isShowPieChartView: Bool {
        guard let viewModel else { return true }
        return !(viewModel.isBusinessAccount || viewModel.isProFlexiAccount)
    }
    
    // MARK: - Setup and configuration
    private func setupColors() {
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
    
    @objc func setUpInvokeCommands() {
        viewModel?.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
    }
    
    @objc func initialiseStorageInfo() {
        viewModel?.dispatch(.loadCurrentStorageStatus)
        viewModel?.dispatch(.loadRootNodeStorage)
        viewModel?.dispatch(.loadBackupStorage)
        viewModel?.dispatch(.loadRubbishBinStorage)
        viewModel?.dispatch(.loadIncomingSharedStorage)
        viewModel?.dispatch(.loadStorageDetails)
        viewModel?.dispatch(.loadTransferDetails)
    }
    
    @objc func configStorageContentView() {
        let isShowPieChartView = isShowPieChartView
        pieChartView?.isHidden = !isShowPieChartView
        usageStorageView?.isHidden = isShowPieChartView

        isShowPieChartView ? setUpPieChartView() : setUsageViewContent()
    }
    
    // MARK: - Gesture handling
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
    
    // MARK: - Appearance and color handling
    private func colorForPage(_ page: Int, type: ColorType) -> UIColor {
        page == 0 ? colorForStorage(type: type) : colorForTransfer(type: type)
    }
    
    private func colorForStorage(type: ColorType) -> UIColor {
        switch viewModel?.currentStorageStatus {
        case .full: type == .background ? TokenColors.Support.error : TokenColors.Text.error
        case .almostFull: type == .background ? TokenColors.Support.warning : TokenColors.Text.warning
        default: type == .background ? TokenColors.Support.success : TokenColors.Text.success
        }
    }
    
    private func colorForTransfer(type: ColorType) -> UIColor {
        switch viewModel?.currentTransferStatus {
        case .full: type == .background ? TokenColors.Support.error : TokenColors.Text.error
        case .almostFull: type == .background ? TokenColors.Support.warning : TokenColors.Text.warning
        default: type == .background ? TokenColors.Support.success : TokenColors.Text.success
        }
    }
    
    private func colorForUsedQuota(_ page: Int) -> UIColor {
        switch page {
        case 0: viewModel?.currentStorageStatus == .noStorageProblems ? TokenColors.Text.primary : colorForPage(page, type: .text)
        default: viewModel?.currentTransferStatus == .noTransferProblems ? TokenColors.Text.primary : colorForPage(page, type: .text)
        }
    }
    
    @objc func colorForSlice(at index: Int) -> UIColor {
        switch index {
        case 0: // Storage / Transfer Quota
            colorForPage(usagePageControl?.currentPage ?? 0, type: .background)
        default: // Available storage/quota or default
            TokenColors.Border.strong
        }
    }
    
    @objc func updateAppearance() {
        setupColors()
        
        pieChartMainLabel?.textColor = colorForPage(usagePageControl?.currentPage ?? 0, type: .text)
        
        pieChartView?.reloadData()
    }
    
    @objc func updateTextLabelsAppearance(_ currentPage: Int) {
        pieChartMainLabel?.attributedText =  NSAttributedString(textForMainLabel(currentPage))
        pieChartMainLabel?.textColor = colorForPage(currentPage, type: .text)
        
        let (usedQuota, totalQuota, labelText) = quotaDetails(for: currentPage)
        let used = formattedQuotaValue(from: usedQuota)
        let total = formattedQuotaValue(from: totalQuota)
        
        pieChartSecondaryLabel?.attributedText = NSAttributedString(
            createStorageUsageAttributedText(
                usedStorage: used,
                totalStorage: total,
                usedColor: colorForUsedQuota(currentPage)
            )
        )
        pieChartTertiaryLabel?.text = labelText
    }
    
    // MARK: - Storage and transfer information
    private func createStorageUsageAttributedText(
        usedStorage: String,
        totalStorage: String,
        usedColor: UIColor,
        totalColor: UIColor = TokenColors.Text.primary
    ) -> AttributedString {
        var attributedString = AttributedString("\(usedStorage) / \(totalStorage)")
        
        if let range = attributedString.range(of: usedStorage) {
            attributedString[range].foregroundColor = usedColor
        }
        
        if let range = attributedString.range(of: "/ \(totalStorage)") {
            attributedString[range].foregroundColor = totalColor
        }
        
        return attributedString
    }
    
    private func textForMainLabel(_ currentPage: Int) -> AttributedString {
        let percentage: Float = switch currentPage {
        case 0: viewModel?.storageUsedPercentage ?? 0
        case 1: viewModel?.transferUsedPercentage ?? 0
        default: 0
        }
        
        let firstPartString = numberFormatter?.string(from: NSNumber(value: percentage.isNaN ? 0 : percentage)) ?? "0"
        var firstPartAttributedString = AttributedString(firstPartString)
        firstPartAttributedString.font = .systemFont(ofSize: 75, weight: .bold)
        
        var secondPartAttributedString = AttributedString(" %")
        secondPartAttributedString.font = .systemFont(ofSize: 40, weight: .bold)
        
        return firstPartAttributedString + secondPartAttributedString
    }
    
    private func formattedQuotaValue(from value: Int64) -> String {
        value == 0 ? "-" : String.memoryStyleString(fromByteCount: value)
    }

    private func quotaDetails(for currentPage: Int) -> (Int64, Int64, String) {
        switch currentPage {
        case 0: (usedStorage, maxStorage, Strings.Localizable.storage)
        case 1: (transferUsed, transferMax, Strings.Localizable.transfer)
        default: (0, 0, "")
        }
    }
    
    private func isTransferFull() -> Bool {
        transferUsed >= transferMax
    }
    
    // MARK: - Content view management
    @objc func reloadStorageContentView(forPage page: Int) {
        isShowPieChartView ? reloadPieChart(page): setUsageViewContent(forPage: page)
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
            guard transferUsed != 0 else {
                usageSizeLabel?.text = "-"
                return
            }
            usageSizeLabel?.text = String.memoryStyleString(fromByteCount: transferUsed)
            
        default: return
        }
    }
    
    // MARK: - Actitivy indicator
    private func startAnimating(_ activityIndicator: UIActivityIndicatorView?) {
        activityIndicator?.isHidden = false
        activityIndicator?.startAnimating()
    }
    
    private func stopAnimating(_ activityIndicator: UIActivityIndicatorView?) {
        activityIndicator?.stopAnimating()
        activityIndicator?.isHidden = true
    }
    
    // MARK: - View model command exection
    private func executeCommand(_ command: UsageViewModel.Command) {
        switch command {
        case .loaded(let storageType, let size):
            switch storageType {
            case .cloud:
                cloudDriveSizeLabel?.text = formattedStorageUsedString(for: size)
                stopAnimating(cloudDriveActivityIndicator)
            case .backups:
                backupsSizeLabel?.text = formattedStorageUsedString(for: size)
                stopAnimating(backupsActivityIndicator)
            case .rubbishBin:
                rubbishBinSizeLabel?.text = formattedStorageUsedString(for: size)
                stopAnimating(rubbishBinActivityIndicator)
            case .incomingShares:
                incomingSharesSizeLabel?.text = formattedStorageUsedString(for: size)
                stopAnimating(incomingSharesActivityIndicator)
            default: break
            }
            reloadCurrentPage()
            
        case .loadedStorage(let used, let max):
            usedStorage = used
            maxStorage = max
            reloadCurrentPage()
            
        case .loadedTransfer(let used, let max):
            transferUsed = used
            transferMax = max
            reloadCurrentPage()
            
        case .startLoading(let type):
            switch type {
            case .cloud: startAnimating(cloudDriveActivityIndicator)
            case .backups: startAnimating(backupsActivityIndicator)
            case .rubbishBin: startAnimating(rubbishBinActivityIndicator)
            case .incomingShares: startAnimating(incomingSharesActivityIndicator)
            case .chart:
                chartContainerView?.isHidden = true
                startAnimating(chartActivityIndicator)
            }
            
        case .stopLoading(let type):
            switch type {
            case .chart:
                stopAnimating(chartActivityIndicator)
                chartContainerView?.isHidden = false
            default: break
            }
            reloadCurrentPage()
        }
    }
    
    private func reloadCurrentPage() {
        guard let currentPage = usagePageControl?.currentPage else { return }
        reloadStorageContentView(forPage: currentPage)
    }
    
    @objc func formattedStorageUsedString(for size: Int64) -> String {
        String
           .memoryStyleString(fromByteCount: size)
           .formattedByteCountString()
    }
}
