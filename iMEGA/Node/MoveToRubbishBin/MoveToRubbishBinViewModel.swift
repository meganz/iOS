import MEGADomain

@MainActor
protocol MoveToRubbishBinViewModelProtocol {
    func moveToRubbishBin(nodes: [NodeEntity])
}

final class MoveToRubbishBinViewModel: MoveToRubbishBinViewModelProtocol {
    private weak var presenter: UIViewController?
    
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func moveToRubbishBin(nodes: [NodeEntity]) {
        guard let presenter else { return }
        NodeActions.moveNodesToRubbishBin(nodes, presenter: presenter)
    }
}
