import Foundation
import MEGAAppPresentation
import UIKit

class SettingCellViewModel: ViewModelType {
    
    let image: UIImage?
    let title: String
    var displayValue: String
    let isDestructive: Bool
    var router: (any Routing)?
    
    var invokeCommand: ((SettingsCommand) -> Void)?
    
    init(image: UIImage?, title: String, isDestructive: Bool = false, displayValue: String = "", router: (any Routing)? = nil) {
        self.image = image
        self.title = title
        self.router = router
        self.isDestructive = isDestructive
        self.displayValue = displayValue
    }
    
    func dispatch(_ action: SettingsAction) {}
    
    func updateDisplayValue(_ value: String) {
        displayValue = value
        invokeCommand?(.reloadData)
    }
    
    func updateRouter(router: (some Routing)?) {
        self.router = router
    }
}
