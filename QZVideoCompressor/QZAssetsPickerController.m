//
//  QZAssetsPickerController.m
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-21.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import "QZAssetsPickerController.h"
#import "QZLocalVideoCompressEngine.h"
#import "QZVideoPreviewController.h"

#define IS_IOS7             ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
#define kThumbnailLength    78.0f
#define kThumbnailSize      CGSizeMake(kThumbnailLength, kThumbnailLength)
#define kPopoverContentSize CGSizeMake(320, 480)


@interface QZAssetsPickerController()
@end

@interface QZAssetsGroupPickerController : UITableViewController

@property(nonatomic, strong) ALAssetsLibrary *assetsLib;
@property(nonatomic, strong) NSMutableArray *groupsAry;

@end

@interface QZAssetsCollectionPickerController : UICollectionViewController<QZVideoPreviewControllerDelegate>

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, assign) NSInteger numPhotos;
@property (nonatomic, assign) NSInteger numVideos;

@end

@interface QZAssetsGroupViewCell : UITableViewCell

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
-(void)bind: (ALAssetsGroup*) assetsGroup;

@end

@interface QZAssetsViewCell : UICollectionViewCell

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy)   NSString *type;
@property (nonatomic, copy)   NSString *title;
@property (nonatomic, strong) UIImage *videoImage;
-(void)bind: (ALAsset*) assets;

@end


@interface QZAssetsSupplementaryView : UICollectionReusableView

@property (nonatomic, strong) UILabel *sectionLabel;

- (void)setNumberOfPhotos:(NSInteger)numberOfPhotos numberOfVideos:(NSInteger)numberOfVideos;

@end


@interface QZAssetsSupplementaryView ()

@end


@interface NSDate (TimeInterval)
+ (NSDateComponents *)componetsWithTimeInterval:(NSTimeInterval)timeInterval;
+ (NSString *)timeDescriptionOfTimeInterval:(NSTimeInterval)timeInterval;
@end


#pragma mark - QZAssetsPickerController

@implementation QZAssetsPickerController
- (id)init
{
    QZAssetsGroupPickerController *groupPickerController = [[QZAssetsGroupPickerController alloc] init];
    
    if (self = [super initWithRootViewController:groupPickerController])
    {
        _maxinumSelection           = NSIntegerMax;
        _assetsFilter               = [ALAssetsFilter allAssets];
        _disableCancelBtn           = NO;
        
        if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
            [self setContentSizeForViewInPopover:kPopoverContentSize];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
@end


#pragma mark - QZAssetsGroupPickerController


@implementation QZAssetsGroupPickerController


- (id)init
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
            [self setContentSizeForViewInPopover:kPopoverContentSize];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setupButtons];
    [self localize];
    [self setupGroup];
}

- (void)setupViews
{
    self.tableView.rowHeight = kThumbnailLength + 12;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)setupButtons
{
    QZAssetsPickerController *picker = (QZAssetsPickerController *)self.navigationController;
    
    if (!picker.disableCancelBtn)
    {
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(cancel:)];
    }
}

- (void)localize
{
    self.title = @"Photos";
}

- (void)setupGroup
{
    if (!self.assetsLib)
        self.assetsLib = [self.class defaultAssetsLibrary];
    
    if (!self.groupsAry)
        self.groupsAry = [[NSMutableArray alloc] init];
    else
        [self.groupsAry removeAllObjects];
    
    QZAssetsPickerController *picker = (QZAssetsPickerController *)self.navigationController;
    ALAssetsFilter *assetsFilter = picker.assetsFilter;
    
    ALAssetsLibraryGroupsEnumerationResultsBlock resultsBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        
        if (group)
        {
            [group setAssetsFilter:assetsFilter];
            
            if (group.numberOfAssets > 0)
                [self.groupsAry addObject:group];
            
        }
        else
        {
            [self reloadData];
        }
    };
    
    
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        
        [self showNotAllowed];
        
    };
    
    // Enumerate Camera roll first
    [self.assetsLib enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                      usingBlock:resultsBlock
                                    failureBlock:failureBlock];
    
    // Then all other groups
    NSUInteger type =
    ALAssetsGroupLibrary | ALAssetsGroupAlbum | ALAssetsGroupEvent |
    ALAssetsGroupFaces | ALAssetsGroupPhotoStream;
    
    [self.assetsLib enumerateGroupsWithTypes:type
                                  usingBlock:resultsBlock
                                failureBlock:failureBlock];
}


#pragma mark - Reload Data

- (void)reloadData
{
    if (self.groupsAry.count == 0)
        [self showNoAssets];
    
    [self.tableView reloadData];
}


