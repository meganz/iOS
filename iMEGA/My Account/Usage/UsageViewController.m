#import "UsageViewController.h"

#import "NSString+MNZCategory.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGA-Swift.h"

#import "Helper.h"

@import PieChart;
@import MEGAL10nObjc;

@interface UsageViewController () <PieChartViewDelegate, PieChartViewDataSource, UIGestureRecognizerDelegate, UIScrollViewDelegate>
@end

@implementation UsageViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initialiseStorageInfo];
    [self configView];
    [self configStorageContentView];
    
    self.rubbishBinSizeLabel.text = [self formattedStorageUsedStringFor:self.rubbishBinSize];
    self.incomingSharesSizeLabel.text = [self formattedStorageUsedStringFor:self.incomingSharesSize];
    
    [self updateAppearance];
    
    [self setUpInvokeCommands];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = LocalizedString(@"Storage", @"Navigate title for the storage information screen");
}

- (void)setUpPieChartView {
    self.pieChartView.delegate = self;
    self.pieChartView.datasource = self;
    [self reloadPieChart:self.usagePageControl.currentPage];
}

#pragma mark - Private

- (void)reloadPieChart:(NSInteger)currentPage {
    [_pieChartMainLabel setAttributedText:[self textForMainLabel:currentPage]];
    
    self.pieChartMainLabel.textColor = [self colorForPage:self.usagePageControl.currentPage traitCollection:self.traitCollection];
    
    [self textForSecondaryAndTertiaryLabels:currentPage];
    
    [self.pieChartView reloadData];
}

- (NSMutableAttributedString *)textForMainLabel:(NSInteger)currentPage {
    NSNumber *usedStorageNumber = [NSNumber numberWithInteger:self.usedStorage];
    NSNumber *maxStorageNumber = [NSNumber numberWithInteger:self.maxStorage];
    
    NSNumber *transferUsedNumber = [NSNumber numberWithInteger:self.transferUsed];
    NSNumber *transferMaxNumber = [NSNumber numberWithInteger:self.transferMax];
    
    NSNumber *number;
    switch (currentPage) {
        case 0: {
            number = [NSNumber numberWithFloat:(usedStorageNumber.floatValue / maxStorageNumber.floatValue) * 100];
            break;
        }
            
        case 1: {
            number = [NSNumber numberWithFloat:(transferUsedNumber.floatValue / transferMaxNumber.floatValue) * 100];
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
    
    NSString *secondPartString = LocalizedString(@" %", @"");
    secondPartMutableAttributedString = [NSMutableAttributedString.alloc initWithString:secondPartString];
    secondPartRange = [secondPartString rangeOfString:secondPartString];
    
    [firstPartMutableAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:75.f weight:UIFontWeightBold] range:firstPartRange];
    [secondPartMutableAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:40.f weight:UIFontWeightBold] range:secondPartRange];
    [firstPartMutableAttributedString appendAttributedString:secondPartMutableAttributedString];
    
    return firstPartMutableAttributedString;
}

- (void)textForSecondaryAndTertiaryLabels:(NSInteger)currentPage {
    NSInteger firstNumber = 0;
    NSInteger secondNumber = 0;
    NSString *tertiaryTextString;
    switch (currentPage) {
        case 0: {
            firstNumber = self.usedStorage;
            secondNumber = self.maxStorage;
            
            tertiaryTextString = LocalizedString(@"Storage", @"Label for any ‘Storage’ button, link, text, title, etc. - (String as short as possible).");
            break;
        }
            
        case 1: {
            firstNumber = self.transferUsed;
            secondNumber = self.transferMax;
            
            tertiaryTextString = LocalizedString(@"Transfer", @"Label to indicate the amount of transfer quota in several places. It is a ‘noun‘ and there is an screenshot with an use example - (String as short as possible).");
            break;
        }
    }
    
    NSString *firstPartString;
    NSString *secondPartString;
    if (firstNumber == 0) {
        firstPartString = @"-";
    } else {
        firstPartString = [NSString memoryStyleStringFromByteCount:firstNumber];
    }
    
    if (secondNumber == 0) {
        secondPartString = @"-";
    } else {
        secondPartString = [NSString memoryStyleStringFromByteCount:secondNumber];
    }
    
    self.pieChartSecondaryLabel.text = [NSString stringWithFormat:@"%@ / %@", firstPartString, secondPartString];
    self.pieChartTertiaryLabel.text = tertiaryTextString;
}

#pragma mark - IBActions

- (IBAction)leftSwipeGestureRecognizer:(UISwipeGestureRecognizer *)sender {
    [self handleGesture:sender];
}

- (IBAction)rightSwipeGestureRecognizer:(UISwipeGestureRecognizer *)sender {
    [self handleGesture:sender];
}

- (IBAction)tapGestureRecognizer:(UITapGestureRecognizer *)sender {
    [self handleGesture:sender];
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
    return [self colorForSliceAt:index];
}

- (double)pieChartView:(PieChartView *)pieChartView valueForSliceAtIndex:(NSUInteger)index {
    double valueForSlice;
    switch (index) {
        case 0: { //Storage / Transfer Quota consumed
            if (self.usagePageControl.currentPage == 0) {
                valueForSlice = ((double)self.usedStorage / (double)self.maxStorage);
            } else {
                valueForSlice = ((double)self.transferUsed / (double)self.transferMax);
            }
            break;
        }
            
        case 1: { //Available storage/quota
            if (self.usagePageControl.currentPage == 0) {
                valueForSlice = (((double)self.maxStorage - (double)self.usedStorage) / (double)self.maxStorage);
            } else {
                valueForSlice = (((double)self.transferMax - (double)self.transferUsed) / (double)self.transferMax);
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
