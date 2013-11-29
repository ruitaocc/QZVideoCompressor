//
//  SliderLeft.m
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-26.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import "SliderLeft.h"

@implementation SliderLeft

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* color5 = [UIColor colorWithRed: 0.992 green: 0.902 blue: 0.004 alpha: 1];
    UIColor* gradientColor2 = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* color6 = [UIColor colorWithRed: 0.196 green: 0.161 blue: 0.047 alpha: 1];
    
    //// Gradient Declarations
    NSArray* gradient3Colors = [NSArray arrayWithObjects:
                                (id)gradientColor2.CGColor,
                                (id)[UIColor colorWithRed: 0.996 green: 0.951 blue: 0.502 alpha: 1].CGColor,
                                (id)color5.CGColor, nil];
    CGFloat gradient3Locations[] = {0, 0, 0.49};
    CGGradientRef gradient3 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradient3Colors, gradient3Locations);
    
    //// Frames
    CGRect bubbleFrame = self.bounds;
    
    
    //// Rounded Rectangle Drawing
    CGRect roundedRectangleRect = CGRectMake(CGRectGetMinX(bubbleFrame), CGRectGetMinY(bubbleFrame), CGRectGetWidth(bubbleFrame), CGRectGetHeight(bubbleFrame));
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: roundedRectangleRect byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft cornerRadii: CGSizeMake(1, 1)];
    [roundedRectanglePath closePath];
    CGContextSaveGState(context);
    [roundedRectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient3,
                                CGPointMake(CGRectGetMidX(roundedRectangleRect), CGRectGetMinY(roundedRectangleRect)),
                                CGPointMake(CGRectGetMidX(roundedRectangleRect), CGRectGetMaxY(roundedRectangleRect)),
                                0);
    CGContextRestoreGState(context);
    [[UIColor clearColor] setStroke];
    roundedRectanglePath.lineWidth = 0.5;
    [roundedRectanglePath stroke];
    
    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(CGRectGetMinX(bubbleFrame) + 0.6 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.25 * CGRectGetHeight(bubbleFrame))];
    
    [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(bubbleFrame) + 0.3 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.45 * CGRectGetHeight(bubbleFrame))];
    [bezier3Path addQuadCurveToPoint:CGPointMake(CGRectGetMinX(bubbleFrame) + 0.3 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.55 * CGRectGetHeight(bubbleFrame)) controlPoint:CGPointMake(CGRectGetMinX(bubbleFrame) + 0.2 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.5 * CGRectGetHeight(bubbleFrame))];
    [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(bubbleFrame) + 0.6 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.75 * CGRectGetHeight(bubbleFrame))];
    [bezier3Path addQuadCurveToPoint:CGPointMake(CGRectGetMinX(bubbleFrame) + 0.6 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.65 * CGRectGetHeight(bubbleFrame)) controlPoint:CGPointMake(CGRectGetMinX(bubbleFrame) + 0.7 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.7 * CGRectGetHeight(bubbleFrame))];
    [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(bubbleFrame) + 0.45 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.55 * CGRectGetHeight(bubbleFrame))];
    [bezier3Path addQuadCurveToPoint:CGPointMake(CGRectGetMinX(bubbleFrame) + 0.45 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.45 * CGRectGetHeight(bubbleFrame)) controlPoint:CGPointMake(CGRectGetMinX(bubbleFrame) + 0.35 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.5 * CGRectGetHeight(bubbleFrame))];
    [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(bubbleFrame) + 0.6 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.35 * CGRectGetHeight(bubbleFrame))];
    [bezier3Path closePath];
    [bezier3Path addQuadCurveToPoint:CGPointMake(CGRectGetMinX(bubbleFrame) + 0.6 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.25 * CGRectGetHeight(bubbleFrame)) controlPoint:CGPointMake(CGRectGetMinX(bubbleFrame) + 0.7 * CGRectGetWidth(bubbleFrame), CGRectGetMinY(bubbleFrame) + 0.3 * CGRectGetHeight(bubbleFrame))];

    bezier3Path.miterLimit = 19;
    
    [color6 setFill];
    [bezier3Path fill];

    
    //// Cleanup
    CGGradientRelease(gradient3);
    CGColorSpaceRelease(colorSpace);
    
    
    
    
    
    
    
    
}


@end
