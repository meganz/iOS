import Foundation

@MainActor
public final class FloatingAddButtonViewModel: ObservableObject {
    @Published public private(set) var showsFloatingAddButton = false
    public let action: @MainActor () -> Void
    public init(initiallyShowsFloatingAddButton: Bool, action: @escaping @MainActor () -> Void) {
        self.showsFloatingAddButton = initiallyShowsFloatingAddButton
        self.action = action
        // [IOS-10542] Handle show/hide logic of FAB
    }
}
