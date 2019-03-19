//
//  IQCaptureHelper.m
//  WebDriverAgentLib
//
//  Created by cheney on 2019/3/19.
//  Copyright © 2019年 Facebook. All rights reserved.
//

#import "IQCaptureHelper.h"
#import "IQScreenHelper.h"
#import <UIKit/UIKit.h>
#import "XCAXClient_iOS.h"
#import <objc/runtime.h>
#import "XCUIDevice+FBHelpers.h"
#import "XCUIScreen.h"


@interface IQCaptureHelper()
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGRect rect;
@property (nonatomic, weak) id <IQCaptureScreenImageDataDelegate> delegate;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@end

@implementation IQCaptureHelper

+ (instancetype)sharedInstance {
  static IQCaptureHelper *manager;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    manager = [[IQCaptureHelper alloc] init];
  });
  return manager;
}

+ (IQCaptureHelper *)IQCaputreWithInterval:(NSTimeInterval)interval andDelegate:(id <IQCaptureScreenImageDataDelegate>)delegate{
  IQCaptureHelper *capture = [IQCaptureHelper sharedInstance];
  [capture initCaputreWithInterval:interval andDelegate:delegate];
  return capture;
}

+ (void)startCapture{
    [[IQCaptureHelper sharedInstance] startCapture];
}

+ (void)stopCapture{
   [[IQCaptureHelper sharedInstance] stopCapture];
}

- (void)initCaputreWithInterval:(NSTimeInterval)interval andDelegate:(id <IQCaptureScreenImageDataDelegate>)delegate{
  self.rect = [IQScreenHelper screenRect];
  self.timeInterval = interval;
  self.delegate = delegate;
}

- (void)startCapture{
  self.rect = [IQScreenHelper screenRect];
  
  self.timer = [NSTimer timerWithTimeInterval:self.timeInterval target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
  [self.timer fire];
}

- (void)stopCapture{
  [self.timer invalidate];
  self.timer = nil;
}

-(void)timerHandler{
  NSError *err = nil;
  NSData * data = (NSData* )[[XCUIScreen mainScreen] screenshotDataForQuality:1 rect:self.rect error:&err];
  if (!err && data) {
     [self.delegate fetchImageData:data];
  }
}

@end
