import MEGAAppPresentation

public protocol AddToCollectionRouting: Routing {
    func dismiss(completion: (() -> Void)?)
    func showSnackBar(message: String)
}