#pragma mark - ALAssetsLibrary

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}


#pragma mark - Not allowed / No assets

- (void)showNotAllowed
{
    self.title              = nil;
    
    UIView *lockedView      = [[UIView alloc] initWithFrame:self.view.bounds];
    UIImageView *locked     = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"QZAssetsPickerLocked"]];
    
    
    CGRect rect             = CGRectInset(self.view.bounds, 8, 8);
    UILabel *title          = [[UILabel alloc] initWithFrame:rect];
    UILabel *message        = [[UILabel alloc] initWithFrame:rect];
    
    title.text              = NSLocalizedString(@"This app does not have access to your photos or videos.", nil);
    title.font              = [UIFont boldSystemFontOfSize:17.0];
    title.textColor         = [UIColor colorWithRed:129.0/255.0 green:136.0/255.0 blue:148.0/255.0 alpha:1];
    title.textAlignment     = NSTextAlignmentCenter;
    title.numberOfLines     = 5;
    
    message.text            = NSLocalizedString(@"You can enable access in Privacy Settings.", nil);
    message.font            = [UIFont systemFontOfSize:14.0];
    message.textColor       = [UIColor colorWithRed:129.0/255.0 green:136.0/255.0 blue:148.0/255.0 alpha:1];
    message.textAlignment   = NSTextAlignmentCenter;
    message.numberOfLines   = 5;
    
    [title sizeToFit];
    [message sizeToFit];
    
    locked.center           = CGPointMake(lockedView.center.x, lockedView.center.y - 40);
    title.center            = locked.center;
    message.center          = locked.center;
    
    rect                    = title.frame;
    rect.origin.y           = locked.frame.origin.y + locked.frame.size.height + 20;
    title.frame             = rect;
    
    rect                    = message.frame;
    rect.origin.y           = title.frame.origin.y + title.frame.size.height + 10;
    message.frame           = rect;
    
    [lockedView addSubview:locked];
    [lockedView addSubview:title];
    [lockedView addSubview:message];
    
    self.tableView.tableHeaderView  = lockedView;
    self.tableView.scrollEnabled    = NO;
}

- (void)showNoAssets
{
    UIView *noAssetsView    = [[UIView alloc] initWithFrame:self.view.bounds];
    
    CGRect rect             = CGRectInset(self.view.bounds, 10, 10);
    UILabel *title          = [[UILabel alloc] initWithFrame:rect];
    UILabel *message        = [[UILabel alloc] initWithFrame:rect];
    
    title.text              = @"No photos or videoes.";
    title.font              = [UIFont systemFontOfSize:26.0];
    title.textColor         = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1];
    title.textAlignment     = NSTextAlignmentCenter;
    title.numberOfLines     = 5;
    
    message.text            = @"You can use iTunes to import.";
    message.font            = [UIFont systemFontOfSize:18.0];
    message.textColor       = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1];
    message.textAlignment   = NSTextAlignmentCenter;
    message.numberOfLines   = 5;
    
    [title sizeToFit];
    [message sizeToFit];
    
    title.center            = CGPointMake(noAssetsView.center.x, noAssetsView.center.y - 10 - title.frame.size.height / 2);
    message.center          = CGPointMake(noAssetsView.center.x, noAssetsView.center.y + 10 + message.frame.size.height / 2);
    
    [noAssetsView addSubview:title];
    [noAssetsView addSubview:message];
    
    self.tableView.tableHeaderView  = noAssetsView;
    self.tableView.scrollEnabled    = NO;
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.groupsAry.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    QZAssetsGroupViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[QZAssetsGroupViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [cell bind:[self.groupsAry objectAtIndex:indexPath.row]];
    
    return cell;
}


#pragma mark - Table view delegate

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kThumbnailLength + 12;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QZAssetsCollectionPickerController *vc = [[QZAssetsCollectionPickerController alloc] init];
    vc.assetsGroup = [self.groupsAry objectAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Actions

- (void)cancel:(id)sender
{
    QZAssetsPickerController *picker = (QZAssetsPickerController *)self.navigationController;
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerControllerDidCancel:)])
        [picker.delegate assetsPickerControllerDidCancel:picker];
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end


#pragma mark - QZAssetsGroupViewCell

@implementation QZAssetsGroupViewCell


