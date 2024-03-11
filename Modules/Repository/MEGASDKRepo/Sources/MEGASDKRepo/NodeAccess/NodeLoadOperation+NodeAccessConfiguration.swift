extension NodeLoadOperation {
    convenience
    init(
        config: NodeAccessConfiguration,
        completion: @escaping NodeLoadCompletion
    ) {
        self.init(
            autoCreate: config.autoCreate,
            loadNodeRequest: config.loadNodeRequest,
            newNodeName: config.nodeName,
            createNodeRequest: config.createNodeRequest,
            setFolderHandleRequest: config.setNodeRequest,
            completion: completion
        )
    }
}
