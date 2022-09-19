#import "UsageViewController.h"

#import "NSString+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGA-Swift.h"

#import "Helper.h"

@import PieChart;


@interface UsageViewController () <PieChartViewDelegate, PieChartViewDataSource, UIGestureRecognizerDelegate, UIScrollViewDelegate>
@end

@implementation UsageViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeStorageInfo];
    [self configView];
    
    self.pieChartView.delegate = self;
    self.pieChartView.datasource = self;
    
    [self reloadPieChart:self.usagePageControl.currentPage];
    
    self.rubbishBinSizeLabel.text = [self textForSizeLabels:self.rubbishBinSize];
    self.incomingSharesSizeLabel.text = [self textForSizeLabels:self.incomingSharesSize];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = NSLocalizedString(@"Storage", @"Navigate title for the storage information screen");
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

- (BOOL)isStorageFull {
    return [self.usedStorage compare: self.maxStorage] != NSOrderedAscending;
}

#pragma mark - Private

- (void)reloadPieChart:(NSInteger)currentPage {
    [_pieChartMainLabel setAttributedText:[self textForMainLabel:currentPage]];
    
    self.pieChartMainLabel.textColor = [self storageColorWithTraitCollection:self.traitCollection
                                                               isStorageFull:self.isStorageFull
                                                                 currentPage:currentPage];
    [self textForSecondaryAndTertiaryLabels:currentPage];
    
    [self.pieChartView reloadData];
}

- (NSMutableAttributedString *)textForMainLabel:(NSInteger)currentPage {
    NSNumber *number;
    switch (currentPage) {
        case 0: {
            number = [NSNumber numberWithFloat:(self.usedStorage.floatValue / self.maxStorage.floatValue) * 100];
            break;
        }
            
        case 1: {
            number = [NSNumber numberWithFloat:(self.transferOwnUsed.floatValue / self.transferMax.floatValue) * 100];
            break;
        }
    }
    
    if (isnan(number.floatValue)) {
        number = [NSNumber numberWithFloat:0];
    }
    
    NSMutableAttributedString *firstPartMutableAttributedString;
    NSMutableAttributedString *secondPartMutableAttributedString;
    NSRange firstPartRange;
    NSRange secondPartRange;
    
    NSString *firstPartString = [self.numberFormatter stringFromNumber:number];
    firstPartRange = [firstPartString rangeOfString:firstPartString];
    firstPartMutableAttributedString = [NSMutableAttributedString.alloc initWithString:firstPartString];
    
    NSString *secondPartString = NSLocalizedString(@" %", nil);
    secondPartMutableAttributedString = [NSMutableAttributedString.alloc initWithString:secondPartString];
    secondPartRange = [secondPartString rangeOfString:secondPartString];
    
    [firstPartMutableAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:75.f weight:UIFontWeightBold] range:firstPartRange];
    [secondPartMutableAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:40.f weight:UIFontWeightBold] range:secondPartRange];
    [firstPartMutableAttributedString appendAttributedString:secondPartMutableAttributedString];
    
    return firstPartMutableAttributedString;
}

- (void)textForSecondaryAndTertiaryLabels:(NSInteger)currentPage {
    NSNumber *firstNumber;
    NSNumber *secondNumber;
    NSString *tertiaryTextString;
    switch (currentPage) {
        case 0: {
            firstNumber = self.usedStorage;
            secondNumber = self.maxStorage;
            
            tertiaryTextString = NSLocalizedString(@"Storage", @"Label for any ‘Storage’ button, link, text, title, etc. - (String as short as possible).");
            break;
        }
            
        case 1: {
            firstNumber = self.transferOwnUsed;
            secondNumber = self.transferMax;
            
            tertiaryTextString = NSLocalizedString(@"Transfer", @"Label to indicate the amount of transfer quota in several places. It is a ‘noun‘ and there is an screenshot with an use example - (String as short as possible).");
            break;
        }
    }
    
    NSString *firstPartString;
    NSString *secondPartString;
    if (firstNumber.boolValue == 0) {
        firstPartString = @"-";
    } else {
        firstPartString = [Helper memoryStyleStringFromByteCount:firstNumber.longLongValue];
    }
    
    if (secondNumber.boolValue == 0) {
        secondPartString = @"-";
    } else {
        secondPartString = [Helper memoryStyleStringFromByteCount:secondNumber.longLongValue];
    }
    
    self.pieChartSecondaryLabel.text = [NSString stringWithFormat:@"%@ / %@", firstPartString, secondPartString];
    self.pieChartTertiaryLabel.text = tertiaryTextString;
}

