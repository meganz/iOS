#import "UsageViewController.h"

#import "PieChartView.h"
#import "SVProgressHUD.h"

#import "NSString+MNZCategory.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "Helper.h"

@interface UsageViewController () <PieChartViewDelegate, PieChartViewDataSource, UIGestureRecognizerDelegate, UIScrollViewDelegate> {
    NSByteCountFormatter *byteCountFormatter;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pieChartTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet PieChartView *pieChartView;
@property (weak, nonatomic) IBOutlet UILabel *pieChartMainLabel;
@property (weak, nonatomic) IBOutlet UILabel *pieChartSecondaryLabel;

@property (weak, nonatomic) IBOutlet UIPageControl *usagePageControl;

@property (weak, nonatomic) IBOutlet UILabel *cloudDriveLabel;
@property (weak, nonatomic) IBOutlet UILabel *cloudDriveSizeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *cloudDriveProgressView;

@property (weak, nonatomic) IBOutlet UILabel *rubbishBinLabel;
@property (weak, nonatomic) IBOutlet UILabel *rubbishBinSizeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *rubbishBinProgressView;

@property (weak, nonatomic) IBOutlet UILabel *incomingSharesLabel;
@property (weak, nonatomic) IBOutlet UILabel *incomingSharesSizeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *incomingSharesProgressView;

@end

@implementation UsageViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.pieChartView.delegate = self;
    self.pieChartView.datasource = self;
    
    if ([[UIDevice currentDevice] iPhone4X]) {
        self.pieChartTopLayoutConstraint.constant = 22.0;
    }
    
    [self.cloudDriveLabel setText:AMLocalizedString(@"cloudDrive", @"")];
    [self.rubbishBinLabel setText:AMLocalizedString(@"rubbishBinLabel", @"")];
    [self.incomingSharesLabel setText:AMLocalizedString(@"incomingShares", @"")];
    
    byteCountFormatter = [[NSByteCountFormatter alloc] init];
    [byteCountFormatter setCountStyle:NSByteCountFormatterCountStyleMemory];
    
    [_pieChartView.layer setCornerRadius:CGRectGetWidth(self.pieChartView.frame)/2];
    [_pieChartView.layer setMasksToBounds:YES];
    [self changePieChartText:_usagePageControl.currentPage];
    
    NSString *stringFromByteCount = [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:0] longLongValue]];
    [_cloudDriveSizeLabel setAttributedText:[self textForSizeLabels:stringFromByteCount]];
    [_cloudDriveProgressView setProgress:([[self.sizesArray objectAtIndex:0] floatValue] / [[self.sizesArray objectAtIndex:4] floatValue]) animated:NO];
    
    stringFromByteCount = [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:1] longLongValue]];
    [_rubbishBinSizeLabel setAttributedText:[self textForSizeLabels:stringFromByteCount]];
    [_rubbishBinProgressView setProgress:([[self.sizesArray objectAtIndex:1] floatValue] / [[self.sizesArray objectAtIndex:4] floatValue]) animated:NO];
     
    stringFromByteCount = [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:2] longLongValue]];
    [_incomingSharesSizeLabel setAttributedText:[self textForSizeLabels:stringFromByteCount]];
    [_incomingSharesProgressView setProgress:([[self.sizesArray objectAtIndex:2] floatValue] / [[self.sizesArray objectAtIndex:4] floatValue]) animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"usedStorage", @"Title of the Used Storage section")];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)changePieChartText:(NSInteger)currentPage {
    
    [_pieChartMainLabel setAttributedText:[self textForMainLabel:currentPage]];
    
    NSString *textSecondaryLabel;
    switch (currentPage) {
        case 0: {
            textSecondaryLabel = [NSString stringWithFormat:AMLocalizedString(@"of %@", @"Sentece showed under the used space percentage to complete the info with the maximum storage."), [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:4] longLongValue]]];
            break;
        }
            
        case 1: {
            textSecondaryLabel = [NSString stringWithFormat:AMLocalizedString(@"used of %@", @"Sentece showed under the used space to complete the info with the maximum storage."), [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:4] longLongValue]]];
            break;
        }
            
        case 2: {
            textSecondaryLabel = [NSString stringWithFormat:AMLocalizedString(@"available of %@", @"Sentece showed under the available space to complete the info with the maximum storage."), [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:4] longLongValue]]];
            break;
        }
    }
    [_pieChartSecondaryLabel setText:textSecondaryLabel];
}

