//
//  OrderSummaryView.m
//  wtbtest
//
//  Created by Jack Ryder on 12/10/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "OrderSummaryView.h"
#import "MessageViewController.h"
#import "ForSaleListing.h"
#import <Crashlytics/Crashlytics.h>
#import "UserProfileController.h"
#import "ChatWithBump.h"
#import "UIImageView+Letters.h"
#import "ReviewsVC.h"
#import <Intercom/Intercom.h>
#import "supportVC.h"
#import "supportAnswerVC.h"

@interface OrderSummaryView ()

@end

@implementation OrderSummaryView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //do order status label at the top then test with a new order object!
    
    //order of steps
    
    //buyer just needs to leave feedback, then wait for shipping and feedback -> complete
    //seller needs to mark as shipped and leave feedback
    
    self.title = @"O R D E R";
    
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor=0.5;
    
    self.transCellHeight = 213;
    self.titleCellHeight = 198;
    self.gotFBCellHeight = 181;
    self.leftFBCellHeight = 181;
    self.leaveFBCellHeight = 195;
    self.paymentCellHeight = 366;
    self.shippingCellHeight =326;
    
    self.rowNumber = 5;
    
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dotsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(showActionSheet)];
    self.navigationItem.rightBarButtonItem = helpButton;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.paymentCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.shippingCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.gotFeedbackCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.leftFeedbackCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.leaveFeedbackCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.transactionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buyerPaymentCell.selectionStyle = UITableViewCellSelectionStyleNone;

    [self cropProfilePic];
    
    //setup cells
    
    [self.orderObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            
            self.title = [NSString stringWithFormat:@"#%@", [self.orderObject.objectId uppercaseString]];
            
            self.dateFormat = [[NSDateFormatter alloc] init];
            [self.dateFormat setLocale:[NSLocale currentLocale]];
            [self.dateFormat setDateFormat:@"dd MMM YYYY"];
            NSString *orderDateString = [self.dateFormat stringFromDate:self.orderObject.createdAt];
            
            if ([[self.orderObject objectForKey:@"relisted"]isEqualToString:@"YES"]) {
                self.itemRelisted = YES;
            }
            
            if ([[self.orderObject objectForKey:@"buyerId"]isEqualToString:[PFUser currentUser].objectId]) {
                self.isBuyer = YES;
                
                //show buyer simplified payment cell
                self.paymentCellHeight = 326;
            }
            
            if ([[self.orderObject objectForKey:@"status"] isEqualToString:@"pending"]) {
                self.paymentPending = YES;
                self.rowNumber = 3;
                [self showAlertWithTitle:@"Payment Pending" andMsg:@"PayPal is busy processing your payment. In the meantime we've reserved the item for you - check back here shortly for order updates. If the payment is pending for over 15 minutes then please contact support from this page and we'll quickly sort it out"];
                [self.messageButton setHidden:YES];
                [self.refundButton setHidden:YES];
                [self.buyerRefundButton setHidden:YES];
            }
            else if ([[self.orderObject objectForKey:@"status"] isEqualToString:@"failed"]) {
                
                self.paymentFailed = YES;
                self.rowNumber = 3;
                [self showAlertWithTitle:@"Order Cancelled" andMsg:@"PayPal was unable to process your payment so the order was cancelled. You have NOT been charged and the item has been made available for sale again. You can attempt to purchase the item again. If the problem persists please contact support"];
                [self.messageButton setHidden:YES];
                [self.refundButton setHidden:YES];
                [self.buyerRefundButton setHidden:YES];
            }
            
            //listing cell
            //get correct size label
            //check if has size
            self.titleLabel.text = [NSString stringWithFormat:@"%@\n%@",[self.orderObject objectForKey:@"itemTitle"],[self.orderObject objectForKey:@"itemSize"]];
            [self.itemImageView setFile:[self.orderObject objectForKey:@"itemImage"]];
            [self.itemImageView loadInBackground];
            
            if (self.isBuyer) {
                self.otherUser = [self.orderObject objectForKey:@"sellerUser"];
            }
            else{
                self.otherUser = [self.orderObject objectForKey:@"buyerUser"];
            }
            
            [self.otherUser fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    NSLog(@"fetched other user");
                    
                    self.fetchedUser = YES;
                    
                    //other user info
                    if(![self.otherUser objectForKey:@"picture"]){
                        
                        NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                                        NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
                        
                        [self.otherUserImageView setImageWithString:self.otherUser.username color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
                    }
                    else{
                        [self.otherUserImageView setFile:[self.otherUser objectForKey:@"picture"]];
                        [self.otherUserImageView loadInBackground];
                    }
                    
                    NSString *transText;
                    
                    if (self.isBuyer) {
                        
                        if (self.paymentPending) {
                            transText = [NSString stringWithFormat:@"Order placed on %@ from\n%@\n@%@",orderDateString,[self.otherUser objectForKey:@"fullname"],self.otherUser.username];
                        }
                        else if(self.paymentFailed){
                            transText = [NSString stringWithFormat:@"Purchase failed on %@ from\n%@\n@%@",orderDateString,[self.otherUser objectForKey:@"fullname"],self.otherUser.username];
                        }
                        else{
                            transText = [NSString stringWithFormat:@"Purchased on %@ from\n%@\n@%@",orderDateString,[self.otherUser objectForKey:@"fullname"],self.otherUser.username];
                        }
                        
                        [self.messageButton setTitle:@"Message Seller" forState:UIControlStateNormal];
                        
                        //setup username of guy left / was left feedback
                        if ([[self.orderObject objectForKey:@"buyerLeftFeedback"] isEqualToString:@"YES"]) {
                            //this user left a review
                            NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"You left feedback for\n@%@", self.otherUser.username]];
                            [self.leftFeedbackLabel setAttributedText:[self modifyString:labelText setFontForText:[NSString stringWithFormat:@"@%@", self.otherUser.username]]];
                        }
                        
                        if ([[self.orderObject objectForKey:@"sellerLeftFeedback"] isEqualToString:@"YES"]) {
                            NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"@%@\n left you feedback", self.otherUser.username]];
                            [self.gotFeedbackLabel setAttributedText:[self modifyString:labelText setFontForText:[NSString stringWithFormat:@"@%@", self.otherUser.username]]];
                        }
                        
                    }
                    else{
                        transText = [NSString stringWithFormat:@"Sold on %@ to\n%@\n@%@",orderDateString,[self.otherUser objectForKey:@"fullname"],self.otherUser.username];
                        [self.messageButton setTitle:@"Message Buyer" forState:UIControlStateNormal];
                        
                        //setup username of guy left / was left feedback
                        if ([[self.orderObject objectForKey:@"buyerLeftFeedback"] isEqualToString:@"YES"]) {
                            //current user got a review
                            NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"@%@\n left you feedback", self.otherUser.username]];
                            [self.gotFeedbackLabel setAttributedText:[self modifyString:labelText setFontForText:[NSString stringWithFormat:@"@%@", self.otherUser.username]]];
                        }
                        
                        if ([[self.orderObject objectForKey:@"sellerLeftFeedback"] isEqualToString:@"YES"]) {
                            //current user left a review
                            NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"You left feedback for\n@%@", self.otherUser.username]];
                            [self.leftFeedbackLabel setAttributedText:[self modifyString:labelText setFontForText:[NSString stringWithFormat:@"@%@", self.otherUser.username]]];
                        }
                    }
                    
                    NSString *name = [self.otherUser objectForKey:@"fullname"];
                    
                    NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:transText];
                    [self.dealLabel setAttributedText:[self modifyString:labelText setFontForText:name]];
                    
                }
                else{
                    NSLog(@"error fetching other user %@", error);
                }
            }];
            
            //setup listing
            self.listingObject = [self.orderObject objectForKey:@"listing"];
            
            //setup address
