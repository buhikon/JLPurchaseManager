//
//  JLPurchaseManager.h
//
//  Version 1.0.0
//
//  Created by Joey L. on 7/27/15.
//  Copyright 2015 Joey L. All rights reserved.
//
//  https://github.com/buhikon/JLPurchaseManager
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol JLPurchaseDelegate

// 여기서 서버와의 구매 통신을 하고,
// 관련된 모든 것이 완료 되었을 때 completion 블록에 YES를 넣고 호출한다. 실패했으면 NO를 넣고 호출.
// (completion 블록을 호출하지 않으면 로딩 화면이 사라지지 않으므로 주의)
- (void)JLPurchaseWillFinish:(SKPaymentTransaction *)transaction completion:(void(^)(BOOL success))completion;

- (void)JLPurchaseDidFinish;
- (void)JLPurchaseDidFail:(NSError *)error;

- (void)JLPurchaseShouldShowLoading;
- (void)JLPurchaseShouldHideLoading;

@end



@interface JLPurchaseManager : NSObject

@property (weak, nonatomic) id<JLPurchaseDelegate> delegate;

+ (JLPurchaseManager *)sharedInstance;

// AppDelegate에서 초반에 호출해야 한다.
- (void)initializeWithDelegate:(id<JLPurchaseDelegate>)delegate;

// 구매
- (void)purchaseWithProductID:(NSString *)productID;
// 구매복원
- (void)restoreCompletedTransactions;

@end
