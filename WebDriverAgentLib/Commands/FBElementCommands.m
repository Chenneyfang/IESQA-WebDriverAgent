/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementCommands.h"

#import "FBSpringboardApplication.h"
#import "FBApplication.h"
#import "FBConfiguration.h"
#import "FBKeyboard.h"
#import "FBPredicate.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBRunLoopSpinner.h"
#import "FBElementCache.h"
#import "FBErrorBuilder.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "FBRuntimeUtils.h"
#import "NSPredicate+FBFormat.h"
#import "XCEventGenerator.h"
#import "XCUICoordinate.h"
#import "XCUIDevice.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBPickerWheel.h"
#import "XCUIElement+FBScrolling.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+FBForceTouch.h"
#import "XCUIElement+FBTyping.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "FBElementTypeTransformer.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"
#import "FBXCodeCompatibility.h"
#import "XCAccessibilityElement.h"
#import "XCAXClient_iOS.h"
#import <sys/utsname.h>


static int identifier = 0;
static int ACTIVE_RETRY_COUNT = 2;
static NSTimeInterval LAST_TIME_STAMP = 0;
static NSTimeInterval FIT_TIME_INTERVAL = 0.1;
const double DOUBLE_ZERO_COMPARE = 0.001;


@interface FBElementCommands ()
@end

@implementation FBElementCommands

#pragma mark - <FBCommandHandler>

+(BOOL)model:(NSString *)model inArray:(NSArray *)array{
  for (NSString *obj in array) {
    if ([obj isEqualToString:model]) {
      return YES;
    }
  }
  return NO;
}

