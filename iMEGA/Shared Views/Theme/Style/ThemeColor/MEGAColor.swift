import Foundation

enum MEGAColor {

    enum CustomViewBackground: Hashable {
        case warning
    }

    enum ThemeButton: Hashable {
        case primary
        case secondary
    }

    enum Text: Hashable {
        case primary
        case secondary
        case tertiary
        case quaternary
        
        case warning
    }

    enum Background: Hashable {
        case primary
        case secondary

        case warning
        case enabled
        case disabled
        case highlighted

        // MARK: - TextField

        case searchTextField

        // MARK: - Search Bar

        case homeTopSide

    }

    enum Tint: Hashable {
        case primary
        case secondary
    }

    enum Shadow: Hashable {
        case primary
    }

    enum Border: Hashable {
        case primary
        case warning
    }

    enum Independent: Hashable {
        case bright
        case dark
        case clear
        case warning
    }
    
    enum Gradient {
        case exploreImagesStart
        case exploreImagesEnd
        
        case exploreDocumentsStart
        case exploreDocumentsEnd
        
        case exploreAudioStart
        case exploreAudioEnd
        
        case exploreVideoStart
        case exploreVideoEnd
    }
}
