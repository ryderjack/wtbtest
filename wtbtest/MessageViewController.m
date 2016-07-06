//
//  MessageViewController.m
//  
//
//  Created by Jack Ryder on 17/06/2016.
//
//

#import "MessageViewController.h"
#import "CheckoutController.h"
#import "DetailImageController.h"
#import "UserProfileController.h"

@interface MessageViewController ()

@end

@implementation MessageViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.otherUserName isEqualToString:@""]) {
        [self.otherUser fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                self.title = self.otherUser.username;
            }
        }];
    }
    else{
       self.title = self.otherUserName;
    }
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(clearOffer)];
    self.profileButton = [[UIBarButtonItem alloc] initWithTitle:@"Profile" style:UIBarButtonItemStylePlain target:self action:@selector(profileTapped)];
    self.navigationItem.rightBarButtonItem = self.profileButton;
    
    self.inputToolbar.contentView.textView.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    self.inputToolbar.contentView.textView.placeHolder = @"Tap the tag icon to send an offer";
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"tagIcon"] forState:UIControlStateNormal];
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"tagIconG"] forState:UIControlStateHighlighted];
    
    self.showLoadEarlierMessagesHeader = YES;
    
    //no avatar images
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    //Register custom menu actions for cells.

    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];

    /**
     *  Customize your toolbar buttons
     *
     *  self.inputToolbar.contentView.leftBarButtonItem = custom button or nil to remove
     *  self.inputToolbar.contentView.rightBarButtonItem = custom button or nil to remove
     */
    
    /**
     *  Set a maximum height for the input toolbar
     *
     *  self.inputToolbar.maximumHeight = 150;
     */
    
    self.senderId = [PFUser currentUser].objectId;
    
    self.messages = [[NSMutableArray alloc]init];
    self.messagesParseArray = [[NSMutableArray alloc]init];
    self.sentMessagesParseArray = [[NSMutableArray alloc]init];
    
    self.skipped = 0;
    
    self.offerMode = NO;
    self.earlierPressed = NO;
    
    [self loadMessages];
    
    self.bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularTaillessImage] capInsets:UIEdgeInsetsZero];
    
    JSQMessagesBubbleImageFactory *bubbleFactoryOutline = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularStrokedTaillessImage] capInsets:UIEdgeInsetsZero];
    
    self.outgoingBubbleImageData = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1]];
    
    self.incomingBubbleImageData = [bubbleFactoryOutline incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1]];
    
    self.offerBubbleImageData = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1]];
    
     self.masker = [[JSQMessagesMediaViewBubbleImageMasker alloc]initWithBubbleImageFactory:self.bubbleFactory];
}