+(CGSize)screenSize{
  
  struct utsname systemInfo;
  uname(&systemInfo);
  NSString *model =  [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
  
  if ([FBElementCommands model:model inArray:@[@"iPhone3,1", @"iPhone3,2", @"iPhone4,1"]]) {
    return  CGSizeMake(320, 480);
  }
  if ([FBElementCommands model:model inArray:@[@"iPhone5,1", @"iPhone5,2", @"iPhone5,3", @"iPhone5,4", @"iPhone6,1", @"iPhone6,2", @"iPhone8,4"]]) {
    return  CGSizeMake(320, 568);
  }
  if ([FBElementCommands model:model inArray:@[@"iPhone7,2", @"iPhone8,1", @"iPhone9,1", @"iPhone9,3", @"iPhone10,1", @"iPhone10,4"]]) {
    return  CGSizeMake(375, 667);
  }
  if ([FBElementCommands model:model inArray:@[@"iPhone7,1", @"iPhone8,2", @"iPhone9,2", @"iPhone9,4", @"iPhone10,2", @"iPhone10,5"]]) {
    return  CGSizeMake(414, 736);
  }
  if ([FBElementCommands model:model inArray:@[@"iPhone10,3", @"iPhone10,6", @"iPhone11,2"]]) {
    return  CGSizeMake(375, 812);
  }
  if ([FBElementCommands model:model inArray:@[@"iPhone11,8"]]) {
    return CGSizeMake(413, 896);
  }
  if ([FBElementCommands model:model inArray:@[@"iPhone11,6"]]) {
    return CGSizeMake(414, 896);
  }
  return CGSizeZero;
}

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/window/size"] respondWithTarget:self action:@selector(handleGetWindowSize:)],
    [[FBRoute GET:@"/element/:uuid/enabled"] respondWithTarget:self action:@selector(handleGetEnabled:)],
    [[FBRoute GET:@"/element/:uuid/rect"] respondWithTarget:self action:@selector(handleGetRect:)],
    [[FBRoute GET:@"/element/:uuid/attribute/:name"] respondWithTarget:self action:@selector(handleGetAttribute:)],
    [[FBRoute GET:@"/element/:uuid/text"] respondWithTarget:self action:@selector(handleGetText:)],
    [[FBRoute GET:@"/element/:uuid/displayed"] respondWithTarget:self action:@selector(handleGetDisplayed:)],
    [[FBRoute GET:@"/element/:uuid/name"] respondWithTarget:self action:@selector(handleGetName:)],
    [[FBRoute POST:@"/element/:uuid/value"] respondWithTarget:self action:@selector(handleSetValue:)],
    [[FBRoute POST:@"/element/:uuid/click"] respondWithTarget:self action:@selector(handleClick:)],
    [[FBRoute POST:@"/element/:uuid/clear"] respondWithTarget:self action:@selector(handleClear:)],
    [[FBRoute GET:@"/element/:uuid/screenshot"] respondWithTarget:self action:@selector(handleElementScreenshot:)],
    [[FBRoute GET:@"/wda/element/:uuid/accessible"] respondWithTarget:self action:@selector(handleGetAccessible:)],
    [[FBRoute GET:@"/wda/element/:uuid/accessibilityContainer"] respondWithTarget:self action:@selector(handleGetIsAccessibilityContainer:)],
    [[FBRoute POST:@"/wda/element/:uuid/swipe"] respondWithTarget:self action:@selector(handleSwipe:)],
    [[FBRoute POST:@"/wda/element/:uuid/pinch"] respondWithTarget:self action:@selector(handlePinch:)],
    [[FBRoute POST:@"/wda/element/:uuid/doubleTap"] respondWithTarget:self action:@selector(handleDoubleTap:)],
    [[FBRoute POST:@"/wda/element/:uuid/twoFingerTap"] respondWithTarget:self action:@selector(handleTwoFingerTap:)],
    [[FBRoute POST:@"/wda/element/:uuid/touchAndHold"] respondWithTarget:self action:@selector(handleTouchAndHold:)],
    [[FBRoute POST:@"/wda/element/:uuid/scroll"] respondWithTarget:self action:@selector(handleScroll:)],
    [[FBRoute POST:@"/wda/element/:uuid/dragfromtoforduration"] respondWithTarget:self action:@selector(handleDrag:)],
    [[FBRoute POST:@"/wda/dragfromtoforduration"] respondWithTarget:self action:@selector(handleDragCoordinate:)],
    [[FBRoute POST:@"/wda/tap/:uuid"] respondWithTarget:self action:@selector(handleTap:)],
    [[FBRoute POST:@"/wda/touchAndHold"] respondWithTarget:self action:@selector(handleTouchAndHoldCoordinate:)],
    [[FBRoute POST:@"/wda/doubleTap"] respondWithTarget:self action:@selector(handleDoubleTapCoordinate:)],
    [[FBRoute POST:@"/wda/keys"] respondWithTarget:self action:@selector(handleKeys:)],
    [[FBRoute POST:@"/wda/pickerwheel/:uuid/select"] respondWithTarget:self action:@selector(handleWheelSelect:)],
    [[FBRoute POST:@"/wda/element/forceTouch/:uuid"] respondWithTarget:self action:@selector(handleForceTouch:)],
    [[FBRoute POST:@"/wda/element/forceTouchByCoordinate/:uuid"] respondWithTarget:self action:@selector(handleForceTouchByCoordinateOnElement:)],
    [[FBRoute POST:@"/keepIdentifier"] respondWithTarget:self action:@selector(handleKeepCommand:)],
    [[FBRoute POST:@"/activeApp"] respondWithTarget:self action:@selector(handleActiveCommand:)],
    [[FBRoute POST:@"/goHome"] respondWithTarget:self action:@selector(handlegoHomeCommand:)],
    [[FBRoute POST:@"/tapCenter"] respondWithTarget:self action:@selector(handlTapScreenCenter:)]
    ];
}


+ (int)currentIdentifier{
  NSArray *arrays =[[XCAXClient_iOS sharedClient] activeApplications];
  XCAccessibilityElement *activeApplicationElement = [arrays firstObject];
  return activeApplicationElement.processIdentifier;
}

+ (BOOL)tryToActiveApp{
  int count = 0;
  while(count < ACTIVE_RETRY_COUNT){
    
    [[FBSpringboardApplication fb_springboard] fb_tapApplicationWithIdentifier:@"抖音短视频内测" error:nil];
    if ([self currentIdentifier] == identifier) {
      return YES;
    }
    count++;
  }
  return NO;
}

