import MEGADomain
@objc extension NSNotification {
    static let MEGAViewModePreferenceDidChange = Notification.Name.MEGAViewModePreferenceDidChange
}

extension Notification.Name {
    static let MEGAViewModePreferenceDidChange = Notification.Name("MEGAViewModePreferenceDidChange")
}

// Code for determining a view mode for
// [FM-1457] OfflineViewController
// [FM-1458] FolderLinkViewController

enum CustomViewModeLocation {
    static let HomeSearch = "HomeSearchResults"
    static let Generic = "Generic" // used for other uses of cloud drive such as Recents
}

enum ViewModeLocation {
    case node(NodeEntity) // per folder preference in cloud drive
    case offlinePath(String) // future use for offline view controller
    case customLocation(Custom) // other situations like home screen search results
    
    // This struct is used to describe a screen that can switch layouts
    // between per location/list/thumbnails that is not offline or cloud drive
    struct Custom {
        let name: String
        
        static let homeSearch = Custom(name: CustomViewModeLocation.HomeSearch)
        
        // use this getter to get a CoreData path parameter to save and read
        // user preferences from the data base, reusing Offline preference storage mechanism
        var path: String {
            "mega-custom-view-mode-location-\(name)"
        }
    }
}

// this is a wrapper to use Swift enum with associated value inside ObjC code
// in the near future, Cloud drive (and other node browser screen will be superseded
// by SwiftUI solution (currently Search module) and we will drop the wrapper
@objc class ViewModeLocation_ObjWrapper: NSObject {
    
    var node: MEGANode?
    var offlinePath: String?
    var customLocation: String?
    
    init(node: MEGANode) {
        self.node = node
        super.init()
    }
    init(offlinePath: String) {
        self.offlinePath = offlinePath
        super.init()
    }
    init(customLocation: String) {
        self.customLocation = customLocation
        super.init()
    }

}

extension ViewModeLocation_ObjWrapper {
    var location: ViewModeLocation? {
        if let node {
            return .node(node.toNodeEntity())
        }
        if let offlinePath {
            return .offlinePath(offlinePath)
        }
        if let customLocation {
            return .customLocation(.init(name: customLocation))
        }
        return nil
    }
}

@objc protocol ViewModeStoringObjC {
    func viewMode(
        for location: ViewModeLocation_ObjWrapper
    ) -> ViewModePreferenceEntity
    func save(
        viewMode: ViewModePreferenceEntity,
        forObjC location: ViewModeLocation_ObjWrapper
    )
}

// pure Swift version used in new Cloud Drive
protocol ViewModeStoring {
    func viewMode(
        for location: ViewModeLocation
    ) -> ViewModePreferenceEntity
    func save(
        viewMode: ViewModePreferenceEntity,
        for location: ViewModeLocation
    )
}

final class ViewModeStore: ViewModeStoring, ViewModeStoringObjC {
    
    func viewMode(for location: ViewModeLocation_ObjWrapper) -> ViewModePreferenceEntity {
        if let location = location.location {
            return self.viewMode(for: location)
        }
        return .list
    }
    
    func save(viewMode: ViewModePreferenceEntity, forObjC location: ViewModeLocation_ObjWrapper) {
        if let location = location.location {
            self.save(viewMode: viewMode, for: location)
        }
    }
    
    private let preferenceRepo: any PreferenceRepositoryProtocol
    private let megaStore: MEGAStore
    private let sdk: MEGASdk
    private let notificationCenter: NotificationCenter
    
    init(
        preferenceRepo: some PreferenceRepositoryProtocol,
        megaStore: MEGAStore,
        sdk: MEGASdk,
        notificationCenter: NotificationCenter
    ) {
        self.preferenceRepo = preferenceRepo
        self.megaStore = megaStore
        self.sdk = sdk
        self.notificationCenter = notificationCenter
    }
    
    private var savedPreference: ViewModePreferenceEntity? {
        guard
            let preference: Int = preferenceRepo.value(forKey: MEGAViewModePreference),
            let preferenceFromSettings = ViewModePreferenceEntity(rawValue: preference)
        else { return nil }
        return preferenceFromSettings
    }
    
    private func savePreference(preference: ViewModePreferenceEntity) {
        preferenceRepo.setValue(
            value: preference.rawValue,
            forKey: MEGAViewModePreference
        ) 
    }
    
    func viewMode(for location: ViewModeLocation) -> ViewModePreferenceEntity {
        
        // for custom locations such as home (offline in the future,
        // we store the view mode in core data per each location path and read it
        // it has a higher priority when saved than the preferences (which apply globally unless
        // layout is changed for given custom location)
        if case .customLocation(let customLocation) = location {
            if let viewMode = perCustom(location: customLocation) {
                return viewMode
            }
        }
        
        if let preferenceFromSettings = savedPreference {
            // when we have a saved preference that is a list or thumbnail, we simply respect that
            // and return
            if preferenceFromSettings == .list || preferenceFromSettings == .thumbnail {
                return preferenceFromSettings
            }
            
            // if user has specified that he/she prefers a per folder view mode
            // we try to read it for the given location from Core Data
            if
                preferenceFromSettings == .perFolder,
                let viewMode = perLocation(for: location)
            {
                return viewMode
            }
        }
        
        // if not preference is saved in the user defaults, we do a best guess with automatic
        // view mode selection
        return automatic(for: location)
    }
    
