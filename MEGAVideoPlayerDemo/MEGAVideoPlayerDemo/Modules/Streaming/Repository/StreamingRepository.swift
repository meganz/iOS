import MEGASdk

struct StreamingRepository: StreamingRepositoryProtocol {
    var httpServerIsLocalOnly: Bool {
        sdk.httpServerIsLocalOnly()
    }

    var httpServerIsRunning: Int {
        sdk.httpServerIsRunning()
    }

    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    func httpServerGetLocalLink(_ node: any PlayableNode) -> URL? {
        guard let megaNode = node as? MEGANode else {
            return nil
        }

        return sdk.httpServerGetLocalLink(megaNode)
    }

    func httpServerStart(_ localOnly: Bool, port: Int) {
        sdk.httpServerStart(localOnly, port: port)
    }

    func httpServerStop() {
        sdk.httpServerStop()
    }
}
