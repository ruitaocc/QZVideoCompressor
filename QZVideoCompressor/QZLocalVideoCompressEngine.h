//
//  QZLocalVideoCompressEngine.h
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-22.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

@class QZLocalVideoCompressEngine;


@protocol QZLocalVideoCompressEngineDelegate <NSObject>
-(void)videoCompressEngine:(QZLocalVideoCompressEngine*)compEngine didFinishCompressALAsset:(ALAsset*)asset toURLPath:(NSURL*)urlPath;
@optional
-(void)videoCompressEngine:(QZLocalVideoCompressEngine*)compEngine compressProgress:(double)progress;

@end



@interface QZLocalVideoCompressEngine : NSObject
@property (nonatomic, strong)AVAsset   *asset; //
@property (nonatomic, copy) NSURL *outputURL;
@property (nonatomic) CMTimeRange timeRange;

@property (nonatomic, assign)id<QZLocalVideoCompressEngineDelegate> delegate;

-(void)compressALAsset:(ALAsset*)alasset toURLPath: (NSURL *)url;//
-(void)cancel;

@end