//            self.addressLabel.text = [self.orderObject objectForKey:@"shippingAddress"];
            self.addressView.text = [self.orderObject objectForKey:@"shippingAddress"];

            
            //setup payment info
            NSString *paymentString;
            NSString *currency = [NSString stringWithFormat:@"%@ ",[self.orderObject objectForKey:@"currency"]];
            
            if (self.isBuyer) {
                //setup buyer cell
                
                self.buyerItemPriceLabel.text = [self.orderObject objectForKey:@"salePriceLabel"];
                self.buyerShippingPriceLabel.text = [self.orderObject objectForKey:@"shippingPriceLabel"];
                
                NSString *totalString = [self.orderObject objectForKey:@"totalPriceLabel"];
                self.buyerTotalPriceLabel.text = [totalString stringByReplacingOccurrencesOfString:currency withString:@""];
                
                if (self.paymentFailed) {
                    [self.buyerPaymentImageView setImage:[UIImage imageNamed:@"OrderCards"]];
                    paymentString = [NSString stringWithFormat:@"Payment Failed\n%@ failed to send",[self.orderObject objectForKey:@"totalPriceLabel"]];
                }
                else if(self.paymentPending){
                    [self.buyerPaymentImageView setImage:[UIImage imageNamed:@"OrderCards"]];
                    paymentString = [NSString stringWithFormat:@"Payment Pending\n%@ sending via PayPal",[self.orderObject objectForKey:@"totalPriceLabel"]];
                }
                else{
                    //order is LIVE
                    paymentString = [NSString stringWithFormat:@"Payment Sent\n%@ sent using PayPal",[self.orderObject objectForKey:@"totalPriceLabel"]];
                }
                
                self.buyerPaymentLabel.text = paymentString;

            }
            else{
                //setup seller cell
                
                self.itemPriceLabel.text = [self.orderObject objectForKey:@"salePriceLabel"];
                self.shippingPriceLabel.text = [self.orderObject objectForKey:@"shippingPriceLabel"];
                
                NSString *totalString;
                
                //firstly check if we have a fee otherwise just show same info as buyer except have FREE fees
                if ([[self.orderObject objectForKey:@"chargedFee"]isEqualToString:@"YES"]) {
                    
                    paymentString = [NSString stringWithFormat:@"Payment Received\n%@ sent to your PayPal",[self.orderObject objectForKey:@"totalSellerPriceLabel"]];
                    
                    self.feePriceLabel.text = [self.orderObject objectForKey:@"feePriceLabel"];
                    
                    totalString = [self.orderObject objectForKey:@"totalSellerPriceLabel"];
                    self.totalPriceLabel.text = [totalString stringByReplacingOccurrencesOfString:currency withString:@""];
                }
                else{
                    //no fee for the seller
                    paymentString = [NSString stringWithFormat:@"Payment Received\n%@ sent to your PayPal",[self.orderObject objectForKey:@"totalPriceLabel"]];

                    self.feePriceLabel.text = @"Free";
                    totalString = [self.orderObject objectForKey:@"totalPriceLabel"];
                    self.totalPriceLabel.text = [totalString stringByReplacingOccurrencesOfString:currency withString:@""];

                }
                
                self.paymentLabel.text = paymentString;
            }
            
            
            //setup next steps
            
            //reviews
            if (self.isBuyer) {
                
                if ([self.orderObject objectForKey:@"refundStatus"]) {
                    if ([[self.orderObject objectForKey:@"refundStatus"] isEqualToString:@"requested"]) {
                        [self.buyerRefundButton setTitle:@"Cancel Refund Request" forState:UIControlStateNormal];
                        self.refundRequested = YES;
                    }
                    else if ([[self.orderObject objectForKey:@"refundStatus"] isEqualToString:@"sent"]) {
                        [self.buyerRefundButton setTitle:@"Refund Received" forState:UIControlStateNormal];
                        self.refundSent = YES;
                    }
                    else{
                        [self.buyerRefundButton setTitle:@"Request a Refund" forState:UIControlStateNormal];
                    }
                }
                else{
                    [self.buyerRefundButton setTitle:@"Request a Refund" forState:UIControlStateNormal];
                }
                
                if ([[self.orderObject objectForKey:@"buyerLeftFeedback"] isEqualToString:@"YES"]) {
                    //this user left a review
                    self.leftFeedback = YES;

                    //get number of stars that this user left & set correct image on leftStarImgView
                    int buyerStars = [[self.orderObject objectForKey:@"sellerStars"]intValue];
                    if (buyerStars == 1) {
                        [self.leftStarImageView setImage:[UIImage imageNamed:@"1OrderStars"]];
                    }
                    else if (buyerStars == 2){
                        [self.leftStarImageView setImage:[UIImage imageNamed:@"2OrderStars"]];
                    }
                    else if (buyerStars == 3){
                        [self.leftStarImageView setImage:[UIImage imageNamed:@"3OrderStars"]];
                    }
                    else if (buyerStars == 4){
                        [self.leftStarImageView setImage:[UIImage imageNamed:@"4OrderStars"]];
                    }
                    else if (buyerStars == 5){
                        [self.leftStarImageView setImage:[UIImage imageNamed:@"5OrderStars"]];
                    }
                }
                
                if ([[self.orderObject objectForKey:@"sellerLeftFeedback"] isEqualToString:@"YES"]) {
                    //other user has left a review
                    self.gotFeedback = YES;
                    
                    self.rowNumber++;
                    
                    //set number of stars on gotImgView
                    int sellerStars = [[self.orderObject objectForKey:@"buyerStars"]intValue];
                    if (sellerStars == 1) {
                        [self.gotStarImageView setImage:[UIImage imageNamed:@"1OrderStars"]];
                    }
                    else if (sellerStars == 2){
                        [self.gotStarImageView setImage:[UIImage imageNamed:@"2OrderStars"]];
                    }
                    else if (sellerStars == 3){
                        [self.gotStarImageView setImage:[UIImage imageNamed:@"3OrderStars"]];
                    }
                    else if (sellerStars == 4){
                        [self.gotStarImageView setImage:[UIImage imageNamed:@"4OrderStars"]];
                    }
                    else if (sellerStars == 5){
                        [self.gotStarImageView setImage:[UIImage imageNamed:@"5OrderStars"]];
                    }
                }
                
            }
            else{
                //seller
                if ([[self.orderObject objectForKey:@"refundStatus"] isEqualToString:@"requested"]) {
                    [self.refundButton setTitle:@"Respond to Refund Request" forState:UIControlStateNormal];
                    self.refundRequested = YES;
                    
                    if (![[self.orderObject objectForKey:@"refundRequestSeen"]isEqualToString:@"YES"]) {
                        [self showAlertWithTitle:@"Refund Requested" andMsg:@"The buyer has requested a full refund, issue a PayPal refund in full from this page or chat to the seller to come to a mutual agreement. If there are any issues please contact support from this page to chat to one of the team"];
                        NSDictionary *params = @{
                                                 @"orderId":self.orderObject.objectId
                                                 };
                        
                        [PFCloud callFunctionInBackground:@"setRefundRequestSeen" withParameters:params block:^(NSDictionary *response, NSError *error) {
                            if (!error) {
                                NSLog(@"refund request marked as seen");
                            }
                            else{
                                NSLog(@"error setting refund request as seen");
                            }
                        }];
                    }
                }
                else if ([[self.orderObject objectForKey:@"status"] isEqualToString:@"refunded"]) {
                    [self.refundButton setTitle:@"Refund Sent" forState:UIControlStateNormal];
                    self.refundSent = YES;
                }
                else{
                    [self.refundButton setTitle:@"Issue Full Refund" forState:UIControlStateNormal];
                }
                
                //user is seller, to do's:
                if ([[self.orderObject objectForKey:@"sellerLeftFeedback"] isEqualToString:@"YES"]) {
                    self.leftFeedback = YES;

                    //user has left a review

                    //get number of stars that this user got & set correct image on leftStarImgView
                    int sellerStars = [[self.orderObject objectForKey:@"buyerStars"]intValue];
                    if (sellerStars == 1) {
                        [self.leftStarImageView setImage:[UIImage imageNamed:@"1OrderStars"]];
                    }
                    else if (sellerStars == 2){
                        [self.leftStarImageView setImage:[UIImage imageNamed:@"2OrderStars"]];
                    }
                    else if (sellerStars == 3){
                        [self.leftStarImageView setImage:[UIImage imageNamed:@"3OrderStars"]];
                    }
                    else if (sellerStars == 4){
                        [self.leftStarImageView setImage:[UIImage imageNamed:@"4OrderStars"]];
                    }
                    else if (sellerStars == 5){
                        [self.leftStarImageView setImage:[UIImage imageNamed:@"5OrderStars"]];
                    }
                }
                
                if ([[self.orderObject objectForKey:@"buyerLeftFeedback"] isEqualToString:@"YES"]) {
                    self.gotFeedback = YES;
                    self.rowNumber++;
                    
                    //set number of stars we left
                    int buyerStars = [[self.orderObject objectForKey:@"sellerStars"]intValue];
                    if (buyerStars == 1) {
                        [self.gotStarImageView setImage:[UIImage imageNamed:@"1OrderStars"]];
                    }
                    else if (buyerStars == 2){
                        [self.gotStarImageView setImage:[UIImage imageNamed:@"2OrderStars"]];
                    }
                    else if (buyerStars == 3){
                        [self.gotStarImageView setImage:[UIImage imageNamed:@"3OrderStars"]];
                    }
                    else if (buyerStars == 4){
                        [self.gotStarImageView setImage:[UIImage imageNamed:@"4OrderStars"]];
                    }
                    else if (buyerStars == 5){
                        [self.gotStarImageView setImage:[UIImage imageNamed:@"5OrderStars"]];
                    }
                }
            }
            
            //shipping
            if ([[self.orderObject objectForKey:@"shipped"] isEqualToString:@"YES"]) {
                self.shipped = YES;
                
                [self.shippingImageView setImage:[UIImage imageNamed:@"OrderCheck"]];
                
                [self.dateFormat setDateFormat:@"dd MMM YYYY"];
                NSDate *shippedDate = [self.orderObject objectForKey:@"shippedDate"];
                
                self.shippingMainLabel.text = [NSString stringWithFormat:@"Item Shipped\nSent on %@ to",[self.dateFormat stringFromDate:shippedDate]];
                
                if ([[self.orderObject objectForKey:@"trackingAdded"]isEqualToString:@"YES"]) {
                    //tracking added
                    self.addedTracking = YES;
                    self.shippingCellHeight += 50;
                    
                    self.addressView.text = [NSString stringWithFormat:@"%@\n\nCourier: %@\nTracking: %@", self.addressView.text,[self.orderObject objectForKey:@"courierName"], [self.orderObject objectForKey:@"trackingId"]];
                    
                    if (self.isBuyer) {
                        [self.shippingButton setTitle:@"I haven't received my item" forState:UIControlStateNormal];
                    }
                    else{
                        [self.shippingButton setTitle:@"Update Tracking" forState:UIControlStateNormal];
                    }
                }
                else{
                    //no tracking added yet
                    if (self.isBuyer) {
                        [self.shippingButton setTitle:@"I haven't received my item" forState:UIControlStateNormal];
                    }
                    else{
                        [self.shippingButton setTitle:@"Add Tracking" forState:UIControlStateNormal];
                    }
                }
            }
            else{
                //not shipped
                if (self.isBuyer) {
                    [self.shippingButton setTitle:@"Resolve a Shipping Issue" forState:UIControlStateNormal];
                    self.shippingMainLabel.text = @"Awaiting Shipment\nto this address";
                }
                else{
                    [self.shippingButton setTitle:@"Mark as Shipped" forState:UIControlStateNormal];
                    self.shippingMainLabel.text = @"Ship your item tracked delivery\nto this address";
                }
            }
            
            [self.tableView reloadData];
            [self calcStatus];
        }
        else{
            NSLog(@"error fetching order %@", error);
            [self showAlertWithTitle:@"Error Fetching Order" andMsg:@"Please check your connection & try again"];
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBarTintColor: nil];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rowNumber;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return self.titleCell;
    }
    
    if (self.paymentFailed || self.paymentPending) {
        if (indexPath.row == 1 && !self.isBuyer) {
            return self.paymentCell;
        }
        else if (indexPath.row == 1 && self.isBuyer) {
            return self.buyerPaymentCell;
        }
        else if (indexPath.row == 2) {
            return self.transactionCell;
        }
    }

    //title/transaction/payment/shipping/leave review
    if (self.rowNumber == 5 && !self.leftFeedback) {
        if (indexPath.row == 1) {
            return self.leaveFeedbackCell;
        }
        else if (indexPath.row == 2) {
            return self.shippingCell;
        }
        else if (indexPath.row == 3 && !self.isBuyer) {
            return self.paymentCell;
        }
        else if (indexPath.row == 3 && self.isBuyer) {
            return self.buyerPaymentCell;
        }
        else if (indexPath.row == 4) {
            return self.transactionCell;
        }
        return nil;
    }

    //title/transaction/payment/shipping/left review
    else if (self.rowNumber == 5 && self.leftFeedback) {
        if (indexPath.row == 1) {
            return self.leftFeedbackCell;
        }
        else if (indexPath.row == 2) {
            return self.shippingCell;
        }
        else if (indexPath.row == 3 && !self.isBuyer) {
            return self.paymentCell;
        }
        else if (indexPath.row == 3 && self.isBuyer) {
            return self.buyerPaymentCell;
        }
        else if (indexPath.row == 4) {
            return self.transactionCell;
        }
        return nil;
    }
    
    //title/transaction/payment/shipping/leave review/got review
    else if (self.rowNumber == 6 && !self.leftFeedback) {
        if (indexPath.row == 1) {
            return self.leaveFeedbackCell;
        }
        else if (indexPath.row == 2) {
            return self.gotFeedbackCell;
        }
        else if (indexPath.row == 3) {
            return self.shippingCell;
        }
        else if (indexPath.row == 4 && !self.isBuyer) {
            return self.paymentCell;
        }
        else if (indexPath.row == 4 && self.isBuyer) {
            return self.buyerPaymentCell;
        }
        else if (indexPath.row == 5) {
            return self.transactionCell;
        }
        return nil;
    }
    
    //title/transaction/payment/shipping/left review/got review
    else{
        if (indexPath.row == 1) {
            return self.leftFeedbackCell;
        }
        else if (indexPath.row == 2) {
            return self.gotFeedbackCell;
        }
        else if (indexPath.row == 3) {
            return self.shippingCell;
        }
        else if (indexPath.row == 4 && !self.isBuyer) {
            return self.paymentCell;
        }
        else if (indexPath.row == 4 && self.isBuyer) {
            return self.buyerPaymentCell;
        }
        else if (indexPath.row == 5) {
            return self.transactionCell;
        }
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row == 0) {
        return self.titleCellHeight;
    }
    
    if (self.paymentFailed || self.paymentPending) {
        if (indexPath.row == 1) {
            return self.paymentCellHeight;
        }
        else if (indexPath.row == 2) {
            return self.transCellHeight;
        }
    }
    
    //title/transaction/payment/shipping/leave review
    if (self.rowNumber == 5 && !self.leftFeedback) {
        if (indexPath.row == 1) {
            return self.leaveFBCellHeight;
        }
        else if (indexPath.row == 2) {
            return self.shippingCellHeight;
        }
        else if (indexPath.row == 3) {
            return self.paymentCellHeight;
        }
        else if (indexPath.row == 4) {
            return self.transCellHeight;
        }
        return 100;
    }
    
    //title/transaction/payment/shipping/left review
    else if (self.rowNumber == 5 && self.leftFeedback) {
        if (indexPath.row == 1) {
            return self.leftFBCellHeight;
        }
        else if (indexPath.row == 2) {
            return self.shippingCellHeight;
        }
        else if (indexPath.row == 3) {
            return self.paymentCellHeight;
        }
        else if (indexPath.row == 4) {
            return self.transCellHeight;
        }
        return 100;
    }
    
    //title/transaction/payment/shipping/leave review/got review
    else if (self.rowNumber == 6 && !self.leftFeedback) {
        if (indexPath.row == 1) {
            return self.leaveFBCellHeight;
        }
        else if (indexPath.row == 2) {
            return self.gotFBCellHeight;
        }
        else if (indexPath.row == 3) {
            return self.shippingCellHeight;
        }
        else if (indexPath.row == 4) {
            return self.paymentCellHeight;
        }
        else if (indexPath.row == 5) {
            return self.transCellHeight;
        }
        return 100;
    }
    
    //title/transaction/payment/shipping/left review/got review
    else{
        if (indexPath.row == 1) {
            return self.leftFBCellHeight;
        }
        else if (indexPath.row == 2) {
            return self.gotFBCellHeight;
        }
        else if (indexPath.row == 3) {
            return self.shippingCellHeight;
        }
        else if (indexPath.row == 4) {
            return self.paymentCellHeight;
        }
        else if (indexPath.row == 5) {
            return self.transCellHeight;
        }
        return 100;
    }
}

