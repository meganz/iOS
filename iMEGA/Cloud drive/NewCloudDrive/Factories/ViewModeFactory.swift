import MEGADomain

// Extracted logic that makes decision what view mode will be used for new CloudDrive (NodeBrowserView).
struct ViewModeFactory {
    
    let viewModeStore: any ViewModeStoring

    @MainActor
    func determineViewMode(
        nodeSource: NodeSource,
        config: NodeBrowserConfig,
        hasOnlyMediaNodesChecker: () -> Bool
    ) -> ViewModePreferenceEntity {
        
        // notes on determining view mode
        // * viewModeStore is used to see, if there are any saved preferences for the given location
        //    * basically user can override and force given view mode always (thumbnail/list)
        //    * user can specify that each folder preference should be save and read individually from Core Data
        //    * if there is no saved preference in settings and not saved view mode for given node,
        //    * viewModeStore will check how many images are in the given parent folder, and make decision based on that
        //    * for an actual implementation, please inspect ViewModeStore.swift
        // * if user has enabled Media Discovery mode preference, we will also use hasOnlyMediaNodesChecker to
        //   see, if given folder has only nodes inside, and we can present it
        // * value of this is injected via config.mediaDiscoveryAutomaticDetectionEnabled which also checks
        //   things like if folder is root (we disable autoMD there) or if we are not in rubbish bin.
        //
        // * once those are taken into account, we should assign output into viewMode and
        //   allow user to change it via context menu
        //
        // * when given folder does not have ANY images inside, media discovery option should NOT be visible in the context menu
        //
        // * as checking if given folder has only visual media or any visual media can take some time, we
        //   probably should make effort to not execute that if it's not necessary
        //
        guard case let .node(provider) = nodeSource, let node = provider() else {
            return .list
        }
        
        if config.mediaDiscoveryAutomaticDetectionEnabled(),
           hasOnlyMediaNodesChecker() {
            return .mediaDiscovery
        }
        
        let savedPreference = viewModeStore.viewMode(for: .node(node))
        if savedPreference == .list || savedPreference == .thumbnail {
            return savedPreference
        }
        
        return .list
    }
}
