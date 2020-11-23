import Foundation

enum HomeSearchState {
    case hints([HomeSearchHintViewModel])
    case results(HomeSearchResultState)
    case didSelectHint(String)
}

enum HomeSearchResultState {
    case loading
    case empty
    case error(message: String)
    case data([HomeSearchResultFileViewModel])
}