- (NSMutableAttributedString *)textForMainLabel:(NSInteger)currentPage {
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setLocale:[NSLocale currentLocale]];
    [numberFormatter setMaximumFractionDigits:0];
    
    NSMutableAttributedString *firstPartMutableAttributedString;
    NSMutableAttributedString *secondPartMutableAttributedString;
    NSString *stringFromByteCount;
    NSRange firstPartRange = NSMakeRange(0, 0);
    NSRange secondPartRange  = NSMakeRange(0, 0);;
    
    switch (currentPage) {
        case 0: {
            NSNumber *number = [NSNumber numberWithFloat:(([[self.sizesArray objectAtIndex:3] floatValue] / [[self.sizesArray objectAtIndex:4] floatValue]) * 100)];
            NSString *firstPartString = [numberFormatter stringFromNumber:number];
            firstPartRange = [firstPartString rangeOfString:firstPartString];
            firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:firstPartString];
            
            NSString *secondPartString = @"%";
            secondPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:secondPartString];
            secondPartRange = [secondPartString rangeOfString:secondPartString];
            break;
        }
            
        case 1: {
            stringFromByteCount = [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:3] longLongValue]];
            break;
        }
            
        case 2: {
            long long availableStorage = [[self.sizesArray objectAtIndex:4] longLongValue] - [[self.sizesArray objectAtIndex:3] longLongValue];
            stringFromByteCount = [byteCountFormatter stringFromByteCount:(availableStorage < 0) ? 0 : availableStorage];
            break;
        }
    }
    
    if (currentPage == 1 || currentPage == 2) {
        NSArray *componentsSeparatedByStringArray = [stringFromByteCount componentsSeparatedByString:@" "];
        
        NSString *firstPartString = [NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray];

        if ([firstPartString length] == 0) {
            firstPartString = [NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray];
        }
        
        firstPartRange = [firstPartString rangeOfString:firstPartString];
        firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:firstPartString];
        
        NSString *secondPartString = [NSString mnz_stringWithoutCountOfComponents:componentsSeparatedByStringArray];
        secondPartRange = [secondPartString rangeOfString:secondPartString];
        secondPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:secondPartString];
    }
    
    [firstPartMutableAttributedString addAttribute:NSFontAttributeName
                                             value:[UIFont mnz_SFUILightWithSize:60.0f]
                                             range:firstPartRange];
    
    [secondPartMutableAttributedString addAttribute:NSFontAttributeName
                                              value:[UIFont mnz_SFUILightWithSize:30.0f]
                                              range:secondPartRange];

    [firstPartMutableAttributedString appendAttributedString:secondPartMutableAttributedString];
    
    return firstPartMutableAttributedString;
}

- (NSMutableAttributedString *)textForSizeLabels:(NSString *)stringFromByteCount {
    NSArray *componentsSeparatedByStringArray = [stringFromByteCount componentsSeparatedByString:@" "];
    NSString *firstPartString = [[NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray] stringByAppendingString:@" "];
    NSMutableAttributedString *firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:firstPartString];
    
    NSRange firstPartRange = [firstPartString rangeOfString:firstPartString];
    [firstPartMutableAttributedString addAttribute:NSFontAttributeName
                                             value:[UIFont mnz_SFUILightWithSize:18.0f]
                                             range:firstPartRange];
    
    if (componentsSeparatedByStringArray.count > 1) {
        NSString *secondPartString = [componentsSeparatedByStringArray objectAtIndex:1];
        NSRange secondPartRange = [secondPartString rangeOfString:secondPartString];
        NSMutableAttributedString *secondPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:secondPartString];
        
        [secondPartMutableAttributedString addAttribute:NSFontAttributeName
                                                  value:[UIFont mnz_SFUILightWithSize:12.0f]
                                                  range:secondPartRange];
        [secondPartMutableAttributedString addAttribute:NSForegroundColorAttributeName
                                                  value:[UIColor mnz_gray777777]
                                                  range:secondPartRange];
        
        [firstPartMutableAttributedString appendAttributedString:secondPartMutableAttributedString];
    }
    
    return firstPartMutableAttributedString;
}

