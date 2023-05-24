import Foundation
import MEGAPresentation

enum GetLinkSwitchOptionCellAction: ActionType {
    case onViewReady
    case onSwitchToggled(isOn: Bool)
}

final class GetLinkSwitchOptionCellViewModel: GetLinkCellViewModelType {
    enum Command: CommandType, Equatable {
        case configView(GetLinkSwitchCellViewConfiguration)
        case updateSwitch(isOn: Bool)
    }
    
    var invokeCommand: ((Command) -> Void)?
    let type: GetLinkCellType
    
    private var configuration: GetLinkSwitchCellViewConfiguration
    
    init(type: GetLinkCellType, configuration: GetLinkSwitchCellViewConfiguration) {
        self.type = type
        self.configuration = configuration
    }
    
    func dispatch(_ action: GetLinkSwitchOptionCellAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(configuration))
        case .onSwitchToggled(let isOn):
            configuration.isSwitchOn = isOn
            invokeCommand?(.updateSwitch(isOn: configuration.isSwitchOn))
        }
    }
}
