#import <PDFKit/PDFKit.h>
#import <UIKit/UIKit.h>
#import "MEGAPDFDocumentSearching.h"

NS_ASSUME_NONNULL_BEGIN

/// - Passed to the system Find session as its searchable object.
/// - Specifically, the interceptor receives the session's `UITextSearching`
///   calls and returns PDFKit results to the session's
///   `UITextSearchAggregator`.
/// - We forward `UITextSearching` calls from the `UITextSearchingFindSession`
///   to PDFKit's `UITextSearching` object, in order to highlight and scroll to
///   results.
/// - Swift's `UITextSearching` is a different type -> Forwarding in Swift will
///   have to manually reach for IMPL through Obj-C runtime features -> Using
///   Objective-C for `UITextSearching`-facing work is the more natural choice.
/// - A search result reaches the screen through these steps. Each step names
///   whether UIKit, PDFKit or our code does the work:
///   1. UIKit: the user types a query into the Find navigator of the
///      `UIFindInteraction` that `PDFViewSearchInteractionHandler` holds as
///      `findInteraction`.
///   2. UIKit: the `UITextSearchingFindSession` that
///      `PDFViewSearchInteractionHandler` returns from
///      `findInteraction(_:sessionFor:)`, built around this interceptor,
///      calls the interceptor's
///      `-performTextSearchWithQueryString:usingOptions:resultAggregator:`
///      and passes UIKit's `UITextSearchAggregator` as `aggregator`.
///   3. Ours: the interceptor passes the query to `documentSearcher`, which
///      finishes a query shorter than four characters with no results, and
///      searches the `PDFDocument` text layer for any other query.
///   4. Ours: `documentSearcher` reports each match as the range
///      `pdfKitSearcher`, PDFKit's searchable view, would report for it, and
///      the interceptor passes it to `aggregator`. UIKit: the aggregator
///      counts them for the Find navigator.
///   5. UIKit: to show a result, the session calls the interceptor's
///      `-decorateFoundTextRange:inDocument:usingStyle:` and
///      `-scrollRangeToVisible:inDocument:`. Ours: the interceptor forwards
///      both to `pdfKitSearcher`.
@interface MEGAPDFUITextSearchingFindSessionInterceptor : NSObject <UITextSearching>
/// Returns nil when PDFKit has not created a searchable descendant.
- (nullable instancetype)initWithPDFView:(PDFView *)pdfView
                        documentSearcher:(id<MEGAPDFDocumentSearching>)documentSearcher;
@end

NS_ASSUME_NONNULL_END
