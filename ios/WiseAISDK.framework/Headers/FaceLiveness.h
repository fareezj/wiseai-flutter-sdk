//
//  FaceLiveness.h
//  WiseAISDK
//
//  Created by JPCHOI on 28/02/2021.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MLKitFaceDetection/MLKitFaceDetection.h>
#import <MLKitVision/MLKitVision.h>
#import "Assets.h"
#import "AppLocationManager.h"

NS_ASSUME_NONNULL_BEGIN
@protocol FaceLivenessDelegate <NSObject>
- (void) onFaceCaptureCompletion;
- (void) onFaceCaptureDismissed;
- (void) onFaceCaptureExceptionWithCode:(NSString *) errorCode
                         andMessage:(NSString *) errorMessage;
- (void) onFaceCaptureExceptionWithCode:(NSString *) errorCode
                         andJsonMessage:(NSString *) errorMessage;
@end

@interface FaceLiveness : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, weak) id<FaceLivenessDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
