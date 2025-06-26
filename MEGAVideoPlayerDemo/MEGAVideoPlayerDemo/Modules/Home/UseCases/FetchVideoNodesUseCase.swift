import MEGASdk

protocol FetchVideoNodesUseCaseProtocol {
    func execute() -> [MEGANode]?
}

struct FetchVideoNodesUseCase: FetchVideoNodesUseCaseProtocol {
    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    func execute() -> [MEGANode]? {
        guard let handle = sdk.rootNode?.handle else { return nil }

        return filterForVideos(
            nodeList: sdk.search(
                with: MEGASearchFilter(
                    term: "",
                    parentNodeHandle: handle,
                    nodeType: .unknown,
                    category: .unknown,
                    sensitiveFilter: .disabled,
                    favouriteFilter: .disabled,
                    creationTimeFrame: nil,
                    modificationTimeFrame: nil
                ),
                orderType: .defaultAsc,
                page: nil,
                cancelToken: MEGACancelToken()
            )
        ).toArray
    }

    private func filterForVideos(nodeList: MEGANodeList) -> MEGANodeList {
        let newNodeList = MEGANodeList()
        for index in 0..<nodeList.size {
            guard let node = nodeList.node(at: index) else { continue }
            guard isVideoType(node) else { continue }

            newNodeList.add(node)
        }
        return newNodeList
    }

    private func isVideoType(_ node: MEGANode) -> Bool {
        guard let fileExtension = node.name?.pathExtension else {
            return false
        }

        return supportedVideoExtensions().contains(fileExtension)
    }

    private func supportedVideoExtensions() -> Set<String> {[
        "3g2", // 3GPP2 format, used on mobile devices (CDMA networks)
        "3gp", // 3GPP format, mobile video (GSM networks)
        "asf", // Advanced Systems Format, developed by Microsoft
        "avi", // Audio Video Interleave, common Windows container
        "flv", // Flash Video, legacy web streaming (deprecated)
        "m2ts", // MPEG-2 Transport Stream, used in Blu-ray discs
        "m4v", // Apple’s MP4 variant, DRM support possible
        "mkv", // Matroska, open-source, flexible multimedia container
        "mov", // Apple QuickTime format, high-quality video
        "mp4", // MPEG-4 Part 14, widely supported standard format
        "mpg", // MPEG-1 or MPEG-2, common legacy format
        "mqv", // Mobile QuickTime, Apple variant (less common)
        "ogv", // Ogg Video, open format for web use
        "qt", // QuickTime File Format, older Apple format
        "ts", // MPEG Transport Stream, used in broadcast and IPTV
        "webm", // Open, web-optimized format by Google
        "wmv" // Windows Media Video, Microsoft proprietary format
    ]}
}