- (void)bind:(ALAssetsGroup *)assetsGroup
{
    self.assetsGroup            = assetsGroup;
    
    CGImageRef posterImage      = assetsGroup.posterImage;
    size_t height               = CGImageGetHeight(posterImage);
    float scale                 = height / kThumbnailLength;
    
    self.imageView.image        = [UIImage imageWithCGImage:posterImage scale:scale orientation:UIImageOrientationUp];
    self.textLabel.text         = [assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    self.detailTextLabel.text   = [NSString stringWithFormat:@"%d", [assetsGroup numberOfAssets]];
    self.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
}

- (NSString *)accessibilityLabel
{
    NSString *label = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    return [label stringByAppendingFormat:@"%d Photos", [self.assetsGroup numberOfAssets]];
}

@end




#pragma mark - QZAssetsCollectionPickerController

#define kAssetsViewCellIdentifier           @"AssetsViewCellIdentifier"
#define kAssetsSupplementaryViewIdentifier  @"AssetsSupplementaryViewIdentifier"

@implementation QZAssetsCollectionPickerController

- (id)init
{
    UICollectionViewFlowLayout *layout  = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize                     = kThumbnailSize;
    layout.sectionInset                 = UIEdgeInsetsMake(9.0, 0, 0, 0);
    layout.minimumInteritemSpacing      = 2.0;
    layout.minimumLineSpacing           = 2.0;
    layout.footerReferenceSize          = CGSizeMake(0, 44.0);
    
    if (self = [super initWithCollectionViewLayout:layout])
    {
        self.collectionView.allowsMultipleSelection = YES;
        
        [self.collectionView registerClass:[QZAssetsViewCell class]
                forCellWithReuseIdentifier:kAssetsViewCellIdentifier];
        
        [self.collectionView registerClass:[QZAssetsSupplementaryView class]
                forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                       withReuseIdentifier:kAssetsSupplementaryViewIdentifier];
        
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
            [self setEdgesForExtendedLayout:UIRectEdgeNone];
        
        if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
            [self setContentSizeForViewInPopover:kPopoverContentSize];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setupButtons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.numPhotos = self.numVideos = 0;
    [self setupAssets];
}



#pragma mark - Setup

- (void)setupViews
{
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

- (void)setupButtons
{
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Preview"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(finishPickingAssets:)];
}

- (void)setupAssets
{
    self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    if (!self.assets)
        self.assets = [[NSMutableArray alloc] init];
    else
        [self.assets removeAllObjects];
    
    ALAssetsGroupEnumerationResultsBlock resultsBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        
        if (asset)
        {
            [self.assets addObject:asset];
            
            NSString *type = [asset valueForProperty:ALAssetPropertyType];
            
            if ([type isEqual:ALAssetTypePhoto])
                self.numPhotos ++;
            if ([type isEqual:ALAssetTypeVideo])
                self.numVideos ++;
        }
        
        else if (self.assets.count > 0)
        {
            [self.collectionView reloadData];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.assets.count-1 inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionTop
                                                animated:YES];
        }
    };
    
    [self.assetsGroup enumerateAssetsUsingBlock:resultsBlock];
}


#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kAssetsViewCellIdentifier;
    
    QZAssetsViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [cell bind:[self.assets objectAtIndex:indexPath.row]];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *viewIdentifiert = kAssetsSupplementaryViewIdentifier;
    
    QZAssetsSupplementaryView *view =
    [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:viewIdentifiert forIndexPath:indexPath];
    
    [view setNumberOfPhotos:self.numPhotos numberOfVideos:self.numVideos];
    
    return view;
}


#pragma mark - Collection View Delegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    QZAssetsPickerController *vc = (QZAssetsPickerController *)self.navigationController;
    
    return ([collectionView indexPathsForSelectedItems].count < vc.maxinumSelection);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self setTitleWithSelectedIndexPaths:collectionView.indexPathsForSelectedItems];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self setTitleWithSelectedIndexPaths:collectionView.indexPathsForSelectedItems];
}


#pragma mark - Title

- (void)setTitleWithSelectedIndexPaths:(NSArray *)indexPaths
{
    // Reset title to group name
    if (indexPaths.count == 0)
    {
        self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
        return;
    }
    
    BOOL photosSelected = NO;
    BOOL videoSelected  = NO;
    
    for (NSIndexPath *indexPath in indexPaths)
    {
        ALAsset *asset = [self.assets objectAtIndex:indexPath.item];
        
        if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypePhoto])
            photosSelected  = YES;
        
        if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo])
            videoSelected   = YES;
        
        if (photosSelected && videoSelected)
            break;
    }
    
    NSString *format;
    
    if (photosSelected && videoSelected)
        format = @"%d Items Selected";
    
    else if (photosSelected)
        format = (indexPaths.count > 1) ?@"%d Photos Selected" : @"%d Photo Selected";
    
    else if (videoSelected)
        format = (indexPaths.count > 1) ?@"%d Videos Selected" : @"%d Video Selected";
    
    self.title = [NSString stringWithFormat:format, indexPaths.count];
}


