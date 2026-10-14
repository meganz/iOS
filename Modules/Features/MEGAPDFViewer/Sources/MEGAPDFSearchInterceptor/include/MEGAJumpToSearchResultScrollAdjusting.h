#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// `MEGAPDFUITextSearchingFindSessionInterceptor` calls this after PDFKit
/// selects a range; a NO result tells the interceptor to use PDFKit's normal
/// result-scrolling path.
NS_SWIFT_UI_ACTOR
@protocol MEGAJumpToSearchResultScrollAdjusting <NSObject>
- (BOOL)scrollRangeIntoUsableArea:(UITextRange *)range
                      inTextInput:(id<UITextInput>)textInput
    NS_SWIFT_NAME(scrollRangeIntoUsableArea(_:in:));
@end

NS_ASSUME_NONNULL_END