    private func perLocation(for location: ViewModeLocation) -> ViewModePreferenceEntity? {
        switch location {
        case .node(let node):
            return perNode(for: node)
        case .offlinePath:
            assert(false, "not suported yet, please refactor OfflineViewController to use this mechanism")
            return .list
        case .customLocation(let customLocation):
            return perCustom(location: customLocation)
        }
    }
    
    private func perNode(for node: NodeEntity) -> ViewModePreferenceEntity? {
        if
            let preference = megaStore.fetchCloudAppearancePreference(handle: node.handle),
            let savedViewMode = preference.viewMode,
            let viewMode = ViewModePreferenceEntity(rawValue: savedViewMode.intValue)
        {
            
            if viewMode == .list || viewMode == .thumbnail {
                return viewMode
            }
            return .list
        }
        
        return nil
    }
    
    private func perCustom(location: ViewModeLocation.Custom) -> ViewModePreferenceEntity? {
        
        // here we are reusing a mechanism for storing view mode preference per offline path,
        // do this instead of creating another NSManagedObject subclass to store simple int in CD
        if
            let preference = megaStore.fetchOfflineAppearancePreference(path: location.path),
            let savedViewMode = preference.viewMode,
            let viewMode = ViewModePreferenceEntity(rawValue: savedViewMode.intValue)
        {
            
            if viewMode == .list || viewMode == .thumbnail {
                return viewMode
            }
            return .list
        }
        
        return nil
    }
    
    private func automatic(for location: ViewModeLocation) -> ViewModePreferenceEntity {
        switch location {
        case .node(let node):
            return automatic(for: node)
        case .offlinePath:
            assert(false, "not supported yet, please refactor OfflineViewController to use this mechanism")
            return .list
        case .customLocation:
            // default for home screen search is list layout, this
            return .list
        }
    }
    
    private func automatic(for node: NodeEntity) -> ViewModePreferenceEntity {
        guard let megaNode = sdk.node(forHandle: node.handle) else { return .list }
        let nodeList = sdk.children(forParent: megaNode)
        var nodesWithThumbnail = 0
        var nodesWithoutThumbnail = 0
        
        for i in 0..<nodeList.size {
            if let child = nodeList.node(at: i) {
                if child.hasThumbnail() {
                    nodesWithThumbnail += 1
                } else {
                    nodesWithoutThumbnail += 1
                }
            }
        }
        
        return nodesWithThumbnail > nodesWithoutThumbnail ? .thumbnail : .list
    }
    
    // this should be called when user changes the view mode in the cloud drive, offline files etc
    // NOT in the settings page
    // Settings page would just save the preferences in the user default without any additional logic
    func save(
        viewMode: ViewModePreferenceEntity,
        for location: ViewModeLocation
    ) {
        guard viewMode != .mediaDiscovery else {
            // do nothing here as there's no preference for
            // media discovery, use can set in preference any of : per folder, list or thumbnail
            return
        }
        
        // for custom locations such as home, we store the setting in core data and read it when requested
        // we do not store that in the preferences
        if case .customLocation = location {
            savePerLocation(viewMode, location: location)
        } else {
            // when user selected 'per folder' option in the settings, we will
            // store view mode for each location in Core Data separately
            if
                let preference = savedPreference,
                preference == .perFolder
            {
                savePerLocation(viewMode, location: location)
            } else {
                // if user in the settings had selected thumbnail or list,
                // then we just override that here
                savePreference(preference: viewMode)
            }
        }
        
        notificationCenter.post(viewMode: viewMode)
    }
    
    private func savePerLocation(_ viewMode: ViewModePreferenceEntity, location: ViewModeLocation) {
        switch location {
        case .node(let node):
            megaStore.insertOrUpdateCloudViewMode(handle: node.handle, viewMode: viewMode.rawValue)
        case .customLocation(let custom):
            megaStore.insertOrUpdateOfflineViewMode(path: custom.path, viewMode: viewMode.rawValue)
        case .offlinePath:
            assert(false, "not supported yet, please refactor OfflineViewController to use this mechanism")
        }
        
    }
}

extension NotificationCenter {
    @objc func post(viewMode: ViewModePreferenceEntity) {
        post(
            name: .MEGAViewModePreferenceDidChange,
            object: nil,
            userInfo: [MEGAViewModePreference: viewMode]
        )
    }
}
