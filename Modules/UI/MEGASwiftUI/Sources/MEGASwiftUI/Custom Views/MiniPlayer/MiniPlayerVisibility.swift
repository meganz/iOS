import Combine
import Foundation

@MainActor
public final class MiniPlayerVisibility: ObservableObject {
    @Published public var height: CGFloat = 0
    @Published public var isHidden: Bool = true
    
    public init() {}
}
