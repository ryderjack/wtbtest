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

@interface MessageViewController ()

@end

@implementation MessageViewController

#pragma mark - View lifecycle

/**
 *  Override point for customization.
 *
 *  Customize your view.
 *  Look at the properties on `JSQMessagesViewController` and `JSQMessagesCollectionView` to see what is possible.
 *
 *  Customize your layout.
 *  Look at the properties on `JSQMessagesCollectionViewFlowLayout` to see what is possible.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.otherUserName;
    
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
                                        [self scrollToBottomAnimated:YES];
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
                        messageText = [[messageOb objectForKey:@"message"]stringByReplacingOccurrencesOfString:@"Tap to buy now" withString:@""];
                    }
                    
                    message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt text:messageText];
                    
                    if ([[messageOb objectForKey:@"offer"]isEqualToString:@"YES"]) {
                        message.isOfferMessage = YES;
                        message.offerObject = [messageOb objectForKey:@"offerObject"];
                    }
                    
                    [self.messages insertObject:message atIndex:0];
                    [self.collectionView reloadData];
                    
                    if (self.earlierPressed == NO) {
                        [self scrollToBottomAnimated:YES];
                    }
                }
            }
        }
        else{
            NSLog(@"no messages");
        }
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
        self.inputToolbar.contentView.textView.text = @"Selling:\nCondition:\nPrice:£\nMeetup?:";
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

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    NSString *messageString = text;
    
    if (self.offerMode == YES) {
        
        // offer message
        messageString = [NSString stringWithFormat:@"%@\nTap to buy now", text];
        
//        //create offer object in bg
        NSArray *strings = [text componentsSeparatedByString:@"\n"];
        
        NSString *itemTitle = @"";
        NSString *condition = @"";
        NSString *meetup = @"";
        NSString *priceString = @"";
        
        for (NSString *substring in strings) {
            NSArray *detailStrings = [substring componentsSeparatedByString:@":"];
            
            if ([detailStrings[0] containsString:@"Selling"]) {
                NSLog(@"item title: %@", detailStrings[1]);
                itemTitle = detailStrings[1];
            }
            else if ([detailStrings[0] containsString:@"Condition"]){
                NSLog(@"condition: %@", detailStrings[1]);
                condition = detailStrings[1];
            }
            else if ([detailStrings[0] containsString:@"Price"]){
                NSLog(@"price: %@", detailStrings[1]);
                
                NSArray *priceArray = [detailStrings[1] componentsSeparatedByString:@"."];
                NSLog(@"price array %@", priceArray);
                
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
                    NSLog(@"no decimal point");
                    priceString = [NSString stringWithFormat:@"%@.00", detailStrings[1]];
                }
                
                NSLog(@"formatted price string %@", priceString);
            }
            else if ([detailStrings[0] containsString:@"Meetup"]){
                NSLog(@"meetup: %@", detailStrings[1]);
                meetup = detailStrings[1];
            }
        }
        
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
        [self.offerObject setObject:self.buyerUser forKey:@"buyerUser"];
        [self.offerObject setObject:[PFUser currentUser] forKey:@"sellerUser"];
        
    }
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:messageString];
    if (self.offerMode == YES) {
        NSLog(@"self.offerobj %@", self.offerObject);
        message.offerObject = self.offerObject;
        NSLog(@"offer prop %@", message.offerObject);
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
    [messageObject saveInBackground];
    
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
        if ([self.convoObject objectForKey:@"convoImages"] == 0) {
            //images have been previously sent in the chat so don't need to send anymore
            CameraController *vc = [[CameraController alloc]init];
            vc.delegate = self;
            vc.offerMode = YES;
            [self presentViewController:vc animated:YES completion:nil];
        }
        else{
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
}

-(void)textViewDidChange:(UITextView *)textView{
    if (textView == self.inputToolbar.contentView.textView) {
        if (![textView.text containsString:@"\nSelling:"] && ![textView.text containsString:@"\nCondition:"] && ![textView.text containsString:@"\nPrice:"] && ![textView.text containsString:@"\nMeetup"]) {
            self.offerMode = NO;
            NSLog(@"offer mode is now off");
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
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Send an offer" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.offerMode = YES;
        self.inputToolbar.contentView.textView.text = @"Selling:\nCondition:\nPrice:£\nMeetup?:";
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        CameraController *vc = [[CameraController alloc]init];
        vc.delegate = self;
        vc.offerMode = YES;
        [self presentViewController:vc animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Pay with PayPal" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Report user" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {

    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)finalImage:(UIImage *)image{
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:self.senderId
                                                   displayName:self.senderDisplayName
                                                         media:photoItem];
    
    NSLog(@"here1");
    
    [self.masker applyOutgoingBubbleImageMaskToMediaView:photoItem.mediaView];
    [self.messages addObject:photoMessage];
    [self finishSendingMessageAnimated:YES];
    
     NSLog(@"here2");
    
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
    
     NSLog(@"here3");
    
    PFObject *picObject = [PFObject objectWithClassName:@"messageImages"];
    [picObject setObject:filePicture forKey:@"Image"];
    [picObject setObject:self.convoObject forKey:@"convo"];
    
    NSLog(@"here4");
    
    [picObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            PFObject *messageObject = [PFObject objectWithClassName:@"messages"];
            
            messageObject[@"message"] = picObject.objectId;
            NSLog(@"here5");
            messageObject[@"sender"] = [PFUser currentUser];
            NSLog(@"here6");
            messageObject[@"senderId"] = [PFUser currentUser].objectId;
            NSLog(@"here7");
            messageObject[@"senderName"] = [PFUser currentUser].username;
            NSLog(@"here8");
            messageObject[@"convoId"] = self.convoId;
            NSLog(@"here9");
            messageObject[@"status"] = @"sent";
            NSLog(@"here10");
            messageObject[@"mediaMessage"] = @"YES";
            NSLog(@"here11");
            [messageObject saveInBackground];
            
            NSLog(@"here5");
            
            if (![self.senderId isEqualToString:self.buyerUser.objectId]) {
                [self.convoObject incrementKey:@"convoImages"];
                [self.convoObject saveInBackground];
            }
            
            NSLog(@"here6");
            
            // add new message object to relevant arrays
            [self.sentMessagesParseArray insertObject:picObject atIndex:0];
            [self.messagesParseArray insertObject:picObject atIndex:0];
            
            NSLog(@"sent array %@ and overall array %@", self.sentMessagesParseArray, self.messagesParseArray);
            
            //call attributedString method to update labels
            NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
            NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
            
            // is crash caused by empty messages?
            
            NSLog(@"lastItemIndex %ld", (long)lastItemIndex);
            
            NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];
            
            [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
            [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
            [self.collectionView reloadItemsAtIndexPaths:@[pathToLastItem]];
            
            if (self.offerMode == YES) {
                [self.offerObject setObject:picObject forKey:@"image"];
                [self.offerObject saveInBackground];
            }
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
                NSAttributedString *string = [[NSAttributedString alloc]initWithString:[[self.sentMessagesParseArray objectAtIndex:0]objectForKey:@"status"]];
                return string;
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
            NSLog(@"in here now1!");
            if ([self.messagesParseArray containsObject:self.sentMessagesParseArray[0]]) {
                NSLog(@"in here now!2");
                NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
                
                NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
                NSInteger itemIndex = [self.messagesParseArray indexOfObject:self.sentMessagesParseArray[0]];
                NSLog(@"in here now!3");
                
                NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:(lastItemIndex -itemIndex)inSection:lastSectionIndex];
                
                NSLog(@"in here now!4");
                
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
    
    if (tappedMessage.isOfferMessage == YES) {
        CheckoutController *vc = [[CheckoutController alloc]init];
        vc.confirmedOfferObject = tappedMessage.offerObject;
        NSLog(@"tapped offer %@", tappedMessage.offerObject);
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([[self.messages objectAtIndex:indexPath.item] isMediaMessage] == YES){
        DetailImageController *vc = [[DetailImageController alloc]init];
        vc.listingPic = NO;
        vc.numberOfPics = 1;
        vc.messagesPicMode = YES;
        
        id<JSQMessageMediaData> mediaItem = tappedMessage.media;
        JSQPhotoMediaItem *photoItem = (JSQPhotoMediaItem *)mediaItem;
        vc.messagePicture = photoItem.image;
        
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!",NSStringFromCGPoint(touchLocation));
}

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods

- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
{
//    if ([UIPasteboard generalPasteboard].image) {
//        // If there's an image in the pasteboard, construct a media item with that image and `send` it.
//        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
//        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
//                                                 senderDisplayName:self.senderDisplayName
//                                                              date:[NSDate date]
//                                                             media:item];
//        [self.messages addObject:message];
//        [self finishSendingMessage];
//        
//        
//        return NO;
//    }
//    return YES;
    return NO;
}

@end
