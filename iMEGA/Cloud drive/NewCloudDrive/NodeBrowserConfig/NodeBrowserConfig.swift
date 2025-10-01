import MEGADomain

struct NodeBrowserConfig {
    var displayMode: DisplayMode?
    var isFromViewInFolder: Bool?
    var isFromUnverifiedContactSharedFolder: Bool?
    var isFromSharedItem: Bool?
    var shouldRemovePlayerDelegate: Bool?
    var warningViewModel: WarningBannerViewModel?
    // this should enabled for non-root nodes
    var mediaDiscoveryAutomaticDetectionEnabled: () -> Bool = { false }

    // Determines whether the NodeBrowserView should handle upgrade encouragement flow or not, default value is true
    var supportsUpgradeEncouragement: Bool = true
    
    /// Provider closure to get the AdsVisibilityConfigurating for showing/hiding external ads.
    /// The AdsVisibilityConfigurating can be access via `UIApplication.mainTabBarRootViewController())` which
    /// might not be available at the time this config is created so we need to use closure to refer to it at a later time.
    var adsConfiguratorProvider: () -> (any AdsVisibilityConfigurating)? = { nil }
    static var `default`: Self {
        .init()
    }
    
    /// small helper function to make it easier to pass down and package display mode into a config
    /// display mode must be carried over into a child folder when presenting in rubbish or backups mode
    static func withOptionalDisplayMode(_ displayMode: DisplayMode?) -> Self {
        var config = Self.default
        config.displayMode = displayMode
        return config
    }
    
    static func withOptionalDisplayMode(_ displayMode: DisplayMode?, warningViewModel: WarningBannerViewModel?) -> Self {
        var config = Self.default
        config.displayMode = displayMode
        config.warningViewModel = warningViewModel
        return config
    }
    
    static func withSupportsUpgradeEncouragement(_ supportsUpgradeEncouragement: Bool) -> Self {
        var config = Self.default
        config.supportsUpgradeEncouragement = supportsUpgradeEncouragement
        return config
    }
}

extension DisplayMode {
    var carriedOverDisplayMode: DisplayMode? {
        // for those 3 special cases, we carry over the display mode so that children are configured properly
        // [bug in the comments in FM-1461]
        if self == .rubbishBin || self == .backup || self == .cloudDrive {
            return self
        }
        return nil
    }
}
