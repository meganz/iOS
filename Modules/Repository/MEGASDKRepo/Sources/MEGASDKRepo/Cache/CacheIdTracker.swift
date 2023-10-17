import Foundation
import MEGASwift

/// Tacks and keeps object identifiers in sync
///
/// NSCached does not have `values` like `Dictionary` we need to keep a `Set` in sync when items are added and removed
/// including eviction
final class CacheIdTracker<Element: Identifiable>: NSObject, NSCacheDelegate {
    @Atomic var identifiers = Set<Element.ID>()
    
    func cache(_ cache: NSCache<AnyObject, AnyObject>,
               willEvictObject object: Any) {
        guard let entry = object as? Element else {
            return
        }
        
        $identifiers.mutate { $0.remove(entry.id) }
    }
}
