import Foundation

extension UIResponder: ErrorHandling {

    @objc func handle(
        _ error: any Error,
        from viewController: UIViewController,
        retryHandler: (() -> Void)? = nil
    ) {
        guard let nextResponder = next else {
            return assertionFailure("""
            Unhandled error \(error) from \(viewController)
            """)
        }

        nextResponder.handle(error,
            from: viewController,
            retryHandler: retryHandler
        )
    }
}
