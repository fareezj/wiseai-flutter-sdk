//
//  Ekyc.h
//  WiseAISDK
//
//  Created by JPCHOI on 27/02/2021.
//

#import <UIKit/UIKit.h>

#import "MyCardOCR.h"
#import "AppLocationManager.h"

NS_ASSUME_NONNULL_BEGIN
@protocol EkycDelegate <NSObject>
- (void) onEkycComplete:(NSString *) jsonResult;
- (void) onEkycException:(NSString *) jsonResult;
@end

@interface Ekyc : UIViewController <MyCardOCRDelegate>
@property (nonatomic, weak) id<EkycDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
