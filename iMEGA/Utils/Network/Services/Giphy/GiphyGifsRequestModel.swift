import Foundation

class GiphyGifsRequestModel: RequestModel {
    
    // MARK: - Properties
    private var searchKey: String = ""
    private var offset: Int = 0
    private var category: GiphyCatogory = .gifs
    
    init(searchKey: String?, offset: Int?, category: GiphyCatogory?) {
        self.searchKey = searchKey ?? ""
        self.offset = offset ?? 0
        self.category = category ?? .gifs
    }
    
    override var isLoggingEnabled: (Bool, Bool) {
        return (true, false)
    }
    
    override var path: String {
        let path = ServiceConstant.path(category)
        if !searchKey.isEmpty {
            return path + "/search"
        }
        return path + "/trending"
    }
    
    override var parameters: [String : Any?] {
        return [
            "q": searchKey,
            "offset": String(offset)
        ]
    }
}
