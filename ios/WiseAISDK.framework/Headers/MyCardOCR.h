//
//  MyCardOCR.h
//  WiseAISDK
//
//  Created by JPCHOI on 27/02/2021.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Assets.h"
#import "AppLocationManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MyCardOCRDelegate <NSObject>
- (void) onOCRCaptureCompletion;
- (void) onOCRCaptureFailed;
- (void) onOCRCaptureDismissed;
- (void) onOCRCaptureExceptionWithCode:(NSString *) errorCode
                         andMessage:(NSString *) errorMessage;
- (void) onOCRCaptureExceptionWithCode:(NSString *) errorCode
                         andJsonMessage:(NSString *) errorMessage;
@end

@interface MyCardOCR : UIViewController <AVCapturePhotoCaptureDelegate, MyCardOCRDelegate>
@property (nonatomic, weak) id<MyCardOCRDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
