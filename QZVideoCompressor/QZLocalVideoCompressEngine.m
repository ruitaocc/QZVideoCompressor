//
//  QZLocalVideoCompressEngine.m
//  QZAssetsPicker
//
//  Created by vectorcai on 13-11-22.
//  Copyright (c) 2013年 vectorcai. All rights reserved.
//

#import "QZLocalVideoCompressEngine.h"

@protocol RWSampleBufferChannelDelegate;

@interface RWSampleBufferChannel : NSObject
{
@private
	AVAssetReaderOutput		*assetReaderOutput;
	AVAssetWriterInput		*assetWriterInput;
	
	dispatch_block_t		completionHandler;
	dispatch_queue_t		serializationQueue;
	BOOL					finished;
}
- (id)initWithAssetReaderOutput:(AVAssetReaderOutput *)assetReaderOutput assetWriterInput:(AVAssetWriterInput *)assetWriterInput;
@property (nonatomic, readonly) NSString *mediaType;
- (void)startWithDelegate:(id <RWSampleBufferChannelDelegate>)delegate completionHandler:(dispatch_block_t)completionHandler;
- (void)cancel;
@end


@protocol RWSampleBufferChannelDelegate <NSObject>
@required
- (void)sampleBufferChannel:(RWSampleBufferChannel *)sampleBufferChannel didReadSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end



@interface QZLocalVideoCompressEngine (){
    AVAsset						*aasset;
    ALAsset                     *al_asset;
    AVAssetImageGenerator		*imageGenerator;
	CMTimeRange					timeRange;
	dispatch_queue_t			serializationQueue;
	
	NSURL						*outputURL;
	BOOL						writingSamples;
    
	AVAssetReader				*assetReader;
	AVAssetWriter				*assetWriter;
	RWSampleBufferChannel		*audioSampleBufferChannel;
	RWSampleBufferChannel		*videoSampleBufferChannel;
	BOOL						cancelled;
}
@property (nonatomic, getter=isWritingSamples) BOOL writingSamples;

- (BOOL)setUpReaderAndWriterReturningError:(NSError **)outError;  // make sure "tracks" key of asset is loaded before calling this
- (BOOL)startReadingAndWritingReturningError:(NSError **)outError;
- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error;

@end

@implementation QZLocalVideoCompressEngine
@synthesize asset = asset;
@synthesize outputURL = outputURL;
@synthesize timeRange = timeRange;
@synthesize writingSamples = writingSamples;
+ (NSArray *)readableTypes
{
	return [AVURLAsset audiovisualTypes];
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
	return YES;
}

-(id)init{
    if (self = [super init]) {
        NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
		serializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    }
    return self;
}

-(void)compressALAsset:(ALAsset*)alasset toURLPath: (NSURL *)url{
    [self saveALAssetToAVAsset:alasset];
    [self setOutputURL:url];
    
    
    AVAsset *localAsset = [self asset];
	[localAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObjects:@"tracks", @"duration", nil] completionHandler:^{
		dispatch_async(serializationQueue, ^{
			if (cancelled)
				return;
			
			BOOL success = YES;
			NSError *localError = nil;
			
			success = ([localAsset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded);
			if (success)
				success = ([localAsset statusOfValueForKey:@"duration" error:&localError] == AVKeyValueStatusLoaded);
			
			if (success)
			{
				NSFileManager *fm = [NSFileManager defaultManager];
				NSString *localOutputPath = [self.outputURL path];
				if ([fm fileExistsAtPath:localOutputPath])
					success = [fm removeItemAtPath:localOutputPath error:&localError];
			}
			
			// Set up the AVAssetReader and AVAssetWriter, then begin writing samples or flag an error
			if (success)
				success = [self setUpReaderAndWriterReturningError:&localError];
			if (success)
				success = [self startReadingAndWritingReturningError:&localError];
			if (!success)
				[self readingAndWritingDidFinishSuccessfully:success withError:localError];
		});
	}];
}

