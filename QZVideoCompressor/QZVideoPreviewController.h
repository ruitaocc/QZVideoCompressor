//
//  QZVideoPreviewController.h
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-25.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GLobalDefineMicro.h"
#import "QZVideoRangeSlider.h"
#import "QZVideoProgressBar.h"
#import <AssetsLibrary/AssetsLibrary.h>

@class QZVideoPreviewController;
@protocol QZVideoPreviewControllerDelegate <NSObject>

- (void)assetsPreviewController:(QZVideoPreviewController *)preViewer didFinishProcessingALAsset:(ALAsset*)asset toURLPath:(NSURL*)urlPath;

@end

@interface QZVideoPreviewController : UIViewController<QZVideoRangeSliderDelegate>

@property (nonatomic, assign) BOOL dismissDirectly;    //
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, assign) id <QZVideoPreviewControllerDelegate>delegate;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) NSURL  *assetURL;
@property (nonatomic, strong) QZVideoProgressBar *playProgressBar;
@property (nonatomic, strong) ALAsset *asset;

@property (nonatomic, copy) void(^playStateChangedBlock)(id controller, BOOL isPlay);
@end
