//
//  QZVideoRangeSlider.m
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-26.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import "QZVideoRangeSlider.h"

@interface QZVideoRangeSlider ()

@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *centerView;
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) SliderLeft *leftThumb;
@property (nonatomic, strong) SliderRight *rightThumb;
@property (nonatomic, strong) SliderCursor *cursorThumb;
@property (nonatomic) CGFloat frame_width;
@property (nonatomic) Float64 durationSeconds;
@property (nonatomic, strong) ResizibleBubble *popoverBubble;

@property (nonatomic, strong) UIView *leftMask;
@property (nonatomic, strong) UIView *rightMask;

@property (nonatomic, assign) int thumbWidth;
@end

@implementation QZVideoRangeSlider
@synthesize thumbWidth = thumbWidth;

#define SLIDER_BORDERS_SIZE 3.0f
#define BG_VIEW_BORDERS_SIZE 2.0f


- (id)initWithFrame:(CGRect)frame videoUrl:(NSURL *)videoUrl{
    
    self = [super initWithFrame:frame];
    if (self) {
        
        _frame_width = frame.size.width;
        
        thumbWidth = ceil(frame.size.width*0.07);
        
        _bgView = [[UIControl alloc] initWithFrame:CGRectMake(thumbWidth-BG_VIEW_BORDERS_SIZE, 0, frame.size.width-(thumbWidth*2)+BG_VIEW_BORDERS_SIZE*2, frame.size.height)];
        _bgView.layer.borderColor = [UIColor grayColor].CGColor;
        _bgView.layer.borderWidth = BG_VIEW_BORDERS_SIZE;
        [self addSubview:_bgView];
        
        _videoUrl = videoUrl;
        
        _leftMask = [[UIView alloc]initWithFrame:CGRectMake(thumbWidth-BG_VIEW_BORDERS_SIZE, 0, 0, frame.size.height)];
        _leftMask.backgroundColor = [UIColor whiteColor];
        _leftMask.alpha = 0.65;
        _leftMask.layer.borderWidth = 0;
        [self addSubview:_leftMask];
        
        _rightMask = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, frame.size.height)];
        _rightMask.backgroundColor = [UIColor whiteColor];
        _rightMask.alpha = 0.65;
        _rightMask.layer.borderWidth = 0;
        [self addSubview:_rightMask];
        
        _topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, SLIDER_BORDERS_SIZE)];
        _topBorder.backgroundColor = [UIColor colorWithRed: 0.996 green: 0.951 blue: 0.502 alpha: 1];
        [self addSubview:_topBorder];
        
        
        _bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-SLIDER_BORDERS_SIZE, frame.size.width, SLIDER_BORDERS_SIZE)];
        _bottomBorder.backgroundColor = [UIColor colorWithRed: 0.992 green: 0.902 blue: 0.004 alpha: 1];
        [self addSubview:_bottomBorder];
        
        
        
        _leftThumb = [[SliderLeft alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, frame.size.height)];
        _leftThumb.contentMode = UIViewContentModeLeft;
        _leftThumb.userInteractionEnabled = YES;
        _leftThumb.clipsToBounds = YES;
        _leftThumb.backgroundColor = [UIColor clearColor];
        _leftThumb.layer.borderWidth = 0;
        [self addSubview:_leftThumb];
        
        
        
        UIPanGestureRecognizer *leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftPan:)];
        [_leftThumb addGestureRecognizer:leftPan];
        
        
        _rightThumb = [[SliderRight alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, frame.size.height)];
        
        _rightThumb.contentMode = UIViewContentModeRight;
        _rightThumb.userInteractionEnabled = YES;
        _rightThumb.clipsToBounds = YES;
        _rightThumb.backgroundColor = [UIColor clearColor];
        [self addSubview:_rightThumb];
        
        UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightPan:)];
        [_rightThumb addGestureRecognizer:rightPan];
        
        _rightPosition = frame.size.width;
        _leftPosition = 0;
        
        
        
        
        _centerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _centerView.backgroundColor = [UIColor clearColor];
        [self addSubview:_centerView];
        
        UIPanGestureRecognizer *centerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCenterPan:)];
        [_centerView addGestureRecognizer:centerPan];
        
        
        _cursorThumb = [[SliderCursor alloc]initWithFrame:CGRectMake(0, SLIDER_BORDERS_SIZE, thumbWidth/2, frame.size.height-SLIDER_BORDERS_SIZE*2)];
        _cursorThumb.contentMode = UIViewContentModeCenter;
        _cursorThumb.userInteractionEnabled = YES;
        _cursorThumb.clipsToBounds = YES;
        _cursorThumb.backgroundColor = [UIColor clearColor];
        //_cursorThumb.hidden = YES;
        [self addSubview:_cursorThumb];
        
        
        _popoverBubble = [[ResizibleBubble alloc] initWithFrame:CGRectMake(0, -50, 100, 50)];
        _popoverBubble.alpha = 0;
        _popoverBubble.backgroundColor = [UIColor clearColor];
        [self addSubview:_popoverBubble];
        
        
        _bubleText = [[UILabel alloc] initWithFrame:_popoverBubble.frame];
        _bubleText.font = [UIFont boldSystemFontOfSize:20];
        _bubleText.backgroundColor = [UIColor clearColor];
        _bubleText.textColor = [UIColor blackColor];
        _bubleText.textAlignment = UITextAlignmentCenter;
        
        [_popoverBubble addSubview:_bubleText];
        
        [self getMovieFrame];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


