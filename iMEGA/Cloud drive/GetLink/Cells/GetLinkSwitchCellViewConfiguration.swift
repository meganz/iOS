import Foundation

struct GetLinkSwitchCellViewConfiguration: Equatable {
    let title: String
    let isEnabled: Bool
    let isProImageViewHidden: Bool
    var isSwitchOn: Bool
    let isActivityIndicatorHidden: Bool
    
    init(title: String, isEnabled: Bool = true, isProImageViewHidden: Bool = true,
         isSwitchOn: Bool = false, isActivityIndicatorHidden: Bool = true) {
        self.title = title
        self.isEnabled = isEnabled
        self.isProImageViewHidden = isProImageViewHidden
        self.isSwitchOn = isSwitchOn
        self.isActivityIndicatorHidden = isActivityIndicatorHidden
    }
}
