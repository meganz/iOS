public struct PDFViewerActionContext: Sendable {
    let hasNode: Bool
    let isLink: Bool
    let isChat: Bool

    public init(hasNode: Bool = false, isLink: Bool = false, isChat: Bool = false) {
        self.hasNode = hasNode
        self.isLink = isLink
        self.isChat = isChat
    }
}

public enum PDFViewerTrailingAction: Sendable {
    case more
    case download
    case none
}
