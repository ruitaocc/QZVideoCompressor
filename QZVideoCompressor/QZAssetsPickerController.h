//
//  QZAssetsPickerController.h
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-21.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPMoviePlayerController.h>

#define AS_ALLVIDEOS [ALAssetsFilter allVideos]
#define AS_ALLPHOTOS [ALAssetsFilter allPhotos]
#define AS_ALLASSETS [ALAssetsFilter allAssets]


@class QZAssetsPickerController;
@protocol QZAssetsPickerControllerDelegate<NSObject>
@optional
- (void)assetsPickerController:(QZAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets;//general

- (void)assetsPickerController:(QZAssetsPickerController *)picker didFinishPickingAssetUrl:(NSURL *)assetUrl;//vedio compress
//cancel
- (void)assetsPickerControllerDidCancel:(QZAssetsPickerController *)picker;

//vedio tmppath and thumbnail
- (void)assetsPickerController:(QZAssetsPickerController *)picker didFinishPickingVedioPath:(NSString *)tmppath thumbImage:(UIImage *)thumb;
@end

@interface QZAssetsPickerController : UINavigationController

@property(nonatomic, weak) id <UINavigationControllerDelegate ,QZAssetsPickerControllerDelegate>delegate;

@property(nonatomic, strong) ALAssetsFilter *assetsFilter;

@property(nonatomic, assign) NSInteger maxinumSelection;

@property(nonatomic, assign) BOOL      disableCancelBtn;

@end
