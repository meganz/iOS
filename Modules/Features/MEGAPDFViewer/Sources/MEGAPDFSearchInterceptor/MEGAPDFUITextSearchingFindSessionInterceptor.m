#import "MEGAPDFUITextSearchingFindSessionInterceptor.h"

@interface MEGAPDFUITextSearchingFindSessionInterceptor ()
@property (nonatomic, weak) id<UITextSearching, UITextInput> pdfKitSearcher;
@property (nonatomic, strong) id<MEGAPDFDocumentSearching> documentSearcher;
+ (nullable id<UITextSearching, UITextInput>)searchableObjectInView:(UIView *)view;
@end

@implementation MEGAPDFUITextSearchingFindSessionInterceptor

- (nullable instancetype)initWithPDFView:(PDFView *)pdfView
                        documentSearcher:(id<MEGAPDFDocumentSearching>)documentSearcher {
    id<UITextSearching, UITextInput> pdfKitSearcher = [self.class searchableObjectInView:pdfView];
    if (pdfKitSearcher == nil) { return nil; }
    self = [super init];
    if (self) {
        _pdfKitSearcher = pdfKitSearcher;
        _documentSearcher = documentSearcher;
    }
    return self;
}

+ (nullable id<UITextSearching, UITextInput>)searchableObjectInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview conformsToProtocol:@protocol(UITextSearching)]
            && [subview conformsToProtocol:@protocol(UITextInput)]) {
            return (id<UITextSearching, UITextInput>)subview;
        }
        id<UITextSearching, UITextInput> found = [self searchableObjectInView:subview];
        if (found != nil) { return found; }
    }
    return nil;
}

// MARK: - UITextSearching

- (void)performTextSearchWithQueryString:(NSString *)string
                            usingOptions:(UITextSearchOptions *)options
                        resultAggregator:(id<UITextSearchAggregator>)aggregator {
    id<UITextSearching, UITextInput> pdfKitSearcher = self.pdfKitSearcher;
    if (pdfKitSearcher == nil) {
        [aggregator finishedSearching];
        return;
    }
    [self.documentSearcher searchForString:string
                              usingOptions:options
                               inTextInput:pdfKitSearcher
                                   onMatch:^(UITextRange *range) {
        [aggregator foundRange:range forSearchString:string inDocument:nil];
    } onFinish:^{
        [aggregator finishedSearching];
    }];
}

- (UITextRange *)selectedTextRange { return self.pdfKitSearcher.selectedTextRange; }

- (NSComparisonResult)compareFoundRange:(UITextRange *)foundRange
                                toRange:(UITextRange *)toRange
                             inDocument:(id)document {
    return [self.pdfKitSearcher compareFoundRange:foundRange
                                          toRange:toRange
                                       inDocument:document];
}

- (void)decorateFoundTextRange:(UITextRange *)range
                    inDocument:(id)document
                    usingStyle:(UITextSearchFoundTextStyle)style {
    [self.pdfKitSearcher decorateFoundTextRange:range inDocument:document usingStyle:style];
}

- (void)clearAllDecoratedFoundText {
    [self.pdfKitSearcher clearAllDecoratedFoundText];
}

- (void)scrollRangeToVisible:(UITextRange *)range inDocument:(id)document {
    if ([self.pdfKitSearcher respondsToSelector:@selector(scrollRangeToVisible:inDocument:)]) {
        [self.pdfKitSearcher scrollRangeToVisible:range inDocument:document];
    }
}

- (void)willHighlightFoundTextRange:(UITextRange *)range inDocument:(id)document {
    if ([self.pdfKitSearcher respondsToSelector:@selector(willHighlightFoundTextRange:inDocument:)]) {
        [self.pdfKitSearcher willHighlightFoundTextRange:range inDocument:document];
    }
}

@end
