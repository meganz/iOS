#import "UsageViewController.h"

#import "NSString+MNZCategory.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGA-Swift.h"

#import "Helper.h"

@import PieChart;
#import "LocalizationHelper.h"

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
    [self updateTextLabelsAppearance:currentPage];
    [self.pieChartView reloadData];
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