-(void)loadMessages{
    PFQuery *messageQuery = [PFQuery queryWithClassName:@"messages"];
    [messageQuery whereKey:@"convoId" equalTo:self.convoId];
    messageQuery.limit = 10;
    messageQuery.skip = self.skipped;
    [messageQuery orderByDescending :@"createdAt"];
    [messageQuery includeKey:@"offerObject"];
    [messageQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count < 10) {
                self.showLoadEarlierMessagesHeader = NO;
            }
            else{
                self.showLoadEarlierMessagesHeader = YES;
            }
            
            int count = (int)[objects count];
            self.skipped = count + self.skipped;
            
            for (PFObject *messageOb in objects) {
                
                if (![self.messagesParseArray containsObject:messageOb]) {
                    [self.messagesParseArray addObject:messageOb];
                }
            
                __block JSQMessage *message = nil;
                
                if (![[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                    [messageOb setObject:@"seen" forKey:@"status"];
                    [messageOb saveInBackground];
                }
                else{
                    // only add current user's messages to parse array so last one's status can be displayed
                    if (![self.sentMessagesParseArray containsObject:messageOb]) {
                        [self.sentMessagesParseArray addObject:messageOb];
                    }
                }

                if ([[messageOb objectForKey:@"mediaMessage"] isEqualToString:@"YES"]) {
                    
                    //media message
                    
                    __block id<JSQMessageMediaData> newMediaData = nil;
                    __block id newMediaAttachmentCopy = nil;
                    __block JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc]init];
                    photoItem.image = nil;
                    
                    message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt media:photoItem];
                    [self.messages insertObject:message atIndex:0];
                    message.msgObject = messageOb;

                    PFQuery *imageQuery = [PFQuery queryWithClassName:@"messageImages"];
                    [imageQuery whereKey:@"objectId" equalTo:[messageOb objectForKey:@"message"]];
                    
                    [imageQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                        if (!error) {
                            PFFile *img = [object objectForKey:@"Image"];
                            [img getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                if (!error) {
                                    
                                    UIImage *messageImage = [UIImage imageWithData:data];
                                    photoItem.image = messageImage;
                                    
                                    newMediaAttachmentCopy = [UIImage imageWithCGImage:photoItem.image.CGImage];
                                    newMediaData = photoItem;
                                    [message setValue:newMediaData forKey:@"media"];
                                    [self.collectionView reloadData];

                                    if ([[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                                        [self.masker applyOutgoingBubbleImageMaskToMediaView:photoItem.mediaView];
                                    }
                                    else{
                                        [self.masker applyIncomingBubbleImageMaskToMediaView:photoItem.mediaView];
                                    }
                                    
                                    if (self.earlierPressed == NO) {
                                        [self scrollToBottomAnimated:NO];
                                    }
                                }
                            }];
                        }
                        else{
                            NSLog(@"error with image query %@", error);
                        }
                    }];
                }
                else{
                    
                    NSString *messageText = [messageOb objectForKey:@"message"];
                    
                    if (![[messageOb objectForKey:@"senderId"] isEqualToString:[PFUser currentUser].objectId]) {
                        messageText = [[messageOb objectForKey:@"message"]stringByReplacingOccurrencesOfString:@"\nTap to cancel offer" withString:@"\nTap to buy now"];
                    }
                    
                    message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt text:messageText];
                    
                    if ([[messageOb objectForKey:@"offer"]isEqualToString:@"YES"]) {
                        PFObject *offerOb = [messageOb objectForKey:@"offerObject"];
                        if ([[offerOb objectForKey:@"status"]isEqualToString:@"open"]) {
                            message.isOfferMessage = YES;
                            message.offerObject = offerOb;
                        }
                    }
                    
                    [self.messages insertObject:message atIndex:0];
                    [self.collectionView reloadData];
                    
                    if (self.earlierPressed == NO) {
                        [self scrollToBottomAnimated:NO];
                    }
                }
            }
        }
        else{
            NSLog(@"no messages");
        }
//        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(loadMessages) userInfo:nil repeats:NO];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /**
     *  Enable/disable springy bubbles, default is NO.
     *  You must set this from `viewDidAppear:`
     *  Note: this feature is mostly stable, but still experimental
     */
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
    
    if (self.sellThisPressed == YES) {
        self.offerMode = YES;
        self.inputToolbar.contentView.textView.text = @"Selling:\nCondition:\nPrice:£\nMeetup:";
    }
}

#pragma mark - Custom menu actions for cells

- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification
{
    /**
     *  Display custom menu actions for cells.
     */
    UIMenuController *menu = [notification object];
    menu.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Custom Action" action:@selector(customAction:)] ];
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    NSString *messageString = text;
    
    if (self.offerMode == YES) {
        
        // offer message
//        messageString = [NSString stringWithFormat:@"%@\nTap to buy now", text];
        
//        //create offer object in bg
        NSArray *strings = [text componentsSeparatedByString:@"\n"];
        
        NSString *itemTitle = @"";
        NSString *condition = @"";
        NSString *meetup = @"";
        NSString *priceString = @"";
        
        //extract offer data
        for (NSString *substring in strings) {
            NSArray *detailStrings = [substring componentsSeparatedByString:@":"];
            NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
            
            if ([detailStrings[0] containsString:@"Selling"]) {
                itemTitle = [detailStrings[1] stringByTrimmingCharactersInSet:set];
                NSLog(@"item title: %@", itemTitle);
                
                if ([itemTitle length] == 0){
                    [self showAlertWithTitle:@"Enter a valid item title" andMsg:@"Tell the buyer what you're selling!"];
                    return;
                }
            }
            else if ([detailStrings[0] containsString:@"Condition"]){
                condition = [detailStrings[1] stringByTrimmingCharactersInSet:set];
                NSLog(@"condition: %@",condition);
                
                if ([condition length] == 0){
                    [self showAlertWithTitle:@"Enter a valid condition for your item" andMsg:@"BNWT/BNWOT/Used?"];
                    return;
                }
            }
            else if ([detailStrings[0] containsString:@"Price"]){
                NSString *offerPriceString = [detailStrings[1] stringByTrimmingCharactersInSet:set];
                NSLog(@"entered string for price: %@", offerPriceString);
                
                NSArray *priceArray = [offerPriceString componentsSeparatedByString:@"."];
                
                if ([priceArray[0] isEqualToString:@"£"]) {
                    priceString = @"£0.00";
                }
                else if (priceArray.count > 1){
                    NSString *intAmount = priceArray[0];
                    
                    if (intAmount.length == 1){
                        NSLog(@"just the £ then a decimal point");
                        intAmount = @"£00";
                    }
                    else{
                        NSLog(@"got a number + the £");
                    }
                    
                    NSMutableString *centAmount = priceArray[1];
                    if (centAmount.length == 2){
                        NSLog(@"all good");
                    }
                    else if (centAmount.length == 1){
                        NSLog(@"got 1 decimal place");
                        centAmount = [NSMutableString stringWithFormat:@"%@0", centAmount];
                    }
                    else{
                        NSLog(@"point but no numbers after it");
                        centAmount = [NSMutableString stringWithFormat:@"%@00", centAmount];
                    }
                    
                    priceString = [NSString stringWithFormat:@"%@.%@", intAmount, centAmount];
                }
                else{
                    priceString = [NSString stringWithFormat:@"%@.00", offerPriceString];
                    NSLog(@"no decimal point so price is %@", priceString);
                }
                
                if ([priceString isEqualToString:@"£0.00"] || [priceString isEqualToString:@""] || [priceString isEqualToString:@" £.00"] || [priceString isEqualToString:@"  "]) {
                    NSLog(@"invalid price entered! %@", priceString);
                    [self showAlertWithTitle:@"Enter a valid price" andMsg:@"Not sure even I'd sell for that much.."];
                    return;
                }
            }
            else if ([detailStrings[0] containsString:@"Meetup"]){
                NSLog(@"meetup: %@", detailStrings[1]);
                meetup = detailStrings[1];

                if ([[meetup stringByTrimmingCharactersInSet: set] length] == 0){
                    [self showAlertWithTitle:@"Enter a value for 'Meetup'" andMsg:@"Just a yes or no will do!"];
                    return;
                }
            }
        }
        
        [JSQSystemSoundPlayer jsq_playMessageSentSound];
        
        NSString *prefixToRemove = @"£";
        NSString *salePrice = [[NSString alloc]init];
        salePrice = [priceString substringFromIndex:[prefixToRemove length]];
        float salePriceFloat = [salePrice intValue];
        
        self.offerObject = nil;
        self.offerObject = [PFObject objectWithClassName:@"offers"];
        
        [self.offerObject setObject:self.listing forKey:@"wtbListing"];
        [self.offerObject setObject:itemTitle forKey:@"title"];
        [self.offerObject setObject:condition forKey:@"condition"];
        self.offerObject[@"salePrice"] = @(salePriceFloat);
        [self.offerObject setObject:self.otherUser forKey:@"buyerUser"];
        [self.offerObject setObject:[PFUser currentUser] forKey:@"sellerUser"];
        [self.offerObject setObject:self.convoObject forKey:@"convo"];
        [self.offerObject setObject:@"open" forKey:@"status"];
    }
    
    if (self.offerMode == YES) {
//        messageString = [messageString stringByReplacingOccurrencesOfString:@"\nTap to buy now" withString:@"\nTap to cancel offer"];
        messageString = [NSString stringWithFormat:@"%@\nTap to cancel offer", text];
    }
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:messageString];
    if (self.offerMode == YES) {
        message.offerObject = self.offerObject;
    }
    
    [self.messages addObject:message];
    
    PFObject *messageObject = [PFObject objectWithClassName:@"messages"];
    messageObject[@"message"] = messageString;
    messageObject[@"sender"] = [PFUser currentUser];
    messageObject[@"senderId"] = [PFUser currentUser].objectId;
    messageObject[@"senderName"] = [PFUser currentUser].username;
    messageObject[@"convoId"] = self.convoId;
    messageObject[@"status"] = @"sent";
    if (self.offerMode == YES) {
        messageObject[@"offer"] = @"YES";
        messageObject[@"offerObject"] = self.offerObject;
        message.isOfferMessage = YES;
    }
    else{
        messageObject[@"offer"] = @"NO";
        message.isOfferMessage = NO;
    }
    
    messageObject[@"mediaMessage"] = @"NO";
    [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded == YES) {
            NSString *pushText = messageString;
            if (self.offerMode == YES) {
                pushText = @"sent an offer 🔌";
            }
            //send push to other user
            NSDictionary *params = @{@"userId": self.otherUser.objectId, @"message": pushText, @"sender": [PFUser currentUser].username};
            [PFCloud callFunctionInBackground:@"sendPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    NSLog(@"response %@", response);
                }
                else{
                    NSLog(@"push error %@", error);
                }
            }];
        }
    }];
    
    [self finishSendingMessageAnimated:YES];
    
    // add new message object to relevant arrays
    [self.sentMessagesParseArray insertObject:messageObject atIndex:0];
    [self.messagesParseArray insertObject:messageObject atIndex:0];
    
    //call attributedString method to update labels
    NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
    NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
    NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];
    
    [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
    [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
    [self.collectionView reloadItemsAtIndexPaths:@[pathToLastItem]];
    
    if (self.offerMode == YES) {
        self.navigationItem.rightBarButtonItem = nil;
        
        if ([self.convoObject objectForKey:@"convoImages"] == 0) {
            //images have been previously sent in the chat so don't need to send anymore
            CameraController *vc = [[CameraController alloc]init];
            vc.delegate = self;
            vc.offerMode = YES;
            [self presentViewController:vc animated:YES completion:nil];
        }
        else{
            self.offerMode = NO;
            PFQuery *convoImagesQuery = [PFQuery queryWithClassName:@"messageImages"];
            [convoImagesQuery whereKey:@"convo" equalTo:self.convoObject];
            [convoImagesQuery orderByDescending:@"createdAt"];
            [convoImagesQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    NSLog(@"got the last image object from the convo %@", object);
                    
                    [self.offerObject setObject:[object objectForKey:@"Image"] forKey:@"image"];
                }
                else{
                    NSLog(@"error %@", error);
                }
                [self.offerObject saveInBackground];
            }];
        }
    }
    
    //update convo object after every message sent
    [self.convoObject incrementKey:@"totalMessages"];
    [self.convoObject setObject:messageObject forKey:@"lastSent"];
    [self.convoObject saveInBackground];
}