-(void)setPopoverBubbleSize: (CGFloat) width height:(CGFloat)height{
    
    CGRect currentFrame = _popoverBubble.frame;
    currentFrame.size.width = width;
    currentFrame.size.height = height;
    currentFrame.origin.y = height;
    _popoverBubble.frame = currentFrame;
    
    currentFrame.origin.x = 0;
    currentFrame.origin.y = 0;
    _bubleText.frame = currentFrame;
    
}


-(void)setMaxGap:(NSInteger)maxGap{
    _leftPosition = 0;
    _rightPosition = _frame_width*maxGap/_durationSeconds;
    _maxGap = maxGap;
}

-(void)setMinGap:(NSInteger)minGap{
    _leftPosition = 0;
    _rightPosition = _frame_width*minGap/_durationSeconds;
    _minGap = minGap;
}


- (void)delegateNotification
{
    if ([_delegate respondsToSelector:@selector(videoRange:didChangeLeftPosition:rightPosition:)]){
        [_delegate videoRange:self didChangeLeftPosition:self.leftPosition rightPosition:self.rightPosition];
    }
    
}

-(void)setCurTime:(CGFloat)curTime{
    _curTime = curTime;
    [self updateCursor];
}


#pragma mark - Gestures

- (void)handleLeftPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:self];
        
        _leftPosition += translation.x;
        if (_leftPosition < 0) {
            _leftPosition = 0;
            
        }
        
        if (
            (_rightPosition-_leftPosition <= _leftThumb.frame.size.width+_rightThumb.frame.size.width) ||
            ((self.maxGap > 0) && (self.rightPosition-self.leftPosition > self.maxGap)) ||
            ((self.minGap > 0) && (self.rightPosition-self.leftPosition < self.minGap))
            ){
            _leftPosition -= translation.x;
        }
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self updateMusk];
        
        [self setNeedsLayout];
        
        [self delegateNotification];
        
    }
    
    _popoverBubble.alpha = 1;
    
    [self setTimeLabel];
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        [self hideBubble:_popoverBubble];
    }
}


- (void)handleRightPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
        
        CGPoint translation = [gesture translationInView:self];
        _rightPosition += translation.x;
        if (_rightPosition < 0) {
            _rightPosition = 0;
        }
        
        if (_rightPosition > _frame_width){
            _rightPosition = _frame_width;
        }
        
        if (_rightPosition-_leftPosition <= 0){
            _rightPosition -= translation.x;
        }
        
        if ((_rightPosition-_leftPosition <= _leftThumb.frame.size.width+_rightThumb.frame.size.width) ||
            ((self.maxGap > 0) && (self.rightPosition-self.leftPosition > self.maxGap)) ||
            ((self.minGap > 0) && (self.rightPosition-self.leftPosition < self.minGap))){
            _rightPosition -= translation.x;
        }
        
        
        [gesture setTranslation:CGPointZero inView:self];
        [self updateMusk];
        
        
        [self setNeedsLayout];
        
        [self delegateNotification];
        
    }
    
    _popoverBubble.alpha = 1;
    
    [self setTimeLabel];
    
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        [self hideBubble:_popoverBubble];
    }
}


