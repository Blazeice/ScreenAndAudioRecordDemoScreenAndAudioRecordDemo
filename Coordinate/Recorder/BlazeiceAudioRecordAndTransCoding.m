//
//  BlazeiceAudioRecordAndTransCoding.m
//  BlazeiceRecordAloudTeacher
//
//  Created by 白冰 on 13-8-27.
//  Copyright (c) 2013年 闫素芳. All rights reserved.
//

#import "BlazeiceAudioRecordAndTransCoding.h"
//#import "BlazeiceAppDelegate.h"

@implementation BlazeiceAudioRecordAndTransCoding
@synthesize recorder,recordFileName,recordFilePath,delegate;

#pragma mark - 开始录音
- (void)beginRecordByFileName:(NSString*)_fileName;{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toRecordOrPause:) name:@"toRecordOrPause" object:nil];
    
    recordFileName = _fileName;
    //设置文件名和录音路径
    recordFilePath = [self getPathByFileName:recordFileName ofType:@"wav"];
    //初始化录音
    AVAudioRecorder *temp = [[AVAudioRecorder alloc]initWithURL:[NSURL URLWithString:[recordFilePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                                       settings:[self getAudioRecorderSettingDict]
                                                          error:nil];
    self.recorder = temp;
    recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    //开始录音
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self.recorder record];
}

#pragma mark - 开始或结束
-(void)toRecordOrPause:(NSNotification*)sender
{
    NSString* str=(NSString*)[sender object];
    if ([str intValue]) {
        [self startRecord];
    }
    else{
        [self pauseRecord];
    }
}

#pragma mark - 录音开始
-(void)startRecord{
    [self.recorder record];
    _nowPause=NO;
}

#pragma mark - 录音暂停
-(void)pauseRecord{
    if (self.recorder.isRecording) {
        [self.recorder pause];
        _nowPause=YES;
    }
}

#pragma mark - 录音结束
- (void)endRecord{
    if (self.recorder.isRecording||(!self.recorder.isRecording&&_nowPause)) {
        [self.recorder stop];
        self.recorder = nil;
        [self.delegate wavComplete];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"toRecordOrPause" object:nil];
}

- (NSString*)getPathByFileName:(NSString *)_fileName ofType:(NSString *)_type
{
    NSString* fileDirectory = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:_fileName]stringByAppendingPathExtension:_type];
    return fileDirectory;
}

- (NSDictionary*)getAudioRecorderSettingDict
{
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey, //采样率
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,//通道的数目
                                   nil];
    return recordSetting;
}


@end
