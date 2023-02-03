import MEGADomain

struct ContextMenuModel {
    var type: CMElementTypeEntity = .unknown
    
    // The following parameters are only available for Actions, not for Menus
    var state: Bool = false
    var isEnabled: Bool = false
    
    // The following parameters are only available for Menus, not for Actions
    var displayInline: Bool = false
    var children: [ContextMenuModel]?
    
    // Within the parameters only available for menus, we have: currentChatStatus, currentSortType and dndRemainingTime, with which we'll create the detail text of the different menus
    var currentChatStatus: String?
    var currentSortType: String?
    var dndRemainingTime: String?
    var currentFilterType: String?
    
    lazy var data: ContextMenuDataModel? = {
        guard let cmData = dataFor(type: type) else { return nil }
        return cmData
    }()
}
