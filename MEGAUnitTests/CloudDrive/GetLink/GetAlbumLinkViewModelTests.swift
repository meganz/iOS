import XCTest
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class GetAlbumLinkViewModelTests: XCTestCase {
    
    func testNumberOfSections_init_isCorrect() {
        let album = AlbumEntity(id: 1, type: .user)
        let sections = [
            GetLinkSectionViewModel(sectionType: .info, cellViewModels: [], itemHandle: album.id)
        ]
        
        let sut = GetAlbumLinkViewModel(album: album, shareAlbumUseCase: MockShareAlbumUseCase(), sectionViewModels: sections)
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
        
        let sut = GetAlbumLinkViewModel(album: album, shareAlbumUseCase: MockShareAlbumUseCase(), sectionViewModels: sections)
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
        let sut = GetAlbumLinkViewModel(album: album, shareAlbumUseCase: MockShareAlbumUseCase(),
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
        let sut = GetAlbumLinkViewModel(album: album, shareAlbumUseCase: MockShareAlbumUseCase(),
                                        sectionViewModels: [section])
        XCTAssertEqual(sut.sectionType(forSection: 0),
                       section.sectionType)
    }
    
    func testDispatchViewConfiguration_onNoExportedAlbums_shouldSetTitleToShareLink() {
        let album = AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(false))
        let sut = GetAlbumLinkViewModel(album: album, shareAlbumUseCase: MockShareAlbumUseCase(),
                                        sectionViewModels: [])
        
        let expectedTitle = Strings.Localizable.General.MenuAction.ShareLink.title(1)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: expectedTitle,
                           isMultilink: false)
        ])
    }
    
    func testDispatchViewConfiguration_onExportedAlbums_shouldSetTitleToManageShareLink() {
        let album = AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(true))
        let sut = GetAlbumLinkViewModel(album: album, shareAlbumUseCase: MockShareAlbumUseCase(),
                                        sectionViewModels: [])
        
        let expectedTitle = Strings.Localizable.General.MenuAction.ManageLink.title(1)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: expectedTitle,
                           isMultilink: false)
        ])
    }
    
    func testDispatchOnViewReady_onAlbumLinkLoaded_shouldUpdateLinkSectionLinkCell() throws {
        let album = AlbumEntity(id: 1, type: .user)
        let sections = [
            GetLinkSectionViewModel(sectionType: .link,
                                    cellViewModels: [GetLinkStringCellViewModel(link: "")],
                                    itemHandle: album.id)
        ]
        let link = "the shared link"
        let shareAlbumUseCase = MockShareAlbumUseCase(shareAlbumLinkResult: .success(link))
        let sut = GetAlbumLinkViewModel(album: album, shareAlbumUseCase: shareAlbumUseCase,
                                        sectionViewModels: sections)
        let updatedIndexPath = IndexPath(row: 0, section: 0)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                           isMultilink: false),
            .enableLinkActions,
            .reloadRows([updatedIndexPath])
        ])
        let updatedCell = try XCTUnwrap(sut.cellViewModel(indexPath: updatedIndexPath) as? GetLinkStringCellViewModel)
        test(viewModel: updatedCell, action: .onViewReady, expectedCommands: [
            .configView(title: link, leftImage: Asset.Images.GetLinkView.linkGetLink.image, isRightImageViewHidden: true)
        ])
    }
    
    func testDispatchSwitchToggled_onDecryptKeySeparateToggled_linkAndKeyShouldUpdateCorrectly() throws {
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
        let sut = GetAlbumLinkViewModel(album: album, shareAlbumUseCase: shareAlbumUseCase,
                                        sectionViewModels: sections)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                           isMultilink: false),
            .enableLinkActions,
            .reloadRows([IndexPath(row: 0, section: 1)])
        ])
        let decryptToggleIndexPath = IndexPath(row: 0, section: 0)
        let expectedKeySectionIndex = 2
        test(viewModel: sut, action: .switchToggled(indexPath: decryptToggleIndexPath, isOn: true),
             expectedCommands: [
                .insertSections([expectedKeySectionIndex]),
                .reloadSections([1])
             ])
        test(viewModel: sut, action: .switchToggled(indexPath: decryptToggleIndexPath, isOn: false),
             expectedCommands: [
                .reloadSections([1]),
                .deleteSections([expectedKeySectionIndex]),
             ])
    }
}
