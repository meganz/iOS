import UIKit

public struct MyAccountHallCellData {
    public let sectionText: String?
    public let detailText: String?
    public let icon: UIImage?
    public let storageText: String?
    public let transferText: String?
    public let storageUsedText: String?
    public let transferUsedText: String?
    public let isPendingViewVisible: Bool
    public let pendingText: String?
    public let promoText: String?
    public let disclosureIndicatorIcon: UIImage?
    public let showLoadingIndicator: Bool
    
    public init(
        sectionText: String? = nil,
        detailText: String? = nil,
        icon: UIImage? = nil,
        storageText: String? = nil,
        transferText: String? = nil,
        storageUsedText: String? = nil,
        transferUsedText: String? = nil,
        isPendingViewVisible: Bool = false,
        pendingText: String? = nil,
        promoText: String? = nil,
        disclosureIndicatorIcon: UIImage? = nil,
        showLoadingIndicator: Bool = false
    ) {
        self.sectionText = sectionText
        self.detailText = detailText
        self.icon = icon
        self.storageText = storageText
        self.transferText = transferText
        self.storageUsedText = storageUsedText
        self.transferUsedText = transferUsedText
        self.isPendingViewVisible = isPendingViewVisible
        self.pendingText = pendingText
        self.promoText = promoText
        self.disclosureIndicatorIcon = disclosureIndicatorIcon
        self.showLoadingIndicator = showLoadingIndicator
    }
}
