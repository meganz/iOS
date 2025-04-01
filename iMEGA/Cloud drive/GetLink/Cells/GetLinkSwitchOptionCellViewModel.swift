import Foundation
import MEGAAppPresentation

struct GetLinkSwitchOptionCellViewModel: GetLinkCellViewModelType {
    let type: GetLinkCellType
    let title: String
    let isEnabled: Bool
    let isProImageViewHidden: Bool
    var isSwitchOn: Bool
    let isActivityIndicatorHidden: Bool
    
    init(type: GetLinkCellType, configuration: GetLinkSwitchCellViewConfiguration) {
        self.type = type
        self.title = configuration.title
        self.isEnabled = configuration.isEnabled
        self.isProImageViewHidden = configuration.isProImageViewHidden
        self.isSwitchOn = configuration.isSwitchOn
        self.isActivityIndicatorHidden = configuration.isActivityIndicatorHidden
    }
}
