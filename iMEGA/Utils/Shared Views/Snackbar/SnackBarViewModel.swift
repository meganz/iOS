import Combine

final class SnackBarViewModel: ObservableObject {

    @Published private(set) var snackBar: SnackBar
    @Published var isShowSnackBar: Bool = true
    
    var displayDuration: Double = 4.0
    
    private var displaySnackBarSubscription: AnyCancellable?
    
    init(snackBar: SnackBar) {
        self.snackBar = snackBar
        
        configureSnackBar()
    }
    
    func update(snackBar: SnackBar) {
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
        if SnackBarRouter.shared.presenter != nil {
            SnackBarRouter.shared.dismissSnackBar()
        }
        cancelDisplaySnackBarSubscription()
        isShowSnackBar = false
    }
    
    private func cancelDisplaySnackBarSubscription() {
        displaySnackBarSubscription?.cancel()
        displaySnackBarSubscription = nil
    }
}
