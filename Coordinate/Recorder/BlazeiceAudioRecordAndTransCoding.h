//
//  BlazeiceAudioRecordAndTransCoding.h
//  BlazeiceRecordAloudTeacher
//
//  Created by 白冰 on 13-8-27.
//  Copyright (c) 2013年 闫素芳. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AudioToolbox/AudioToolbox.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
@protocol BlazeiceAudioRecordAndTransCodingDelegate<NSObject>
-(void)wavComplete;
@end


@interface BlazeiceAudioRecordAndTransCoding : NSObject

@property (retain, nonatomic)   AVAudioRecorder     *recorder;
@property (copy, nonatomic)     NSString            *recordFileName;//录音文件名
@property (copy, nonatomic)     NSString            *recordFilePath;//录音文件路径
@property (assign,nonatomic) BOOL nowPause;
@property (nonatomic, assign) id<BlazeiceAudioRecordAndTransCodingDelegate>delegate;
- (void)beginRecordByFileName:(NSString*)_fileName;
- (void)endRecord;
@end
