//
//  THCapture.m
//  ScreenCaptureViewTest
//
//  Created by wayne li on 11-8-24.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "THCapture.h"
#import "CGContextCreator.h"
//#import "BlazeiceAppDelegate.h"

static NSString* const kFileName=@"output.mov";

@interface THCapture()
//配置录制环境
- (BOOL)setUpWriter;
//清理录制环境
- (void)cleanupWriter;
//完成录制工作
- (void)completeRecordingSession;
//录制每一帧
- (void)drawFrame;
@end

@implementation THCapture
@synthesize frameRate=_frameRate;
@synthesize captureLayer=_captureLayer;
@synthesize delegate=_delegate;

- (id)init
{
    self = [super init];
    if (self) {
        _frameRate=10;//默认帧率为10
    }
    
    return self;
}

- (void)dealloc {
	[self cleanupWriter];
}

#pragma mark -
#pragma mark CustomMethod

- (bool)startRecording1
{
    bool result = NO;
    if (! _recording && _captureLayer)
    {
        result = [self setUpWriter];
        if (result)
        {
            startedAt = [NSDate date];
            _spaceDate=0;
            _recording = true;
            _writing = false;
            //绘屏的定时器
            NSDate *nowDate = [NSDate date];
            timer = [[NSTimer alloc] initWithFireDate:nowDate interval:1.0/_frameRate target:self selector:@selector(drawFrame) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        }
    }
	return result;
}

- (void)stopRecording
{
    if (_recording) {
         _recording = false;
        [timer invalidate];
        timer = nil;
        [self completeRecordingSession];
        [self cleanupWriter];
    }
}
- (void)drawFrame
{
    /*if ([BlazeiceAppDelegate sharedAppDelegate].isPausing) {
         _spaceDate=_spaceDate+1.0/35;
        return;
    }*/
    if (!_writing) {
        [self performSelectorInBackground:@selector(getFrame) withObject:nil];
    }
}
-(void) writeVideoFrameAtTime:(CMTime)time addImage:(CGImageRef )newImage
{
    if (![videoWriterInput isReadyForMoreMediaData]) {
		NSLog(@"Not ready for video data");
	}
	else {
		@synchronized (self) {
			CVPixelBufferRef pixelBuffer = NULL;
			CGImageRef cgImage = CGImageCreateCopy(newImage);
			CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
			
			int status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, avAdaptor.pixelBufferPool, &pixelBuffer);
			if(status != 0){
				//could not get a buffer from the pool
				NSLog(@"Error creating pixel buffer:  status=%d", status);
			}
			// set image data into pixel buffer
			CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
			uint8_t* destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
			CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels);  //XXX:  will work if the pixel buffer is contiguous and has the same bytesPerRow as the input data
			
			if(status == 0){
				BOOL success = [avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
				if (!success)
					NSLog(@"Warning:  Unable to write buffer to video");
			}
			
			//clean up
			CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
			CVPixelBufferRelease( pixelBuffer );
			CFRelease(image);
			CGImageRelease(cgImage);
		}
	}
}
- (void)getFrame
{
    if (!_writing) {
        _writing = true;
        size_t width  = CGBitmapContextGetWidth(context);
        size_t height = CGBitmapContextGetHeight(context);
        @try {
            CGContextClearRect(context, CGRectMake(0, 0,width , height));
            [self.captureLayer renderInContext:context];
            self.captureLayer.contents=nil;
            CGImageRef cgImage = CGBitmapContextCreateImage(context);
            if (_recording) {
                float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0-_spaceDate*1000.0;
                //NSLog(@"millisElapsed = %f",millisElapsed);
                [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000) addImage:cgImage];
            }
            CGImageRelease(cgImage);
        }
        @catch (NSException *exception) {
            
        }
        _writing = false;
    }
}

- (NSString*)tempFilePath {
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:kFileName];
	
	return filePath;
}
-(BOOL) setUpWriter {
    
    CGSize size = self.captureLayer.frame.size;
    //Clear Old TempFile
	NSError  *error = nil;
    NSString *filePath=[self tempFilePath];
    NSFileManager* fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:filePath])
    {
		if ([fileManager removeItemAtPath:filePath error:&error] == NO)
        {
			NSLog(@"Could not delete old recording file at path:  %@", filePath);
            return NO;
		}
	}
    
    //Configure videoWriter
    NSURL   *fileUrl=[NSURL fileURLWithPath:filePath];
	videoWriter = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:AVFileTypeQuickTimeMovie error:&error];
	NSParameterAssert(videoWriter);
	
	//Configure videoWriterInput
	NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithDouble:size.width*size.height], AVVideoAverageBitRateKey,
										   nil ];
	
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   AVVideoCodecH264, AVVideoCodecKey,
								   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
								   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
								   videoCompressionProps, AVVideoCompressionPropertiesKey,
								   nil];

	videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
	
	NSParameterAssert(videoWriterInput);
	videoWriterInput.expectsMediaDataInRealTime = YES;
	NSDictionary* bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
	
	avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
	
	//add input
	[videoWriter addInput:videoWriterInput];
	[videoWriter startWriting];
	[videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
    
    
    //create context
    if (context== NULL)
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate (NULL,
                                         size.width,
                                         size.height,
                                         8,//bits per component
                                         size.width * 4,
                                         colorSpace,
                                         kCGImageAlphaNoneSkipFirst);
        CGColorSpaceRelease(colorSpace);
        CGContextSetAllowsAntialiasing(context,NO);
        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0,-1, 0, size.height);
        CGContextConcatCTM(context, flipVertical);
    }
    if (context== NULL)
    {
		fprintf (stderr, "Context not created!");
        return NO;
	}
	
	return YES;
}

- (void) cleanupWriter {
   
	avAdaptor = nil;
	
	videoWriterInput = nil;
	
	videoWriter = nil;
	
	startedAt = nil;
    

    //CGContextRelease(context);
    //context=NULL;
}

- (void) completeRecordingSession {
     
	
	[videoWriterInput markAsFinished];
	
	// Wait for the video
	int status = videoWriter.status;
	while (status == AVAssetWriterStatusUnknown)
    {
		NSLog(@"Waiting...");
		[NSThread sleepForTimeInterval:0.5f];
		status = videoWriter.status;
	}
	
    BOOL success = [videoWriter finishWriting];
    if (!success)
    {
        NSLog(@"finishWriting returned NO");
        if ([_delegate respondsToSelector:@selector(recordingFaild:)]) {
            [_delegate recordingFaild:nil];
        }
        return ;
    }
    
    NSLog(@"Completed recording, file is stored at:  %@", [self tempFilePath]);
    if ([_delegate respondsToSelector:@selector(recordingFinished:)]) {
        [_delegate recordingFinished:[self tempFilePath]];
    }
}


@end
