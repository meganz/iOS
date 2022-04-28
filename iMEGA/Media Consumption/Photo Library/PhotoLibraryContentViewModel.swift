import Foundation
import Combine
import SwiftUI

@MainActor
@objc final class PhotoLibraryContentViewModel: NSObject, ObservableObject {
    @Published var library: PhotoLibrary
    @Published var selectedMode: PhotoLibraryViewMode = .all
    
    var cardScrollPosition: PhotoScrollPosition?
    var photoScrollPosition: PhotoScrollPosition?
    lazy var selection = PhotoSelection()
    
    // MARK: - Init
    init(library: PhotoLibrary) {
        self.library = library
        super.init()
    }
}
