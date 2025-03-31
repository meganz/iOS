#import "SearchInPdfViewController.h"
#import "NSArray+MNZCategory.h"
#import "MEGA-Swift.h"

#import <PDFKit/PDFKit.h>

@interface SearchInPdfViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, PDFDocumentDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray<PDFSelection *> *searchResults;
@property (strong, nonatomic) UISearchBar *searchBar;

@end

@implementation SearchInPdfViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.searchResults = [NSMutableArray new];
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.showsCancelButton = YES;
    self.navigationItem.titleView = self.searchBar;

    if ([UIDevice currentDevice].iPadDevice) {
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(iPadCancelSearch)];
        [cancel setTitleTextAttributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody], NSForegroundColorAttributeName:[UIColor mnz_secondaryTextColor]} forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem = cancel;
    }
    
    [AppearanceManager forceSearchBarUpdate:self.searchBar 
       backgroundColorWhenDesignTokenEnable:[UIColor surface1Background]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.searchBar becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [self.searchBar resignFirstResponder];

    [super viewDidDisappear:animated];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceSearchBarUpdate:self.searchBar 
           backgroundColorWhenDesignTokenEnable:[UIColor surface1Background]];
    }
}

#pragma mark - Private

- (void)iPadCancelSearch {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"SearchItemCell" forIndexPath:indexPath];
    
    PDFSelection *selection = [self.searchResults objectOrNilAtIndex:indexPath.row];
    if (selection == nil) {
        return cell;
    }
    
    [selection extendSelectionForLineBoundaries];
    
    UILabel *page = [cell viewWithTag:1];
    page.text = selection.pages.firstObject.label;
    
    UILabel *text = [cell viewWithTag:2];
    text.text = selection.string;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:^{
        PDFSelection *searchResult = [self.searchResults objectOrNilAtIndex:indexPath.row];
        if (searchResult == nil) {
            return;
        }
        [self.delegate didSelectSearchResult:searchResult];
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

    [self.searchResults removeAllObjects];
    [self.tableView reloadData];
    
    if (searchBar.text.length > 3) {
        self.pdfDocument.delegate = self;
        [self.pdfDocument beginFindString:searchBar.text withOptions:NSCaseInsensitiveSearch];
    }
}

#pragma mark - PDFDocumentDelegate

- (void)didMatchString:(PDFSelection *)instance {
    [self.searchResults addObject:instance];
    [self.tableView reloadData];
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *keyInfo = [notification userInfo];
    CGRect keyboardFrame = [[keyInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.tableView convertRect:keyboardFrame fromView:nil];
    CGRect intersect = CGRectIntersection(keyboardFrame, self.tableView.bounds);
    if (!CGRectIsNull(intersect)) {
        NSTimeInterval duration = [[keyInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
        [UIView animateWithDuration:duration delay:0.0 options:curve animations: ^{
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, intersect.size.height, 0);
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, intersect.size.height, 0);
        } completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *keyInfo = [notification userInfo];
    NSTimeInterval duration = [[keyInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
    [UIView animateWithDuration:duration delay:0.0 options:curve animations: ^{
        self.tableView.contentInset = UIEdgeInsetsZero;
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    } completion:nil];
}

@end