-(void)textViewDidChange:(UITextView *)textView{
    if (textView == self.inputToolbar.contentView.textView) {
        if (![textView.text containsString:@"\nSelling:"] && ![textView.text containsString:@"\nCondition:"] && ![textView.text containsString:@"\nPrice:"] && ![textView.text containsString:@"\nMeetup:"]) {
            self.offerMode = NO;
        }
        [self.inputToolbar toggleSendButtonEnabled];
    }
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
    [self alertSheet];
}

-(void)alertSheet{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    
    if (self.userIsBuyer == YES) {
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Send an offer" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.offerMode = YES;
            self.inputToolbar.contentView.textView.text = @"Selling: \nCondition: \nPrice: £\nMeetup: ";
            self.navigationItem.rightBarButtonItem = self.cancelButton;
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            CameraController *vc = [[CameraController alloc]init];
            vc.delegate = self;
            vc.offerMode = YES;
            [self presentViewController:vc animated:YES completion:nil];
        }]];
        
    }
    else{
        //show different options
    }
    
    
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Pay with PayPal" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Report user" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report inappropriate behaviour" message:@"bump takes inappropriate behaviour very seriously.\nIf you feel like this user has behaved wrongly please let us know so we can make your experience on bump as brilliant as possible." preferredStyle:UIAlertControllerStyleAlert];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
        }]];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            PFObject *reportObject = [PFObject objectWithClassName:@"ReportedUsers"];
            reportObject[@"reportedUser"] = self.otherUser;
            reportObject[@"reporter"] = [PFUser currentUser];
            reportObject[@"convo"] = self.convoObject;
            [reportObject saveInBackground];
        }]];
        [self presentViewController:alertView animated:YES completion:nil];
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)finalImage:(UIImage *)image{
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:self.senderId
                                                   displayName:self.senderDisplayName
                                                         media:photoItem];
    [self.masker applyOutgoingBubbleImageMaskToMediaView:photoItem.mediaView];
    [self.messages addObject:photoMessage];
    [self finishSendingMessageAnimated:YES];
    
    PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:UIImageJPEGRepresentation(image, 0.6)];
    [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (error) {
             NSLog(@"error %@", error);
         }
         else{
             NSLog(@"saved image");
         }
     }];
    
    PFObject *picObject = [PFObject objectWithClassName:@"messageImages"];
    [picObject setObject:filePicture forKey:@"Image"];
    [picObject setObject:self.convoObject forKey:@"convo"];
    [picObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            self.messageObject = [PFObject objectWithClassName:@"messages"];
            self.messageObject[@"message"] = picObject.objectId;
            self.messageObject[@"sender"] = [PFUser currentUser];
            self.messageObject[@"senderId"] = [PFUser currentUser].objectId;
            self.messageObject[@"senderName"] = [PFUser currentUser].username;
            self.messageObject[@"convoId"] = self.convoId;
            self.messageObject[@"status"] = @"sent";
            self.messageObject[@"mediaMessage"] = @"YES";
            if (self.tagString) {
                NSLog(@"setting tag");
                [self.messageObject setObject:self.tagString forKey:@"tagString"];
            }
            [self.messageObject saveInBackground];
            
            //set msg object so photo is tagged
            photoMessage.msgObject = self.messageObject;
            
            if (![self.senderId isEqualToString:self.otherUser.objectId]) {
                [self.convoObject incrementKey:@"convoImages"];
            }
            
            NSLog(self.offerMode ? @"YES":@"NO");
            
            if (self.offerMode == YES) {
                [self.offerObject setObject:picObject forKey:@"image"];
                [self.offerObject saveEventually];
            }
            else{
                [self.convoObject setObject:self.messageObject forKey:@"lastSent"];
                
                //send push to other user
                NSDictionary *params = @{@"userId": self.otherUser.objectId, @"message": @"📸", @"sender": [PFUser currentUser].username};
                [PFCloud callFunctionInBackground:@"sendPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                    if (!error) {
                        NSLog(@"response %@", response);
                        
                    }
                    else{
                        NSLog(@"image push error %@", error);
                    }
                }];
            }
            
            self.offerMode = NO;
            [self.convoObject incrementKey:@"totalMessages"];
            [self.convoObject saveInBackground];
            
            // add new message object to relevant arrays
            [self.sentMessagesParseArray insertObject:picObject atIndex:0];
            [self.messagesParseArray insertObject:picObject atIndex:0];
            
            //call attributedString method to update labels
            NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
            NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
            NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];
            
            [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
            [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
            [self.collectionView reloadItemsAtIndexPaths:@[pathToLastItem]];
        }
        else{
            NSLog(@"error saving %@", error);
        }
    }];
}

