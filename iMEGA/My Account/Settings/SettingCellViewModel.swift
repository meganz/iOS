import Foundation

class SettingCellViewModel: ViewModelType {
    
    let image: ImageAsset?
    let title: String
    var displayValue: String
    let isDestructive: Bool
    var router: Routing?
    
    var invokeCommand: ((SettingsCommand) -> Void)?
    
    init(image: ImageAsset?, title: String, isDestructive: Bool = false, displayValue: String = "", router: Routing? = nil) {
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
    
    func updateRouter(router: Routing?) {
        self.router = router
    }
}
