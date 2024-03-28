/// Abstract protocol for a  CloudDrive screen to decide whether it should display ads or not
protocol CloudDriveAdsSlotDisplayable {
    var shouldDisplayAdsSlot: Bool { get }
}

extension CloudDriveViewController: CloudDriveAdsSlotDisplayable {
    var shouldDisplayAdsSlot: Bool {
        // We should only display Ads for .cloudDrive mode, for other modes (.rubbishBin, .backup, etc..) we should not show Ads
        displayMode == .cloudDrive
    }
}

extension SearchBarUIHostingController<NodeBrowserView>: CloudDriveAdsSlotDisplayable {
    var shouldDisplayAdsSlot: Bool {
        displayModeProvider.displayMode() == .cloudDrive
    }
}
