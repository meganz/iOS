import XCTest
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class GetAlbumsLinkViewModelTests: XCTestCase {

    func testNumberOfSections_init_isCorrect() {
        let album = AlbumEntity(id: 1, type: .user)
        let sections = [
            GetLinkSectionViewModel(sectionType: .info, cellViewModels: [], itemHandle: album.id)
        ]
        let sut = GetAlbumsLinkViewModel(albums: [album],
                                         shareAlbumUseCase: MockShareAlbumUseCase(),
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
        let sut = GetAlbumsLinkViewModel(albums: [album],
                                         shareAlbumUseCase: MockShareAlbumUseCase(),
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
        let sut = GetAlbumsLinkViewModel(albums: [album],
                                         shareAlbumUseCase: MockShareAlbumUseCase(),
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
        let sut = GetAlbumsLinkViewModel(albums: [album],
                                         shareAlbumUseCase: MockShareAlbumUseCase(),
                                         sectionViewModels: [section])
        XCTAssertEqual(sut.sectionType(forSection: 0),
                       section.sectionType)
    }
    
    func testDispatch_onViewReady_shouldSetTitleToShareLink() throws {
        let albums = [AlbumEntity(id: 1, type: .user), AlbumEntity(id: 2, type: .user)]
        let sut = GetAlbumsLinkViewModel(albums: albums, shareAlbumUseCase: MockShareAlbumUseCase(), sectionViewModels: [])
        
        let expectedTitle = Strings.Localizable.General.MenuAction.ShareLink.title(albums.count)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: expectedTitle,
                           isMultilink: true,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(albums.count)),
            .hideMultiLinkDescription,
            .showHud(.status(Strings.Localizable.generatingLinks)),
            .dismissHud
        ])
    }
    
    func testDispatch_onViewReadyLinksLoaded_shouldUpdateLinkCells() throws {
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
        let sut = GetAlbumsLinkViewModel(albums: albums,
                                         shareAlbumUseCase: MockShareAlbumUseCase(shareAlbumsLinks: links),
                                         sectionViewModels: sections)
        expectSuccessfulOnViewReady(sut: sut, albums: albums, expectedRowReload: expectedRowReloads)
        
        try expectedRowReloads.forEach { index in
            let cellViewModel = try XCTUnwrap(sut.cellViewModel(indexPath: index) as? GetLinkStringCellViewModel)
            XCTAssertEqual(cellViewModel.type, .link)
        }
    }
    
    func testDispatch_shareLink_shouldShowShareActivityWithJoinedLinksInNewLine() {
        let albums = [AlbumEntity(id: 1, type: .user),
                      AlbumEntity(id: 2, type: .user)]
        let sections = albums.map {
            GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                GetLinkStringCellViewModel(link: "")
            ], itemHandle: $0.id)
        }
        let links = Dictionary(uniqueKeysWithValues: albums.map { ($0.id, "link-\($0.id)") })
        let sut = GetAlbumsLinkViewModel(albums: albums,
                                         shareAlbumUseCase: MockShareAlbumUseCase(shareAlbumsLinks: links),
                                         sectionViewModels: sections)
        let expectedRowReloads = sections.indices.map {
            IndexPath(row: 0, section: $0)
        }
        expectSuccessfulOnViewReady(sut: sut, albums: albums, expectedRowReload: expectedRowReloads)
        let expectedLink = links.values.joined(separator: "\n")
        let barButton = UIBarButtonItem()
        test(viewModel: sut, action: .shareLink(sender: barButton),
             expectedCommands: [
                .showShareActivity(sender: barButton, link: expectedLink, key: nil)
             ])
    }
    
    func testDispatch_copyLink_shouldAddSpaceSeparatedLinksToPasteboard() {
        let albums = [AlbumEntity(id: 1, type: .user),
                      AlbumEntity(id: 2, type: .user)]
        let sections = albums.map {
            GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                GetLinkStringCellViewModel(link: "")
            ], itemHandle: $0.id)
        }
        let links = Dictionary(uniqueKeysWithValues: albums.map { ($0.id, "link-\($0.id)") })
        let sut = GetAlbumsLinkViewModel(albums: albums,
                                         shareAlbumUseCase: MockShareAlbumUseCase(shareAlbumsLinks: links),
                                         sectionViewModels: sections)
        
        let expectedRowReloads = sections.indices.map {
            IndexPath(row: 0, section: $0)
        }
        expectSuccessfulOnViewReady(sut: sut, albums: albums, expectedRowReload: expectedRowReloads)
        let expectedLink = links.values.joined(separator: " ")
        test(viewModel: sut, action: .copyLink,
             expectedCommands: [
                .addToPasteBoard(expectedLink),
                .showHud(.custom(Asset.Images.NodeActions.copy.image,
                                                Strings.Localizable.linksCopiedToClipboard))
             ])
    }
    
    func testDispatch_onDidSelectRowIndexPath_shouldAddSelectedLinkToPasteBoard() {
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
        let sut = GetAlbumsLinkViewModel(albums: albums,
                                         shareAlbumUseCase: MockShareAlbumUseCase(shareAlbumsLinks: links),
                                         sectionViewModels: sections)
        let linkIndexPath = IndexPath(row: 0, section: 0)
        expectSuccessfulOnViewReady(sut: sut, albums: albums, expectedRowReload: [linkIndexPath])
        
        test(viewModel: sut, action: .didSelectRow(indexPath: linkIndexPath),
             expectedCommands: [
                .addToPasteBoard(expectedLink),
                .showHud(.custom(Asset.Images.NodeActions.copy.image,
                                                Strings.Localizable.linkCopiedToClipboard))
             ])
    }
    
    private func expectSuccessfulOnViewReady(sut: GetAlbumsLinkViewModel, albums: [AlbumEntity], expectedRowReload: [IndexPath]) {
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(albums.count),
                           isMultilink: true,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(albums.count)),
            .hideMultiLinkDescription,
            .showHud(.status(Strings.Localizable.generatingLinks)),
            .reloadRows(expectedRowReload),
            .enableLinkActions,
            .dismissHud
        ])
    }
}
