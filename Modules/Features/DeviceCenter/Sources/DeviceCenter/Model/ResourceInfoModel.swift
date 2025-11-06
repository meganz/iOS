import Foundation
import MEGAFoundation
import MEGAL10n
import SwiftUI

public typealias DateFormatterClosure = @Sendable (Date) -> String

/// ResourceInfoModel: Data model to hold and provide all necessary information to display details about a resource.
public struct ResourceInfoModel: Sendable {
    /// icon: Representative image of the current resource that is established according to the type of resource
    public let icon: Image
    /// name: Name associated with the current resource
    public let name: String
    /// counter: A `ResourceCounter` instance that encapsulates the count of files and folders within the resource.
    ///         This count is performed recursively, meaning it includes all files and folders contained within any
    ///         subfolders of the resource. This provides a detailed breakdown of the resource's contents, useful for
    ///         displaying to users or for internal logic that depends on the composition of the resource.
    public let counter: ResourceCounter
    /// totalSize: Total size occupied by all items contained in the current resource, measured in bytes.
    public let totalSize: UInt64
    /// added: Date of addition of the current resource. This value is optional as it is not required for devices.
    public let added: Date?
    /// formatDateClosure: An optional closure for custom formatting of the `added` date. This allows for flexible
    ///                presentation of dates according to the locale settings. The closure takes a `Date` as
    ///                its input and returns a formatted string representation of that date.
    private let formatDateClosure: DateFormatterClosure
    
    public init(
        icon: Image,
        name: String,
        counter: ResourceCounter,
        totalSize: UInt64 = UInt64(0),
        added: Date? = nil,
        formatDateClosure: @escaping DateFormatterClosure = { DateFormatter.dateMediumTimeShort().localisedString(from: $0) }
    ) {
        self.icon = icon
        self.name = name
        self.counter = counter
        self.totalSize = totalSize
        self.added = added
        self.formatDateClosure = formatDateClosure
    }
    
    public var formattedAddedDate: String {
        guard let added = added else { return "" }
        return formatDateClosure(added)
    }
}

/// ResourceCounter: Utility struct to encapsulate the count of files and folders within a resource, providing a detailed 
///               breakdown of its contents
public struct ResourceCounter: Sendable {
    /// files: Number of files contained in the current resource, this number is calculated recursively, across the different 
    ///     folder levels contained in the current resource
    var files: Int
    /// folders: Number of folders contained in the current resource, this number is calculated recursively, across the 
    ///       different folder levels contained in the current resource
    var folders: Int
    
    public static var emptyCounter: Self {
        .init(
            files: 0,
            folders: 0
        )
    }
    
    public init(
        files: Int,
        folders: Int
    ) {
        self.files = files
        self.folders = folders
    }
    
    public var formattedResourceContents: String {
        switch (files, folders) {
        case (0, 0):
            return Strings.Localizable.emptyFolder
        case (0, _):
            return Strings.Localizable.General.Format.Count.folder(folders)
        case (_, 0):
            return Strings.Localizable.General.Format.Count.file(files)
        default:
            return "\(Strings.Localizable.General.Format.Count.FolderAndFile.folder(folders)) \(Strings.Localizable.General.Format.Count.FolderAndFile.file(files))"
        }
    }
}
