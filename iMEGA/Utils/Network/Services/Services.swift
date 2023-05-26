import Foundation

class Services {
    class func getGiphyStickers(searchKey: String?, offset: Int?, category: GiphyCatogory?, completion: @escaping(Swift.Result<[GiphyResponseModel], ErrorModel>) -> Void) -> URLSessionDataTask {
        return ServiceManager.shared.sendRequest(request: GiphyGifsRequestModel(searchKey: searchKey, offset: offset, category: category)) { (result) in
            completion(result)
        }
    }
}
