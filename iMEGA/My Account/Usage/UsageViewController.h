#import <UIKit/UIKit.h>

@import PieChart;

@interface UsageViewController: UIViewController
@property (weak, nonatomic) IBOutlet UIView * _Nullable cloudDriveView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable cloudDriveLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable cloudDriveSizeLabel;
@property (weak, nonatomic) IBOutlet UIView * _Nullable cloudDriveBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIView * _Nullable backupsView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable backupsLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable backupsSizeLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView * _Nullable backupsActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView * _Nullable backupsBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIView * _Nullable rubbishBinView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable rubbishBinLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable rubbishBinSizeLabel;
@property (weak, nonatomic) IBOutlet UIView * _Nullable rubbishBinBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIView * _Nullable incomingSharesView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable incomingSharesLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable incomingSharesSizeLabel;
@property (weak, nonatomic) IBOutlet UIView * _Nullable incomingSharesBottomSeparatorView;

@property (weak, nonatomic) IBOutlet PieChartView * _Nullable pieChartView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable pieChartMainLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable pieChartSecondaryLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable pieChartTertiaryLabel;

@property (weak, nonatomic) IBOutlet UIView * _Nullable usageStorageView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable usageTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable usageSizeLabel;

@property (weak, nonatomic) IBOutlet UIPageControl * _Nullable usagePageControl;
@property (weak, nonatomic) IBOutlet UIView * _Nullable usageBottomSeparatorView;

@property (strong, nonatomic, nullable) NSNumber *cloudDriveSize;
@property (strong, nonatomic, nullable) NSNumber *backupsSize;
@property (strong, nonatomic, nullable) NSNumber *rubbishBinSize;
@property (strong, nonatomic, nullable) NSNumber *incomingSharesSize;

@property (strong, nonatomic) NSNumberFormatter * _Nullable numberFormatter;
@property (strong, nonatomic, nullable) NSNumber *usedStorage;
@property (strong, nonatomic, nullable) NSNumber *maxStorage;

@property (strong, nonatomic, nullable) NSNumber *transferOwnUsed;
@property (strong, nonatomic, nullable) NSNumber *transferMax;

- (BOOL)isStorageFull;
- (NSString * _Nonnull)textForSizeLabels:(NSNumber * _Nonnull)number;
- (void)setUpPieChartView;
- (void)reloadPieChart:(NSInteger)currentPage;

@end
