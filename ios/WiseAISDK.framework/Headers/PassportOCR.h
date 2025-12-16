//
//  PassportOCR.h
//  WiseAISDK
//
//  Created by JPCHOI on 08/04/2021.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Assets.h"
#import "AppLocationManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PassportOCRDelegate <NSObject>
- (void) onPassportOCRCaptureCompletion;
- (void) onPassportOCRCaptureFailed;
- (void) onPassportOCRCaptureExceptionWithCode:(NSString *) errorCode
                         andMessage:(NSString *) errorMessage;
- (void) onPassportOCRCaptureExceptionWithCode:(NSString *) errorCode
                         andJsonMessage:(NSString *) errorMessage;
@end

@interface PassportOCR : UIViewController <AVCapturePhotoCaptureDelegate, PassportOCRDelegate>
@property (nonatomic, weak) id<PassportOCRDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