- (void)handleCenterPan:(UIPanGestureRecognizer *)gesture
{
    
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:self];
        
        _leftPosition += translation.x;
        _rightPosition += translation.x;
        
        if (_rightPosition > _frame_width || _leftPosition < 0){
            _leftPosition -= translation.x;
            _rightPosition -= translation.x;
        }
        
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self updateMusk];
        
        [self setNeedsLayout];
        
        [self delegateNotification];
        
    }
    
    _popoverBubble.alpha = 1;
    
    [self setTimeLabel];
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        [self hideBubble:_popoverBubble];
    }
    
}


- (void)layoutSubviews
{
    CGFloat inset = _leftThumb.frame.size.width / 2;
    
    _leftThumb.center = CGPointMake(_leftPosition+inset, _leftThumb.frame.size.height/2);
    
    _rightThumb.center = CGPointMake(_rightPosition-inset, _rightThumb.frame.size.height/2);
    
    _topBorder.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, 0, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width/2, SLIDER_BORDERS_SIZE);
    
    _bottomBorder.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, _bgView.frame.size.height-SLIDER_BORDERS_SIZE, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width/2, SLIDER_BORDERS_SIZE);
    
    
    _centerView.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, _centerView.frame.origin.y, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width, _centerView.frame.size.height);
    
    
    CGRect frame = _popoverBubble.frame;
    frame.origin.x = _centerView.frame.origin.x+_centerView.frame.size.width/2-frame.size.width/2;
    _popoverBubble.frame = frame;
}

-(void)updateMusk{
    [self updateLeftMusk:_leftPosition];
    [self updateRightMusk:_rightPosition];
}

-(void)updateLeftMusk:(CGFloat)lpos{
    CGRect frame = _leftMask.frame;
    frame.size.width = lpos;
    _leftMask.frame = frame;
}

-(void)updateRightMusk:(CGFloat)rpos{
    CGRect frame = _rightMask.frame;
    frame.origin.x = rpos;
    frame.size.width = _frame_width - thumbWidth + SLIDER_BORDERS_SIZE - rpos;
    _rightMask.frame = frame;
}

-(void)updateCursor{
    CGRect frame = _cursorThumb.frame;
    frame.origin.x= thumbWidth + _curTime/_durationSeconds*(_frame_width-thumbWidth*2.5);
    if (frame.origin.x < (_leftPosition + thumbWidth)) {
        frame.origin.x =(_leftPosition + thumbWidth);
    }
    if (frame.origin.x > (_rightPosition-thumbWidth*1.5)) {
        frame.origin.x =_rightPosition-thumbWidth*1.5;
    }
    _cursorThumb.frame = frame;
}

#pragma mark - Video

