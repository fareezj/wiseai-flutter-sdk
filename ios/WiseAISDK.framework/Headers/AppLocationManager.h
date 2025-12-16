//
//  AppLocationManager.h
//  WiseAISDK
//
//  Created by Nicholas Foo on 02/07/2021.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Assets.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppLocationManager : NSObject <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
+ (AppLocationManager*) sharedSingleton;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
@end

NS_ASSUME_NONNULL_END
