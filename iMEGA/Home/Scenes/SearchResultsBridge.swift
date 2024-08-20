/// Purpose of this class is to decouple Home screen and its Search bar view from the search results screen which is being replaced
/// by modern generic solution in the Search module
/// It implements delegate protocols that mediate communication SearchBar <-> HomeSearchResultsViewController
/// As we want to hide the new feature behind a flag, we need this intermediate layer to
/// not have to change too much in the existing implementation of search results which will go away eventually

import Search 
class SearchResultsBridge: MEGASearchBarViewEditingDelegate {
    
    func didHighlightSearchBar() {
        didHighlightTrampoline?()
    }
    
    func didInputText(_ inputText: String) {
        didInputTextTrampoline?(inputText)
    }
    
    func didClearText() {
        didClearTrampoline?()
    }
    
    func didFinishSearching() {
        didFinishSearchingTrampoline?()
    }
    
    /// for adjusting bottom scroll indicator inset for when minified audio player is presented or not
    func update(bottomInset: CGFloat) {
        updateBottomInsetTrampoline?(bottomInset)
    }
    
    func hideKeyboard() {
        hideKeyboardTrampoline?()
    }
    
    var hideKeyboardTrampoline: (() -> Void)?
    var didFinishSearchingTrampoline: (() -> Void)?
    var didHighlightTrampoline: (() -> Void)?
    var didInputTextTrampoline: ((String) -> Void)?
    var didClearTrampoline: (() -> Void)?
    var updateBottomInsetTrampoline: ((CGFloat) -> Void)?
    var didChangeLayoutTrampoline: ((PageLayout) -> Void)?
}
