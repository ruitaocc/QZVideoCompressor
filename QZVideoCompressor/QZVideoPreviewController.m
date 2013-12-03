//
//  QZVideoPreviewController.m
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-25.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import "QZVideoPreviewController.h"
#import <AVFoundation/AVFoundation.h>
#import "QZLocalVideoCompressEngine.h"

#define kQZVideoScale (320.0f/480.0f)
#define k_VIDEO_VIEW_HEIGHT             320

@interface QZVideoPreviewController ()<QZLocalVideoCompressEngineDelegate>{
    UIButton*   _backBtn;
    UIButton*   _doneBtn;
    AVPlayerLayer*    _avLayer;
    CMTime     _curTime;
    UIView*     _preView;
    
    CALayer *_wmLayer;
    AVAssetImageGenerator*  _imageGenerator;
    QZLocalVideoCompressEngine *_compEngine;
    id      _playTimeObserver;
    UILabel *progressLabel;
    UIActivityIndicatorView *activityIndicator;
}
@property (strong, nonatomic) QZVideoRangeSlider *videoRangeSlider;
@property (nonatomic) CGFloat startTime;
@property (nonatomic) CGFloat stopTime;
@end

@implementation QZVideoPreviewController
@synthesize player = _player;
@synthesize assetURL = _assetURL;
@synthesize playBtn = _playBtn;
@synthesize videoRangeSlider = _videoRangeSlider;
@synthesize playProgressBar = _playProgressBar;
@synthesize asset = _asset;
- (id)init
{
    self = [super init];
    if (self) {
        _curTime = kCMTimeZero;
        
    }
    return self;
}


