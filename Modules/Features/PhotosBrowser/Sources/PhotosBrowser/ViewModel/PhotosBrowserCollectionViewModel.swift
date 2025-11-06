import Combine
import Foundation
import MEGADomain

public class PhotosBrowserCollectionViewModel: ObservableObject {
    let library: MediaLibrary
    
    var currentIndex: Int {
        library.currentIndex
    }
    
    // MARK: Lifecycle
    
    init(library: MediaLibrary) {
        self.library = library
    }
}
