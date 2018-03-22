
#import "SearchInPdfViewController.h"

#import <PDFKit/PDFKit.h>

@interface SearchInPdfViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, PDFDocumentDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray<PDFSelection *> *searchResults NS_AVAILABLE_IOS(11.0);
@property (strong, nonatomic) UISearchBar *searchBar;

@end

@implementation SearchInPdfViewController

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (void)viewDidLoad {
    [super viewDidLoad];

    self.searchResults = [NSMutableArray new];
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.showsCancelButton = YES;
    self.searchBar.tintColor = [UIColor redColor];
    self.navigationItem.titleView = self.searchBar;
    
    [self.searchBar becomeFirstResponder];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"SearchItemCell" forIndexPath:indexPath];
    
    PDFSelection *selection = [[self.searchResults objectAtIndex:indexPath.row] copy];
    [selection extendSelectionForLineBoundaries];
    
    UILabel *page = [cell viewWithTag:1];
    page.text = selection.pages[0].label;
    
    UILabel *text = [cell viewWithTag:2];
    text.text = selection.string;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate didSelectSearchResult:[self.searchResults objectAtIndex:indexPath.row]];
    }];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.pdfDocument.delegate = nil;
    [self.pdfDocument cancelFindString];

    if (searchBar.text.length > 3) {
        [self.searchResults removeAllObjects];
        [self.tableView reloadData];
        self.pdfDocument.delegate = self;
        [self.pdfDocument beginFindString:searchBar.text withOptions:NSCaseInsensitiveSearch];
    }
}

#pragma mark - PDFDocumentDelegate

- (void)didMatchString:(PDFSelection *)instance {
    [self.searchResults addObject:instance];
    [self.tableView reloadData];
}

#pragma clang diagnostic pop

@end
