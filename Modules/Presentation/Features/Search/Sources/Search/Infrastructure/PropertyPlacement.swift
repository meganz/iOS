/// Encodes a semantic positioning of properties for various layouts
/// inspect files for exact placement:
/// * VerticalThumbnailView.swift,
/// * HorizontalThumbnailView.swift
/// * SearchResultRowView.swift
public enum PropertyPlacement: Equatable, Sendable {
    
    public enum Secondary: Equatable, Sendable {
        case leading
        case trailing
        case trailingEdge
    }
    
    /// property not rendered
    case none
    /// after title
    case prominent
    /// various positions depending on the Secondary value and given layout mode
    case secondary(Secondary)
    /// middle line of text between title and subtitle, supported only in list mode
    case auxLine
    /// supported in list mode only now
    case previewOverlay
}
