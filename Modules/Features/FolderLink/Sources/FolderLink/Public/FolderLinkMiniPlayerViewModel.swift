import Combine
import Foundation

@MainActor
public final class FolderLinkMiniPlayerViewModel: ObservableObject {
    @Published public var showing: Bool = false
    @Published public var height: CGFloat = 0
}

