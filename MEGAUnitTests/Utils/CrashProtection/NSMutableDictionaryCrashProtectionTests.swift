import Foundation
import ObjectiveC
import Testing

/// The protection is installed by `+load` in the MEGA host app, so it is already in place for every test here.
///
/// A write it drops asserts where assertions are on, as they are in Debug. Those tests let assertion failures
/// on their thread pass instead of raising them: an uncaught exception — like the one the write itself would
/// throw without the protection — aborts the test process. Whether the assertion fires is not checked, so the
/// tests hold in any build configuration.
@Suite("NSMutableDictionary crash protection")
struct NSMutableDictionaryCrashProtectionTests {
    /// Swift cannot pass nil to either setter — the key and `setObject(_:forKey:)`'s object are non-optional —
    /// so the messages are sent by selector instead.
    private static let setObjectForKeyedSubscript = NSSelectorFromString("setObject:forKeyedSubscript:")
    private static let setObjectForKey = NSSelectorFromString("setObject:forKey:")

    // MARK: - setObject:forKeyedSubscript:

    @Test func nilKey_dropsTheWrite() {
        let dictionary = NSMutableDictionary(dictionary: ["kept": 1])

        IgnoringAssertionHandler.ignoringFailures {
            dictionary.perform(Self.setObjectForKeyedSubscript, with: 2, with: nil)
        }

        #expect(dictionary as? [String: Int] == ["kept": 1])
    }

    /// The shape of the Firebase crash: `GULMutableDictionary` writes asynchronously on its own serial queue.
    @Test func nilKey_onSerialQueue_dropsTheWrite() async {
        let queue = DispatchQueue(label: "NSMutableDictionaryCrashProtectionTests")

        // The dictionary stays on the queue; only its Sendable contents come back.
        let contents = await withCheckedContinuation { (continuation: CheckedContinuation<[String: Int]?, Never>) in
            queue.async {
                let dictionary = NSMutableDictionary(dictionary: ["kept": 1])
                IgnoringAssertionHandler.ignoringFailures {
                    dictionary.perform(Self.setObjectForKeyedSubscript, with: 2, with: nil)
                }
                continuation.resume(returning: dictionary as? [String: Int])
            }
        }

        #expect(contents == ["kept": 1])
    }

    @Test func nonNilKey_storesTheObject() {
        let dictionary = NSMutableDictionary()

        dictionary["key"] = 1

        #expect(dictionary as? [String: Int] == ["key": 1])
    }

    @Test func nilObject_stillRemovesTheKey() {
        let dictionary = NSMutableDictionary(dictionary: ["removed": 1, "kept": 2])

        dictionary["removed"] = nil

        #expect(dictionary as? [String: Int] == ["kept": 2])
    }

    // MARK: - setObject:forKey:

    @Test func setObjectForKey_nilKey_dropsTheWrite() {
        let dictionary = NSMutableDictionary(dictionary: ["kept": 1])

        IgnoringAssertionHandler.ignoringFailures {
            dictionary.perform(Self.setObjectForKey, with: 2, with: nil)
        }

        #expect(dictionary as? [String: Int] == ["kept": 1])
    }

    /// Unlike subscripting, a nil object is not a removal here: the write is dropped and the old value kept.
    @Test func setObjectForKey_nilObject_dropsTheWriteAndKeepsTheOldValue() {
        let dictionary = NSMutableDictionary(dictionary: ["key": 1])

        IgnoringAssertionHandler.ignoringFailures {
            dictionary.perform(Self.setObjectForKey, with: nil, with: "key")
        }

        #expect(dictionary as? [String: Int] == ["key": 1])
    }

    @Test func setObjectForKey_nonNilKeyAndObject_storesTheObject() {
        let dictionary = NSMutableDictionary()

        dictionary.setObject(1, forKey: "key" as NSString)

        #expect(dictionary as? [String: Int] == ["key": 1])
    }
}

/// Lets `NSAssert` failures on the current thread pass instead of raising.
///
/// `NSAssert` hands failures to the thread's `NSAssertionHandler`, which each thread can replace through its
/// thread dictionary. The method it calls is variadic, so Swift cannot override it; it is added through the
/// runtime instead, as one that does nothing.
private final class IgnoringAssertionHandler: NSAssertionHandler {
    private static let installIgnoring: Void = {
        let selector = NSSelectorFromString("handleFailureInMethod:object:file:lineNumber:description:")
        guard let method = class_getInstanceMethod(NSAssertionHandler.self, selector) else {
            preconditionFailure("NSAssertionHandler no longer handles method assertion failures")
        }

        let ignore: @convention(block) (IgnoringAssertionHandler) -> Void = { _ in }
        class_addMethod(IgnoringAssertionHandler.self, selector, imp_implementationWithBlock(ignore), method_getTypeEncoding(method))
    }()

    /// Runs `body` with assertion failures on this thread ignored rather than raised.
    static func ignoringFailures(_ body: () -> Void) {
        _ = installIgnoring

        let threadDictionary = Thread.current.threadDictionary
        let previousHandler = threadDictionary[NSAssertionHandlerKey]
        threadDictionary[NSAssertionHandlerKey] = IgnoringAssertionHandler()
        defer { threadDictionary[NSAssertionHandlerKey] = previousHandler }

        body()
    }
}
