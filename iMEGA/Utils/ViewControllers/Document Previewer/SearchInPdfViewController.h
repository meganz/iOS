
#import <UIKit/UIKit.h>

@class PDFDocument, PDFSelection;

@protocol SearchInPdfViewControllerProtocol

- (void)didSelectSearchResult:(PDFSelection *)result;

@end

@interface SearchInPdfViewController : UIViewController

@property (strong, nonatomic) PDFDocument *pdfDocument;
@property (weak, nonatomic) id<SearchInPdfViewControllerProtocol> delegate;

@end
