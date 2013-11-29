//
//  SliderCursor.h
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-26.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "SliderLeft.h"
#import "SliderRight.h"
#import "ResizibleBubble.h"
#import "SliderCursor.h"

@protocol QZVideoRangeSliderDelegate;

@interface QZVideoRangeSlider : UIView


@property (nonatomic, weak) id <QZVideoRangeSliderDelegate> delegate;
@property (nonatomic) CGFloat leftPosition;
@property (nonatomic) CGFloat rightPosition;
@property (nonatomic) CGFloat curTime;
@property (nonatomic, strong) UILabel *bubleText;
@property (nonatomic, strong) UIView *topBorder;
@property (nonatomic, strong) UIView *bottomBorder;
@property (nonatomic, assign) NSInteger maxGap;
@property (nonatomic, assign) NSInteger minGap;


- (id)initWithFrame:(CGRect)frame videoUrl:(NSURL *)videoUrl;
- (void)setPopoverBubbleSize: (CGFloat) width height:(CGFloat)height;


@end


@protocol QZVideoRangeSliderDelegate <NSObject>

@optional

- (void)videoRange:(QZVideoRangeSlider *)videoRange didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition;

- (void)videoRange:(QZVideoRangeSlider *)videoRange didGestureStateEndedLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition;


@end




