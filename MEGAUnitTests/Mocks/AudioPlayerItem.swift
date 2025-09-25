@testable import MEGA

extension AudioPlayerItem {

    static var mockItem: Self {
        .init(name: "Track 5", url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3")!, node: MEGANode())
    }
    
    static var mockArray: [AudioPlayerItem] {
        [AudioPlayerItem(name: "Track 1", url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!, node: nil),
         AudioPlayerItem(name: "Track 2", url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3")!, node: nil),
         AudioPlayerItem(name: "Track 3", url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3")!, node: nil),
         AudioPlayerItem(name: "Track 4", url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3")!, node: nil)]
    }
    
    static func mockArray(count: Int) -> [AudioPlayerItem] {
        (1...count).map { i in
            AudioPlayerItem(
                name: "Track \(i)",
                url: URL(string: "https://www.example.com/track\(i).mp3")!,
                node: nil
            )
        }
    }
    
    convenience init(url: URL, node: MEGANode? = nil) {
        self.init(name: "", url: url, node: node)
    }
}