+ (id<FBResponsePayload>)handleKeepCommand:(FBRouteRequest *)request
{
  identifier = [self currentIdentifier];
  
  
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleActiveCommand:(FBRouteRequest *)request
{
  if (identifier == [self currentIdentifier]) {
    return FBResponseWithOK();
  }
  NSTimeInterval currentTimeStamp = [[NSDate date] timeIntervalSince1970];
  if ((currentTimeStamp - LAST_TIME_STAMP) > FIT_TIME_INTERVAL) {       // 这个方法会连续调用三次，在这个地方特殊处理，100ms内连续请求认为是重复回调。
    [self tryToActiveApp];
    LAST_TIME_STAMP = [[NSDate date] timeIntervalSince1970];
  }
  
  return FBResponseWithOK();
  
}

+ (id<FBResponsePayload>)handlegoHomeCommand:(FBRouteRequest *)request
{
  [[XCUIDevice sharedDevice] fb_goToHomescreenWithError:nil];
  return FBResponseWithOK();
}



#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetEnabled:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  BOOL isEnabled = element.isWDEnabled;
  return FBResponseWithStatus(FBCommandStatusNoError, isEnabled ? @YES : @NO);
}

+ (id<FBResponsePayload>)handleGetRect:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  return FBResponseWithStatus(FBCommandStatusNoError, element.wdRect);
}

+ (id<FBResponsePayload>)handleGetAttribute:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  id attributeValue = [element fb_valueForWDAttributeName:request.parameters[@"name"]];
  attributeValue = attributeValue ?: [NSNull null];
  return FBResponseWithStatus(FBCommandStatusNoError, attributeValue);
}

+ (id<FBResponsePayload>)handleGetText:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  id text = FBFirstNonEmptyValue(element.wdValue, element.wdLabel);
  text = text ?: [NSNull null];
  return FBResponseWithStatus(FBCommandStatusNoError, text);
}

+ (id<FBResponsePayload>)handleGetDisplayed:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  BOOL isVisible = element.isWDVisible;
  return FBResponseWithStatus(FBCommandStatusNoError, isVisible ? @YES : @NO);
}

+ (id<FBResponsePayload>)handleGetAccessible:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  return FBResponseWithStatus(FBCommandStatusNoError, @(element.isWDAccessible));
}

+ (id<FBResponsePayload>)handleGetIsAccessibilityContainer:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  return FBResponseWithStatus(FBCommandStatusNoError, @(element.isWDAccessibilityContainer));
}

+ (id<FBResponsePayload>)handleGetName:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  id type = [element wdType];
  return FBResponseWithStatus(FBCommandStatusNoError, type);
}

