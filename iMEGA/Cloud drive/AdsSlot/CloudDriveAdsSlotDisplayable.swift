/// Abstract protocol for a  CloudDrive screen to decide whether it should display ads or not
protocol CloudDriveAdsSlotDisplayable {
    var shouldDisplayAdsSlot: Bool { get }
}

extension NewCloudDriveViewController: CloudDriveAdsSlotDisplayable {
    var shouldDisplayAdsSlot: Bool {
        displayModeProvider.displayMode() == .cloudDrive
    }
}