-(void)saveALAssetToAVAsset:(ALAsset*)alasset{
    al_asset = alasset;
    NSDictionary *assetOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *localAsset = [AVURLAsset URLAssetWithURL:[alasset valueForProperty:ALAssetPropertyAssetURL] options:assetOptions];
    [self setAsset:localAsset];
}

- (BOOL)setUpReaderAndWriterReturningError:(NSError **)outError
{
	BOOL success = YES;
	NSError *localError = nil;
	AVAsset *localAsset = [self asset];
	NSURL *localOutputURL = [self outputURL];
	
	assetReader = [[AVAssetReader alloc] initWithAsset:asset error:&localError];
    
    assetReader.timeRange = self.timeRange;
	
    success = (assetReader != nil);
	if (success)
	{
		assetWriter = [[AVAssetWriter alloc] initWithURL:localOutputURL fileType:AVFileTypeQuickTimeMovie error:&localError];
		success = (assetWriter != nil);
	}
    
	if (success)
	{
		AVAssetTrack *audioTrack = nil, *videoTrack = nil;
		
        NSArray *audioTracks = [localAsset tracksWithMediaType:AVMediaTypeAudio];
		if ([audioTracks count] > 0)
			audioTrack = [audioTracks objectAtIndex:0];
		NSArray *videoTracks = [localAsset tracksWithMediaType:AVMediaTypeVideo];
		if ([videoTracks count] > 0)
			videoTrack = [videoTracks objectAtIndex:0];
		
		if (audioTrack)
		{
			NSDictionary *decompressionAudioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
														[NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
														nil];
			AVAssetReaderOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:decompressionAudioSettings];
            [assetReader addOutput:output];
			
			AudioChannelLayout stereoChannelLayout = {
				.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
				.mChannelBitmap = 0,
				.mNumberChannelDescriptions = 0
			};
			NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
            
            
			// Compress to 128kbps AAC with the asset writer
			NSDictionary *compressionAudioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
													  [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
													  [NSNumber numberWithInteger:128000], AVEncoderBitRateKey,
													  [NSNumber numberWithInteger:44100], AVSampleRateKey,
													  channelLayoutAsData, AVChannelLayoutKey,
													  [NSNumber numberWithUnsignedInteger:2], AVNumberOfChannelsKey,
													  nil];
            
            
            
			AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:[audioTrack mediaType] outputSettings:compressionAudioSettings];
           [assetWriter addInput:input];
			
			audioSampleBufferChannel = [[RWSampleBufferChannel alloc] initWithAssetReaderOutput:output assetWriterInput:input];
		}
		
		if (videoTrack)
		{
            CGAffineTransform transform = [videoTrack preferredTransform];
			NSDictionary *decompressionVideoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
														[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB], (id)kCVPixelBufferPixelFormatTypeKey,
														[NSDictionary dictionary], (id)kCVPixelBufferIOSurfacePropertiesKey,
                                                        
														nil];
			AVAssetReaderOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:decompressionVideoSettings];
            [assetReader addOutput:output];
			
			
            float bitRate = 512.f * 1024.f;
            NSInteger frameInterval = 30;
            
            NSDictionary *compressionSettings2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 [NSNumber numberWithFloat:bitRate], AVVideoAverageBitRateKey,
                                                 [NSNumber numberWithInteger:frameInterval], AVVideoMaxKeyFrameIntervalKey,
                                                 nil];

            NSMutableDictionary *videoSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                  AVVideoCodecH264, AVVideoCodecKey,
                                                  AVVideoScalingModeResizeAspectFill, AVVideoScalingModeKey,
                                                  [NSNumber numberWithDouble:480], AVVideoWidthKey,
                                                  [NSNumber numberWithDouble:480], AVVideoHeightKey,
                                                  nil];

			if (compressionSettings2)
				[videoSettings setObject:compressionSettings2 forKey:AVVideoCompressionPropertiesKey];
			
			AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:[videoTrack mediaType] outputSettings:videoSettings];
            input.transform = transform;
            [assetWriter addInput:input];
			
			videoSampleBufferChannel = [[RWSampleBufferChannel alloc] initWithAssetReaderOutput:output assetWriterInput:input];
		}
	}
	
	if (outError)
		*outError = localError;
	
	return success;
}

