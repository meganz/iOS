#import "MEGARecordingSearchAggregator.h"

@interface MEGARecordingSearchAggregator () <UITextSearchAggregator>
@property (nonatomic) NSInteger foundRangeCount;
@property (nonatomic) BOOL didFinishSearching;
@property (nonatomic) NSMutableArray<UITextRange *> *recordedRanges;
@end

@implementation MEGARecordingSearchAggregator

- (instancetype)init {
    self = [super init];
    if (self) {
        _recordedRanges = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)performingQuery:(NSString *)query
                  onInterceptor:(MEGAPDFUITextSearchingFindSessionInterceptor *)interceptor {
    MEGARecordingSearchAggregator *aggregator = [self new];
    [interceptor performTextSearchWithQueryString:query
                                     usingOptions:[UITextSearchOptions new]
                                 resultAggregator:aggregator];
    return aggregator;
}

+ (instancetype)performingQuery:(NSString *)query onPDFKitSearcherInView:(UIView *)pdfView {
    MEGARecordingSearchAggregator *aggregator = [self new];
    [[self searcherInView:pdfView] performTextSearchWithQueryString:query
                                                       usingOptions:[UITextSearchOptions new]
                                                   resultAggregator:aggregator];
    return aggregator;
}

+ (nullable id<UITextSearching>)searcherInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview conformsToProtocol:@protocol(UITextSearching)]) { return (id<UITextSearching>)subview; }
        id<UITextSearching> found = [self searcherInView:subview];
        if (found != nil) { return found; }
    }
    return nil;
}

- (BOOL)hasSameRangesAs:(MEGARecordingSearchAggregator *)other inView:(UIView *)pdfView {
    id<UITextSearching> searcher = [self.class searcherInView:pdfView];
    if (searcher == nil || self.recordedRanges.count != other.recordedRanges.count) { return NO; }
    for (UITextRange *range in self.recordedRanges) {
        NSUInteger match = [other.recordedRanges indexOfObjectPassingTest:^BOOL(UITextRange *candidate, NSUInteger index, BOOL *stop) {
            return [searcher compareFoundRange:range toRange:candidate inDocument:nil] == NSOrderedSame;
        }];
        if (match == NSNotFound) { return NO; }
    }
    return YES;
}

- (NSComparisonResult)compareRangeAtIndex:(NSUInteger)index
                           toRangeAtIndex:(NSUInteger)otherIndex
                            onInterceptor:(MEGAPDFUITextSearchingFindSessionInterceptor *)interceptor {
    return [interceptor compareFoundRange:self.recordedRanges[index]
                                  toRange:self.recordedRanges[otherIndex]
                               inDocument:nil];
}

- (NSArray<UITextRange *> *)foundRanges {
    return [self.recordedRanges copy];
}

- (NSOrderedSet<UITextRange *> *)allFoundRanges {
    return [NSOrderedSet orderedSetWithArray:self.recordedRanges];
}

- (void)foundRange:(UITextRange *)range
   forSearchString:(NSString *)string
        inDocument:(id)document {
    self.foundRangeCount += 1;
    [self.recordedRanges addObject:range];
}

- (void)invalidateFoundRange:(UITextRange *)range inDocument:(id)document {
}

- (void)invalidate {
}

- (void)finishedSearching {
    self.didFinishSearching = YES;
}

@end
