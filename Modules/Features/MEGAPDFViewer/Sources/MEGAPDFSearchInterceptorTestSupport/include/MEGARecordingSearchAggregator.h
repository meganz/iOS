#import <Foundation/Foundation.h>
#import "MEGAPDFUITextSearchingFindSessionInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGARecordingSearchAggregator : NSObject

@property (nonatomic, readonly) NSInteger foundRangeCount;
@property (nonatomic, readonly) BOOL didFinishSearching;
@property (nonatomic, readonly) NSArray<UITextRange *> *foundRanges;

+ (instancetype)performingQuery:(NSString *)query
                  onInterceptor:(MEGAPDFUITextSearchingFindSessionInterceptor *)interceptor;

/// Searches PDFKit's own searchable descendant of `pdfView` directly.
+ (instancetype)performingQuery:(NSString *)query onPDFKitSearcherInView:(UIView *)pdfView;

/// Orders two recorded ranges through `interceptor`'s
/// `-compareFoundRange:toRange:inDocument:`.
- (NSComparisonResult)compareRangeAtIndex:(NSUInteger)index
                           toRangeAtIndex:(NSUInteger)otherIndex
                            onInterceptor:(MEGAPDFUITextSearchingFindSessionInterceptor *)interceptor;

/// Returns YES when both aggregators recorded the same ranges in any order, as
/// judged by PDFKit's searchable descendant of `pdfView`.
- (BOOL)hasSameRangesAs:(MEGARecordingSearchAggregator *)other inView:(UIView *)pdfView;

@end

NS_ASSUME_NONNULL_END
