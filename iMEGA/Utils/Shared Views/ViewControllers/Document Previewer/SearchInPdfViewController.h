
#import <UIKit/UIKit.h>

@class PDFDocument, PDFSelection;

@protocol SearchInPdfViewControllerProtocol;

@interface SearchInPdfViewController : UIViewController

@property (strong, nonatomic) PDFDocument *pdfDocument;
@property (weak, nonatomic) id<SearchInPdfViewControllerProtocol> delegate;

@end
