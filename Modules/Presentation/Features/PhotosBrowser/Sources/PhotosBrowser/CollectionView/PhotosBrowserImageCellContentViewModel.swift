import Foundation
import MEGADomain

public final class PhotosBrowserImageCellContentViewModel: ObservableObject {
    let entity: PhotosBrowserLibraryEntity
    
    public init(entity: PhotosBrowserLibraryEntity) {
        self.entity = entity
    }
}