#pragma mark - action buttons

- (IBAction)viewFeedbackCurrentLeft:(id)sender {
    if (self.leftFeedback) {
        PFObject *feedbackObject;
        
        if (self.isBuyer) {
            if (![self.orderObject objectForKey:@"sellerReview"]) {
                return;
            }
            feedbackObject = [self.orderObject objectForKey:@"sellerReview"]; //this is the review of the buyer NOT the review the buyer left
        }
        else{
            if (![self.orderObject objectForKey:@"buyerReview"]) {
                return;
            }
            feedbackObject = [self.orderObject objectForKey:@"buyerReview"];
        }
        
        ReviewsVC *vc = [[ReviewsVC alloc]init];
        vc.singleMode = YES;
        vc.feedbackObject = feedbackObject;
        [self.navigationController pushViewController:vc animated:YES];
    }
}
- (IBAction)viewFeedbackPressed:(id)sender {
    if (self.gotFeedback) {
        PFObject *feedbackObject;
        
        if (self.isBuyer) {
            feedbackObject = [self.orderObject objectForKey:@"buyerReview"]; //this is the review of the buyer NOT the review the buyer left
        }
        else{
            feedbackObject = [self.orderObject objectForKey:@"sellerReview"];
        }
        
        NSLog(@"fb object %@", feedbackObject);
        
        ReviewsVC *vc = [[ReviewsVC alloc]init];
        vc.singleMode = YES;
        vc.feedbackObject = feedbackObject;
        [self.navigationController pushViewController:vc animated:YES];
    }
}
-(void)helpPressed{
    if (self.tappedSupport) {
        NSLog(@"returning from help");
        return;
    }
    self.tappedSupport = YES;
    
    [self showHUDForCopy:NO];
    
    //get the support ticket or create a new one if needed
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"supportConvos"];
    NSString *convoId = [NSString stringWithFormat:@"TICKET%@%@", [PFUser currentUser].objectId, self.orderObject.objectId];
    [convoQuery whereKey:@"ticketId" equalTo:convoId];
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.tappedSupport = NO;
            [self hideHUD];
            
            //convo exists, go there
            ChatWithBump *vc = [[ChatWithBump alloc]init];
            vc.convoId = [NSString stringWithFormat:@"TICKET%@%@", [PFUser currentUser].objectId, self.orderObject.objectId];
            vc.convoObject = object;
            vc.otherUser = [PFUser currentUser];
            vc.supportMode = YES;
            vc.isBuyer = self.isBuyer;
            //            [self.navigationController tabBarItem].badgeValue = nil;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            //create a new one
            PFObject *convoObject = [PFObject objectWithClassName:@"supportConvos"];
            convoObject[@"userId"] = [PFUser currentUser].objectId;
            convoObject[@"user"] = [PFUser currentUser];
            convoObject[@"ticketId"] = [NSString stringWithFormat:@"TICKET%@%@", [PFUser currentUser].objectId, self.orderObject.objectId];
            convoObject[@"totalMessages"] = @0;
            convoObject[@"status"] = @"open";
            convoObject[@"orderObject"] = self.orderObject;
            convoObject[@"orderDate"] = self.orderObject.createdAt;
            convoObject[@"listing"] = self.listingObject;
            
            if (self.isBuyer) {
                convoObject[@"purchase"] = @"YES";
                convoObject[@"buyerId"] = [PFUser currentUser].objectId;
                convoObject[@"sellerId"] = self.otherUser.objectId;
            }
            else{
                convoObject[@"purchase"] = @"NO";
                convoObject[@"buyerId"] = self.otherUser.objectId;
                convoObject[@"sellerId"] = [PFUser currentUser].objectId;
            }
            
            convoObject[@"itemTitle"] = [self.orderObject objectForKey:@"itemTitle"];
            convoObject[@"itemImage"] = [self.orderObject objectForKey:@"itemImage"];
            
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //saved, goto VC
                    self.tappedSupport = NO;
                    [self hideHUD];
                    
                    ChatWithBump *vc = [[ChatWithBump alloc]init];
                    vc.convoId = [NSString stringWithFormat:@"TICKET%@%@", [PFUser currentUser].objectId, self.orderObject.objectId];
                    vc.convoObject = convoObject;
                    vc.otherUser = [PFUser currentUser];
                    vc.supportMode = YES;
                    vc.isBuyer = self.isBuyer;
                    
                    //                    [self.navigationController tabBarItem].badgeValue = nil;
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    self.tappedSupport = NO;
                    [self hideHUD];
                    
                    [self showAlertWithTitle:@"Connection Error" andMsg:@"Make sure you're connected to the internet and try again!"];
                    NSLog(@"error saving support ticket");
                }
            }];
        }
    }];
}

