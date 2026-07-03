import Foundation

public protocol CopyDataBasesRepositoryProtocol: RepositoryProtocol {
    func applicationSupportDirectoryURL(completion: @escaping (Result<URL, CopyDataBasesErrorEntity>) -> Void)
    func groupSupportDirectoryURL(completion: @escaping (Result<URL, CopyDataBasesErrorEntity>) -> Void)
    func newestModificationDateOfItemAt(url: URL, completion: @escaping (Result<Date, CopyDataBasesErrorEntity>) -> Void)
    func contentsOfItemAt(url: URL, completion: @escaping (Result<[String], CopyDataBasesErrorEntity>) -> Void)
    func removeContentsOfItemAt(url: URL, completion: @escaping (Result<Void, CopyDataBasesErrorEntity>) -> Void)
    func copyContentsOfItemAt(url: URL, to destination: URL, completion: @escaping (Result<Void, CopyDataBasesErrorEntity>) -> Void)
}
