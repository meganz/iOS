import Combine
import Foundation
import MEGADomain
import SwiftUI

public final class VideoSelection: ObservableObject {
    
    @Published public var editMode: EditMode = .inactive {
        willSet {
            if !newValue.isEditing {
                allSelected = false
            }
        }
    }
    
    @Published public var videos = [HandleEntity: NodeEntity]()
    
    @Published var allSelected = false {
        willSet {
            if !newValue {
                videos.removeAll()
            }
        }
    }
    
    @Published var isSelected = false
    
    @Published var isHidden = false
    
    @Published var isSelectionDisabled = false
    
    public init() { }
    
    func setSelectedVideos(_ videos: [NodeEntity]) {
        self.videos = Dictionary(uniqueKeysWithValues: videos.map { ($0.handle, $0) })
    }
    
    func isVideoSelected(_ video: NodeEntity) -> Bool {
        videos[video.handle] != nil
    }
    
    func toggleSelection(for video: NodeEntity) {
        if videos[video.handle] == nil {
            videos[video.handle] = video
        } else {
            videos.removeValue(forKey: video.handle)
        }
    }
    
    func isVideoSelectedPublisher(for node: NodeEntity) -> AnyPublisher<Bool, Never> {
        $allSelected
            .map { [weak self] allSelected -> AnyPublisher<Bool, Never> in
                guard let self else {
                    return Empty().eraseToAnyPublisher()
                }
                
                guard !allSelected else {
                    return Just(true).eraseToAnyPublisher()
                }
                
                return $videos
                    .map { $0[node.handle] != nil }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func onTappedCheckMark(for nodeEntity: NodeEntity) {
        guard
            editMode.isEditing,
            !isSelectionDisabled
        else {
            return
        }
        
        toggleSelection(for: nodeEntity)
    }
}