- (IBAction)viewUserPressed:(id)sender {
    [self.viewUserButton setEnabled:NO];
    
    [Answers logCustomEventWithName:@"Tapped User Checkout"
                   customAttributes:@{}];
    
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = self.otherUser;
    [self.viewUserButton setEnabled:YES];
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)viewListingPressed:(id)sender {
    [self.viewListingButton setEnabled:NO];

    [Answers logCustomEventWithName:@"Tapped Listing Checkout"
                   customAttributes:@{}];
    
    ForSaleListing *vc = [[ForSaleListing alloc]init];
    vc.listingObject = self.listingObject;
    vc.source = @"checkout";
    vc.fromBuyNow = YES;
    vc.pureWTS = YES;
    vc.fromPush = YES;
    vc.fromOrder = YES;
    [self.viewListingButton setEnabled:YES];
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)messagePressed:(id)sender {
    [self setupMessages];
}
- (IBAction)refundPressed:(id)sender {
    if (self.isBuyer) {
        //buyer pressed
        if (self.refundRequested) {
            //do nothing, already requested a refund
            NSLog(@"already requested refund");
            [self showCancelRefundPopUp];

        }
        else if (self.refundSent){
            //do nothing, refund already sent
            NSLog(@"refund already sent");

        }
        else{
            //request a refund pressed
            //show pop up so buyer can confirm
            [self showRefundPopUp];
            NSLog(@"request a refund pressed");
        }
    }
    else{
        //seller pressed
        if (self.refundRequested) {
            //show seller a decision pop up
            NSLog(@"refund has been requested by buyer, show pop up for seller to decide");
            [self showRefundDecisionPopup];

        }
        else if (self.refundSent){
            //do nothing, refund already sent
            NSLog(@"refund already sent");
        }
        else{
            //issue a refund pressed
            NSLog(@"issue a refund pressed");
            [self showRefundConfirmPopup];
        }
    }
}