-(void)dismissPressed:(BOOL)yesorno{
    if (yesorno == YES && self.offerMode == YES) {
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Take a picture of the item you're selling" message:@"Take a picture now of the item you're selling. Tap the tag icon then 'Take a picture'" preferredStyle:UIAlertControllerStyleAlert];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
        }]];
        [self presentViewController:alertView animated:YES completion:nil];
    }
}

-(void)tagString:(NSString *)tag{
    self.tagString = tag;
    NSLog(@"tag %@", self.tagString);
}

#pragma mark - JSQMessages CollectionView DataSource

- (NSString *)senderDisplayName {
    return [PFUser currentUser].username;
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.item];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    [self.messages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = self.messages[indexPath.item];
    
    if (message.isOfferMessage == YES) {
        return self.offerBubbleImageData;
    }
    
    if ([message.senderId isEqualToString:self.senderId])
    {
        return self.outgoingBubbleImageData;
    }
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
//    JSQMessage *message = [self.demoData.messages objectAtIndex:indexPath.item];
//    
//    if ([message.senderId isEqualToString:self.senderId]) {
//        if (![NSUserDefaults outgoingAvatarSetting]) {
//            return nil;
//        }
//    }
//    else {
//        if (![NSUserDefaults incomingAvatarSetting]) {
//            return nil;
//        }
//    }
    
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.sentMessagesParseArray.count > 0 && self.messagesParseArray.count > 0) {
        if ([self.messagesParseArray containsObject:self.sentMessagesParseArray[0]]) {
            
            //user has sent a message
            
            NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
            NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
            NSInteger itemIndex = [self.messagesParseArray indexOfObject:self.sentMessagesParseArray[0]];
            NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:(lastItemIndex -itemIndex)inSection:lastSectionIndex];
            
            if (indexPath == pathToLastItem) {
                NSString *statusString = [[self.sentMessagesParseArray objectAtIndex:0]objectForKey:@"status"];
                
                if ([statusString isEqualToString:@"sent"]||[statusString isEqualToString:@"seen"]) {
                    //valid status, go ahead
                    NSAttributedString *string = [[NSAttributedString alloc]initWithString:statusString];
                    return string;
                }
                else{
                    //invalid status, return sent as default
                    NSAttributedString *invalString = [[NSAttributedString alloc]initWithString:@"sent"];
                    return invalString;
                }
            }
            else{
                //index path is not last
            }
        }
        else{
            //user hasn't send a message
        }
    }
    
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    UIEdgeInsets insets = {-5, 0, 0, 10};
    cell.cellBottomLabel.textInsets = insets;
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.messages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        cell.textView.textColor = [UIColor blackColor];
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    if (msg.isOfferMessage) {
        cell.textView.textColor = [UIColor whiteColor];
    }
    
    return cell;
}