#pragma mark - IBActions

- (IBAction)leftSwipeGestureRecognizer:(UISwipeGestureRecognizer *)sender {
    NSInteger page = _usagePageControl.currentPage;
    if (page == 2) {
        return;
    }
    
    [self changePieChartText:(page+1)];
    [_usagePageControl setCurrentPage:(page+1)];
}

- (IBAction)rightSwipeGestureRecognizer:(UISwipeGestureRecognizer *)sender {
    NSInteger page = _usagePageControl.currentPage;
    if (page == 0) {
        return;
    }
    
    [self changePieChartText:(page-1)];
    [_usagePageControl setCurrentPage:(page-1)];
}

- (IBAction)tapGestureRecognizer:(UITapGestureRecognizer *)sender {
    NSInteger page = _usagePageControl.currentPage;
    if (page == 2) {
        page = 0;
    } else {
        ++page;
    }
    
    [self changePieChartText:page];
    [_usagePageControl setCurrentPage:page];
}

#pragma mark - PieChartViewDelegate

- (CGFloat)centerCircleRadius {
    return 88.f;
}

#pragma mark - PieChartViewDataSource

- (int)numberOfSlicesInPieChartView:(PieChartView *)pieChartView {
    return 7;
}

- (UIColor *)pieChartView:(PieChartView *)pieChartView colorForSliceAtIndex:(NSUInteger)index {
    switch (index) {
        case 0: //Cloud Drive
            return [UIColor mnz_blue2BA6DE];
            break;
            
        case 1:
        case 3:
        case 5:
            return [UIColor whiteColor];
            break;
            
        case 2: //Rubbish Bin
            return [UIColor mnz_green31B500];
            break;
            
        case 4: //Incoming Shares
            return [UIColor mnz_orangeFFA500];
            break;
            
        default: //Available space
            return [UIColor mnz_grayF7F7F7];
            break;
    }
}

- (double)pieChartView:(PieChartView *)pieChartView valueForSliceAtIndex:(NSUInteger)index {
    double valueForSlice;
    switch (index) {
        case 1:
        case 3:
        case 5: //Spaces between Cloud Drive and Rubbish Bin, Rubbish Bin and Incoming Shares, Incoming Shares and available space
            valueForSlice = 0.2f;
            break;
            
        case 0: //Cloud Drive
            valueForSlice = ([[self.sizesArray objectAtIndex:0] doubleValue] / [[self.sizesArray objectAtIndex:4] doubleValue]) * 94.0f;
            break;
            
        case 2: //Rubbish Bin
            valueForSlice = ([[self.sizesArray objectAtIndex:1] doubleValue] / [[self.sizesArray objectAtIndex:4] doubleValue]) * 94.0f;
            break;
            
        case 4: //Incoming Shares
            valueForSlice = ([[self.sizesArray objectAtIndex:2] doubleValue] / [[self.sizesArray objectAtIndex:4] doubleValue]) * 94.0f;
            break;
            
        case 6: //Available space
            valueForSlice = (([[self.sizesArray objectAtIndex:4] doubleValue] - [[self.sizesArray objectAtIndex:3] doubleValue]) / [[self.sizesArray objectAtIndex:4] doubleValue]) * 94.0f;
            break;
            
        default:
            valueForSlice = 0;
            break;
    }
    
    if (valueForSlice < 0) {
        valueForSlice = 0;
    }
    
    return valueForSlice;
}

@end