-(void)showRefundDecisionPopup{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Issue Full Refund" message:@"The buyer has requested a full refund. You can tap to grant a PayPal refund in full or if you'd like to chat to the buyer to come to a resolution just hit 'Message Buyer' from this page. If you have any issues or concerns please contact support from this page to chat to one of the team" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [alertView addAction:[UIAlertAction actionWithTitle:@"Issue Refund" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
        NSString *requestId = @"";
        
        //check if been a previous refund attempt
        if ([[self.orderObject objectForKey:@"refundCount"]intValue] > 0 && [self.orderObject objectForKey:@"refundRequest"]) {
            //to stop refund requests happening with same requestId we keep appending a string to the end
            requestId = [NSString stringWithFormat:@"%@1",[self.orderObject objectForKey:@"refundRequestString"]];
            [self.orderObject setObject:requestId forKey:@"refundRequestString"];
            
        }
        
        NSDictionary *params = @{
                                     @"orderId":self.orderObject.objectId,
                                     @"total":[self.orderObject objectForKey:@"totalPrice"],
                                     @"currency":[self.orderObject objectForKey:@"currency"],
                                     @"invoiceId":[NSString stringWithFormat:@"invoice_%@",self.listingObject.objectId],
                                     @"custom":self.listingObject.objectId,
                                     @"refundURL":[self.orderObject objectForKey:@"refundURL"],
                                     @"payerId":[self.orderObject objectForKey:@"merchantId"]
                                };
        [self showHUDForCopy:NO];
        [PFCloud callFunctionInBackground:@"triggerRefund" withParameters:params block:^(NSDictionary *response, NSError *error) {
            if (!error) {
                [Answers logCustomEventWithName:@"Refund triggered"
                               customAttributes:@{
                                                  @"orderId":self.orderObject.objectId
                                                  }];
                
                [self hideHUD];
                self.refundRequested = NO;
                self.refundSent = YES;
                [self.refundButton setTitle:@"Refund Sent" forState:UIControlStateNormal];
                self.nextStepLabel.text = @"Refund Sent";
            }
            else{
                [Answers logCustomEventWithName:@"Refund Error"
                               customAttributes:@{
                                                  @"orderId":self.orderObject.objectId
                                                  }];
                
                [self hideHUD];
                NSLog(@"error issuing refund %@", error);
                [self showAlertWithTitle:@"Refund Error" andMsg:@"Make sure you're connected to the internet & try again\n\nMake sure you have the funds available in your PayPal account ready to refund\n\nIf you're still having issues please try and refund from PayPal's desktop site"];
            }
        }];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}
-(void)showRefundConfirmPopup{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Issue Full Refund" message:@"You can tap to issue a PayPal refund in full or if you'd like to chat to the buyer to come to a resolution just hit 'Message Buyer' from this page. If you have any issues or concerns please contact support from this page to chat to one of the team" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [alertView addAction:[UIAlertAction actionWithTitle:@"Issue Refund" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        NSDictionary *params = @{
                                 @"orderId":self.orderObject.objectId,
                                 @"total":[self.orderObject objectForKey:@"totalPrice"],
                                 @"currency":[self.orderObject objectForKey:@"currency"],
                                 @"invoiceId":[NSString stringWithFormat:@"invoice_%@",self.listingObject.objectId],
                                 @"custom":self.listingObject.objectId,
                                 @"refundURL":[self.orderObject objectForKey:@"refundURL"],
                                 @"payerId":[self.orderObject objectForKey:@"merchantId"]
                                 };
        [self showHUDForCopy:NO];
        [PFCloud callFunctionInBackground:@"triggerRefund" withParameters:params block:^(NSDictionary *response, NSError *error) {
            if (!error) {
                [Answers logCustomEventWithName:@"Refund triggered"
                               customAttributes:@{
                                                  @"orderId":self.orderObject.objectId,
                                                  @"where":@"popup"
                                                  }];
                
                [self hideHUD];
                self.refundRequested = NO;
                self.refundSent = YES;
                [self.refundButton setTitle:@"Refund Sent" forState:UIControlStateNormal];
                self.nextStepLabel.text = @"Refund Sent";
            }
            else{
                [Answers logCustomEventWithName:@"Refund Error"
                               customAttributes:@{
                                                  @"orderId":self.orderObject.objectId,
                                                  @"where":@"popup"
                                                  }];
                
                [self hideHUD];
                NSLog(@"error issuing refund %@", error);
                [self showAlertWithTitle:@"Refund Error #2" andMsg:@"Make sure you're connected to the internet & try again\n\nMake sure you have the funds available in your PayPal account ready to refund\n\nIf you're still having issues please try and refund from PayPal's desktop site"];
            }
        }];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showCancelRefundPopUp{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Cancel Refund Request?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel Refund" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        NSDictionary *params = @{
                                 @"orderId":self.orderObject.objectId
                                 };
        
        [PFCloud callFunctionInBackground:@"setRefundCancelled" withParameters:params block:^(NSDictionary *response, NSError *error) {
            if (!error) {
                [Answers logCustomEventWithName:@"Cancelled Refund"
                               customAttributes:@{
                                                  @"orderId" : self.orderObject.objectId
                                                  }];
                
                self.refundRequested = NO;
                [self.buyerRefundButton setTitle:@"Request a Refund" forState:UIControlStateNormal];
                
                //allows calcStatus to ignore the status of the orderobject that has been fetched since we're updating the correct one in the cloud func
                self.refundCancelled = YES;
                [self calcStatus];
            }
            else{
                [Answers logCustomEventWithName:@"Cancelled Refund Error"
                               customAttributes:@{
                                                  @"orderId" : self.orderObject.objectId
                                                  }];
                NSLog(@"error setting refund as requested %@", error);
                [self showAlertWithTitle:@"Refund Request Cancel Error" andMsg:@"Make sure you're connected to the internet & try again"];
            }
        }];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}
