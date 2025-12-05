@testable import MEGA
import MEGAAssets
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import MEGASwiftUI
import Search
import SearchMock
import SwiftUI
import Testing

@Suite("CloudDriveContentUnavailableViewModelProviderTests")
@MainActor
struct CloudDriveContentUnavailableViewModelProviderTests {
    private enum TestData {
        static let nonBackupOrRubbishBinDisplayModes: [DisplayMode] = DisplayMode.allCases.filter { $0 != .backup && $0 != .rubbishBin }
        static let rootNode = NodeEntity(nodeType: .root)
        static let nonRootNode = NodeEntity(handle: 1)
        @MainActor static let defaultEmptyViewAssets = SearchConfig.EmptyViewAssets.testAssets
    }

    @Suite("When usesRevampedUI is disabled")
    struct UsesRevampedUIDisabled {
        @Test("Use the output from defaultEmptyViewAssets")
        @MainActor func emptyViewModelWhenUsesRevampedUIIsFalse() async throws {
            let sut = makeSUT(usesRevampedUI: false)
            let output = sut.emptyViewModel(query: .initial, appliedChips: [], config: .testConfig)

            #expect(output.title == TestData.defaultEmptyViewAssets.title)
            #expect(output.image == TestData.defaultEmptyViewAssets.image)
            #expect(output.subtitle == nil)
            #expect(output.actions.isEmpty)
        }
    }

    @Suite("When usesRevampedUI is enabled")
    struct UsesRevampedUIEnabled {
        @Test("Different search parameter results in legacy outputs")
        @MainActor func emptyViewModelWithDifferentSearchQueries() async throws {
            let sut = makeSUT(nodeSource: NodeSource.node { NodeEntity(handle: 1) })
            let defaultAssets = TestData.defaultEmptyViewAssets

            // Test scenarios that should return legacy output
            let testCases: [(query: SearchQuery, chips: [SearchChipEntity])] = [
                (.userSupplied(.query("text", isSearchActive: false, chips: [])), []),
                (.userSupplied(.query("text", isSearchActive: false, chips: [])), [.video]),
                (.userSupplied(.query("", isSearchActive: true, chips: [])), [])
            ]

            for (query, chips) in testCases {
                let output = sut.emptyViewModel(query: query, appliedChips: chips, config: .testConfig)
                #expect(output.image == defaultAssets.image)
                #expect(output.title == defaultAssets.title)
                #expect(output.subtitle == nil)
                #expect(output.actions.isEmpty)
            }
        }

        @Test("Root node should yield revamped empty view model with one action")
        @MainActor func emptyViewModelForRootNode() async throws {
            let sut = makeSUT(nodeSource: NodeSource.node { TestData.rootNode })
            let output = sut.emptyViewModel(query: .initial, appliedChips: [], config: .testConfig)

            #expect(output.image == MEGAAssets.Image.cloudDriveEmptyStateRoot)
            #expect(output.title == Strings.Localizable.CloudDrive.EmptyStateTitle.root)
            #expect(output.subtitle == Strings.Localizable.CloudDrive.emptyStateSubtitle)
            #expect(output.actions.isNotEmpty)
            #expect(output.actions.first is ContentUnavailableViewModel.ButtonAction)
        }

        @Test("Non-root node with different DisplayMode yields correct output view model", arguments: DisplayMode.allCases)
        @MainActor func emptyViewModelForNonRootNode(displayMode: DisplayMode) async throws {
            let sut = makeSUT(
                nodeSource: NodeSource.node { TestData.nonRootNode },
                displayMode: displayMode,
                nodeUseCase: MockNodeUseCase(nodeAccessLevel: { .full })
            )
            let output = sut.emptyViewModel(query: .initial, appliedChips: [], config: .testConfig)

            if TestData.nonBackupOrRubbishBinDisplayModes.contains(displayMode) {
                #expect(output.image == MEGAAssets.Image.cloudDriveEmptyStateNonRoot)
                #expect(output.title == Strings.Localizable.CloudDrive.EmptyStateTitle.nonRoot)
                #expect(output.subtitle == Strings.Localizable.CloudDrive.emptyStateSubtitle)
                #expect(output.actions.isNotEmpty)
                #expect(output.actions.first is ContentUnavailableViewModel.ButtonAction)
            } else {
                #expect(output.image == TestData.defaultEmptyViewAssets.image)
                #expect(output.title == TestData.defaultEmptyViewAssets.title)
                #expect(output.subtitle == nil)
                #expect(output.actions.isEmpty)
            }
        }

        @Test("Valid Non-root node with different node access levels yields correct output view model with correct button action", arguments: NodeAccessTypeEntity.allCases)
        @MainActor func emptyViewModelForNonRootNode(nodeAccessLevel: NodeAccessTypeEntity) async throws {
            let sut = makeSUT(
                nodeSource: NodeSource.node { TestData.nonRootNode },
                displayMode: .cloudDrive,
                nodeUseCase: MockNodeUseCase(nodeAccessLevel: { nodeAccessLevel })
            )
            let delegate = MockDelegate()
            sut.delegate = delegate

            let output = sut.emptyViewModel(query: .initial, appliedChips: [], config: .testConfig)

            #expect(output.image == MEGAAssets.Image.cloudDriveEmptyStateNonRoot)
            #expect(output.title == Strings.Localizable.CloudDrive.EmptyStateTitle.nonRoot)
            #expect(output.subtitle == Strings.Localizable.CloudDrive.emptyStateSubtitle)

            let hasWriteAccess = [NodeAccessTypeEntity.full, .owner, .readWrite].contains(nodeAccessLevel)
            if hasWriteAccess {
                #expect(output.actions.isNotEmpty)
                
                let action = try #require(output.actions.first as? ContentUnavailableViewModel.ButtonAction)
                #expect(action.image == MEGAAssets.Image.plus)
                #expect(action.title == Strings.Localizable.addFiles)
                
                action.handler()
                #expect(delegate.emptyStateAddButtonTappedCalled == true)
            } else {
                #expect(output.actions.isEmpty)
            }
        }
    }

    // MARK: - Test Helpers

    static private func makeSUT(
        nodeSource: NodeSource = NodeSource.node { NodeEntity(handle: 0) },
        displayMode: DisplayMode? = nil,
        nodeUseCase: MockNodeUseCase = MockNodeUseCase(),
        usesRevampedUI: Bool = true
    ) -> CloudDriveContentUnavailableViewModelProvider {
        CloudDriveContentUnavailableViewModelProvider(
            defaultEmptyViewAssets: TestData.defaultEmptyViewAssets,
            nodeSource: nodeSource,
            displayMode: displayMode,
            nodeUseCase: nodeUseCase,
            usesRevampedUI: usesRevampedUI
        )
    }
}

private final class MockDelegate: CloudDriveContentUnavailableViewModelProviderDelegate {
    var emptyStateAddButtonTappedCalled = false
    
    func emptyStateAddButtonTapped() {
        emptyStateAddButtonTappedCalled = true
    }
}
