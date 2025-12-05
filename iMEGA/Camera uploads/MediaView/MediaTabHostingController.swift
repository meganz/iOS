import Combine
import SwiftUI
import UIKit

// MARK: - MediaTabHostingController

final class MediaTabHostingController: UIHostingController<MediaTabView> {

    // MARK: - Properties

    private let viewModel: MediaTabViewModel
    private var toolbarItemsFactory: MediaBottomToolbarItemsFactory
    private var subscriptions = Set<AnyCancellable>()

    lazy var toolbar = UIToolbar()

    // MARK: - Initialization

    init(
        viewModel: MediaTabViewModel,
        toolbarItemsFactory: MediaBottomToolbarItemsFactory
    ) {
        self.viewModel = viewModel
        self.toolbarItemsFactory = toolbarItemsFactory

        let rootView = MediaTabView(viewModel: viewModel)
        super.init(rootView: rootView)

        self.toolbarItemsFactory.actionDelegate = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupToolbarObservers()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hideToolbar()
    }

    // MARK: - Private Methods

    private func setupToolbarObservers() {
        viewModel.$showToolbar
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                guard let self else { return }
                if shouldShow, let config = viewModel.toolbarConfig {
                    self.showToolbar(with: config)
                } else {
                    self.hideToolbar()
                }
            }
            .store(in: &subscriptions)

        viewModel.$toolbarConfig
            .compactMap { $0 }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] config in
                self?.updateToolbar(with: config)
            }
            .store(in: &subscriptions)
    }
}

// MARK: - MediaToolbarProvider

extension MediaTabHostingController: MediaToolbarProvider {

    func updateToolbar(with config: MediaBottomToolbarConfig) {
        let items = toolbarItemsFactory.buildToolbarItems(config: config)

        let flexibleSpace = UIBarButtonItem.flexibleSpace
        toolbar.items = items.flatMap { item in
            item == items.last ? [item] : [item, flexibleSpace]
        }
    }
}

// MARK: - MediaToolbarActionDelegate

extension MediaTabHostingController: MediaToolbarActionDelegate {
    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        // Delegate to the view model, which will route to the appropriate tab view model
        viewModel.handleToolbarItemAction(action)
    }
}
