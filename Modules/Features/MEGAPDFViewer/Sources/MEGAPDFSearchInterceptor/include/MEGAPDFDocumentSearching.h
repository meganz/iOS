#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// `MEGAPDFUITextSearchingFindSessionInterceptor` calls this to search the
/// document, and passes each match and the end of the search on to the
/// session's `UITextSearchAggregator`.
NS_SWIFT_NAME(PDFDocumentSearching)
NS_SWIFT_UI_ACTOR
@protocol MEGAPDFDocumentSearching <NSObject>
/// Cancels any earlier search, then reports each match as a range in
/// `textInput` and calls `onFinish` once.
- (void)searchForString:(NSString *)string
           usingOptions:(UITextSearchOptions *)options
            inTextInput:(id<UITextInput>)textInput
                onMatch:(void (^)(UITextRange *range))onMatch
               onFinish:(void (^)(void))onFinish
    NS_SWIFT_NAME(search(for:options:in:onMatch:onFinish:));
@end

NS_ASSUME_NONNULL_END
