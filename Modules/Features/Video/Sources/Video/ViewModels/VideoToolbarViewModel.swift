import Combine

public final class VideoToolbarViewModel: ObservableObject {
    @Published public var isDisabled = true
    
    public init(isDisabled: Bool = true) {
        self.isDisabled = isDisabled
    }
}
