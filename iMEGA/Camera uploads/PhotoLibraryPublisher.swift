import Foundation
import Combine

@available(iOS 14.0, *)
@objc final class PhotoLibraryPublisher: NSObject {
    private let subject = PassthroughSubject<PhotoLibrary, Never>()
    
    func updatePhotoLibrary(_ library: PhotoLibrary) {
        subject.send(library)
    }
    
    func subscribe(_ viewModel: PhotoLibraryContentViewModel) {
        subject
            .throttle(for: .seconds(3), scheduler: DispatchQueue.main, latest: true)
            .assign(to: &viewModel.$library)
    }
}
