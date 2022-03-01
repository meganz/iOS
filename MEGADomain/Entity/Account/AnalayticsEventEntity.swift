import Foundation

enum AnalayticsEventEntity {
    typealias Name = String
    
    static let imagesExplorerCardTappedString: Name = "image_explorer_card_tapped"
    static let docsExplorerCardTappedString: Name = "docs_explorer_card_tapped"
    static let audioExplorerCardTappedString: Name = "audio_explorer_card_tapped"
    static let videoExplorerCardTappedString: Name = "video_explorer_card_tapped"
    
    private static let cameraUploadsSettingString: Name = "camera_uploads_setting"
    private static let isOnString: Name = "is_on"
    
    static func cameraUploadsSettings(enabled: Bool) -> (name: Name, parameters: [Name: Any]?) {
        (cameraUploadsSettingString, [isOnString: enabled])
    }
}