#pragma mark - Actions

- (void)finishPickingAssets:(id)sender
{
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems)
    {
        [assets addObject:[self.assets objectAtIndex:indexPath.item]];
    }
    QZAssetsPickerController *picker = (QZAssetsPickerController *)self.navigationController;

    if ([assets count]==1 && [[assets objectAtIndex:0] valueForProperty:ALAssetPropertyType]==ALAssetTypeVideo) {
        
        QZVideoPreviewController *videoPreviewController = [[QZVideoPreviewController alloc] init];
        videoPreviewController.delegate = self;
        ALAsset *alasset = [assets objectAtIndex:0];
        [videoPreviewController setAsset:alasset];
        [videoPreviewController setAssetURL:[alasset valueForProperty:ALAssetPropertyAssetURL]];
        [picker presentViewController:videoPreviewController animated:YES completion:NO];
    
    }//if ([picker.delegate respondsToSelector:@selector(assetsPickerController:didFinishPickingAssets:)])
    //    [picker.delegate assetsPickerController:picker didFinishPickingAssets:assets];
    //[picker.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
    
}

- (NSString *)videoFilePath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"/Documents/tmp.mp4"];
}
- (void)getVideoFromAssetLibraryFail
{
    QZAssetsPickerController *picker = (QZAssetsPickerController *)self.navigationController;
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:didFinishPickingVedioPath:thumbImage:)]) {
        [picker.delegate assetsPickerController:picker didFinishPickingVedioPath:nil thumbImage:nil];
    }
}

- (void)getVideoFromAssetLibrarySuccess
{
    NSString * videoPath = [self videoFilePath];
    
    MPMoviePlayerController *tmpplayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:videoPath]];
    tmpplayer.shouldAutoplay = NO;
    UIImage *thumbnail = [tmpplayer thumbnailImageAtTime:0.0f timeOption:MPMovieTimeOptionNearestKeyFrame];
    
    QZAssetsPickerController *picker = (QZAssetsPickerController *)self.navigationController;
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:didFinishPickingVedioPath:thumbImage:)]) {
        [picker.delegate assetsPickerController:picker didFinishPickingVedioPath:[self videoFilePath] thumbImage:thumbnail];
    }

}

#pragma mark - QZVideoPreviewController Delegate
-(void)assetsPreviewController:(QZVideoPreviewController *)preViewer didFinishProcessingALAsset:(ALAsset *)asset toURLPath:(NSURL *)urlPath{
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    [assets addObject:asset];
    QZAssetsPickerController *picker = (QZAssetsPickerController *)self.navigationController;
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:didFinishPickingAssetUrl:)])
            [picker.delegate assetsPickerController:picker didFinishPickingAssetUrl:urlPath];
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end




#pragma mark - QZAssetsViewCell

@implementation QZAssetsViewCell

static UIFont *titleFont = nil;

static CGFloat titleHeight;
static UIImage *videoIcon;
static UIColor *titleColor;
static UIImage *checkedIcon;
static UIColor *selectedColor;

+ (void)initialize
{
    titleFont       = [UIFont systemFontOfSize:12];
    titleHeight     = 20.0f;
    videoIcon       = [UIImage imageNamed:@"QZAssetsPickerVideo"];
    titleColor      = [UIColor whiteColor];
    checkedIcon     = [UIImage imageNamed:(!IS_IOS7) ? @"QZAssetsPickerChecked~iOS6" : @"QZAssetsPickerChecked"];
    selectedColor   = [UIColor colorWithWhite:1 alpha:0.3];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.opaque                     = YES;
        self.isAccessibilityElement     = YES;
        self.accessibilityTraits        = UIAccessibilityTraitImage;
    }
    
    return self;
}

- (void)bind:(ALAsset *)asset
{
    self.asset  = asset;
    self.image  = [UIImage imageWithCGImage:asset.thumbnail];
    self.type   = [asset valueForProperty:ALAssetPropertyType];
    self.title  = [NSDate timeDescriptionOfTimeInterval:[[asset valueForProperty:ALAssetPropertyDuration] doubleValue]];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}


// Draw everything to improve scrolling responsiveness

