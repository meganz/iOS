import Foundation

final class PhotoLibraryDayViewModel: ObservableObject {
    @Published var photosByDayList: [PhotosByDay]
    
    init(photosByDayList: [PhotosByDay]) {
        self.photosByDayList = photosByDayList
    }
}
