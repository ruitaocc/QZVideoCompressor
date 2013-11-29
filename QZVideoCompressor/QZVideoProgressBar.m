//
//  QZVideoProgressBar.m
//  QZone
//
//  Created by dahonglin on 13-10-18, refactored by renjunyi on 13-11-13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "QZVideoProgressBar.h"

@interface QZVideoProgressBar () {
    struct {
        unsigned int topBorder:1;
        unsigned int bottomBorder:1;
    } _extraStyleFlags;
}

@property (strong,   nonatomic) NSArray         *fixedMarks;
@property (readonly, nonatomic) NSMutableArray  *marks;

@end

@implementation QZVideoProgressBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _referenceValue = 1.f;
        _currentProgress = 0.f;
        _fixedMarks = @[];
        _marks = [[NSMutableArray alloc] init];
        _foregroundColor = [UIColor colorWithRed:36.f/255.0 green:113.f/255.0 blue:247.f/255.0 alpha:1.0];
        _markerColor = [UIColor blackColor];
        _fixedMarkerColor = [UIColor blackColor];
        _borderColor = [UIColor blackColor];
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setReferenceValue:(float)referenceValue
{
    assert(_referenceValue > 0.f);
    if (_referenceValue != referenceValue) {
        _referenceValue = referenceValue;
        _currentProgress = _currentValue / _referenceValue;
        [self setNeedsDisplay];
    }
}

- (void)setCurrentValue:(float)currentValue
{
    if (currentValue > _currentValue) {
        _currentValue = (currentValue > _referenceValue) ? _referenceValue : currentValue;
        _currentProgress = _currentValue / _referenceValue;
        [self setNeedsDisplay];
    } else if (currentValue == 0.f) {
        _currentValue = 0.f;
        _currentProgress = 0.f;
        [self.marks removeAllObjects];
        [self setNeedsDisplay];
    }
}

- (void)setFixedMarks:(NSArray *)fixedMarks
{
    if (_fixedMarks != fixedMarks) {
        _fixedMarks = fixedMarks;
        [self setNeedsDisplay];
    }
}

- (void)setMark
{
    if ([self.marks.lastObject floatValue] < self.currentProgress) {
        [self.marks addObject:@(self.currentProgress)];
    }
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    NSParameterAssert(foregroundColor);
    _foregroundColor = foregroundColor;
    [self setNeedsDisplay];
}

- (void)setMarkerColor:(UIColor *)markerColor
{
    NSParameterAssert(markerColor);
    _markerColor = markerColor;
    [self setNeedsDisplay];
}

- (void)setFixedMarkerColor:(UIColor *)fixedMarkerColor
{
    NSParameterAssert(fixedMarkerColor);
    _fixedMarkerColor = fixedMarkerColor;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat minX = CGRectGetMinX(self.bounds), maxX = CGRectGetMaxX(self.bounds);
    CGFloat minY = CGRectGetMinY(self.bounds), maxY = CGRectGetMaxY(self.bounds);
    CGFloat width = CGRectGetWidth(self.bounds), height = CGRectGetHeight(self.bounds);

    // draw fixed marks
    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColorWithColor(context, self.fixedMarkerColor.CGColor);
    CGContextSetFillColorWithColor(context, self.fixedMarkerColor.CGColor);
    for (NSNumber *mark in self.fixedMarks) {
        CGFloat x = minX + mark.floatValue / self.referenceValue * width;
        CGContextMoveToPoint(context, x, minY);
        CGContextAddLineToPoint(context, x, maxY);
        CGContextStrokePath(context);
    }
    
    // draw progress bar foreground
    CGContextSetFillColorWithColor(context, self.foregroundColor.CGColor);
    CGContextAddRect(context, CGRectMake(minX, minY, self.currentProgress * width, height));
    CGContextFillPath(context);
    CGContextStrokePath(context);
    
    // draw marks
    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColorWithColor(context, self.markerColor.CGColor);
    CGContextSetFillColorWithColor(context, self.markerColor.CGColor);
    for (NSNumber *mark in self.marks) {
        if (mark.floatValue < self.currentValue) {
            CGFloat x = minX + mark.floatValue * width;
            CGContextMoveToPoint(context, x, minY);
            CGContextAddLineToPoint(context, x, maxY);
            CGContextStrokePath(context);
        }
    }
    
    // draw border
    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    if (_extraStyleFlags.topBorder) {
        CGContextMoveToPoint(context, minX, minY);
        CGContextAddLineToPoint(context, maxX, minY);
        CGContextStrokePath(context);
    }
    if (_extraStyleFlags.bottomBorder) {
        CGContextMoveToPoint(context, minX, maxY);
        CGContextAddLineToPoint(context, maxX, maxY);
        CGContextStrokePath(context);
    }
}

#pragma mark - Extra style flags

- (void)setNeedsTopBorder:(BOOL)needsTopBorder
{
    _extraStyleFlags.topBorder = needsTopBorder;
    [self setNeedsDisplay];
}

- (BOOL)needsTopBorder
{
    return _extraStyleFlags.topBorder;
}

- (void)setNeedsBottomBorder:(BOOL)needsBottomBorder
{
    _extraStyleFlags.bottomBorder = needsBottomBorder;
    [self setNeedsDisplay];
}

- (BOOL)needsBottomBorder
{
    return _extraStyleFlags.bottomBorder;
}

@end
