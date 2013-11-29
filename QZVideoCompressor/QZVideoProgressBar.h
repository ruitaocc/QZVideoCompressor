//
//  QZVideoProgressBar.h
//  Qzone
//
//  Created by dahonglin on 13-10-18, refactored by renjunyi on 13-11-13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QZVideoProgressBar : UIView

@property (nonatomic, strong)   UIColor *foregroundColor;
@property (nonatomic, strong)   UIColor *fixedMarkerColor;
@property (nonatomic, strong)   UIColor *markerColor;
@property (nonatomic, strong)   UIColor *borderColor;

@property (nonatomic, assign)   BOOL    needsTopBorder;
@property (nonatomic, assign)   BOOL    needsBottomBorder;

@property (nonatomic, assign)   CGFloat referenceValue;
@property (nonatomic, assign)   CGFloat currentValue;
@property (nonatomic, readonly) CGFloat currentProgress;

// 设置固定标记
- (void)setFixedMarks:(NSArray *)fixedMarks;

// 在当前进度位置设置一个标记
- (void)setMark;

@end
