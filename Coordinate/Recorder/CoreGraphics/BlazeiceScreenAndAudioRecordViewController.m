//
//  BlazeiceScreenAndAudioRecordViewController.m
//  BlazeiceScreenAndAudioRecord
//
//  Created by 白冰 on 15/12/3.
//  Copyright © 2015年 Corrine Chan. All rights reserved.
//

#import "BlazeiceScreenAndAudioRecordViewController.h"
#define VEDIOPATH @"vedioPath"

@interface BlazeiceScreenAndAudioRecordViewController ()

@end

@implementation BlazeiceScreenAndAudioRecordViewController{
    BlazeiceDooleView *doodleView;
    UIButton *button;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    CGRect frame = CGRectMake(0, 100, kMainScreenWidth,kMainScreenHeight-80);
    doodleView = [[BlazeiceDooleView alloc] initWithFrame:frame];
    doodleView.drawView.formPush = YES;//标志他是从教师端推送过来的。
    [self.view addSubview:doodleView];
    
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 40, kMainScreenWidth, 40)];
    [button setTitle:@"开始录制" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.tag = 1;
    [button addTarget:self action:@selector(recordOrStopRecord) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}
-(void)recordOrStopRecord{
    if (button.tag==1) {
        [button setTitle:@"停止录制" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        button.tag = 2;
        [self recordMustSuccess];
    }else{
        [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        button.tag = 1;
        [button setTitle:@"开始录制" forState:UIControlStateNormal];
        [self StopRecord];
    }
}
- (void)recordMustSuccess {
    if(capture == nil){
        capture=[[THCapture alloc] init];
    }
    capture.frameRate = 35;
    capture.delegate = self;
    capture.captureLayer = doodleView.layer;
    if (!audioRecord) {
        audioRecord = [[BlazeiceAudioRecordAndTransCoding alloc]init];
        audioRecord.recorder.delegate=self;
        audioRecord.delegate=self;
    }
    
    
    [capture performSelector:@selector(startRecording1)];
    
    NSString* path=[self getPathByFileName:VEDIOPATH ofType:@"wav"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]){
        [fileManager removeItemAtPath:path error:nil];
    }
    [self performSelector:@selector(toStartAudioRecord) withObject:nil afterDelay:0.1];
    
}

#pragma mark -
#pragma mark audioRecordDelegate
/**
 *  开始录音
 */
-(void)toStartAudioRecord
{
    [audioRecord beginRecordByFileName:VEDIOPATH];
}
/**
 *  音频录制结束合成视频音频
 */
-(void)wavComplete
{
    //视频录制结束,为视频加上音乐
    if (audioRecord) {
        NSString* path=[self getPathByFileName:VEDIOPATH ofType:@"wav"];
        [THCaptureUtilities mergeVideo:opPath andAudio:path andTarget:self andAction:@selector(mergedidFinish:WithError:)];
    }
}


#pragma mark -
#pragma mark THCaptureDelegate
- (void)recordingFinished:(NSString*)outputPath
{
    opPath=outputPath;
    if (audioRecord) {
        [audioRecord endRecord];
    }
    //[self mergedidFinish:outputPath WithError:nil];
}

- (void)recordingFaild:(NSError *)error
{
}


#pragma mark -
#pragma mark CustomMethod

- (void)video: (NSString *)videoPath didFinishSavingWithError:(NSError *) error contextInfo: (void *)contextInfo{
    if (error) {
        NSLog(@"---%@",[error localizedDescription]);
    }
}

- (void)mergedidFinish:(NSString *)videoPath WithError:(NSError *)error
{
    NSDateFormatter* dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:SS"];
    NSString* currentDateStr=[dateFormatter stringFromDate:[NSDate date]];
    
    NSString* fileName=[NSString stringWithFormat:@"白板录制,%@.mov",currentDateStr];
    
    NSString* path=[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",fileName]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath])
    {
        NSError *err=nil;
        [[NSFileManager defaultManager] moveItemAtPath:videoPath toPath:path error:&err];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"allVideoInfo"]) {
        NSMutableArray* allFileArr=[[NSMutableArray alloc] init];
        [allFileArr addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"allVideoInfo"]];
        [allFileArr insertObject:fileName atIndex:0];
        [[NSUserDefaults standardUserDefaults] setObject:allFileArr forKey:@"allVideoInfo"];
    }
    else{
        NSMutableArray* allFileArr=[[NSMutableArray alloc] init];
        [allFileArr addObject:fileName];
        [[NSUserDefaults standardUserDefaults] setObject:allFileArr forKey:@"allVideoInfo"];
    }
    
    //音频与视频合并结束，存入相册中
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}


- (void)StopRecord{
    
    [capture performSelector:@selector(stopRecording)];
}

- (NSString*)getPathByFileName:(NSString *)_fileName ofType:(NSString *)_type
{
    NSString* fileDirectory = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:_fileName]stringByAppendingPathExtension:_type];
    return fileDirectory;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
