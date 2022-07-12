import XCTest
@testable import MEGA

final class PhotoViewModelTests: XCTestCase {
    private func photoViewModel() -> PhotoViewModel {
        let photoUpdatePublisher = PhotoUpdatePublisher(photosViewController: PhotosViewController())
        let photoLibraryRepository = PhotoLibraryRepository.newRepo
        let fileSearchRepository = SDKFilesSearchRepository.newRepo
        let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: photoLibraryRepository, searchRepository: fileSearchRepository)
        let viewModel = PhotoViewModel(
            photoUpdatePublisher: photoUpdatePublisher,
            photoLibraryUseCase: photoLibraryUseCase
        )
        
        return viewModel
    }
    
    private func mediaNodesSorted() -> [MEGANode] {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        
        return [
            MockNode(handle: 1, name: "TestImage.png", nodeType: .file, parentHandle:0, modificationTime: today),
            MockNode(handle: 2, name: "TestVideo1.mp4", nodeType: .file, parentHandle:0),
            MockNode(handle: 2, name: "TestImage2.jpg", nodeType: .file, parentHandle:1, modificationTime: yesterday)
        ]
    }
    
    private func mediaNodesReverseSorted() -> [MEGANode] {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        
        return [
            MockNode(handle: 2, name: "TestImage2.jpg", nodeType: .file, parentHandle:1, modificationTime: yesterday),
            MockNode(handle: 1, name: "TestImage.png", nodeType: .file, parentHandle:0, modificationTime: today),
            MockNode(handle: 2, name: "TestVideo1.mp4", nodeType: .file, parentHandle:0)
        ]
    }
    
    func testLoadSortOrderType() throws {
        let sut = photoViewModel()
        
        Helper.save(.defaultAsc, for: PhotoViewModel.SortingKeys.cameraUploadExplorerFeed.rawValue)
        let sortTypeUnknown = sut.sortOrderType(forKey: .cameraUploadExplorerFeed)
        XCTAssert(sortTypeUnknown == .newest)
        
        Helper.save(.modificationAsc, for: PhotoViewModel.SortingKeys.cameraUploadExplorerFeed.rawValue)
        let sortTypeOldest = sut.sortOrderType(forKey: .cameraUploadExplorerFeed)
        XCTAssert(sortTypeOldest == .oldest)
        
        Helper.save(.modificationDesc, for: PhotoViewModel.SortingKeys.cameraUploadExplorerFeed.rawValue)
        let sortTypeNewest = sut.sortOrderType(forKey: .cameraUploadExplorerFeed)
        XCTAssert(sortTypeNewest == .newest)
    }
    
    func testReorderPhotos() throws {
        let sut = photoViewModel()
        sut.mediaNodesArray = mediaNodesSorted()
       
        sut.cameraUploadExplorerSortOrderType = .nameAscending
        XCTAssert(sut.mediaNodesArray == mediaNodesSorted())

        sut.cameraUploadExplorerSortOrderType = .newest
        XCTAssert(sut.mediaNodesArray == mediaNodesSorted())
        
        sut.cameraUploadExplorerSortOrderType = .oldest
        XCTAssert(sut.mediaNodesArray == mediaNodesReverseSorted())
    }
}
