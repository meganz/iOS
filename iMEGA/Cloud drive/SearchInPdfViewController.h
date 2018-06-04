
#import <UIKit/UIKit.h>

@class PDFDocument, PDFSelection;

@protocol SearchInPdfViewControllerProtocol

- (void)didSelectSearchResult:(PDFSelection *)result API_AVAILABLE(ios(11.0));

@end

API_AVAILABLE(ios(11.0))
@interface SearchInPdfViewController : UIViewController

@property (strong, nonatomic) PDFDocument *pdfDocument;
@property (weak, nonatomic) id<SearchInPdfViewControllerProtocol> delegate;

@end
