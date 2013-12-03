//
//  QZViewController.m
//  QZVideoCompressor
//
//  Created by vectorcai on 13-11-29.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import "QZViewController.h"
#import "QZAssetsPickerController.h"

@interface QZViewController ()<UINavigationControllerDelegate, QZAssetsPickerControllerDelegate>
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UILabel * infoLabel;
@property (nonatomic, strong) UIButton * selectBtn;


@end

@implementation QZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _selectBtn = [[UIButton alloc] initWithFrame:CGRectMake(90, 100, 140, 44)];
    _selectBtn.backgroundColor = [UIColor lightGrayColor];
    _selectBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_selectBtn setTitle:@"Select Vedio" forState:UIControlStateNormal];
    [_selectBtn addTarget:self action:@selector(pickAssets:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_selectBtn];
    
    _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, 320, 140)];
    _infoLabel.backgroundColor = [UIColor lightGrayColor];
    _infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _infoLabel.numberOfLines = 0;
    [self.view addSubview:_infoLabel];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pickAssets:(id)sender
{
    if (!self.assets)
        self.assets = [[NSMutableArray alloc] init];
    
    QZAssetsPickerController *picker = [[QZAssetsPickerController alloc] init];
    picker.maxinumSelection = 1;
    picker.assetsFilter = AS_ALLVIDEOS;
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - asset picker delegate
-(void)assetsPickerController:(QZAssetsPickerController *)picker didFinishPickingAssetUrl:(NSURL *)assetUrl{
    _infoLabel.text = [NSString stringWithFormat:@"Local NSURL:  %@",assetUrl];
}






@end
