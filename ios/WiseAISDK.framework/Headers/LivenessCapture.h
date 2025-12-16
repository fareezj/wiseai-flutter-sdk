//
//  LivenessCapture.h
//  WiseAISDK
//
//  Created by Nicholas Foo on 07/07/2021.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MLKitFaceDetection/MLKitFaceDetection.h>
#import <MLKitVision/MLKitVision.h>
#import "Assets.h"
#import "AppLocationManager.h"
#import <math.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LivenessCaptureDelegate <NSObject>
- (void) onLivenessCaptureCompletion;
- (void) onLivenessCaptureExceptionWithCode:(NSString *) errorCode
                         andMessage:(NSString *) errorMessage;
- (void) onLivenessCaptureExceptionWithCode:(NSString *) errorCode
                         andJsonMessage:(NSString *) errorMessage;
@end

@interface LivenessCapture : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, weak) id<LivenessCaptureDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
