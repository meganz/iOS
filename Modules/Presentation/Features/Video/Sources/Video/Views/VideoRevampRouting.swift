import MEGADomain
import MEGAPresentation

public protocol VideoRevampRouting: Routing {
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity])
}
