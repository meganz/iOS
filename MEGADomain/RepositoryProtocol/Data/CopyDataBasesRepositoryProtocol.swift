
import Foundation

protocol CopyDataBasesRepositoryProtocol {
    func applicationSupportDirectoryURL(completion: @escaping (Result<URL, QuickAccessWidgetErrorEntity>) -> Void)
    func groupSupportDirectoryURL(completion: @escaping (Result<URL, QuickAccessWidgetErrorEntity>) -> Void)
    func newestModificationDateOfItemAt(url: URL, completion: @escaping (Result<Date, QuickAccessWidgetErrorEntity>) -> Void)
    func contentsOfItemAt(url: URL, completion: @escaping (Result<[String], QuickAccessWidgetErrorEntity>) -> Void)
    func removeContentsOfItemAt(url: URL, completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func copyContentsOfItemAt(url: URL, to destination: URL, completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
}
