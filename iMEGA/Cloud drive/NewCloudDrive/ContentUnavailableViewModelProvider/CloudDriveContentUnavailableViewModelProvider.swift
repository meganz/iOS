import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI

@MainActor
protocol CloudDriveContentUnavailableViewModelProviderDelegate: AnyObject {
    func emptyStateAddButtonTapped()
}

// [IOS-10931] Move CloudDriveContentUnavailableViewModelProvider to CloudDrive module
@MainActor
final class CloudDriveContentUnavailableViewModelProvider: ContentUnavailableViewModelProviding {
    private let defaultEmptyViewAssets: SearchConfig.EmptyViewAssets
    private let nodeSource: NodeSource
    private let displayMode: DisplayMode?
    private let nodeUseCase: any NodeUseCaseProtocol
    private let usesRevampedUI: Bool
    // initially this is a let, but then because of complex circular reference we need to make this a var
    // Check the initialization of CloudDriveContentUnavailableViewModelProvider in CloudDriveViewControllerFactory
    // For more details
    weak var delegate: (any CloudDriveContentUnavailableViewModelProviderDelegate)?

    init(
        defaultEmptyViewAssets: SearchConfig.EmptyViewAssets,
        nodeSource: NodeSource,
        displayMode: DisplayMode?,
        nodeUseCase: some NodeUseCaseProtocol,
        usesRevampedUI: Bool
    ) {
        self.defaultEmptyViewAssets = defaultEmptyViewAssets
        self.usesRevampedUI = usesRevampedUI
        self.nodeSource = nodeSource
        self.displayMode = displayMode
        self.nodeUseCase = nodeUseCase
    }

    func emptyViewModel(
        query: SearchQuery,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableViewModel {

        // To show revamped UI, we should also check for the search query
        guard usesRevampedUI, !query.isSearchActive, query.query.isEmpty, appliedChips.isEmpty else {
            return legacyEmptyViewModel(query: query, appliedChips: appliedChips, config: config)
        }

        guard let parentNode = nodeSource.parentNode else {
            return legacyEmptyViewModel(query: query, appliedChips: appliedChips, config: config)
        }

        if parentNode.nodeType == .root {
            return viewModelForRoot
        }

        // Revamp UI is only applicable for CD folders and CD root, not rubbish bin and backup
        guard [DisplayMode.backup, .rubbishBin].notContains(displayMode) else {
            return legacyEmptyViewModel(query: query, appliedChips: appliedChips, config: config)
        }

        let nodeAccessLevel = nodeUseCase.nodeAccessLevel(nodeHandle: parentNode.handle)
        let showsAddFilesButton = [NodeAccessTypeEntity.full, .owner, .readWrite].contains(nodeAccessLevel)
        return viewModelForNonRoot(showsAddFilesButton: showsAddFilesButton)
    }

    private func legacyEmptyViewModel(
        query: SearchQuery,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableViewModel {
        // we show contextual, chip-related empty screen only when there
        // is not text query
        if query.query.isEmpty {
            // node format takes priority when showing empty assets.
            let chip = appliedChips.first { $0.type.isNodeFormatChip || $0.type.isNodeTypeChip } ?? appliedChips.first

            // this assumes only one chip at most can be applied at any given time
            return config.emptyViewAssetFactory(chip, query).emptyViewModel
        }

        // when there is non-empty text query (and no results of course) ,
        // [independently if there is any chip selected
        // we show generic 'no results' empty screen
        return config.emptyViewAssetFactory(nil, query).emptyViewModel
    }

    private var addFilesButton: ContentUnavailableViewModel.ButtonAction {
        ContentUnavailableViewModel.ButtonAction(title: Strings.Localizable.addFiles, image: MEGAAssets.Image.plus, handler: { [weak self] in

            DIContainer.tracker.trackAnalyticsEvent(with: CloudDriveEmptyStateAddFilesPressedEvent())
            self?.delegate?.emptyStateAddButtonTapped()
        })
    }

    private var viewModelForRoot: ContentUnavailableViewModel {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.cloudDriveEmptyStateRoot,
            title: Strings.Localizable.CloudDrive.EmptyStateTitle.root,
            subtitle: Strings.Localizable.CloudDrive.emptyStateSubtitle,
            font: .body, // Not used in revamped UI
            titleTextColor: .primary, // Not used in revamped UI
            actions: [addFilesButton]
        )
    }

    private func viewModelForNonRoot(showsAddFilesButton: Bool) -> ContentUnavailableViewModel {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.cloudDriveEmptyStateNonRoot,
            title: Strings.Localizable.CloudDrive.EmptyStateTitle.nonRoot,
            subtitle: Strings.Localizable.CloudDrive.emptyStateSubtitle,
            font: .body, // Not used in revamped UI
            titleTextColor: .primary, // Not used in revamped UI
            actions: showsAddFilesButton ? [addFilesButton] : []
        )
    }
}
