import Foundation

public enum ExplorerTypeEntity {
    case audio
    case video
    // this uses .allDocs node type filter to show all of {DOCUMENT, PDF, PRESENTATION, SPREADSHEET} nodes
    // mapping done in ExplorerTypeEntity+Mapper.swift, not the same as documents
    // which excludes pdf/presentations/spreadsheets
    case allDocs
    case favourites
}