- (NSString * _Nonnull)textForSizeLabels:(NSNumber * _Nonnull)number {
    NSString *stringFromByteCount = [Helper memoryStyleStringFromByteCount:number.longLongValue];
    
    return [NSString mnz_formatStringFromByteCountFormatter:stringFromByteCount];
}

#pragma mark - IBActions

- (IBAction)leftSwipeGestureRecognizer:(UISwipeGestureRecognizer *)sender {
    NSInteger page = _usagePageControl.currentPage;
    if (page == 1) {
        return;
    }
    
    [self reloadPieChart:(page + 1)];
    [_usagePageControl setCurrentPage:(page+1)];
}

- (IBAction)rightSwipeGestureRecognizer:(UISwipeGestureRecognizer *)sender {
    NSInteger page = _usagePageControl.currentPage;
    if (page == 0) {
        return;
    }
    
    [self reloadPieChart:(page - 1)];
    [_usagePageControl setCurrentPage:(page-1)];
}

- (IBAction)tapGestureRecognizer:(UITapGestureRecognizer *)sender {
    NSInteger page = _usagePageControl.currentPage;
    if (page == 1) {
        page = 0;
    } else {
        ++page;
    }
    
    [self reloadPieChart:page];
    [_usagePageControl setCurrentPage:page];
}

#pragma mark - PieChartViewDelegate

- (CGFloat)centerCircleRadius {
    return 118.f;
}

#pragma mark - PieChartViewDataSource

- (int)numberOfSlicesInPieChartView:(PieChartView *)pieChartView {
    return 2;
}

- (UIColor *)pieChartView:(PieChartView *)pieChartView colorForSliceAtIndex:(NSUInteger)index {
    switch (index) {
        case 0: //Storage / Transfer Quota
            return [self storageColorWithTraitCollection:self.traitCollection
                                           isStorageFull:self.isStorageFull
                                             currentPage:self.usagePageControl.currentPage];
            
        case 1: //Available storage/quota
            return [UIColor mnz_tertiaryGrayForTraitCollection:self.traitCollection];
            
        default:
            return [UIColor mnz_tertiaryGrayForTraitCollection:self.traitCollection];
    }
}

- (double)pieChartView:(PieChartView *)pieChartView valueForSliceAtIndex:(NSUInteger)index {
    double valueForSlice;
    switch (index) {
        case 0: { //Storage / Transfer Quota consumed
            if (self.usagePageControl.currentPage == 0) {
                valueForSlice = (self.cloudDriveSize.doubleValue / self.maxStorage.doubleValue);
            } else {
                valueForSlice = (self.transferOwnUsed.doubleValue / self.transferMax.doubleValue);
            }
            break;
        }
            
        case 1: { //Available storage/quota
            if (self.usagePageControl.currentPage == 0) {
                valueForSlice = ((self.maxStorage.doubleValue - self.usedStorage.doubleValue) / self.maxStorage.doubleValue);
            } else {
                valueForSlice = ((self.transferMax.doubleValue - self.transferOwnUsed.doubleValue) / self.transferMax.doubleValue);
            }
            
            if (isnan(valueForSlice)) {
                valueForSlice = 1;
            }
            break;
        }
            
        default:
            valueForSlice = 0;
            break;
    }
    
    if (valueForSlice < 0 || isnan(valueForSlice)) {
        valueForSlice = 0;
    }
    
    return valueForSlice;
}

@end
