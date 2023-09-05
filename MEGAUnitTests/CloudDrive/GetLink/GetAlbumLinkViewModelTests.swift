@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import XCTest

final class GetAlbumLinkViewModelTests: XCTestCase {
    
    func testNumberOfSections_init_isCorrect() {
        let album = AlbumEntity(id: 1, type: .user)
        let sections = [
            GetLinkSectionViewModel(sectionType: .info, cellViewModels: [], itemHandle: album.id)
        ]
        
        let sut = makeGetAlbumLinkViewModel(album: album,
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
        
        let sut = makeGetAlbumLinkViewModel(album: album,
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
        let sut = makeGetAlbumLinkViewModel(album: album,
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
        let sut = makeGetAlbumLinkViewModel(album: album,
                                            sectionViewModels: [section])
        XCTAssertEqual(sut.sectionType(forSection: 0),
                       section.sectionType)
    }
    
    func testDispatchViewConfiguration_onNoExportedAlbums_shouldSetTitleToShareLinkAndTrackScreen() {
        let album = AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(false))
        let tracker = MockTracker()
        let sut = makeGetAlbumLinkViewModel(album: album,
                                            tracker: tracker)
        
        let expectedTitle = Strings.Localizable.General.MenuAction.ShareLink.title(1)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: expectedTitle,
                           isMultilink: false,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1))
        ])
        
        tracker.assertTrackAnalyticsEventCalled(
            with: [
                SingleAlbumLinkScreenEvent()
            ]
        )
    }
    
    func testDispatchViewConfiguration_onExportedAlbums_shouldSetTitleToManageShareLink() {
        let album = AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(true))
        let sut = makeGetAlbumLinkViewModel(album: album)
        
        let expectedTitle = Strings.Localizable.General.MenuAction.ManageLink.title(1)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: expectedTitle,
                           isMultilink: false,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1))
        ])
    }
    
    func testDispatchOnViewReady_onAlbumLinkLoaded_shouldUpdateLinkSectionLinkCell() async throws {
        let album = AlbumEntity(id: 1, type: .user)
        let sections = [
            GetLinkSectionViewModel(sectionType: .link,
                                    cellViewModels: [GetLinkStringCellViewModel(link: "")],
                                    itemHandle: album.id)
        ]
        let link = "the shared link"
        let shareAlbumUseCase = MockShareAlbumUseCase(shareAlbumLinkResult: .success(link))
        let sut = makeGetAlbumLinkViewModel(album: album,
                                            shareAlbumUseCase: shareAlbumUseCase,
                                            sectionViewModels: sections)
        
        let updatedIndexPath = IndexPath(row: 0, section: 0)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                           isMultilink: false,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)),
            .enableLinkActions,
            .reloadRows([updatedIndexPath])
        ])
        
        await sut.loadingTask?.value
        
        let updatedCell = try XCTUnwrap(sut.cellViewModel(indexPath: updatedIndexPath) as? GetLinkStringCellViewModel)
        test(viewModel: updatedCell, action: .onViewReady, expectedCommands: [
            .configView(title: link, leftImage: Asset.Images.GetLinkView.linkGetLink.image, isRightImageViewHidden: true)
        ])
    }
    
    func testDispatchSwitchToggled_onDecryptKeySeparateToggled_linkAndKeyShouldUpdateCorrectly() async throws {
        let album = AlbumEntity(id: 1, type: .user)
        let sections = [
            GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                    cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                      configuration: GetLinkSwitchCellViewConfiguration(title: "Test"))],
                                    itemHandle: album.id),
            GetLinkSectionViewModel(sectionType: .link,
                                    cellViewModels: [GetLinkStringCellViewModel(link: "")],
                                    itemHandle: album.id)
        ]
        let link = "/collection/link#key"
        let shareAlbumUseCase = MockShareAlbumUseCase(shareAlbumLinkResult: .success(link))
        let sut = makeGetAlbumLinkViewModel(album: album,
                                            shareAlbumUseCase: shareAlbumUseCase,
                                            sectionViewModels: sections)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                           isMultilink: false,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                          ),
            .enableLinkActions,
            .reloadRows([IndexPath(row: 0, section: 1)])
        ])
        
        await sut.loadingTask?.value
        
        let decryptToggleIndexPath = IndexPath(row: 0, section: 0)
        let expectedKeySectionIndex = 2
        test(viewModel: sut, action: .switchToggled(indexPath: decryptToggleIndexPath, isOn: true),
             expectedCommands: [
                .insertSections([expectedKeySectionIndex]),
                .reloadSections([1]),
                .configureToolbar(isDecryptionKeySeperate: true)
             ])
        let decryptCellViewModel = try XCTUnwrap(sut.cellViewModel(indexPath: decryptToggleIndexPath) as?  GetLinkSwitchOptionCellViewModel)
        XCTAssertTrue(decryptCellViewModel.isSwitchOn)
        test(viewModel: sut, action: .switchToggled(indexPath: decryptToggleIndexPath, isOn: false),
             expectedCommands: [
                .reloadSections([1]),
                .deleteSections([expectedKeySectionIndex]),
                .configureToolbar(isDecryptionKeySeperate: false)
             ])
    }
    
    func testDispatchShareLink_onDecryptSeperateOff_shouldOnlyShareOriginalLink() async {
        let album = AlbumEntity(id: 1, type: .user)
        let link = "https://mega.nz/collection/link#key"
        let sections = [
            GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                    cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                      configuration: GetLinkSwitchCellViewConfiguration(title: "Test"))],
                                    itemHandle: album.id)
        ]
        let shareAlbumUseCase = MockShareAlbumUseCase(shareAlbumLinkResult: .success(link))
        let sut = makeGetAlbumLinkViewModel(album: album,
                                            shareAlbumUseCase: shareAlbumUseCase,
                                            sectionViewModels: sections)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                           isMultilink: false,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                          )
        ])
        await sut.loadingTask?.value
        let barButton = await UIBarButtonItem()
        test(viewModel: sut, action: .shareLink(sender: barButton),
             expectedCommands: [
                .showShareActivity(sender: barButton, link: link, key: nil)
             ])
    }
    
    func testDispatchShareLink_onDecryptSeperateOn_shouldShareLinkSeperatelyFromKey() async {
        let album = AlbumEntity(id: 1, type: .user)
        let linkOnly = "https://mega.nz/collection/link"
        let key = "key"
        let link = "\(linkOnly)#\(key)"
        let sections = [
            GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                    cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                      configuration: GetLinkSwitchCellViewConfiguration(title: "Test", isSwitchOn: true))],
                                    itemHandle: album.id)
        ]
        let shareAlbumUseCase = MockShareAlbumUseCase(shareAlbumLinkResult: .success(link))
        let sut = makeGetAlbumLinkViewModel(album: album,
                                            shareAlbumUseCase: shareAlbumUseCase,
                                            sectionViewModels: sections)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                           isMultilink: false,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                          )
        ])
        await sut.loadingTask?.value
        let barButton = await UIBarButtonItem()
        test(viewModel: sut, action: .shareLink(sender: barButton),
             expectedCommands: [
                .showShareActivity(sender: barButton, link: linkOnly, key: key)
             ])
    }
    
    func testDispatchCopyLink_onDecryptSeperateOff_shouldCopyShareOriginalLink() async {
        let album = AlbumEntity(id: 1, type: .user)
        let link = "https://mega.nz/collection/link#key"
        let sections = [
            GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                    cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                      configuration: GetLinkSwitchCellViewConfiguration(title: "Test"))],
                                    itemHandle: album.id)
        ]
        let shareAlbumUseCase = MockShareAlbumUseCase(shareAlbumLinkResult: .success(link))
        let sut = makeGetAlbumLinkViewModel(album: album,
                                            shareAlbumUseCase: shareAlbumUseCase,
                                            sectionViewModels: sections)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                           isMultilink: false,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                          )
        ])
        
        await sut.loadingTask?.value
        
        test(viewModel: sut, action: .copyLink,
             expectedCommands: [
                .addToPasteBoard(link),
                .showHud(.custom(Asset.Images.NodeActions.copy.image,
                                 Strings.Localizable.SharedItems.GetLink.linkCopied(1)))
             ])
    }
    
    func testDispatchCopyLink_onDecryptSeperateOn_shouldCopyOnlyLink() async {
        let album = AlbumEntity(id: 1, type: .user)
        let linkOnly = "https://mega.nz/collection/link"
        let key = "key"
        let link = "\(linkOnly)#\(key)"
        let sections = [
            GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                    cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                      configuration: GetLinkSwitchCellViewConfiguration(title: "Test", isSwitchOn: true))],
                                    itemHandle: album.id)
        ]
        let shareAlbumUseCase = MockShareAlbumUseCase(shareAlbumLinkResult: .success(link))
        let sut = makeGetAlbumLinkViewModel(album: album,
                                            shareAlbumUseCase: shareAlbumUseCase,
                                            sectionViewModels: sections)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                           isMultilink: false,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                          )
        ])
        
        await sut.loadingTask?.value
        
        test(viewModel: sut, action: .copyLink,
             expectedCommands: [
                .addToPasteBoard(linkOnly),
                .showHud(.custom(Asset.Images.NodeActions.copy.image,
                                 Strings.Localizable.SharedItems.GetLink.linkCopied(1)))
             ])
    }
    
    func testDispatchCopyKey_onDecryptSeperateOn_shouldCopyKey() async {
        let album = AlbumEntity(id: 1, type: .user)
        let linkOnly = "https://mega.nz/collection/link"
        let key = "key"
        let link = "\(linkOnly)#\(key)"
        let sections = [
            GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                    cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                      configuration: GetLinkSwitchCellViewConfiguration(title: "Test", isSwitchOn: true))],
                                    itemHandle: album.id)
        ]
        let shareAlbumUseCase = MockShareAlbumUseCase(shareAlbumLinkResult: .success(link))
        let sut = makeGetAlbumLinkViewModel(album: album,
                                            shareAlbumUseCase: shareAlbumUseCase,
                                            sectionViewModels: sections)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                           isMultilink: false,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                          )
        ])
        
        await sut.loadingTask?.value
        
        test(viewModel: sut, action: .copyKey,
             expectedCommands: [
                .addToPasteBoard(key),
                .showHud(.custom(Asset.Images.NodeActions.copy.image,
                                 Strings.Localizable.keyCopiedToClipboard))
             ])
    }
    
    // MARK: - Helpers
    
    private func makeGetAlbumLinkViewModel(
        album: AlbumEntity,
        shareAlbumUseCase: some ShareAlbumUseCaseProtocol = MockShareAlbumUseCase(),
        sectionViewModels: [GetLinkSectionViewModel] = [],
        tracker: some AnalyticsTracking = MockTracker()
    ) -> GetAlbumLinkViewModel {
        GetAlbumLinkViewModel(album: album,
                              shareAlbumUseCase: shareAlbumUseCase,
                              sectionViewModels: sectionViewModels,
                              tracker: tracker)
    }
}
