import Combine
import UIKit

public final class SnackBarViewModel: ObservableObject {

    @Published public private(set) var snackBar: SnackBar
    @Published public var isShowSnackBar: Bool = true
    
    var displayDuration: Double = 4.0
    
    public typealias WillDismissBlock = () -> Void
    private var displaySnackBarSubscription: AnyCancellable?
    private let willDismiss: WillDismissBlock?
    
    public init(
        snackBar: SnackBar,
        willDismiss: WillDismissBlock?
    ) {
        self.snackBar = snackBar
        self.willDismiss = willDismiss
        
        configureSnackBar()
    }
    
    public func update(snackBar: SnackBar) {
        self.snackBar = snackBar
        configureSnackBar()
    }
    
    private func configureSnackBar() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        cancelDisplaySnackBarSubscription()
        
        displaySnackBarSubscription = Just(Void.self)
            .delay(for: .seconds(displayDuration), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.dismissSnackBar()
            }
    }
    
    private func dismissSnackBar() {
        // There is a case where we dimiss the modal screen faster then this dismiss method called by subscription, resulting a crash since we assert the `presenter` inside `dismissSnackbar()` function. Thus, nil checking is needed here.
        willDismiss?()
        
        cancelDisplaySnackBarSubscription()
        isShowSnackBar = false
    }
    
    private func cancelDisplaySnackBarSubscription() {
        displaySnackBarSubscription?.cancel()
        displaySnackBarSubscription = nil
    }
}