#pragma mark - UICollectionView Delegate

#pragma mark - Custom menu items

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        [self customAction:sender];
        return;
    }
    
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)customAction:(id)sender
{
    NSLog(@"Custom action received! Sender: %@", sender);
    
}

#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
        if (self.sentMessagesParseArray.count > 0 && self.messagesParseArray.count > 0) {
            if ([self.messagesParseArray containsObject:self.sentMessagesParseArray[0]]) {
                NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
                NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
                NSInteger itemIndex = [self.messagesParseArray indexOfObject:self.sentMessagesParseArray[0]];
                NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:(lastItemIndex -itemIndex)inSection:lastSectionIndex];
                if (indexPath == pathToLastItem) {
                    return kJSQMessagesCollectionViewCellLabelHeightDefault;
                }
                else{
                    return 0.0f;
                }
            }
            else{
                return 0.0f;
            }
        }
        else{
            return 0.0f;
        } 
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    self.earlierPressed = YES;
    [self loadMessages];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{

    JSQMessage *tappedMessage = [self.messages objectAtIndex:indexPath.item];
    
    if ([[self.messages objectAtIndex:indexPath.item] isMediaMessage] == YES){
        DetailImageController *vc = [[DetailImageController alloc]init];
        vc.listingPic = NO;
        vc.numberOfPics = 1;
        vc.messagesPicMode = YES;
        vc.tagText = [tappedMessage.msgObject objectForKey:@"tagString"];
        id<JSQMessageMediaData> mediaItem = tappedMessage.media;
        JSQPhotoMediaItem *photoItem = (JSQPhotoMediaItem *)mediaItem;
        vc.messagePicture = photoItem.image;
        
        [self presentViewController:vc animated:YES completion:nil];
    }
    
    else if ([tappedMessage.senderId isEqualToString:[PFUser currentUser].objectId]) {
        if (tappedMessage.isOfferMessage == YES) {
            
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Cancel offer" message:@"Are you sure you want to cancel your offer? If the buyer has already purchased the item then you must explain the situation asap" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                PFObject *offerObj = tappedMessage.offerObject;
                [offerObj setObject:@"cancelled" forKey:@"status"];
                [offerObj saveInBackground];
                tappedMessage.isOfferMessage = NO;
                [self.collectionView reloadData];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }
    else{
        if (tappedMessage.isOfferMessage == YES) { //doesnt work after offer with image just been sent but does that matter because seller shouldnt click thru to offer
            if ([[tappedMessage.offerObject objectForKey:@"status"]isEqualToString:@"open"]) {
                CheckoutController *vc = [[CheckoutController alloc]init];
                vc.confirmedOfferObject = tappedMessage.offerObject;
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!",NSStringFromCGPoint(touchLocation));
}

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods

- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
{
    return NO;
}

-(void)clearOffer{
    self.inputToolbar.contentView.textView.text = @"";
    self.offerMode = NO;
    self.navigationItem.rightBarButtonItem = self.profileButton;
}

-(void)profileTapped{
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = self.otherUser;
    [self.navigationController pushViewController:vc animated:YES];
}
@end