-(void)showRefundPopUp{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Request Full Refund?" message:@"The seller will be notified of your request, if you have any issues please contact support from this page" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [alertView addAction:[UIAlertAction actionWithTitle:@"Request" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        NSDictionary *params = @{
                                 @"orderId":self.orderObject.objectId
                                 };
        
        [PFCloud callFunctionInBackground:@"setRefundRequested" withParameters:params block:^(NSDictionary *response, NSError *error) {
            if (!error) {
                [Answers logCustomEventWithName:@"Refund Requested"
                               customAttributes:@{
                                                  @"orderId" : self.orderObject.objectId
                                                  }];
                
                self.refundRequested = YES;
                self.nextStepLabel.text = @"Refund Requested";
                [self.buyerRefundButton setTitle:@"Cancel Refund Request" forState:UIControlStateNormal];
            }
            else{
                [Answers logCustomEventWithName:@"Refund Requested Error"
                               customAttributes:@{
                                                  @"orderId" : self.orderObject.objectId
                                                  }];
                
                NSLog(@"error setting refund as requested %@", error);
                [self showAlertWithTitle:@"Refund Request Error" andMsg:@"Make sure you're connected to the internet & try again"];
            }
        }];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}
- (IBAction)shippingButtonPressed:(id)sender {
    if (!self.shipped) {
        if (self.isBuyer) {
            //resolve a shipping issue
            supportAnswerVC *vc = [[supportAnswerVC alloc]init];
            vc.showShippingAnswer = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            [self showHUDForCopy:NO];
            
            NSDictionary *params = @{
                                     @"orderId":self.orderObject.objectId,
                                     @"senderName": [PFUser currentUser].username,
                                     @"otherUserId":self.otherUser.objectId,
                                     @"itemTitle" : [self.orderObject objectForKey:@"itemTitle"]
                                     };
            
            [PFCloud callFunctionInBackground:@"markItemShipped" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    [Answers logCustomEventWithName:@"Item Shipped"
                                   customAttributes:@{
                                                      @"orderId" : self.orderObject.objectId
                                                      }];
                    
                    [self hideHUD];
                    self.shipped = YES;
                    
                    //update shipping cell
                    [self.shippingImageView setImage:[UIImage imageNamed:@"OrderCheck"]];
                    [self.dateFormat setDateFormat:@"dd MMM YYYY"];
                    NSDate *shippedDate = [NSDate date];
                    self.shippingMainLabel.text = [NSString stringWithFormat:@"Item Shipped\nSent on %@ to",[self.dateFormat stringFromDate:shippedDate]];
                    [self.shippingButton setTitle:@"Add Tracking" forState:UIControlStateNormal];
                    
                    //update next step label
                    [self calcStatus];
                    
                }
                else{
                    [Answers logCustomEventWithName:@"Item Shipped Error"
                                   customAttributes:@{
                                                      @"orderId" : self.orderObject.objectId
                                                      }];
                    
                    NSLog(@"error marking as shipped %@", error);
                    [self hideHUD];
                    [self showAlertWithTitle:@"Shipping Error" andMsg:@"Make sure you're connected to the internet then try again!"];
                }
            
            }];
        }
    }
    else{
        if (self.isBuyer) {
            //resolve a shipping issue
            supportAnswerVC *vc = [[supportAnswerVC alloc]init];
            vc.showShippingAnswer = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            //add tracking pressed
            [self addTracking];
        }
    }
}
- (IBAction)leaveFeedbackPressed:(id)sender {
    if (!self.fetchedUser) {
        return;
    }
    
    FeedbackController *vc = [[FeedbackController alloc]init];
    vc.delegate = self;
    vc.user = self.otherUser;
    vc.purchased = self.isBuyer;
    vc.orderObject = self.orderObject;
    vc.messageNav = self.navigationController;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)nextStepPressed:(id)sender {
    if (self.paymentFailed || self.paymentPending) {
        return;
    }
    
    if (self.refundRequested && !self.isBuyer) {
        [self showRefundDecisionPopup];
        return;
    }
    
    if (self.isBuyer) {
        if (!self.leftFeedback) {
            [self leaveFeedbackPressed:self];
        }
    }
    else{
        //seller only
        if(self.refundSent){
            //relist item pressed
            NSLog(@"refund sent");
            
            [self showHUDForCopy:NO];
            NSDictionary *params = @{
                                     @"ogListingId":self.listingObject.objectId,
                                     @"sellerId":[PFUser currentUser].objectId,
                                     @"orderId":self.orderObject.objectId
                                     };
            
            [PFCloud callFunctionInBackground:@"relistItem" withParameters:params block:^(NSString *orderId, NSError *error) {
                if (!error) {
                    
                    self.itemRelisted = YES;
                    self.nextStepLabel.text = @"Payment Refunded - Item Relisted";
                    
                    [self hideHUD];
                    
                    [Answers logCustomEventWithName:@"Relisted Item"
                                   customAttributes:@{}];
                }
                else{
                    NSLog(@"error relisting item %@", error);
                    [self hideHUD];
                    
                    [Answers logCustomEventWithName:@"Relisted Item Error"
                                   customAttributes:@{
                                                      @"error":error.description
                                                      }];
                    
                    [self showAlertWithTitle:@"Relist Error" andMsg:@"Please check your connection and try again. If this error persists please contact support"];
                    
                }
            }];
        }
        else if (!self.shipped){
            [self shippingButtonPressed:self];
        }
        else if (!self.leftFeedback) {
            [self leaveFeedbackPressed:self];
        }
    }
}


#pragma mark - feedback delegate
-(void)leftReviewWithStars:(int)stars{
    self.leftFeedback = YES;
    
    //update stars & label in leftReviewCell
    int leftStars = stars;
    
    NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"You left feedback for\n@%@", self.otherUser.username]];
    [self.leftFeedbackLabel setAttributedText:[self modifyString:labelText setFontForText:[NSString stringWithFormat:@"@%@", self.otherUser.username]]];
    
    //get number of stars that this user left & set correct image on leftStarImgView
    if (leftStars == 1) {
        [self.leftStarImageView setImage:[UIImage imageNamed:@"1OrderStars"]];
    }
    else if (leftStars == 2){
        [self.leftStarImageView setImage:[UIImage imageNamed:@"2OrderStars"]];
    }
    else if (leftStars == 3){
        [self.leftStarImageView setImage:[UIImage imageNamed:@"3OrderStars"]];
    }
    else if (leftStars == 4){
        [self.leftStarImageView setImage:[UIImage imageNamed:@"4OrderStars"]];
    }
    else if (leftStars == 5){
        [self.leftStarImageView setImage:[UIImage imageNamed:@"5OrderStars"]];
    }

    //update table view
    [self.tableView reloadData];
    
    //update next steps label
    [self calcStatus];
    
}

#pragma mark - helpers

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(NSMutableAttributedString *)modifyString: (NSMutableAttributedString *)mainString setColorForText:(NSString*) textToFind withColor:(UIColor*) color
{
    NSRange range = [mainString.mutableString rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        [mainString addAttribute:NSForegroundColorAttributeName value:color range:range];
    }
    
    return mainString;
}