-(void)getMovieFrame{
    
    AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:_videoUrl options:nil];
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:myAsset];
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    if ([self isRetina]){
        self.imageGenerator.maximumSize = CGSizeMake(_bgView.frame.size.width*2, _bgView.frame.size.height*2);
    } else {
        self.imageGenerator.maximumSize = CGSizeMake(_bgView.frame.size.width, _bgView.frame.size.height);
    }
    
    int picWidth = 20;
    
    // First image
    NSError *error;
    CMTime actualTime;
    CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
    if (halfWayImage != NULL) {
        UIImage *videoScreen;
        if ([self isRetina]){
            videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
        } else {
            videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
        }
        //UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
        UIImageView *tmp = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, _bgView.frame.size.height)];
        tmp.clipsToBounds = YES;
        tmp.image = videoScreen;
        tmp.contentMode = UIViewContentModeScaleAspectFill;
        
        [_bgView addSubview:tmp];
        picWidth = tmp.frame.size.width;
        CGImageRelease(halfWayImage);
    }
    
    
    _durationSeconds = CMTimeGetSeconds([myAsset duration]);
    
    int picsCnt = ceil(_bgView.frame.size.width / picWidth);
    
    NSMutableArray *allTimes = [[NSMutableArray alloc] init];
    
    int time4Pic = 0;
    
    
    
    
    
    
    for (int i=1; i<picsCnt; i++){
        time4Pic = i*picWidth;
        
        CMTime timeFrame = CMTimeMakeWithSeconds(_durationSeconds*time4Pic/_bgView.frame.size.width, 600);
        
        
        [allTimes addObject:[NSValue valueWithCMTime:timeFrame]];
    }
    
    NSArray *times = allTimes;
    
    __block int k = 1;
    
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times
                                              completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime,
                                                                  AVAssetImageGeneratorResult result, NSError *error) {
                                                  
                                                  if (result == AVAssetImageGeneratorSucceeded) {
                                                      
                                                      
                                                       UIImage *videoScreen;
                                                      if ([self isRetina]){
                                                          videoScreen = [[UIImage alloc] initWithCGImage:image scale:2.0 orientation:UIImageOrientationUp];
                                                      } else {
                                                          videoScreen = [[UIImage alloc] initWithCGImage:image scale:1 orientation:UIImageOrientationUp];
                                                      }
                                                      
                                                      
                                                      
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          //UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
                                                          UIImageView *tmp = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, _bgView.frame.size.height)];
                                                          tmp.contentMode = UIViewContentModeScaleAspectFill;
                                                          tmp.clipsToBounds = YES;
                                                          tmp.image = videoScreen;
                                                          
                                                          int all = (k+1)*tmp.frame.size.width;
                                                          
                                                          
                                                          CGRect currentFrame = tmp.frame;
                                                          currentFrame.origin.x = k*currentFrame.size.width;
                                                          if (all > _bgView.frame.size.width){
                                                              int delta = all - _bgView.frame.size.width;
                                                              currentFrame.size.width -= delta;
                                                          }
                                                          tmp.frame = currentFrame;
                                                          k++;
                                                          //NSLog(@"%@",tmp);
                                                          [_bgView addSubview:tmp];
                                                      });
                                                      
                                                  }
                                                  
                                                  if (result == AVAssetImageGeneratorFailed) {
                                                      NSLog(@"Failed with error: %@", [error localizedDescription]);
                                                  }
                                                  if (result == AVAssetImageGeneratorCancelled) {
                                                      NSLog(@"Canceled");
                                                  }
                                              }];
}




#pragma mark - Properties

- (CGFloat)leftPosition
{
    return _leftPosition * _durationSeconds / _frame_width;
}


- (CGFloat)rightPosition
{
    return _rightPosition * _durationSeconds / _frame_width;
}


#pragma mark - Bubble

- (void)hideBubble:(UIView *)popover
{
    [UIView animateWithDuration:0.4
                          delay:0
                        options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:^(void) {
                         
                         _popoverBubble.alpha = 0;
                     }
                     completion:nil];
    
    if ([_delegate respondsToSelector:@selector(videoRange:didGestureStateEndedLeftPosition:rightPosition:)]){
        [_delegate videoRange:self didGestureStateEndedLeftPosition:self.leftPosition rightPosition:self.rightPosition];
        
    }
}


-(void) setTimeLabel{
    self.bubleText.text = [self trimIntervalStr];
    //NSLog([self timeDuration1]);
    //NSLog([self timeDuration]);
}


-(NSString *)trimDurationStr{
    int delta = floor(self.rightPosition - self.leftPosition);
    return [NSString stringWithFormat:@"%d", delta];
}


-(NSString *)trimIntervalStr{
    
    NSString *from = [self timeToStr:self.leftPosition];
    NSString *to = [self timeToStr:self.rightPosition];
    return [NSString stringWithFormat:@"%@ - %@", from, to];
}




#pragma mark - Helpers

- (NSString *)timeToStr:(CGFloat)time
{
    // time - seconds
    NSInteger min = floor(time / 60);
    NSInteger sec = floor(time - min * 60);
    NSString *minStr = [NSString stringWithFormat:min >= 10 ? @"%i" : @"0%i", min];
    NSString *secStr = [NSString stringWithFormat:sec >= 10 ? @"%i" : @"0%i", sec];
    return [NSString stringWithFormat:@"%@:%@", minStr, secStr];
}


-(BOOL)isRetina{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            
            ([UIScreen mainScreen].scale == 2.0));
}


@end
