import MEGADomain

struct VideoListViewModelContentProvider: VideoListViewModelContentProviderProtocol {
    
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    
    init(photoLibraryUseCase: any PhotoLibraryUseCaseProtocol) {
        self.photoLibraryUseCase = photoLibraryUseCase
    }
    
    func search(by searchText: String = "", sortOrderType: SortOrderEntity, durationFilterOptionType: DurationChipFilterOptionType, locationFilterOptionType: LocationChipFilterOptionType) async throws -> [NodeEntity] {
        let filteredLocationVideos = try await videos(by: searchText, sortOrderType: sortOrderType, locationFilterOptionType: locationFilterOptionType)
        try Task.checkCancellation()
        return videosFiltered(by: durationFilterOptionType, videos: filteredLocationVideos)
    }
}

extension VideoListViewModelContentProvider {
    
    private func videosFiltered(by durationType: DurationChipFilterOptionType?, videos: [NodeEntity]) -> [NodeEntity] {
        guard let durationFilter = videoFilter(for: durationType) else {
            return videos
        }
        return videos.filter(durationFilter)
    }
    
    private func videos(by searchText: String, sortOrderType: SortOrderEntity, locationFilterOptionType: LocationChipFilterOptionType) async throws -> [NodeEntity] {
        let filteredLocationVideos = try await photoLibraryUseCase.media(
            for: filterOptionEntity(for: locationFilterOptionType),
            excludeSensitive: nil,
            searchText: searchText,
            sortOrder: sortOrderType
        )
        
        try Task.checkCancellation()
        
        return switch locationFilterOptionType {
        case .sharedItems:
            filteredLocationVideos.filter(\.isExported)
        default:
            filteredLocationVideos
        }
    }
    
    private func videoFilter(for durationType: DurationChipFilterOptionType?) -> ((NodeEntity) -> Bool)? {
        switch durationType {
        case .lessThan10Seconds:
            return { $0.duration < 10 }
        case .between10And60Seconds:
            return { $0.duration >= 10 && $0.duration < 60 }
        case .between1And4Minutes:
            return { $0.duration >= 60 && $0.duration < 240 }
        case .between4And20Minutes:
            return { $0.duration >= 240 && $0.duration < 1200 }
        case .moreThan20Minutes:
            return { $0.duration >= 1200 }
        default:
            return nil
        }
    }
    
    private func filterOptionEntity(for locationType: LocationChipFilterOptionType?) -> PhotosFilterOptionsEntity {
        switch locationType {
        case .allLocation, .sharedItems, .none:
            [ .videos, .allLocations ]
        case .cloudDrive:
            [ .videos, .cloudDrive ]
        case .cameraUploads:
            [ .videos, .cameraUploads ]
        }
    }
}