-(void)cropProfilePic{
    self.otherUserImageView.layer.cornerRadius = 30;
    self.otherUserImageView.layer.masksToBounds = YES;
    self.otherUserImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.otherUserImageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(NSMutableAttributedString *)modifyString: (NSMutableAttributedString *)mainString setFontForText:(NSString*) textToFind
{
    NSRange range = [mainString.mutableString rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        [mainString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-Medium" size:13] range:range];
    }
    
    return mainString;
}

-(void)setBuyerUnseen:(BOOL) buyer withIncrement:(BOOL)increment{
    NSString *updateBuyer;
    NSString *incrementChoice;

    if (buyer) {
        updateBuyer = @"YES";
    }
    else{
        updateBuyer = @"NO";
    }
    
    if (increment) {
        incrementChoice = @"YES";
    }
    else{
        incrementChoice = @"NO";
    }
    
    NSDictionary *params = @{
                             @"orderId":self.orderObject.objectId,
                             @"updateBuyer": updateBuyer,
                             @"increment":incrementChoice
                             };
    
    [PFCloud callFunctionInBackground:@"updateOrderUnseen" withParameters:params block:^(NSString *orderId, NSError *error) {
        if (!error) {
            NSLog(@"updated Order Unseen");
        }
        else{
            NSLog(@"error updating order unseen %@", error);
        }
    }];
    
}

-(void)calcStatus{
    NSString *nextStep;
    BOOL complete = NO;
    
    //only buyer will be able to see orders that are pending or failed so this code is fine here
    if ([[self.orderObject objectForKey:@"status"]isEqualToString:@"pending"]) {
        self.nextStepLabel.text = @"Payment Pending";
        
        //set order as seen
        [self setBuyerUnseen:YES withIncrement:NO];
        return;
    }
    else if([[self.orderObject objectForKey:@"status"]isEqualToString:@"failed"]) {
        self.nextStepLabel.text = @"Payment Failed";
        [self.nextStepLabel setTextColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
        
        //if this user's unseen isn't zero, set it to zero so they've definitely seen the payment failed
        if (self.isBuyer) { //always going to be the buyer but just keep this in
            
            int unseen = [[self.orderObject objectForKey:@"buyerUnseen"]intValue];
            if (unseen != 0) {
                [self setBuyerUnseen:YES withIncrement:NO];
            }
        }
        return;
    }
    else if([[self.orderObject objectForKey:@"status"]isEqualToString:@"refunded"]) {
        
        //if this user's unseen isn't zero, set it to zero so they've definitely seen the payment was refunded
        if (self.isBuyer) {
            self.nextStepLabel.text = @"Payment Refunded";

            int unseen = [[self.orderObject objectForKey:@"buyerUnseen"]intValue];
            if (unseen != 0) {
                [self setBuyerUnseen:YES withIncrement:NO];
            }
        }
        else{
            if (self.itemRelisted) {
                self.nextStepLabel.text = @"Payment Refunded - Item Relisted";
            }
            else{
                NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:@"Payment Refunded - Relist Item"];
                [self.nextStepLabel setAttributedText:[self modifyString:labelText setColorForText:@"Relist Item" withColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]]];
            }
            
            int unseen = [[self.orderObject objectForKey:@"sellerUnseen"]intValue];
            if (unseen != 0) {
                [self setBuyerUnseen:NO withIncrement:NO];
            }
        }
        
        return;
    }
    else if([[self.orderObject objectForKey:@"refundStatus"]isEqualToString:@"requested"] && !self.refundCancelled) {
        if (self.isBuyer) {
            self.nextStepLabel.text = @"Refund Requested";
            
            int unseen = [[self.orderObject objectForKey:@"buyerUnseen"]intValue];
            if (unseen != 0) {
                [self setBuyerUnseen:YES withIncrement:NO];
            }
        }
        else{
            NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:@"Respond to Refund Request"];
            [self.nextStepLabel setAttributedText:[self modifyString:labelText setColorForText:@"Respond to Refund Request" withColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]]];
            
            int unseen = [[self.orderObject objectForKey:@"sellerUnseen"]intValue];
            if (unseen != 0) {
                [self setBuyerUnseen:NO withIncrement:NO];
            }
        }
        return;
    }
    
    if (self.refundCancelled) {
        self.refundCancelled = NO;
    }
    
    if (self.isBuyer) {
        if (!self.leftFeedback) {
            nextStep = @"Leave Feedback";
        }
        else if (!self.shipped){
            nextStep = @"Awaiting Shipment";
            if ([[self.orderObject objectForKey:@"buyerUnseen"]intValue] != 0) {
                [self setBuyerUnseen:YES withIncrement:NO];
            }
        }
        else if (!self.gotFeedback){
            nextStep = @"Awaiting Feedback";
            if ([[self.orderObject objectForKey:@"buyerUnseen"]intValue] != 0) {
                [self setBuyerUnseen:YES withIncrement:NO];
            }
        }
        else{
            if ([[self.orderObject objectForKey:@"buyerUnseen"]intValue] != 0) {
                [self setBuyerUnseen:YES withIncrement:NO];
            }
            complete = YES;
        }
    }
    else{
        if (!self.shipped){
            nextStep = @"Mark as Shipped";
        }
        else if (!self.leftFeedback) {
            nextStep = @"Leave Feedback";
        }
        else if (!self.gotFeedback){
            nextStep = @"Awaiting Feedback";
            if ([[self.orderObject objectForKey:@"sellerUnseen"]intValue] != 0) {
                [self setBuyerUnseen:NO withIncrement:NO];
            }
        }
        else{
            complete = YES;
            if ([[self.orderObject objectForKey:@"sellerUnseen"]intValue] != 0) {
                [self setBuyerUnseen:NO withIncrement:NO];
            }
        }
    }
    if (complete) {
        if (self.isBuyer) {
            
            if (self.refundSent) {
                self.nextStepLabel.text = @"Refund Received";
            }
            else if(self.refundRequested){
                self.nextStepLabel.text = @"Refund Requested";
            }
            else{
                self.nextStepLabel.text = @"Purchase Complete";
            }
        }
        else{
            if (self.refundSent) {
//                self.nextStepLabel.text = @"Refund Sent";
                if (self.itemRelisted) {
                    self.nextStepLabel.text = @"Payment Refunded - Item Relisted";
                }
                else{
                    NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:@"Payment Refunded - Relist Item"];
                    [self.nextStepLabel setAttributedText:[self modifyString:labelText setColorForText:@"Relist Item" withColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]]];
                }
            }
            else if(self.refundRequested){
                self.nextStepLabel.text = @"Respond to Refund Request";
            }
            else{
                self.nextStepLabel.text = @"Sale Complete";
            }
        }
    }
    else{
        NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"Next Step %@", nextStep]];
        [self.nextStepLabel setAttributedText:[self modifyString:labelText setColorForText:nextStep withColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]]];
    }
}

