/// A request to show or hide the Find navigator, which the view clears once
/// it has acted on it.
enum PDFSearchRequest: Equatable {
    case present
    case dismiss
}