- (BOOL)startReadingAndWritingReturningError:(NSError **)outError
{
	BOOL success = YES;
	NSError *localError = nil;
    
	success = [assetReader startReading];
	if (!success)
		localError = [assetReader error];
	if (success)
	{
		success = [assetWriter startWriting];
		if (!success)
			localError = [assetWriter error];
	}
	
	if (success)
	{
		dispatch_group_t dispatchGroup = dispatch_group_create();
		
		[assetWriter startSessionAtSourceTime:[self timeRange].start];
		
		if (audioSampleBufferChannel)
		{
			id <RWSampleBufferChannelDelegate> delegate = nil;
			if (!videoSampleBufferChannel)
				delegate = self;
            
			dispatch_group_enter(dispatchGroup);
			[audioSampleBufferChannel startWithDelegate:delegate completionHandler:^{
				dispatch_group_leave(dispatchGroup);
			}];
		}
		if (videoSampleBufferChannel)
		{
			dispatch_group_enter(dispatchGroup);
			[videoSampleBufferChannel startWithDelegate:self completionHandler:^{
				dispatch_group_leave(dispatchGroup);
			}];
		}
		
		dispatch_group_notify(dispatchGroup, serializationQueue, ^{
			BOOL finalSuccess = YES;
			NSError *finalError = nil;
			
			if (cancelled)
			{
				[assetReader cancelReading];
				[assetWriter cancelWriting];
			}
			else
			{
				if ([assetReader status] == AVAssetReaderStatusFailed)
				{
					finalSuccess = NO;
					finalError = [assetReader error];
				}
				
				if (finalSuccess)
				{
					finalSuccess = [assetWriter finishWriting];
					if (!finalSuccess)
						finalError = [assetWriter error];
				}
			}
            
			[self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
		});
		
		
	}
	
	if (outError)
		*outError = localError;
	
	return success;
}

- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error
{
	if (!success)
	{
		[assetReader cancelReading];
		[assetWriter cancelWriting];
	}
	
	// Tear down ivars
	assetReader = nil;
	assetWriter = nil;
	audioSampleBufferChannel = nil;
	videoSampleBufferChannel = nil;
	cancelled = NO;
	
    
	dispatch_async(dispatch_get_main_queue(), ^{
		
        if (success && self.delegate && [self.delegate respondsToSelector:@selector(videoCompressEngine:didFinishCompressALAsset:toURLPath:)]) {
            [self.delegate videoCompressEngine:self didFinishCompressALAsset:al_asset toURLPath:outputURL];
        }
        
		if (!success)
		{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error"
                                                            message:[error localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Done", nil];
            [alert show];
		}
		[self setWritingSamples:NO];
	});
}
- (void)cancel:(id)sender
{
	dispatch_async(serializationQueue, ^{
		[audioSampleBufferChannel cancel];
		[videoSampleBufferChannel cancel];
		cancelled = YES;
        self.delegate = nil;
    });
}

- (void)cancel
{
	dispatch_async(serializationQueue, ^{
		[audioSampleBufferChannel cancel];
		[videoSampleBufferChannel cancel];
		cancelled = YES;
    });
}


static double progressOfSampleBufferInTimeRange(CMSampleBufferRef sampleBuffer, CMTimeRange timeRange)
{
	CMTime progressTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
	progressTime = CMTimeSubtract(progressTime, timeRange.start);
	CMTime sampleDuration = CMSampleBufferGetDuration(sampleBuffer);
	if (CMTIME_IS_NUMERIC(sampleDuration))
		progressTime= CMTimeAdd(progressTime, sampleDuration);
	return CMTimeGetSeconds(progressTime) / CMTimeGetSeconds(timeRange.duration);
}

static void removeARGBColorComponentOfPixelBuffer(CVPixelBufferRef pixelBuffer, size_t componentIndex)
{
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	
	size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
	size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
	static const size_t bytesPerPixel = 4;
	unsigned char *base = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
	for (size_t row = 0; row < bufferHeight; ++row)
	{
		for (size_t column = 0; column < bufferWidth; ++column)
		{
			unsigned char *pixel = base + (row * bytesPerRow) + (column * bytesPerPixel);
			pixel[componentIndex] = 0;
		}
	}
	
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

+ (size_t)componentIndexFromFilterTag:(NSInteger)filterTag
{
	return (size_t)filterTag;
}

- (void)sampleBufferChannel:(RWSampleBufferChannel *)sampleBufferChannel didReadSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
	CVPixelBufferRef pixelBuffer = NULL;
	
	double progress = progressOfSampleBufferInTimeRange(sampleBuffer, [self timeRange]);
	
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	if (imageBuffer && (CFGetTypeID(imageBuffer) == CVPixelBufferGetTypeID()))
	{
		pixelBuffer = (CVPixelBufferRef)imageBuffer;
	}
    dispatch_async(dispatch_get_main_queue(), ^{
		if (self.delegate && [self.delegate respondsToSelector:@selector(videoCompressEngine:compressProgress:)]) {
            [self.delegate videoCompressEngine:self compressProgress:progress];
        }
        
	});
	
}

@end


@interface RWSampleBufferChannel ()
- (void)callCompletionHandlerIfNecessary;  
@end

@implementation RWSampleBufferChannel

- (id)initWithAssetReaderOutput:(AVAssetReaderOutput *)localAssetReaderOutput assetWriterInput:(AVAssetWriterInput *)localAssetWriterInput
{
	self = [super init];
	
	if (self)
	{
		assetReaderOutput = localAssetReaderOutput;
		assetWriterInput = localAssetWriterInput;
		
		finished = NO;
		NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
		serializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
	}
	
	return self;
}



- (NSString *)mediaType
{
	return [assetReaderOutput mediaType];
}

- (void)startWithDelegate:(id <RWSampleBufferChannelDelegate>)delegate completionHandler:(dispatch_block_t)localCompletionHandler
{
	completionHandler = [localCompletionHandler copy];
    
	[assetWriterInput requestMediaDataWhenReadyOnQueue:serializationQueue usingBlock:^{
		if (finished)
			return;
		
		BOOL completedOrFailed = NO;
		
		while ([assetWriterInput isReadyForMoreMediaData] && !completedOrFailed)
		{
			CMSampleBufferRef sampleBuffer = [assetReaderOutput copyNextSampleBuffer];
			if (sampleBuffer != NULL)
			{
				if ([delegate respondsToSelector:@selector(sampleBufferChannel:didReadSampleBuffer:)])
					[delegate sampleBufferChannel:self didReadSampleBuffer:sampleBuffer];
				
				BOOL success = [assetWriterInput appendSampleBuffer:sampleBuffer];
				CFRelease(sampleBuffer);
				sampleBuffer = NULL;
				
				completedOrFailed = !success;
			}
			else
			{
				completedOrFailed = YES;
			}
		}
		
		if (completedOrFailed)
			[self callCompletionHandlerIfNecessary];
	}];
}

- (void)cancel
{
	dispatch_async(serializationQueue, ^{
		[self callCompletionHandlerIfNecessary];
	});
}

- (void)callCompletionHandlerIfNecessary
{
	BOOL oldFinished = finished;
	finished = YES;
    
	if (oldFinished == NO)
	{
		[assetWriterInput markAsFinished];
        
		dispatch_block_t localCompletionHandler = completionHandler ;
		completionHandler = nil;
        
		if (localCompletionHandler)
		{
			localCompletionHandler();
			localCompletionHandler=nil;
		}
	}
}




@end
