@testable import ContentLibraries
import MEGAL10n
import XCTest

final class VideoPlaylistNameCreationMapperTests: XCTestCase {
    
    func testVideoPlaylistName_noNameIsEntered_returnsDefaultVideoPlaylistName() {
        let defaultVideoPlaylistName = Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder
        let currentPlaylistNames = [String]()
        
        let samples: [String?] = [nil, ""]
        samples.enumerated().forEach { (index, newName) in
            let result = VideoPlaylistNameCreationMapper.videoPlaylistName(from: newName, from: currentPlaylistNames)
            
            XCTAssertEqual(result, defaultVideoPlaylistName, "Failed at index: \(index) for value: \(String(describing: newName))")
        }
    }
    
    func testVideoPlaylistName_noNameIsEnteredAndHasDefaultNameInTheListAlready_returnsDefaultVideoPlaylistNameWithIndex() {
        let defaultVideoPlaylistName = Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder
        let firstVideoPlaylistName = defaultVideoPlaylistName
        let currentPlaylistNames = [firstVideoPlaylistName]
        
        let samples: [String?] = [nil, ""]
        samples.enumerated().forEach { (index, newName) in
            let result = VideoPlaylistNameCreationMapper.videoPlaylistName(from: newName, from: currentPlaylistNames)
            
            XCTAssertEqual(result, defaultVideoPlaylistName + " (\(1))", "Failed at index: \(index) for value: \(String(describing: newName))")
        }
    }
    
    func testVideoPlaylistName_noNameIsEnteredAndHasDefaultNameInTheListAlreadyMultiple_returnsDefaultVideoPlaylistNameWithIndex() {
        let defaultVideoPlaylistName = Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder
        let firstVideoPlaylistName = defaultVideoPlaylistName
        let secondVideoPlaylistName = defaultVideoPlaylistName + " (\(1))"
        let currentPlaylistNames = [firstVideoPlaylistName, secondVideoPlaylistName]
        
        let samples: [String?] = [nil, ""]
        samples.enumerated().forEach { (index, newName) in
            let result = VideoPlaylistNameCreationMapper.videoPlaylistName(from: newName, from: currentPlaylistNames)
            
            XCTAssertEqual(result, defaultVideoPlaylistName + " (\(2))", "Failed at index: \(index) for value: \(String(describing: newName))")
        }
    }
    
    func testVideoPlaylistName_uniqueNameIsEntered_returnsEnteredName() {
        let defaultVideoPlaylistName = Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder
        let firstVideoPlaylistName = defaultVideoPlaylistName
        let secondVideoPlaylistName = defaultVideoPlaylistName + " (\(1))"
        let currentPlaylistNames = [firstVideoPlaylistName, secondVideoPlaylistName]
        let uniquePlaylistName = "a unique playlist name"
        
        let result = VideoPlaylistNameCreationMapper.videoPlaylistName(from: uniquePlaylistName, from: currentPlaylistNames)
        
        XCTAssertEqual(result, uniquePlaylistName)
    }
}
