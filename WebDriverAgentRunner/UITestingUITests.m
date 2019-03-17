/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>


#import <WebDriverAgentLib/FBDebugLogDelegateDecorator.h>
#import <WebDriverAgentLib/FBConfiguration.h>
#import <WebDriverAgentLib/FBFailureProofTestCase.h>
#import <WebDriverAgentLib/FBWebServer.h>
#import <WebDriverAgentLib/XCTestCase.h>
#import <sys/utsname.h>

typedef NS_ENUM(NSUInteger, IPHONE_RESOLUTION_TYPE) {
  Resolution_Type_A,   // 320 * 480
  Resolution_Type_B,   // 375 * 667
  Resolution_Type_C,   // 414 * 736
  Resolution_Type_D    // 413 * 896
};


@interface UITestingUITests : FBFailureProofTestCase <FBWebServerDelegate>
@end

@implementation UITestingUITests

-(BOOL)model:(NSString *)model inArray:(NSArray *)array{
  for (NSString *obj in array) {
    if ([obj isEqualToString:model]) {
      return YES;
    }
  }
  return NO;
}

-(CGSize)screenSize{
  
  struct utsname systemInfo;
  uname(&systemInfo);
  NSString *model =  [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

  if ([self model:model inArray:@[@"iPhone3,1", @"iPhone3,2", @"iPhone4,1"]]) {
    return  CGSizeMake(320, 480);
  }
  if ([self model:model inArray:@[@"iPhone5,1", @"iPhone5,2", @"iPhone5,3", @"iPhone5,4", @"iPhone6,1", @"iPhone6,2", @"iPhone8,4"]]) {
    return  CGSizeMake(320, 568);
  }
  if ([self model:model inArray:@[@"iPhone7,2", @"iPhone8,1", @"iPhone9,1", @"iPhone9,3", @"iPhone10,1", @"iPhone10,4"]]) {
    return  CGSizeMake(375, 667);
  }
  if ([self model:model inArray:@[@"iPhone7,1", @"iPhone8,2", @"iPhone9,2", @"iPhone9,4", @"iPhone10,2", @"iPhone10,5"]]) {
    return  CGSizeMake(414, 736);
  }
  if ([self model:model inArray:@[@"iPhone10,3", @"iPhone10,6", @"iPhone11,2"]]) {
    return  CGSizeMake(375, 812);
  }
  if ([self model:model inArray:@[@"iPhone11,8"]]) {
    return CGSizeMake(413, 896);
  }
  if ([self model:model inArray:@[@"iPhone11,6"]]) {
    return CGSizeMake(414, 896);
  }
  return CGSizeZero;
}

+ (void)setUp
{
  [FBDebugLogDelegateDecorator decorateXCTestLogger];
  [FBConfiguration disableRemoteQueryEvaluation];
  [super setUp];
}

/**
 Never ending test used to start WebDriverAgent
 */
- (void)testRunner
{
  FBWebServer *webServer = [[FBWebServer alloc] init];
  webServer.delegate = self;
  [webServer startServing];
}


#pragma mark - FBWebServerDelegate

- (void)webServerDidRequestShutdown:(FBWebServer *)webServer
{
  [webServer stopServing];
}

@end
