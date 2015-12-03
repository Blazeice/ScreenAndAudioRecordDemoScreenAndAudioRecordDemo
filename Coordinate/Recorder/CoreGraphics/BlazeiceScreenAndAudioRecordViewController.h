//
//  BlazeiceScreenAndAudioRecordViewController.h
//  BlazeiceScreenAndAudioRecord
//
//  Created by 白冰 on 15/12/3.
//  Copyright © 2015年 Corrine Chan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlazeiceDooleView.h"
#import "THCapture.h"
#import "BlazeiceAudioRecordAndTransCoding.h"
@interface BlazeiceScreenAndAudioRecordViewController : UIViewController <THCaptureDelegate,AVAudioRecorderDelegate,BlazeiceAudioRecordAndTransCodingDelegate>
{
    THCapture *capture;
    BlazeiceAudioRecordAndTransCoding*audioRecord;
    NSString* opPath;
}

@end
