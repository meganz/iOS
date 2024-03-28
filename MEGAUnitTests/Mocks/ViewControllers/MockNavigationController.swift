class MockNavigationController: UINavigationController {
    
    enum Message {
        case present(UIViewController)
    }
    
    private(set) var messages = [Message]()
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        messages.append(.present(viewControllerToPresent))
    }
}
