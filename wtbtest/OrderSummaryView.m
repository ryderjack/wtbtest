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
    
    self.transCellHeight = 213;
    self.titleCellHeight = 198;
    self.gotFBCellHeight = 181;
    self.leftFBCellHeight = 181;
    self.leaveFBCellHeight = 195;
    self.paymentCellHeight = 320;
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
    
    [self cropProfilePic];
    
    self.dateFormat = [[NSDateFormatter alloc] init];
    [self.dateFormat setLocale:[NSLocale currentLocale]];
    [self.dateFormat setDateFormat:@"dd MMM YYYY"];
    NSString *orderDateString = [self.dateFormat stringFromDate:self.orderObject.createdAt];

    //don't need to fetch, have all info already - no pointers needed.
    
    //setup cells
    
    [self.orderObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            
            if ([[self.orderObject objectForKey:@"buyerId"]isEqualToString:[PFUser currentUser].objectId]) {
                self.isBuyer = YES;
            }
            
            //listing cell
            //get correct size label
            //check if has size
            self.titleLabel.text = [NSString stringWithFormat:@"%@\n%@",[self.orderObject objectForKey:@"itemTitle"],[self.orderObject objectForKey:@"itemSize"]];
            [self.itemImageView setFile:[self.orderObject objectForKey:@"itemImage"]];
            [self.itemImageView loadInBackground];
            
            if (self.isBuyer) {
                self.otherUser = [self.orderObject objectForKey:@"sellerUser"];
                [self.refundButton setTitle:@"Request Refund" forState:UIControlStateNormal];
            }
            else{
                self.otherUser = [self.orderObject objectForKey:@"buyerUser"];
                [self.refundButton setTitle:@"Issue Refund" forState:UIControlStateNormal];
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
                        
                        transText = [NSString stringWithFormat:@"Purchased on %@ from\n%@\n@%@",orderDateString,[self.otherUser objectForKey:@"fullname"],self.otherUser.username];
                        
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
            self.addressLabel.text = [self.orderObject objectForKey:@"shippingAddress"];
            
            //setup payment info
            NSString *paymentString;
            
            self.itemPriceLabel.text = [self.orderObject objectForKey:@"salePriceLabel"];
            self.shippingPriceLabel.text = [self.orderObject objectForKey:@"shippingPriceLabel"];
            self.totalPriceLabel.text = [self.orderObject objectForKey:@"totalPriceLabel"];
            
            if (self.isBuyer) {
                paymentString = [NSString stringWithFormat:@"Payment Sent\n%@ sent using PayPal",[self.orderObject objectForKey:@"totalPriceLabel"]];
            }
            else{
                paymentString = [NSString stringWithFormat:@"Payment Received\n%@ sent to your PayPal",[self.orderObject objectForKey:@"totalPriceLabel"]];
            }
            self.paymentLabel.text = paymentString;
            
            
            //setup next steps
            
            //reviews
            if (self.isBuyer) {
                
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
                    
                    self.addressLabel.text = [NSString stringWithFormat:@"%@\n\nCourier: %@\nTracking: %@", self.addressLabel.text,[self.orderObject objectForKey:@"courierName"], [self.orderObject objectForKey:@"trackingId"]];
                    
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
                    [self.shippingButton setTitle:@"Report a Shipping Issue" forState:UIControlStateNormal];
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

    //title/transaction/payment/shipping/leave review
    if (self.rowNumber == 5 && !self.leftFeedback) {
        if (indexPath.row == 1) {
            return self.leaveFeedbackCell;
        }
        else if (indexPath.row == 2) {
            return self.shippingCell;
        }
        else if (indexPath.row == 3) {
            return self.paymentCell;
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
        else if (indexPath.row == 3) {
            return self.paymentCell;
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
        else if (indexPath.row == 4) {
            return self.paymentCell;
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
        else if (indexPath.row == 4) {
            return self.paymentCell;
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
            feedbackObject = [self.orderObject objectForKey:@"sellerReview"]; //this is the review of the buyer NOT the review the buyer left
        }
        else{
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
    
    [self showHUD];
    
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
    [self.viewListingButton setEnabled:YES];
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)messagePressed:(id)sender {
    [self setupMessages];
}
- (IBAction)refundPressed:(id)sender {
}
- (IBAction)shippingButtonPressed:(id)sender {
    if (!self.shipped) {
        if (self.isBuyer) {
            [self helpPressed];
        }
        else{
            [self showHUD];
            [self.orderObject setObject:@"YES" forKey:@"shipped"];
            [self.orderObject setObject:[NSDate date] forKey:@"shippedDate"];
            [self.orderObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    [self hideHUD];
                    self.shipped = YES;
                    
                    //send a push to the buyer
                    NSString *pushString = [NSString stringWithFormat:@"%@ just shipped '%@' ✈️", [PFUser currentUser].username, [self.orderObject objectForKey:@"itemTitle"]];
                    
                    NSDictionary *params = @{@"userId": self.otherUser.objectId, @"message": pushString, @"sender": [PFUser currentUser].username};
                    [PFCloud callFunctionInBackground:@"sendPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                        if (!error) {
                            NSLog(@"response sending review push %@", response);
                            
                            [Answers logCustomEventWithName:@"Sent Shipping Push"
                                           customAttributes:@{
                                                              @"success":@"YES"
                                                              }];
                        }
                        else{
                            NSLog(@"review push error %@", error);
                            
                            [Answers logCustomEventWithName:@"Sent Shipping Push"
                                           customAttributes:@{
                                                              @"success":@"NO",
                                                              @"error" : error.description
                                                              }];
                        }
                    }];
                    
                    //update shipping cell
                    [self.shippingImageView setImage:[UIImage imageNamed:@"OrderCheck"]];
                    [self.dateFormat setDateFormat:@"dd MMM YYYY"];
                    NSDate *shippedDate = [self.orderObject objectForKey:@"shippedDate"];
                    self.shippingMainLabel.text = [NSString stringWithFormat:@"Item Shipped\nSent on %@ to",[self.dateFormat stringFromDate:shippedDate]];
                    [self.shippingButton setTitle:@"Add Tracking" forState:UIControlStateNormal];
                    
                    //update next step label
                    [self calcStatus];
                }
                else{
                    [self hideHUD];
                    NSLog(@"error marking as shipped");
                }
            }];
        }
    }
    else{
        if (self.isBuyer) {
            //report an issue pressed
            [self helpPressed];
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
    if (self.isBuyer) {
        if (!self.leftFeedback) {
            [self leaveFeedbackPressed:self];
        }
    }
    else{
        if (!self.shipped){
            [self shippingButtonPressed:self];
        }
        else if (!self.leftFeedback) {
            [self leaveFeedbackPressed:self];
        }
    }
}


#pragma mark - feedback delegate
-(void)leftReview{
    self.leftFeedback = YES;
    
    //update stars & label in leftReviewCell
    int leftStars = 0;

    if (self.isBuyer) {
        if ([[self.orderObject objectForKey:@"buyerLeftFeedback"] isEqualToString:@"YES"]) {
            //current user left a review
            NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"You left feedback for\n@%@", self.otherUser.username]];
            [self.leftFeedbackLabel setAttributedText:[self modifyString:labelText setFontForText:[NSString stringWithFormat:@"@%@", self.otherUser.username]]];
            
            leftStars = [[self.orderObject objectForKey:@"sellerStars"]intValue];

        }
    }
    else{
        if ([[self.orderObject objectForKey:@"sellerLeftFeedback"] isEqualToString:@"YES"]) {
            //current user left a review
            NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"You left feedback for\n@%@", self.otherUser.username]];
            [self.leftFeedbackLabel setAttributedText:[self modifyString:labelText setFontForText:[NSString stringWithFormat:@"@%@", self.otherUser.username]]];
        }
        
        leftStars = [[self.orderObject objectForKey:@"buyerStars"]intValue];
    }
    
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

-(void)calcStatus{
    NSString *nextStep;
    BOOL complete = NO;
    
    if (self.isBuyer) {
        if (!self.leftFeedback) {
            nextStep = @"Leave Feedback";
        }
        else if (!self.shipped){
            nextStep = @"Awaiting Shipment";
            if ([[self.orderObject objectForKey:@"buyerUnseen"]intValue] != 0) {
                self.orderObject[@"buyerUnseen"] = @0;
                [self.orderObject saveInBackground];
            }
        }
        else if (!self.gotFeedback){
            nextStep = @"Awaiting Feedback";
            if ([[self.orderObject objectForKey:@"buyerUnseen"]intValue] != 0) {
                self.orderObject[@"buyerUnseen"] = @0;
                [self.orderObject saveInBackground];
            }
        }
        else{
            if ([[self.orderObject objectForKey:@"buyerUnseen"]intValue] != 0) {
                self.orderObject[@"buyerUnseen"] = @0;
                [self.orderObject saveInBackground];
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
                self.orderObject[@"sellerUnseen"] = @0;
                [self.orderObject saveInBackground];
            }
        }
        else{
            complete = YES;
            if ([[self.orderObject objectForKey:@"sellerUnseen"]intValue] != 0) {
                self.orderObject[@"sellerUnseen"] = @0;
                [self.orderObject saveInBackground];
            }
        }
    }
    if (complete) {
        if (self.isBuyer) {
            self.nextStepLabel.text = @"Purchase Complete";
        }
        else{
            self.nextStepLabel.text = @"Sale Complete";
        }
    }
    else{
        NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"Next Step %@", nextStep]];
        [self.nextStepLabel setAttributedText:[self modifyString:labelText setColorForText:nextStep withColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]]];
    }
}

-(void)setupMessages{
    if (!self.fetchedUser || self.settingUpMessages || !self.otherUser) {
        NSLog(@"returning!");
        return;
    }
    
    self.settingUpMessages = YES;
    
    [self showHUD];
    
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
                    NSLog(@"saved %@    user: %@    listing: %@", convoObject,self.otherUser, self.listingObject);
                    
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

-(void)showHUD{
    
    if (!self.spinner) {
        self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    }
    
    [self.spinner startAnimating];
    
    if (!self.hud) {
        self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        self.hud.square = YES;
        self.hud.mode = MBProgressHUDModeCustomView;
        self.hud.customView = self.spinner;
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
            
            [self.orderObject setObject:@"YES" forKey:@"trackingAdded"];
            [self.orderObject setObject:trackingField.text forKey:@"trackingId"];
            [self.orderObject setObject:courierField.text forKey:@"courierName"];
            [self.orderObject saveInBackground];
            
            //update UI
            [self.shippingButton setTitle:@"Update Tracking" forState:UIControlStateNormal];
            self.addressLabel.text = [NSString stringWithFormat:@"%@\n\nCourier: %@\nTracking: %@", self.addressLabel.text,courierField.text,trackingField.text];
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
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Contact Support" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self helpPressed];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}
@end
