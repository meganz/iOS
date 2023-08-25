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
        SnackBarRouter.shared.dismissSnackBar()
        cancelDisplaySnackBarSubscription()
        isShowSnackBar = false
    }
    
    private func cancelDisplaySnackBarSubscription() {
        displaySnackBarSubscription?.cancel()
        displaySnackBarSubscription = nil
    }
}