-(void)viewDidLoad{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.view.backgroundColor = [UIColor colorWithRed:25.f/255.f green:32.f/255.f blue:49.f/255.f alpha:1.f];
    self.view.autoresizesSubviews = YES;
    
    // navigation bar
    {
        self.title = @"Preview";
    }
    
    CGRect bounds = self.view.bounds;
    
    
    // preView
    {
        _preView = [[UIView alloc] initWithFrame:CGRectMake(0, IOS7_OFFSET_FIX, bounds.size.width, k_VIDEO_VIEW_HEIGHT)];
        _player = [[AVPlayer alloc]initWithURL:_assetURL];
        _player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
        _avLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _avLayer.bounds = _preView.bounds;
        _avLayer.anchorPoint = (CGPoint){.5, .5};
        _avLayer.position = (CGPoint){CGRectGetMidX(_preView.bounds), CGRectGetMidY(_preView.bounds)};
        _avLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [_preView.layer addSublayer:_avLayer];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        
        [self.view addSubview:_preView];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        //[self resume];
    }
    
    
    _videoRangeSlider = [[QZVideoRangeSlider alloc] initWithFrame:CGRectMake(10, 20, self.view.frame.size.width-20, 44) videoUrl:_assetURL ];
    _videoRangeSlider.bubleText.font = [UIFont systemFontOfSize:12];
    [_videoRangeSlider setPopoverBubbleSize:120 height:56];
    
    // Yellow
    _videoRangeSlider.topBorder.backgroundColor = [UIColor colorWithRed: 0.996 green: 0.951 blue: 0.502 alpha: 1];
    _videoRangeSlider.bottomBorder.backgroundColor = [UIColor colorWithRed: 0.992 green: 0.902 blue: 0.004 alpha: 1];
    
    
    _videoRangeSlider.delegate = self;
    
    [self.view addSubview:_videoRangeSlider];
    
    // 顶部线条
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, IOS7_OFFSET_FIX, bounds.size.width, 0.5)];
    lineView.backgroundColor = [UIColor blackColor];
    lineView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:lineView];
    // 底部栏
    UIImageView *bottomBarView = nil;
    {
        double buttomBarHeight = [UIScreen mainScreen].bounds.size.height > 480.f ? 125 : 94;
        bottomBarView = [[UIImageView alloc]initWithFrame:CGRectMake(0, bounds.size.height - buttomBarHeight, bounds.size.width, buttomBarHeight)];
        bottomBarView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        bottomBarView.userInteractionEnabled = YES;
        [self.view addSubview:bottomBarView];
        
        //播放按钮
        _playBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
        [bottomBarView addSubview:_playBtn];
        _playBtn.center = CGPointMake(CGRectGetMidX(bottomBarView.bounds), CGRectGetMidY(bottomBarView.bounds));
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"btn_microvideo_play_ios7"] forState:UIControlStateNormal];
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"btn_microvideo_pause_ios7"] forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(playBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.playStateChangedBlock)
                self.playStateChangedBlock(self, YES);
        });
        //_playBtn.selected = YES;
        
        _backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100 , 44)];
        _backBtn.center = CGPointMake(50, CGRectGetMidY(bottomBarView.bounds));
        [bottomBarView addSubview:_backBtn];
        [[_backBtn titleLabel]setTextAlignment :NSTextAlignmentLeft];
        [_backBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(cancelBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        
        
        _doneBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100 , 44)];
        _doneBtn.center = CGPointMake(270, CGRectGetMidY(bottomBarView.bounds));
        [bottomBarView addSubview:_doneBtn];
        [[_doneBtn titleLabel]setTextAlignment :NSTextAlignmentRight];
        [_doneBtn setTitle:@"Compress" forState:UIControlStateNormal];
        [_doneBtn addTarget:self action:@selector(doneBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    {
        CGFloat progressContainViewHeight = CGRectGetMinY(bottomBarView.frame) - CGRectGetMaxY(_preView.frame) - 1;
        UIView *progressContainView = nil;
        if ([UIScreen mainScreen].bounds.size.height > 480.f) {
            progressContainView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(bottomBarView.frame) - progressContainViewHeight, bounds.size.width, progressContainViewHeight)];
            progressContainView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        } else {
            progressContainView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(bottomBarView.frame) - progressContainViewHeight - 5.5, bounds.size.width, 5)];
            progressContainView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        }
        self.playProgressBar = [[QZVideoProgressBar alloc] initWithFrame:progressContainView.bounds];
        self.playProgressBar.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        self.playProgressBar.backgroundColor = ([UIScreen mainScreen].bounds.size.height > 480.f) ? [UIColor clearColor] : [UIColor colorWithWhite:1.f alpha:0.35];
        self.playProgressBar.markerColor = ([UIScreen mainScreen].bounds.size.height > 480.f) ? [UIColor blackColor] : [UIColor colorWithWhite:1.f alpha:0.8];
        self.playProgressBar.referenceValue = 100;
        self.playProgressBar.currentValue = 0;
        self.playProgressBar.needsBottomBorder = ([UIScreen mainScreen].bounds.size.height > 480.f);
        
        [progressContainView addSubview:self.playProgressBar];
        [progressContainView setBackgroundColor:[UIColor clearColor]];
        [self.view addSubview:progressContainView];
    }
    {
        progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 200, 200, 40)];
        progressLabel.center = CGPointMake(160, ([UIScreen mainScreen].bounds.size.height)/2+40);
        progressLabel.text =@"Processing...";
        [progressLabel setTextAlignment :NSTextAlignmentCenter];
        [progressLabel setTextColor:[UIColor whiteColor]];
        [progressLabel setFont:[UIFont systemFontOfSize:16]];
        [progressLabel setHidden:YES];
        [self.view addSubview:progressLabel];
       
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.center = CGPointMake(160, ([UIScreen mainScreen].bounds.size.height)/2);
        [self.view addSubview:activityIndicator];
        [activityIndicator stopAnimating];
    }
    self.startTime = 0;
    AVURLAsset * av_asset = [[AVURLAsset alloc] initWithURL:self.assetURL options:nil];
    self.stopTime = CMTimeGetSeconds([av_asset duration]);
    [self addPlayerTimerCallBack];
}

- (void)addPlayerTimerCallBack
{
    __unsafe_unretained __typeof(self) _self = self;
    _playTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30)
                                                              queue:NULL
                                                         usingBlock:^(CMTime time) {
                                                             CMTime cur_time = _self.player.currentTime;
                                                             [_self updateRangeSliderCursor:cur_time];
                                                             CMTime end_time = CMTimeMakeWithSeconds(_self.stopTime, 600);
                                                             if (CMTimeCompare(cur_time,end_time)>=0) {
                                                                 [_self playerItemDidReachEnd:nil];
                                                             }
                                                             
                                                         }];
}

