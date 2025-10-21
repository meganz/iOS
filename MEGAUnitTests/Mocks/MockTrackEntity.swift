@testable import MEGA

extension TrackEntity {
    static let mockURL = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3")!
    
    static var mockItem: Self {
        .init(url: mockURL, node: MEGANode())
    }
    
    static var mockArray: [TrackEntity] {
        [TrackEntity(url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!),
         TrackEntity(url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3")!),
         TrackEntity(url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3")!),
         TrackEntity(url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3")!)]
    }
    
    init(url: URL) {
        self.init(url: url, node: nil)
    }
}
