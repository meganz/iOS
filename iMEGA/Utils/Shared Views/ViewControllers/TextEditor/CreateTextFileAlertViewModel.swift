import MEGAPresentation

enum CreateTextFileAlertViewAction: ActionType {
    case createTextFile(_ fileName: String)
}

protocol CreateTextFileAlertViewRouting: Routing {
    func createTextFile(_ fileName: String)
}

final class CreateTextFileAlertViewModel {
    private var router: CreateTextFileAlertViewRouting
    
    init(router: CreateTextFileAlertViewRouting) {
        self.router = router
    }
    
    func dispatch(_ action: CreateTextFileAlertViewAction) {
        switch action {
        case .createTextFile(let fileName):
            router.createTextFile(fileName)
        }
    }
}
