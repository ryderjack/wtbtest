//
//  JRMessage.h
//  wtbtest
//
//  Created by Jack Ryder on 22/09/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "JSQMessagesViewController.h"
//#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "JSQMessages.h"
#import <Parse/Parse.h>

@interface JRMessage : JSQMessage

@property (nonatomic, strong) PFObject *offerObject;

@property (assign, nonatomic) BOOL isOfferMessage;

// returns whether an offer is waiting seller confirmation
@property (nonatomic) BOOL isWaiting;

@property (nonatomic) BOOL isPurchased;

@property (nonatomic) BOOL isShared;

@property (nonatomic) BOOL isPayPal;

@property (nonatomic, strong) PFObject *sharedListing;

@property (nonatomic) BOOL saleShare;

@property (nonatomic, strong) PFObject *msgObject;
@end