-(void)setupMessages{
    if (!self.fetchedUser || self.settingUpMessages || !self.otherUser) {
        return;
    }
    
    self.settingUpMessages = YES;
    
    [self showHUDForCopy:NO];
    
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    
    if (self.isBuyer) {
        [convoQuery whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [convoQuery whereKey:@"convoId" equalTo: [NSString stringWithFormat:@"%@%@%@",self.otherUser.objectId,[PFUser currentUser].objectId, self.listingObject.objectId]];
    }
    else{
        [convoQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        [convoQuery whereKey:@"convoId" equalTo: [NSString stringWithFormat:@"%@%@%@",[PFUser currentUser].objectId,self.otherUser.objectId, self.listingObject.objectId]];
    }
    
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists, goto that one but pretype a message like "I'm interested in your Supreme bogo" etc.
            MessageViewController *vc = [[MessageViewController alloc]init];
            vc.convoId = [object objectForKey:@"convoId"];
            vc.convoObject = object;
            vc.listing = self.listingObject;
            vc.otherUser = self.otherUser;
            vc.otherUserName = @"";
            
            if (self.isBuyer) {
                vc.userIsBuyer = YES;
            }
            
            vc.pureWTS = YES;
            vc.fromOrder = YES;
            
            [self hideHUD];
            self.settingUpMessages = NO;
            
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            NSLog(@"create a new convo");
            
            //create a new convo and goto it
            PFObject *convoObject = [PFObject objectWithClassName:@"convos"];
            
            convoObject[@"wtsListing"] = self.listingObject;
            convoObject[@"pureWTS"] = @"YES";
            convoObject[@"orderConvo"] = @"YES";

            convoObject[@"totalMessages"] = @0;
            convoObject[@"buyerUnseen"] = @0;
            convoObject[@"sellerUnseen"] = @0;
            convoObject[@"profileConvo"] = @"NO";
            [convoObject setObject:@"NO" forKey:@"buyerDeleted"];
            [convoObject setObject:@"NO" forKey:@"sellerDeleted"];
            
            //save additional stuff onto convo object for faster inbox loading
            if ([self.orderObject objectForKey:@"itemImage"]) {
                convoObject[@"thumbnail"] = [self.orderObject objectForKey:@"itemImage"];
            }
            
            NSLog(@"create a new convo 1 %@", self.otherUser);
            
            if (self.isBuyer) {
                convoObject[@"buyerUser"] = [PFUser currentUser];
                convoObject[@"sellerUser"] = self.otherUser;
                convoObject[@"convoId"] = [NSString stringWithFormat:@"%@%@%@",self.otherUser.objectId,[PFUser currentUser].objectId, self.listingObject.objectId];
                
                convoObject[@"sellerUsername"] = self.otherUser.username;
                convoObject[@"sellerId"] = self.otherUser.objectId;
                
                if ([self.otherUser objectForKey:@"picture"]) {
                    convoObject[@"sellerPicture"] = [self.otherUser objectForKey:@"picture"];
                }
                
                convoObject[@"buyerUsername"] = [PFUser currentUser].username;
                convoObject[@"buyerId"] = [PFUser currentUser].objectId;
                
                if ([[PFUser currentUser] objectForKey:@"picture"]) {
                    convoObject[@"buyerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
                }
            }
            else{
                convoObject[@"buyerUser"] = self.otherUser;
                convoObject[@"sellerUser"] = [PFUser currentUser];
                convoObject[@"convoId"] = [NSString stringWithFormat:@"%@%@%@",[PFUser currentUser].objectId, self.otherUser.objectId, self.listingObject.objectId];
                
                convoObject[@"sellerUsername"] = [PFUser currentUser].username;
                convoObject[@"sellerId"] = [PFUser currentUser].objectId;
                
                if ([[PFUser currentUser] objectForKey:@"picture"]) {
                    convoObject[@"sellerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
                }
                
                convoObject[@"buyerUsername"] = self.otherUser.username;
                convoObject[@"buyerId"] = self.otherUser.objectId;
                
                if ([self.otherUser objectForKey:@"picture"]) {
                    convoObject[@"buyerPicture"] = [self.otherUser objectForKey:@"picture"];
                }
            }
            
            NSLog(@"create a new convo 2");
            
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
//                    NSLog(@"saved %@    user: %@    listing: %@", convoObject,self.otherUser, self.listingObject);
                    
                    //saved
                    MessageViewController *vc = [[MessageViewController alloc]init];
                    vc.convoId = [NSString stringWithFormat:@"%@%@%@",self.otherUser.objectId,[PFUser currentUser].objectId, self.listingObject.objectId];
                    vc.convoObject = convoObject;
                    vc.listing = self.listingObject;
                    vc.otherUser = self.otherUser;
                    vc.otherUserName = @"";
                    
                    if (self.isBuyer) {
                        vc.userIsBuyer = YES;
                    }
                    
                    vc.fromOrder = YES;
                    vc.pureWTS = YES;
                    
                    [self hideHUD];
                    self.settingUpMessages = NO;
                    
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    NSLog(@"error saving convo %@", error);
                    [self hideHUD];
                    self.settingUpMessages = NO;
                }
            }];
        }
    }];
}

#pragma mark - HUD

-(void)showHUDForCopy:(BOOL)copying{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    
    if (!copying) {
        if (!self.spinner) {
            self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
        }
        
        self.hud.customView = self.spinner;
        [self.spinner startAnimating];
    }
    else{
        self.hud.labelText = @"Copied";
    }
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.hud = nil;
        self.spinner = nil;
    });
}

-(void)addTracking{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Add Tracking" message:nil preferredStyle:UIAlertControllerStyleAlert];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = @"Courier Name";
     }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = @"Tracking Number";
     }];
        
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *courierField = alertController.textFields.firstObject;
        UITextField *trackingField = alertController.textFields.lastObject;
        
        NSString *courierCheck = [courierField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *trackingCheck = [trackingField.text stringByReplacingOccurrencesOfString:@" " withString:@""];

        if (courierCheck.length > 0 && trackingCheck.length > 0) {
            //update order object
            self.addedTracking = YES;
            self.shippingCellHeight += 50;
            [self.tableView reloadData];
            
            NSDictionary *params = @{
                                     @"orderId":self.orderObject.objectId,
                                     @"senderName": [PFUser currentUser].username,
                                     @"otherUserId":self.otherUser.objectId,
                                     @"itemTitle" : [self.orderObject objectForKey:@"itemTitle"],
                                     @"courierName" : courierField.text,
                                     @"trackingId" : trackingField.text
                                     };
            
            [PFCloud callFunctionInBackground:@"addItemTracking" withParameters:params block:^(NSString *orderId, NSError *error) {
                if (!error) {
                    NSLog(@"added item tracking!");
                    [Answers logCustomEventWithName:@"Tracking Added"
                                   customAttributes:@{
                                                      @"orderId" : self.orderObject.objectId
                                                      }];
                }
                else{
                    [Answers logCustomEventWithName:@"Tracking Added Error"
                                   customAttributes:@{
                                                      @"orderId" : self.orderObject.objectId
                                                      }];
                    NSLog(@"error adding tracking %@", error);
                }
            }];
            
            //update UI
            [self.shippingButton setTitle:@"Update Tracking" forState:UIControlStateNormal];
            self.addressView.text = [NSString stringWithFormat:@"%@\n\nCourier: %@\nTracking: %@", self.addressView.text,courierField.text,trackingField.text];
        }

    }];
    [alertController addAction:okAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)showActionSheet{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Support Center" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"View Support VC Pressed"
                       customAttributes:@{
                                          @"from":@"order"
                                          }];
        
        supportVC *vc = [[supportVC alloc]init];
        vc.tier1Mode = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }]];

    //CHANGE
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Check Order Status" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        //call check order status
        //need paypal orderId and bump orderId

        NSDictionary *params = @{@"bumpOrderId": self.orderObject.objectId, @"ppOrderId":[self.orderObject objectForKey:@"paypalOrderId"]};
        [PFCloud callFunctionInBackground:@"checkOrderStatus" withParameters:params block:^(NSDictionary *response, NSError *error) {
            if (!error) {
                NSLog(@"order status response %@", response);

            }
            else{
                NSLog(@"order status error %@", error);
            }
        }];
    }]];

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Copy Order #ID" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Copied Order ID"
                       customAttributes:@{}];
        
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:[NSString stringWithFormat:@"#%@",[self.orderObject.objectId uppercaseString]]];
        
        //show HUD
        [self showHUDForCopy:YES];
        
        double delayInSeconds = 2.0; // number of seconds to wait
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self hideHUD];
            self.hud.labelText = @"";
        });
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}
@end
