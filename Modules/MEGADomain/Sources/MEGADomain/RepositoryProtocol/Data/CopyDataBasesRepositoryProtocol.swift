import Foundation

public protocol CopyDataBasesRepositoryProtocol: RepositoryProtocol {
    func applicationSupportDirectoryURL(completion: @escaping (Result<URL, GetFavouriteNodesErrorEntity>) -> Void)
    func groupSupportDirectoryURL(completion: @escaping (Result<URL, GetFavouriteNodesErrorEntity>) -> Void)
    func newestModificationDateOfItemAt(url: URL, completion: @escaping (Result<Date, GetFavouriteNodesErrorEntity>) -> Void)
    func contentsOfItemAt(url: URL, completion: @escaping (Result<[String], GetFavouriteNodesErrorEntity>) -> Void)
    func removeContentsOfItemAt(url: URL, completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func copyContentsOfItemAt(url: URL, to destination: URL, completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
}
