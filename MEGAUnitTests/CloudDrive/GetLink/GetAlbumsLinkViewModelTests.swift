@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class GetAlbumsLinkViewModelTests: XCTestCase {

    func testNumberOfSections_init_isCorrect() {
        let album = AlbumEntity(id: 1, type: .user)
        let sections = [
            GetLinkSectionViewModel(sectionType: .info, cellViewModels: [], itemHandle: album.id)
        ]
        let sut = makeGetAlbumsLinkViewModel(albums: [album],
                                             sectionViewModels: sections)
        
        XCTAssertEqual(sut.numberOfSections, sections.count)
    }
    
    func testNumberRowsInSection_init_isCorrect() {
        let album = AlbumEntity(id: 1, type: .user)
        let cellViewModels = [GetLinkStringCellViewModel(link: "Test link")]
        let sections = [
            GetLinkSectionViewModel(sectionType: .info,
                                    cellViewModels: cellViewModels,
                                    itemHandle: album.id)
        ]
        let sut = makeGetAlbumsLinkViewModel(albums: [album],
                                             sectionViewModels: sections)
        
        XCTAssertEqual(sut.numberOfRowsInSection(0),
                       cellViewModels.count)
    }
    
    func testCellViewModel_init_forIndexPath_isCorrect() {
        let album = AlbumEntity(id: 1, type: .user)
        let cellViewModels = [GetLinkStringCellViewModel(link: "Test link")]
        let sections = [
            GetLinkSectionViewModel(sectionType: .info,
                                    cellViewModels: cellViewModels,
                                    itemHandle: album.id)
        ]
        let sut = makeGetAlbumsLinkViewModel(albums: [album],
                                             sectionViewModels: sections)
        
        let indexPath = IndexPath(row: 0, section: 0)
        XCTAssertEqual(sut.cellViewModel(indexPath: indexPath)?.type,
                       cellViewModels[indexPath.row].type
        )
    }
    
    func testCellViewModel_init_sectionTypeRetrievalIsCorrect() {
        let album = AlbumEntity(id: 1, type: .user)
        let section = GetLinkSectionViewModel(sectionType: .info,
                                              cellViewModels: [],
                                              itemHandle: album.id)
        let sut = makeGetAlbumsLinkViewModel(albums: [album],
                                             sectionViewModels: [section])
        
        XCTAssertEqual(sut.sectionType(forSection: 0),
                       section.sectionType)
    }
    
    @MainActor func testDispatch_onViewReady_shouldSetTitleToShareLinkAndTrackEvent() throws {
        for hiddenNodesFeatureFlagActive in [true, false] {
            let albums = [AlbumEntity(id: 1, type: .user), AlbumEntity(id: 2, type: .user)]
            let tracker = MockTracker()
            let sut = makeGetAlbumsLinkViewModel(
                albums: albums,
                shareCollectionUseCase: MockShareCollectionUseCase(doesCollectionsContainSensitiveElement: albums.reduce(into: [HandleEntity: Bool](), { $0[$1.id] = false })),
                tracker: tracker,
                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            let expectedTitle = Strings.Localizable.General.MenuAction.ShareLink.title(albums.count)
            test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(title: expectedTitle,
                               isMultilink: true,
                               shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(albums.count)),
                .hideMultiLinkDescription,
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .dismissHud
            ], expectationValidation: ==)
            
            assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [
                    MultipleAlbumLinksScreenEvent()
                ]
            )
        }
    }
    
    @MainActor func testDispatch_onViewReadyAndAllAlbumsAlreadyExported_shouldSetTitleToShareLinkAndTrackEvent() throws {
        for hiddenNodesFeatureFlagActive in [true, false] {
            let albums = [
                AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(true)),
                AlbumEntity(id: 2, type: .user, sharedLinkStatus: .exported(true))
            ]
            let tracker = MockTracker()
            let sut = makeGetAlbumsLinkViewModel(
                albums: albums,
                shareCollectionUseCase: MockShareCollectionUseCase(doesCollectionsContainSensitiveElement: albums.reduce(into: [HandleEntity: Bool](), { $0[$1.id] = false })),
                tracker: tracker,
                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            let expectedTitle = Strings.Localizable.General.MenuAction.ManageLink.title(albums.count)
            test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(title: expectedTitle,
                               isMultilink: true,
                               shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(albums.count)),
                .hideMultiLinkDescription,
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .dismissHud
            ], expectationValidation: ==)
            
            assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [
                    MultipleAlbumLinksScreenEvent()
                ]
            )
        }
    }
    
    @MainActor func testDispatch_onViewReadyLinksLoaded_shouldUpdateLinkCells() throws {
        for hiddenNodesFeatureFlagActive in [true, false] {
            
            let firstAlbum = AlbumEntity(id: 1, type: .user)
            let secondAlbum = AlbumEntity(id: 2, type: .user)
            let albums = [firstAlbum, secondAlbum]
            let sections = albums.map {
                GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                    GetLinkStringCellViewModel(link: "")
                ], itemHandle: $0.id)
            }
            let expectedRowReloads = sections.indices.map {
                IndexPath(row: 0, section: $0)
            }
            let links = [firstAlbum.id: "link1", secondAlbum.id: "link2"]
            let sut = makeGetAlbumsLinkViewModel(albums: albums,
                                                 shareCollectionUseCase: MockShareCollectionUseCase(
                                                    shareCollectionsLinks: links,
                                                    doesCollectionsContainSensitiveElement: albums.reduce(into: [HandleEntity: Bool](), { $0[$1.id] = false })),
                                                 sectionViewModels: sections,
                                                 hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            expectSuccessfulOnViewReady(sut: sut, albums: albums, expectedRowReload: expectedRowReloads)
            
            try expectedRowReloads.forEach { index in
                let cellViewModel = try XCTUnwrap(sut.cellViewModel(indexPath: index) as? GetLinkStringCellViewModel)
                XCTAssertEqual(cellViewModel.type, .link)
            }
        }
    }
    
    @MainActor func testDispatch_shareLink_shouldShowShareActivityWithJoinedLinksInNewLine() {
        for hiddenNodesFeatureFlagActive in [true, false] {
            
            let albums = [AlbumEntity(id: 1, type: .user),
                          AlbumEntity(id: 2, type: .user)]
            let sections = albums.map {
                GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                    GetLinkStringCellViewModel(link: "")
                ], itemHandle: $0.id)
            }
            let links = Dictionary(uniqueKeysWithValues: albums.map { ($0.id, "link-\($0.id)") })
            let sut = makeGetAlbumsLinkViewModel(albums: albums,
                                                 shareCollectionUseCase: MockShareCollectionUseCase(
                                                    shareCollectionsLinks: links,
                                                    doesCollectionsContainSensitiveElement: albums.reduce(into: [HandleEntity: Bool](), { $0[$1.id] = false })),
                                                 sectionViewModels: sections,
                                                 hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            let expectedRowReloads = sections.indices.map {
                IndexPath(row: 0, section: $0)
            }
            expectSuccessfulOnViewReady(sut: sut, albums: albums,
                                        expectedRowReload: expectedRowReloads)
            
            let expectedLink = links.values.joined(separator: "\n")
            let barButton = UIBarButtonItem()
            test(viewModel: sut, action: .shareLink(sender: barButton),
                 expectedCommands: [
                    .showShareActivity(sender: barButton, link: expectedLink, key: nil)
                 ], expectationValidation: ==)
        }
    }
    
    @MainActor func testDispatch_copyLink_shouldAddSpaceSeparatedLinksToPasteboard() {
        for hiddenNodesFeatureFlagActive in [true, false] {
            
            let albums = [AlbumEntity(id: 1, type: .user),
                          AlbumEntity(id: 2, type: .user)]
            let sections = albums.map {
                GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                    GetLinkStringCellViewModel(link: "")
                ], itemHandle: $0.id)
            }
            let links = Dictionary(uniqueKeysWithValues: albums.map { ($0.id, "link-\($0.id)") })
            let sut = makeGetAlbumsLinkViewModel(albums: albums,
                                                 shareCollectionUseCase: MockShareCollectionUseCase(
                                                    shareCollectionsLinks: links,
                                                    doesCollectionsContainSensitiveElement: albums.reduce(into: [HandleEntity: Bool](), { $0[$1.id] = false })),
                                                 sectionViewModels: sections,
                                                 hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            let expectedRowReloads = sections.indices.map {
                IndexPath(row: 0, section: $0)
            }
            expectSuccessfulOnViewReady(sut: sut, albums: albums, expectedRowReload: expectedRowReloads)
            let expectedLink = links.values.joined(separator: " ")
            test(viewModel: sut, action: .copyLink,
                 expectedCommands: [
                    .addToPasteBoard(expectedLink),
                    .showHud(.custom(UIImage.copy,
                                     Strings.Localizable.SharedItems.GetLink.linkCopied(links.values.count)))
                 ], expectationValidation: ==)
        }
    }
    
    @MainActor func testDispatch_onDidSelectRowIndexPath_shouldAddSelectedLinkToPasteBoard() {
        for hiddenNodesFeatureFlagActive in [true, false] {
            let album = AlbumEntity(id: 1, type: .user)
            let otherAlbum = AlbumEntity(id: 3, type: .user)
            let albums = [album, otherAlbum]
            let sections = albums.map {
                GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                    GetLinkStringCellViewModel(link: "")
                ], itemHandle: $0.id)
            }
            let expectedLink = "link-to-copy"
            let links = [album.id: expectedLink]
            let sut = makeGetAlbumsLinkViewModel(albums: albums,
                                                 shareCollectionUseCase: MockShareCollectionUseCase(
                                                    shareCollectionsLinks: links,
                                                    doesCollectionsContainSensitiveElement: albums.reduce(into: [HandleEntity: Bool](), { $0[$1.id] = false })),
                                                 sectionViewModels: sections,
                                                 hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            let linkIndexPath = IndexPath(row: 0, section: 0)
            expectSuccessfulOnViewReady(sut: sut, albums: albums, expectedRowReload: [linkIndexPath])
            
            test(viewModel: sut, action: .didSelectRow(indexPath: linkIndexPath),
                 expectedCommands: [
                    .addToPasteBoard(expectedLink),
                    .showHud(.custom(UIImage.copy,
                                     Strings.Localizable.SharedItems.GetLink.linkCopied(1)))
                 ], expectationValidation: ==)
        }
    }
    
    @MainActor func testDispatch_onViewReadyAndAlbumContainsSensitiveElement_shouldShowAlert() throws {
        let albums = [AlbumEntity(id: 1, type: .user), AlbumEntity(id: 2, type: .user)]
        let tracker = MockTracker()
        let sut = makeGetAlbumsLinkViewModel(
            albums: albums,
            shareCollectionUseCase: MockShareCollectionUseCase(doesCollectionsContainSensitiveElement: albums.reduce(into: [HandleEntity: Bool](), { $0[$1.id] = true })),
            tracker: tracker,
            hiddenNodesFeatureFlagActive: true)
        
        let expectedTitle = Strings.Localizable.General.MenuAction.ShareLink.title(albums.count)
        test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
            .configureView(title: expectedTitle,
                           isMultilink: true,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(albums.count)),
            .hideMultiLinkDescription,
            .showHud(.status(Strings.Localizable.generatingLinks)),
            .dismissHud,
            .showAlert(AlertModel(
                title: Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.title,
                message: Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.Message.multi,
                actions: [
                    .init(title: Strings.Localizable.cancel, style: .cancel, handler: { }),
                    .init(title: Strings.Localizable.continue, style: .default, isPreferredAction: true, handler: { })
                ]))
        ], expectationValidation: ==)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                MultipleAlbumLinksScreenEvent()
            ]
        )
    }
    
    func testDispatch_onViewReadyAndAlbumContainsSensitiveElementAndContinuesAndTapsContinue_shouldLoadLinks() throws {
        let albums = [AlbumEntity(id: 1, type: .user), AlbumEntity(id: 2, type: .user)]
        let sections = albums.map {
            GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                GetLinkStringCellViewModel(link: "")
            ], itemHandle: $0.id)
        }
        let expectedRowReloads = sections.indices.map { IndexPath(row: 0, section: $0) }
        let tracker = MockTracker()
        let sut = makeGetAlbumsLinkViewModel(
            albums: albums,
            shareCollectionUseCase: MockShareCollectionUseCase(
                shareCollectionsLinks: Dictionary(uniqueKeysWithValues: albums.map { ($0.id, "link-\($0.id)") }),
                doesCollectionsContainSensitiveElement: albums.reduce(into: [HandleEntity: Bool](), { $0[$1.id] = true })),
            sectionViewModels: sections,
            tracker: tracker,
            hiddenNodesFeatureFlagActive: true)
        
        let expectation = expectation(description: "Expect sensitive content alert to appear")
        var continueAction: AlertModel.AlertAction?
        sut.invokeCommand = {
            if case let .showAlert(alertModel) = $0,
               let action = alertModel.actions.first(where: { $0.title ==  Strings.Localizable.continue }) {
                continueAction = action
                expectation.fulfill()
            }
        }
        
        sut.dispatch(.onViewDidAppear)
        
        wait(for: [expectation], timeout: 1)
        
        test(viewModel: sut, trigger: { continueAction?.handler() }, expectedCommands: [
            .showHud(.status(Strings.Localizable.generatingLinks)),
            .reloadRows(expectedRowReloads),
            .enableLinkActions,
            .dismissHud
        ], expectationValidation: ==)

    }
    
    @MainActor func testDispatch_onViewReadyAndOneAlbumContainsSensitiveElementsAndIsNotExported_shouldShowAlert() throws {
        let albums = [
            AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(true)),
            AlbumEntity(id: 2, type: .user)
        ]
        let sections = albums.map {
            GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                GetLinkStringCellViewModel(link: "")
            ], itemHandle: $0.id)
        }

        let tracker = MockTracker()
        let sut = makeGetAlbumsLinkViewModel(
            albums: albums,
            shareCollectionUseCase: MockShareCollectionUseCase(
                shareCollectionsLinks: Dictionary(uniqueKeysWithValues: albums.map { ($0.id, "link-\($0.id)") }),
                doesCollectionsContainSensitiveElement: albums.reduce(into: [HandleEntity: Bool](), { $0[$1.id] = true })),
            sectionViewModels: sections,
            tracker: tracker,
            hiddenNodesFeatureFlagActive: true)
        
        let expectedTitle = Strings.Localizable.General.MenuAction.ManageLink.title(albums.count)
        test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
            .configureView(title: expectedTitle,
                           isMultilink: true,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(albums.count)),
            .hideMultiLinkDescription,
            .showHud(.status(Strings.Localizable.generatingLinks)),
            .dismissHud,
            .showAlert(AlertModel(
                title: Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.title,
                message: Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.Message.multi,
                actions: [
                    .init(title: Strings.Localizable.cancel, style: .cancel, handler: { }),
                    .init(title: Strings.Localizable.continue, style: .default, isPreferredAction: true, handler: { })
                ]))
        ], expectationValidation: ==)
    }
    
    func testDispatch_onViewReadyAndAlbumContainsSensitiveElementAndContinuesAndTapsCancel_shouldDismissView() throws {
        let albums = [AlbumEntity(id: 1, type: .user), AlbumEntity(id: 2, type: .user)]
        let tracker = MockTracker()
        let sut = makeGetAlbumsLinkViewModel(
            albums: albums,
            shareCollectionUseCase: MockShareCollectionUseCase(
                doesCollectionsContainSensitiveElement: albums.reduce(into: [HandleEntity: Bool](), { $0[$1.id] = true })),
            tracker: tracker,
            hiddenNodesFeatureFlagActive: true)
        
        let expectation = expectation(description: "Expect sensitive content alert to appear")
        var cancelAction: AlertModel.AlertAction?
        sut.invokeCommand = {
            if case let .showAlert(alertModel) = $0,
               let action = alertModel.actions.first(where: { $0.title ==  Strings.Localizable.cancel }) {
                cancelAction = action
                expectation.fulfill()
            }
        }
        
        sut.dispatch(.onViewDidAppear)
        
        wait(for: [expectation], timeout: 1)
        
        test(viewModel: sut, trigger: { cancelAction?.handler() }, expectedCommands: [
            .dismiss
        ], expectationValidation: ==)
    }
    
    @MainActor private func expectSuccessfulOnViewReady(sut: GetAlbumsLinkViewModel, albums: [AlbumEntity], expectedRowReload: [IndexPath]) {
        test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(albums.count),
                           isMultilink: true,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(albums.count)),
            .hideMultiLinkDescription,
            .showHud(.status(Strings.Localizable.generatingLinks)),
            .reloadRows(expectedRowReload),
            .enableLinkActions,
            .dismissHud
        ], expectationValidation: ==)
    }
    
    private func makeGetAlbumsLinkViewModel(
        albums: [AlbumEntity] = [],
        shareCollectionUseCase: some ShareCollectionUseCaseProtocol = MockShareCollectionUseCase(),
        sectionViewModels: [GetLinkSectionViewModel] = [],
        tracker: some AnalyticsTracking = MockTracker(),
        hiddenNodesFeatureFlagActive: Bool = false
    ) -> GetAlbumsLinkViewModel {
        GetAlbumsLinkViewModel(albums: albums,
                               shareCollectionUseCase: shareCollectionUseCase,
                               sectionViewModels: sectionViewModels,
                               tracker: tracker,
                               remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: hiddenNodesFeatureFlagActive]))
    }
}
