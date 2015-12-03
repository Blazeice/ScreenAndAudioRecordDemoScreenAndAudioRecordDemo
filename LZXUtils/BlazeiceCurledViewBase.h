//
//  BlazeiceCurledViewBase.h
//  lexue-teacher
//
//  Created by 白冰 on 13-7-19.
//  Copyright (c) 2013年 白冰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlazeiceCurledViewBase : NSObject

+(UIBezierPath*)curlShadowPathWithShadowDepth:(CGFloat)shadowDepth controlPointXOffset:(CGFloat)controlPointXOffset controlPointYOffset:(CGFloat)controlPointYOffset forView:(UIView*)view;

@end
