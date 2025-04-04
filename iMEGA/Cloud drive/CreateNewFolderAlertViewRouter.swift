import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import UIKit

@MainActor
protocol CreateNewFolderAlertRouting {
    func start() async -> NodeEntity?
    func showNodeAlreadyExistsError() async
}

struct CreateNewFolderAlertViewRouter: CreateNewFolderAlertRouting {
    private let navigationController: UINavigationController
    private let parentNode: NodeEntity

    init(navigationController: UINavigationController, parentNode: NodeEntity) {
        self.navigationController = navigationController
        self.parentNode = parentNode
    }

    func start() async -> NodeEntity? {
        let nodeUseCase = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )

        let viewModel = CreateNewFolderAlertViewModel(
            router: self,
            parentNode: parentNode,
            nodeUseCase: nodeUseCase
        )

        let alert = makeAlert(with: viewModel)
        present(alert: alert)
        return await viewModel.waitUntilFinished()
    }

    func showNodeAlreadyExistsError() {
        SVProgressHUD.showError(withStatus: Strings.Localizable.thereIsAlreadyAFolderWithTheSameName)
    }

    // MARK: - Private methods.

    private func present(alert: UIAlertController) {
        navigationController.present(alert, animated: true)
    }

    private func makeAlert(with viewModel: CreateNewFolderAlertViewModel) -> UIAlertController {
        let createFolderAlert = UIAlertController(
            title: Strings.Localizable.newFolder, message: nil, preferredStyle: .alert
        )

        createFolderAlert.addAction(
            UIAlertAction(title: Strings.Localizable.cancel, style: .cancel) { [weak viewModel] _ in
                guard let viewModel else { return }
                viewModel.cancelAction()
            }
        )

        let createAction = UIAlertAction(
            title: Strings.Localizable.createFolderButton,
            style: .default
        ) { [weak createFolderAlert, weak viewModel] _ in
            guard let viewModel else { return }
            viewModel.createButtonTapped(
                withFolderName: createFolderAlert?.textFields?.last?.text ?? ""
            )
        }

        createAction.isEnabled = false
        createFolderAlert.addAction(createAction)

        createFolderAlert.addTextField { [weak createFolderAlert, weak createAction, weak viewModel] textField in
            guard let viewModel else { return }
            configure(
                textField: textField,
                alert: createFolderAlert,
                createAction: createAction,
                viewModel: viewModel
            )
        }

        return createFolderAlert
    }

    private func configure(
        textField: UITextField,
        alert: UIAlertController?,
        createAction: UIAlertAction?,
        viewModel: CreateNewFolderAlertViewModel
    ) {
        textField.placeholder = Strings.Localizable.newFolderMessage
        textField.addAction(
            editingChangedAction(with: textField, alert: alert, createAction: createAction, viewModel: viewModel),
            for: .editingChanged
        )
        textField.shouldReturnCompletion = { [weak viewModel] _ in
            guard let viewModel else { return true }
            return viewModel.shouldReturnCompletion(for: textField.text)
        }
    }

    private func editingChangedAction(
        with textField: UITextField,
        alert: UIAlertController?,
        createAction: UIAlertAction?,
        viewModel: CreateNewFolderAlertViewModel
    ) -> UIAction {
        UIAction { [weak viewModel] _ in
            guard let createAction, let viewModel, let text = textField.text else { return }
            let alertProperties = viewModel.makeAlertProperties(with: text)
            alert?.title = alertProperties.title
            textField.textColor = alertProperties.textFieldTextColor
            createAction.isEnabled = alertProperties.isActionEnabled
        }
    }
}