+ (id<FBResponsePayload>)handleSetValue:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSString *elementUUID = request.parameters[@"uuid"];
  XCUIElement *element = [elementCache elementForUUID:elementUUID];
  id value = request.arguments[@"value"];
  if (!value) {
    return FBResponseWithErrorFormat(@"Missing 'value' parameter");
  }
  NSString *textToType = value;
  if ([value isKindOfClass:[NSArray class]]) {
    textToType = [value componentsJoinedByString:@""];
  }
  if (element.elementType == XCUIElementTypePickerWheel) {
    [element adjustToPickerWheelValue:textToType];
    return FBResponseWithOK();
  }
  if (element.elementType == XCUIElementTypeSlider) {
    CGFloat sliderValue = textToType.floatValue;
    if (sliderValue < 0.0 || sliderValue > 1.0 ) {
      return FBResponseWithErrorFormat(@"Value of slider should be in 0..1 range");
    }
    [element adjustToNormalizedSliderPosition:sliderValue];
    return FBResponseWithOK();
  }
  NSUInteger frequency = (NSUInteger)[request.arguments[@"frequency"] longLongValue] ?: [FBConfiguration maxTypingFrequency];
  NSError *error = nil;
  if (![element fb_typeText:textToType frequency:frequency error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithElementUUID(elementUUID);
}

+ (id<FBResponsePayload>)handleClick:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSString *elementUUID = request.parameters[@"uuid"];
  XCUIElement *element = [elementCache elementForUUID:elementUUID];
  NSError *error = nil;
  if (![element fb_tapWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithElementUUID(elementUUID);
}

+ (id<FBResponsePayload>)handleClear:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSString *elementUUID = request.parameters[@"uuid"];
  XCUIElement *element = [elementCache elementForUUID:elementUUID];
  NSError *error;
  if (![element fb_clearTextWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithElementUUID(elementUUID);
}

+ (id<FBResponsePayload>)handleDoubleTap:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  [element doubleTap];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDoubleTapCoordinate:(FBRouteRequest *)request
{
  CGPoint doubleTapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  XCUICoordinate *doubleTapCoordinate = [self.class gestureCoordinateWithCoordinate:doubleTapPoint application:request.session.application shouldApplyOrientationWorkaround:isSDKVersionLessThan(@"11.0")];
  [doubleTapCoordinate doubleTap];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTwoFingerTap:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  [element twoFingerTap];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTouchAndHold:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  [element pressForDuration:[request.arguments[@"duration"] doubleValue]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTouchAndHoldCoordinate:(FBRouteRequest *)request
{
  CGPoint touchPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  XCUICoordinate *pressCoordinate = [self.class gestureCoordinateWithCoordinate:touchPoint application:request.session.application shouldApplyOrientationWorkaround:isSDKVersionLessThan(@"11.0")];
  [pressCoordinate pressForDuration:[request.arguments[@"duration"] doubleValue]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleForceTouch:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  double pressure = [request.arguments[@"pressure"] doubleValue];
  double duration = [request.arguments[@"duration"] doubleValue];
  NSError *error = nil;
  if (![element fb_forceTouchWithPressure:pressure duration:duration error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleForceTouchByCoordinateOnElement:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  double pressure = [request.arguments[@"pressure"] doubleValue];
  double duration = [request.arguments[@"duration"] doubleValue];
  CGPoint forceTouchPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  NSError *error = nil;
  if (![element fb_forceTouchCoordinate:forceTouchPoint pressure:pressure duration:duration error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleScroll:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  
  // Using presence of arguments as a way to convey control flow seems like a pretty bad idea but it's
  // what ios-driver did and sadly, we must copy them.
  NSString *const name = request.arguments[@"name"];
  if (name) {
    XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingIdentifier:name] allElementsBoundByIndex] lastObject];
    if (!childElement) {
      return FBResponseWithErrorFormat(@"'%@' identifier didn't match any elements", name);
    }
    return [self.class handleScrollElementToVisible:childElement withRequest:request];
  }
  
  NSString *const direction = request.arguments[@"direction"];
  if (direction) {
    NSString *const distanceString = request.arguments[@"distance"] ?: @"1.0";
    CGFloat distance = (CGFloat)distanceString.doubleValue;
    if ([direction isEqualToString:@"up"]) {
      [element fb_scrollUpByNormalizedDistance:distance];
    } else if ([direction isEqualToString:@"down"]) {
      [element fb_scrollDownByNormalizedDistance:distance];
    } else if ([direction isEqualToString:@"left"]) {
      [element fb_scrollLeftByNormalizedDistance:distance];
    } else if ([direction isEqualToString:@"right"]) {
      [element fb_scrollRightByNormalizedDistance:distance];
    }
    return FBResponseWithOK();
  }
  
  NSString *const predicateString = request.arguments[@"predicateString"];
  if (predicateString) {
    NSPredicate *formattedPredicate = [NSPredicate fb_formatSearchPredicate:[FBPredicate predicateWithFormat:predicateString]];
    XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:formattedPredicate] allElementsBoundByIndex] lastObject];
    if (!childElement) {
      return FBResponseWithErrorFormat(@"'%@' predicate didn't match any elements", predicateString);
    }
    return [self.class handleScrollElementToVisible:childElement withRequest:request];
  }
  
  if (request.arguments[@"toVisible"]) {
    return [self.class handleScrollElementToVisible:element withRequest:request];
  }
  return FBResponseWithErrorFormat(@"Unsupported scroll type");
}


+ (id<FBResponsePayload>)handlTapScreenCenter:(FBRouteRequest *)request{
  CGRect rect = [[UIScreen mainScreen] bounds];
  CGPoint center = CGPointMake(rect.size.width / 2, rect.size.height / 2);
  [[XCEventGenerator sharedGenerator]pressAtPoint:center forDuration:0.1 orientation:UIInterfaceOrientationUnknown handler:^(XCSynthesizedEventRecord *record, NSError *error) {
    [FBLogger verboseLog:error.description];
  }];
  
  return FBResponseWithOK();
  
  
}
+ (id<FBResponsePayload>)handleDragCoordinate:(FBRouteRequest *)request
{
  //FBSession *session = request.session;
  NSTimeInterval duration = (NSTimeInterval)[request.arguments[@"duration"] doubleValue];
  if ((duration - 0) < DOUBLE_ZERO_COMPARE ) {
    duration = 1;
  }
//  CGPoint startPoint = CGPointMake((CGFloat)[request.arguments[@"fromX"] doubleValue], (CGFloat)[request.arguments[@"fromY"] doubleValue]);
//  CGPoint endPoint = CGPointMake((CGFloat)[request.arguments[@"toX"] doubleValue], (CGFloat)[request.arguments[@"toY"] doubleValue]);
  
  CGSize size = [self screenSize];
  double start_x_offset = (double)[request.arguments[@"fromX"] doubleValue];
  double start_y_offset = (double)[request.arguments[@"fromY"] doubleValue];
  
  double end_x_offset = (double)[request.arguments[@"toX"] doubleValue];
  double end_y_offset = (double)[request.arguments[@"toY"] doubleValue];
  
  CGPoint startPoint = CGPointMake(start_x_offset * size.width, start_y_offset * size.height);
  CGPoint endPoint = CGPointMake(end_x_offset * size.width, end_y_offset * size.height);
  
  [[XCEventGenerator sharedGenerator] pressAtPoint:startPoint forDuration:0 liftAtPoint:endPoint velocity: (5000/duration)  orientation:UIInterfaceOrientationUnknown name:nil handler:^(XCSynthesizedEventRecord *record, NSError *error) {
    [FBLogger verboseLog:error.description];
  }];
  
  
  
  return FBResponseWithOK();
  //  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  //  NSTimeInterval velocity = 1 / duration * 500;
  
  //  XCUICoordinate *endCoordinate = [self.class gestureCoordinateWithCoordinate:endPoint application:session.application shouldApplyOrientationWorkaround:isSDKVersionLessThan(@"11.0")];
  //  XCUICoordinate *startCoordinate = [self.class gestureCoordinateWithCoordinate:startPoint application:session.application shouldApplyOrientationWorkaround:isSDKVersionLessThan(@"11.0")];
  //  [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
  //
  //  XCAccessibilityElement *activeApplicationElement = [[[XCAXClient_iOS sharedClient] activeApplications] firstObject];
  //
  //  FBApplication *application = [FBApplication fb_applicationWithPID:activeApplicationElement.processIdentifier];
  //  NSArray *array = [application childrenMatchingType:XCUIElementTypeAny];
  //  if (array) {
  //
  //  }
  //  if (application) {
  //    NSLog(@"%ld",application.accessibilityElements.count);
  //  }
  
  // [[FBSpringboardApplication fb_springboard] fb_tapApplicationWithIdentifier:@"抖音短视频内测" error:nil];
  
}


+ (id<FBResponsePayload>)handleDrag:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  FBElementCache *elementCache = session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  CGPoint startPoint = CGPointMake((CGFloat)(element.frame.origin.x + [request.arguments[@"fromX"] doubleValue]), (CGFloat)(element.frame.origin.y + [request.arguments[@"fromY"] doubleValue]));
  CGPoint endPoint = CGPointMake((CGFloat)(element.frame.origin.x + [request.arguments[@"toX"] doubleValue]), (CGFloat)(element.frame.origin.y + [request.arguments[@"toY"] doubleValue]));
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  BOOL shouldApplyOrientationWorkaround = isSDKVersionGreaterThanOrEqualTo(@"10.0") && isSDKVersionLessThan(@"11.0");
  XCUICoordinate *endCoordinate = [self.class gestureCoordinateWithCoordinate:endPoint application:session.application shouldApplyOrientationWorkaround:shouldApplyOrientationWorkaround];
  XCUICoordinate *startCoordinate = [self.class gestureCoordinateWithCoordinate:startPoint application:session.application shouldApplyOrientationWorkaround:shouldApplyOrientationWorkaround];
  [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleSwipe:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  NSString *const direction = request.arguments[@"direction"];
  if (!direction) {
    return FBResponseWithErrorFormat(@"Missing 'direction' parameter");
  }
  if ([direction isEqualToString:@"up"]) {
    [element swipeUp];
  } else if ([direction isEqualToString:@"down"]) {
    [element swipeDown];
  } else if ([direction isEqualToString:@"left"]) {
    [element swipeLeft];
  } else if ([direction isEqualToString:@"right"]) {
    [element swipeRight];
  } else {
    return FBResponseWithErrorFormat(@"Unsupported swipe type");
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTap:(FBRouteRequest *)request
{
  //FBElementCache *elementCache = request.session.elementCache;
  
  double x_offset = (CGFloat)[request.arguments[@"x"] doubleValue];
  double y_offset = (CGFloat)[request.arguments[@"y"] doubleValue];
  CGSize size = [self screenSize];
  CGPoint tapPoint = CGPointMake(x_offset * size.width, y_offset * size.height);
  
  //CGPoint tapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  //  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  //  if (nil == element) {
  //    XCUICoordinate *tapCoordinate = [self.class gestureCoordinateWithCoordinate:tapPoint application:request.session.application shouldApplyOrientationWorkaround:isSDKVersionLessThan(@"11.0")];
  //    [tapCoordinate tap];
  //  } else {
  //    NSError *error;
  //    if (![element fb_tapCoordinate:tapPoint error:&error]) {
  //      return FBResponseWithError(error);
  //    }
  //  }
  [[XCEventGenerator sharedGenerator]pressAtPoint:tapPoint forDuration:0.1 orientation:UIInterfaceOrientationUnknown handler:^(XCSynthesizedEventRecord *record, NSError *error) {
    [FBLogger verboseLog:error.description];
  }];
  
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handlePinch:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  CGFloat scale = (CGFloat)[request.arguments[@"scale"] doubleValue];
  CGFloat velocity = (CGFloat)[request.arguments[@"velocity"] doubleValue];
  [element pinchWithScale:scale velocity:velocity];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleKeys:(FBRouteRequest *)request
{
  NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
  NSUInteger frequency = [request.arguments[@"frequency"] unsignedIntegerValue] ?: [FBConfiguration maxTypingFrequency];
  NSError *error;
  if (![FBKeyboard typeText:textToType frequency:frequency error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleGetWindowSize:(FBRouteRequest *)request
{
  CGRect frame = request.session.application.wdFrame;
  CGSize screenSize = FBAdjustDimensionsForApplication(frame.size, request.session.application.interfaceOrientation);
  return FBResponseWithStatus(FBCommandStatusNoError, @{
                                                        @"width": @(screenSize.width),
                                                        @"height": @(screenSize.height),
                                                        });
}

+ (id<FBResponsePayload>)handleElementScreenshot:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  NSError *error;
  NSData *screenshotData = [element fb_screenshotWithError:&error];
  if (nil == screenshotData) {
    return FBResponseWithError(error);
  }
  NSString *screenshot = [screenshotData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return FBResponseWithObject(screenshot);
}

static const CGFloat DEFAULT_OFFSET = (CGFloat)0.2;

+ (id<FBResponsePayload>)handleWheelSelect:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  if (element.elementType != XCUIElementTypePickerWheel) {
    return FBResponseWithErrorFormat(@"The element is expected to be a valid Picker Wheel control. '%@' was given instead", element.wdType);
  }
  NSString* order = [request.arguments[@"order"] lowercaseString];
  CGFloat offset = DEFAULT_OFFSET;
  if (request.arguments[@"offset"]) {
    offset = (CGFloat)[request.arguments[@"offset"] doubleValue];
    if (offset <= 0.0 || offset > 0.5) {
      return FBResponseWithErrorFormat(@"'offset' value is expected to be in range (0.0, 0.5]. '%@' was given instead", request.arguments[@"offset"]);
    }
  }
  BOOL isSuccessful = false;
  NSError *error;
  if ([order isEqualToString:@"next"]) {
    isSuccessful = [element fb_selectNextOptionWithOffset:offset error:&error];
  } else if ([order isEqualToString:@"previous"]) {
    isSuccessful = [element fb_selectPreviousOptionWithOffset:offset error:&error];
  } else {
    return FBResponseWithErrorFormat(@"Only 'previous' and 'next' order values are supported. '%@' was given instead", request.arguments[@"order"]);
  }
  if (!isSuccessful) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

#pragma mark - Helpers

+ (id<FBResponsePayload>)handleScrollElementToVisible:(XCUIElement *)element withRequest:(FBRouteRequest *)request
{
  NSError *error;
  if (!element.exists) {
    return FBResponseWithErrorFormat(@"Can't scroll to element that does not exist");
  }
  if (![element fb_scrollToVisibleWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

/**
 Returns gesture coordinate for the application based on absolute coordinate
 
 @param coordinate absolute screen coordinates
 @param application the instance of current application under test
 @shouldApplyOrientationWorkaround whether to apply orientation workaround. This is to
 handle XCTest bug where it does not translate screen coordinates for elements if
 screen orientation is different from the default one (which is portrait).
 Different iOS version have different behavior, for example iOS 9.3 returns correct
 coordinates for elements in landscape, but iOS 10.0+ returns inverted coordinates as if
 the current screen orientation would be portrait.
 @return translated gesture coordinates ready to be passed to XCUICoordinate methods
 */
+ (XCUICoordinate *)gestureCoordinateWithCoordinate:(CGPoint)coordinate application:(XCUIApplication *)application shouldApplyOrientationWorkaround:(BOOL)shouldApplyOrientationWorkaround
{
  CGPoint point = coordinate;
  if (shouldApplyOrientationWorkaround) {
    point = FBInvertPointForApplication(coordinate, application.frame.size, application.interfaceOrientation);
  }
  
  /**
   If SDK >= 11, the tap coordinate based on application is not correct when
   the application orientation is landscape and
   tapX > application portrait width or tapY > application portrait height.
   Pass the window element to the method [FBElementCommands gestureCoordinateWithCoordinate:element:]
   will resolve the problem.
   More details about the bug, please see the following issues:
   #705: https://github.com/facebook/WebDriverAgent/issues/705
   #798: https://github.com/facebook/WebDriverAgent/issues/798
   #856: https://github.com/facebook/WebDriverAgent/issues/856
   Notice: On iOS 10, if the application is not launched by wda, no elements will be found.
   See issue #732: https://github.com/facebook/WebDriverAgent/issues/732
   */
  XCUIElement *element = application;
  if (isSDKVersionGreaterThanOrEqualTo(@"11.0")) {
    XCUIElement *window = application.windows.fb_firstMatch;
    if (window) {
      element = window;
      point.x -= element.frame.origin.x;
      point.y -= element.frame.origin.y;
    }
  }
  return [self gestureCoordinateWithCoordinate:point element:element];
}

/**
 Returns gesture coordinate based on the specified element.
 
 @param coordinate absolute coordinates based on the element
 @param element the element in the current application under test
 @return translated gesture coordinates ready to be passed to XCUICoordinate methods
 */
+ (XCUICoordinate *)gestureCoordinateWithCoordinate:(CGPoint)coordinate element:(XCUIElement *)element
{
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:element normalizedOffset:CGVectorMake(0, 0)];
  return [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:CGVectorMake(coordinate.x, coordinate.y)];
}

@end

