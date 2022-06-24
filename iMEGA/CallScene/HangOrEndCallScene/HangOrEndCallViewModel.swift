
protocol HangOrEndCallRouting: AnyObject, Routing {
    func leaveCall()
    func endCallForAll()
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
}

final class HangOrEndCallViewModel {
    
    private let router: HangOrEndCallRouting
    
    init(router: HangOrEndCallRouting) {
        self.router = router
    }
    
    func leaveCallAction() {
        router.leaveCall()
    }
    
    func endForAllAction() {
        router.endCallForAll()
    }
}
