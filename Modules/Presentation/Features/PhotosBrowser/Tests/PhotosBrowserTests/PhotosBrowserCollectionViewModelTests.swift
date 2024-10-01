import Combine
import Foundation

@testable @preconcurrency import PhotosBrowser

import MEGADomain
@preconcurrency import MEGAPresentation
import MEGATest
import Testing

struct PhotosBrowserCollectionViewModelTests {
    
    @MainActor
    @Test func testInitialMediaAssets() {
        let initialAssets = [
            PhotosBrowserLibraryEntity(handle: 0, base64Handle: "0", name: "test_0", modificationTime: Date.now),
            PhotosBrowserLibraryEntity(handle: 1, base64Handle: "1", name: "test_1", modificationTime: Date.now)
        ]
        let library = MediaLibrary(assets: initialAssets, currentIndex: 0)
        let viewModel = PhotosBrowserCollectionViewModel(library: library)
        
        #expect(viewModel.mediaAssets.count == initialAssets.count)
    }
    
    @Test func mediaAssetsUpdatesWhenLibraryAssetsChange() async {
        let initialAssets = [PhotosBrowserLibraryEntity(handle: 0, base64Handle: "0", name: "test_0", modificationTime: Date.now)]
        let updatedAssets = [
            PhotosBrowserLibraryEntity(handle: 1, base64Handle: "1", name: "test_1", modificationTime: Date.now),
            PhotosBrowserLibraryEntity(handle: 1, base64Handle: "2", name: "test_2", modificationTime: Date.now)
        ]
        let library = MediaLibrary(assets: initialAssets, currentIndex: 0)
        let viewModel = PhotosBrowserCollectionViewModel(library: library)
        
        var receivedMediaAssets: [PhotosBrowserLibraryEntity]?
        var cancellables = Set<AnyCancellable>()
        
        await confirmation("mediaAssets should update when library.assets changes") { @MainActor confirm in
            viewModel.$mediaAssets
                .dropFirst()
                .sink { newAssets in
                    receivedMediaAssets = newAssets
                    confirm()
                }
                .store(in: &cancellables)
            
            library.assets = updatedAssets
        }
        
        #expect(receivedMediaAssets?.count == updatedAssets.count)
        #expect(viewModel.mediaAssets.count == updatedAssets.count)
    }
}
