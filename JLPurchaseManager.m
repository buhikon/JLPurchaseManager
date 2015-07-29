//
//  JLPurchaseManager.m
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

#import "JLPurchaseManager.h"

@interface JLPurchaseManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    int _loadingCount;
}
@end


@implementation JLPurchaseManager

static JLPurchaseManager *instance = nil;

#pragma mark -
#pragma mark singleton

+ (JLPurchaseManager *)sharedInstance
{
    @synchronized(self)
    {
        if (!instance)
            instance = [[JLPurchaseManager alloc] init];
        
        return instance;
    }
}

#pragma mark - public methods

// AppDelegate에서 초반에 호출해야 한다.
- (void)initializeWithDelegate:(id<JLPurchaseDelegate>)delegate
{
    self.delegate = delegate;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)purchaseWithProductID:(NSString *)productID
{
    if([self canMakePayments]) {
        [self addLoading];
        NSSet *productIdentifiers = [NSSet setWithObjects:productID, nil];
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
        request.delegate = self;
        [request start];
    }
    else {
        [self.delegate JLPurchaseDidFail:[self errorWithCode:20001]];
    }
}

- (void)restoreCompletedTransactions
{
    if( [self canMakePayments] ) {
        [self addLoading];
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
}


#pragma mark - private methods

- (NSError *)errorWithCode:(NSInteger)code
{
    NSString *errorDescription = nil;
    switch (code) {
        case 20001:
            errorDescription = @"This device is not able or allowed to make payments.";
            break;
        case 20002:
            errorDescription = @"Invalid product ID.";
            break;
        case 20003:
            errorDescription = @"Failed to load list of products.";
            break;
        case 20004:
            errorDescription = @"";
            break;
        default:
            break;
    }
    
    NSDictionary *userInfo = nil;
    if(errorDescription) {
        userInfo = @{@"NSLocalizedDescriptionKey":errorDescription};
    }
    
    return [NSError errorWithDomain:@"com.github.buhikon"
                               code:code
                           userInfo:userInfo];
}

- (BOOL)canMakePayments
{
    if( [SKPaymentQueue canMakePayments] ) {
        return YES;
    }
    else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"응용 프로그램 내 구입 비활성화 됨"
                                                        message:@"구입을 하시려면 설정 어플의\n[일반] > [차단]으로 가신 후 '응용 프로그램 내 구입'을 활성화해야 합니다."
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"확인", nil];
        [alert show];
        return NO;
    }
}

- (void)addLoading
{
    if(++_loadingCount == 1) {
        [self.delegate JLPurchaseShouldShowLoading];
    }
}

- (void)removeLoading
{
    if(--_loadingCount <= 0) {
        [self.delegate JLPurchaseShouldHideLoading];
    }
    if(_loadingCount < 0) _loadingCount = 0;
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSArray *skProducts = response.products;
    if( skProducts.count > 0 ) {
        SKProduct *product = [skProducts objectAtIndex:0];
        SKPayment * payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    else {
        [self.delegate JLPurchaseDidFail:[self errorWithCode:20002]];
        [self removeLoading];
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    [self.delegate JLPurchaseDidFail:[self errorWithCode:20003]];
    [self removeLoading];
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    [self removeLoading];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    };
}

#pragma mark - 

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
    [self.delegate JLPurchaseWillFinish:transaction completion:^(BOOL success) {
        if(success) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            [self.delegate JLPurchaseDidFinish];
        }
        [self removeLoading];
    }];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    [self.delegate JLPurchaseWillFinish:transaction completion:^(BOOL success) {
        if(success) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            [self.delegate JLPurchaseDidFinish];
        }
        [self removeLoading];
    }];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    [self.delegate JLPurchaseDidFail:transaction.error];
    
    [self removeLoading];
}


@end
