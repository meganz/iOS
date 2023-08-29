import UIKit

/// Used to represent different properties of results as images
/// ie:
/// label, isLiked, isDisputed, isOffline etc

public struct Property {
    // using data instead of String or (UI)Image makes the icon platform and UI framework agnostic
    // (we can create UIKit.UIImage or SwiftUI.Image from this Data) but also support
    // memory generated images for example for dynamically drawn images with dynamic properties
    public let icon: Data
}

/// represents a type of result, currently only node, in the future: a chat, a contact etc
public enum ResultType {
    case node
}
