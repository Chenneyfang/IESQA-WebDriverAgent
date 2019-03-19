//
//  IQCaptureHelper.h
//  WebDriverAgentLib
//
//  Created by cheney on 2019/3/19.
//  Copyright © 2019年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IQCaptureScreenImageDataDelegate <NSObject>

-(void)fetchImageData:(NSData *)imageData;

@end


@interface IQCaptureHelper : NSObject

+ (IQCaptureHelper *)IQCaputreWithInterval:(NSTimeInterval)interval andDelegate:(id <IQCaptureScreenImageDataDelegate>)delegate;

+ (void)startCapture;

+ (void)stopCapture;

@end