- (void)drawRect:(CGRect)rect
{
    // Image
    [self.image drawInRect:CGRectMake(0, 0, kThumbnailLength, kThumbnailLength)];
    
    // Video title
    if ([self.type isEqual:ALAssetTypeVideo])
    {
        // Create a gradient from transparent to black
        CGFloat colors [] = {
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.8,
            0.0, 0.0, 0.0, 1.0
        };
        
        CGFloat locations [] = {0.0, 0.75, 1.0};
        
        CGColorSpaceRef baseSpace   = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient      = CGGradientCreateWithColorComponents(baseSpace, colors, locations, 2);
        
        CGContextRef context    = UIGraphicsGetCurrentContext();
        
        CGFloat height          = rect.size.height;
        CGPoint startPoint      = CGPointMake(CGRectGetMidX(rect), height - titleHeight);
        CGPoint endPoint        = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
        
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation);
        
        
        CGSize titleSize        = [self.title sizeWithFont:titleFont];
        [titleColor set];
        [self.title drawAtPoint:CGPointMake(rect.size.width - titleSize.width - 2 , startPoint.y + (titleHeight - 12) / 2)
                       forWidth:kThumbnailLength
                       withFont:titleFont
                       fontSize:12
                  lineBreakMode:NSLineBreakByTruncatingTail
             baselineAdjustment:UIBaselineAdjustmentAlignCenters];
        
        [videoIcon drawAtPoint:CGPointMake(2, startPoint.y + (titleHeight - videoIcon.size.height) / 2)];
    }
    
    if (self.selected)
    {
        CGContextRef context    = UIGraphicsGetCurrentContext();
		CGContextSetFillColorWithColor(context, selectedColor.CGColor);
		CGContextFillRect(context, rect);
        
        [checkedIcon drawAtPoint:CGPointMake(CGRectGetMaxX(rect) - checkedIcon.size.width, CGRectGetMinY(rect))];
    }
}


- (NSString *)accessibilityLabel
{
    ALAssetRepresentation *representation = self.asset.defaultRepresentation;
    
    NSMutableArray *labels          = [[NSMutableArray alloc] init];
    NSString *type                  = [self.asset valueForProperty:ALAssetPropertyType];
    NSDate *date                    = [self.asset valueForProperty:ALAssetPropertyDate];
    CGSize dimension                = representation.dimensions;
    
    
    // Type
    if ([type isEqual:ALAssetTypeVideo])
        [labels addObject:@"Video"];
    else
        [labels addObject:@"Photo"];
    
    // Orientation
    if (dimension.height >= dimension.width)
        [labels addObject:@"Portrait"];
    else
        [labels addObject:@"Landscape"];
    
    // Date
    NSDateFormatter *df             = [[NSDateFormatter alloc] init];
    df.locale                       = [NSLocale currentLocale];
    df.dateStyle                    = NSDateFormatterMediumStyle;
    df.timeStyle                    = NSDateFormatterShortStyle;
    df.doesRelativeDateFormatting   = YES;
    
    [labels addObject:[df stringFromDate:date]];
    
    return [labels componentsJoinedByString:@", "];
}


@end


#pragma mark - QZAssetsSupplementaryView

@implementation QZAssetsSupplementaryView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _sectionLabel               = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds, 8.0, 8.0)];
        _sectionLabel.font          = [UIFont systemFontOfSize:18.0];
        _sectionLabel.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:_sectionLabel];
    }
    
    return self;
}

- (void)setNumberOfPhotos:(NSInteger)numberOfPhotos numberOfVideos:(NSInteger)numberOfVideos
{
    NSString *title;
    
    if (numberOfVideos == 0)
        title = [NSString stringWithFormat:@"%ld Photos", (long)numberOfPhotos];
    else if (numberOfPhotos == 0)
        title = [NSString stringWithFormat:@"%ld Videos", (long)numberOfVideos];
    else
        title = [NSString stringWithFormat:@"%ld Photos, %ld Videos", (long)numberOfPhotos, (long)numberOfVideos];
    
    self.sectionLabel.text = title;
}

@end

#pragma mark - NSDate
@implementation NSDate (TimeInterval)

+ (NSDateComponents *)componetsWithTimeInterval:(NSTimeInterval)timeInterval
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *date1 = [[NSDate alloc] init];
    NSDate *date2 = [[NSDate alloc] initWithTimeInterval:timeInterval sinceDate:date1];
    
    unsigned int unitFlags =
    NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit |
    NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
    
    return [calendar components:unitFlags
                       fromDate:date1
                         toDate:date2
                        options:0];
}

+ (NSString *)timeDescriptionOfTimeInterval:(NSTimeInterval)timeInterval
{
    NSDateComponents *components = [self.class componetsWithTimeInterval:timeInterval];
    
    if (components.hour > 0)
    {
        return [NSString stringWithFormat:@"%d:%02d:%02d", components.hour, components.minute, components.second];
    }
    
    else
    {
        return [NSString stringWithFormat:@"%d:%02d", components.minute, components.second];
    }
}


@end