-(void)cancelBtnAction:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)doneBtnAction:(id)sender{
    if (![progressLabel isHidden]) {
        return;
    }
    if ([self isPlaying]) {
        [self pause];
    }
    {
        [progressLabel setHidden:NO];
        [activityIndicator startAnimating];
    }
    
    NSString *outputPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"480.mp4"];
    AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:self.assetURL options:nil];
    
    CMTime start = CMTimeMakeWithSeconds(self.startTime, anAsset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.stopTime-self.startTime, anAsset.duration.timescale);
    NSLog(@"self.stopTime %f",self.startTime);
    NSLog(@"self.stopTime %f",self.stopTime);
    
    CMTimeRange range = CMTimeRangeMake(start, duration);
    _compEngine= [[QZLocalVideoCompressEngine alloc] init];
    _compEngine.delegate = self;
    _compEngine.timeRange = range;
    [_compEngine compressALAsset:self.asset toURLPath:[NSURL fileURLWithPath:outputPath]];

}

- (BOOL)isPlaying
{
    return _player.rate != 0;
}

- (void)playBtnAction:(id)sender
{
    if (![progressLabel isHidden]) {
        return;
    }
    if ([self isPlaying]) {
        [self pause];
    } else {
        [self resume];
    }
}

- (void)playerItemDidReachEnd:(NSNotification*)notification
{
    CMTime start_time = CMTimeMakeWithSeconds(self.startTime, 600);
    [_player seekToTime:start_time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self pause];

}

-(void)updateRangeSliderCursor:(CMTime)cur_time{
    [_videoRangeSlider setCurTime:(float)(cur_time.value)/cur_time.timescale];
}

-(void)pause
{
    [_player pause];
    CALayer *layer = _wmLayer;
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
    if (self.playStateChangedBlock)
        self.playStateChangedBlock(self, NO);
    _playBtn.selected = NO;
}

-(void)resume
{
    [_player play];
    CALayer *layer = _wmLayer;
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
    if (self.playStateChangedBlock)
        self.playStateChangedBlock(self, YES);
    _playBtn.selected = YES;
}
- (void)dealloc
{
    _compEngine.delegate =nil;
    [_compEngine cancel];
    _compEngine = nil;
    self.playStateChangedBlock = NULL;
    [self pause];
    if(_playTimeObserver)
    {
        [_player removeTimeObserver:_playTimeObserver];
        _playTimeObserver = nil;
    }
    _player = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)updateFirstFrame{
    CMTime seek = CMTimeMakeWithSeconds(self.startTime, 600);

    [_player seekToTime:seek toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark - QZVideoRangeSlider Delegate
- (void)videoRange:(QZVideoRangeSlider *)videoRange didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition{
    self.stopTime = rightPosition;
    if(fabs(leftPosition - self.startTime)>0.001){
        self.startTime = leftPosition;
        [self updateFirstFrame];
    }
    
};

- (void)videoRange:(QZVideoRangeSlider *)videoRange didGestureStateEndedLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition{};
#pragma mark - QZLocalVideoCompressEngine Delegate

-(void)videoCompressEngine:(QZLocalVideoCompressEngine*)compEngine didFinishCompressALAsset:(ALAsset*)asset toURLPath:(NSURL*)urlPath{
    {
        [progressLabel setHidden:YES];
        [activityIndicator stopAnimating];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(assetsPreviewController:didFinishProcessingALAsset:toURLPath:)]) {
        [self.delegate assetsPreviewController:self didFinishProcessingALAsset:asset toURLPath:urlPath];
    }
};
-(void)videoCompressEngine:(QZLocalVideoCompressEngine*)compEngine compressProgress:(double)progress{
    if (progress<0) {
        progressLabel.text =@"Processing...";
        return;
    }
    progress = progress>1.0?1:progress;
    progressLabel.text =[NSString stringWithFormat:@"Processing%d/100",(int)ceil(progress*100)];
    [self.playProgressBar setCurrentValue:progress*100];
};

@end
