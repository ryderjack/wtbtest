//
//  ChatWithBump.m
//  wtbtest
//
//  Created by Jack Ryder on 05/10/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ChatWithBump.h"
#import <Crashlytics/Crashlytics.h>
#import "UIImage+Resize.h"
#import "DetailImageController.h"

@interface ChatWithBump ()

@end

@implementation ChatWithBump

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Team Bump";
    
    UIButton *btn =  [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0,0,25,25);
    PFImageView *buttonView = [[PFImageView alloc]initWithFrame:btn.frame];
    [buttonView setImage:[UIImage imageNamed:@"29"]];
    [self setImageBorder:buttonView];
    [btn addSubview:buttonView];
    UIBarButtonItem *imageButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    self.navigationItem.rightBarButtonItem = imageButton;
    
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    self.inputToolbar.contentView.textView.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    self.inputToolbar.contentView.textView.placeHolder = @"Ask us anything!";
//    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"sendPicBlk"] forState:UIControlStateNormal];
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"sendPicBlue"] forState:UIControlStateHighlighted];
    
    self.inputToolbar.contentView.backgroundColor = [UIColor whiteColor];
    [self.inputToolbar.contentView.textView.layer setBorderWidth:0.0];
    [self.inputToolbar.contentView.rightBarButtonItem setHidden:YES];
    
    //avatar images
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(35, 35);
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    UIImage *image = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"29"] withDiameter:35];
    UIImage *placeholder = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"empty"] withDiameter:35];
    self.avaImage = [[JSQMessagesAvatarImage alloc]initWithAvatarImage:image highlightedImage:image placeholderImage:placeholder];
    
    //Register custom menu actions for cells.
    
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];
    
    self.senderId = [PFUser currentUser].objectId;
    
    self.messages = [[NSMutableArray alloc]init];
    self.messagesParseArray = [[NSMutableArray alloc]init];
    self.sentMessagesParseArray = [[NSMutableArray alloc]init];
    self.convoImagesArray = [[NSMutableArray alloc]init];
    
    //hide by default
    self.showLoadEarlierMessagesHeader = NO;
    
    [self loadConvoImages];
    [self loadMessages];
    
    self.bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularTaillessImage] capInsets:UIEdgeInsetsZero];
    
    JSQMessagesBubbleImageFactory *bubbleFactoryOutline = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularStrokedTaillessImage] capInsets:UIEdgeInsetsZero];
    
    self.outgoingBubbleImageData = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1]];
    
    self.incomingBubbleImageData = [bubbleFactoryOutline incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1]];
    
    self.masker = [[JSQMessagesMediaViewBubbleImageMasker alloc]initWithBubbleImageFactory:self.bubbleFactory];
}

-(void)loadMessages{
    PFQuery *messageQuery = [PFQuery queryWithClassName:@"teamBumpMsgs"];
    [messageQuery whereKey:@"convoId" equalTo:self.convoId];
    [messageQuery orderByDescending :@"createdAt"];
    [messageQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                
                for (PFObject *messageOb in objects) {
                    
                    if (![self.messagesParseArray containsObject:messageOb]) {
                        [self.messagesParseArray addObject:messageOb];
                    }
                    
                    __block JSQMessage *message = nil;
                    
                    if (![[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                        [messageOb setObject:@"seen" forKey:@"status"];
                        [messageOb saveInBackground];
                        [self.convoObject setObject:@0 forKey:@"userUnseen"];
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
                        photoItem.image = [UIImage imageNamed:@"empty"];
                        
                        if ([[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                            photoItem.appliesMediaViewMaskAsOutgoing = YES;
                        }
                        else{
                            photoItem.appliesMediaViewMaskAsOutgoing = NO;
                        }
                        
                        message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt media:photoItem];
                        message.msgObject = messageOb;
                        
                        [self.messages insertObject:message atIndex:0];
                        
                        //added so placeholder view is correct
                        
                        if ([[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                            photoItem.appliesMediaViewMaskAsOutgoing = YES;
                        }
                        else{
                            photoItem.appliesMediaViewMaskAsOutgoing = NO;
                        }
                        
                        PFQuery *imageQuery = [PFQuery queryWithClassName:@"teamBumpmMsgImages"];
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
                                        
                                        if ([[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                                            [self.masker applyOutgoingBubbleImageMaskToMediaView:photoItem.mediaView];
                                        }
                                        else{
                                            [self.masker applyIncomingBubbleImageMaskToMediaView:photoItem.mediaView];
                                        }
                                        [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
                                        
                                        [self.collectionView reloadData];
                                        
                                        message = nil;
                                    }
                                    else{
                                        NSLog(@"error getting img data %@", error);
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
                        
                        message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt text:messageText];
                        
                        if (![self.messages containsObject:message]) {
                            [self.messages insertObject:message atIndex:0];
                        }
                    }
                }
                
                [self.convoObject saveInBackground];
                
                [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
                [self.collectionView reloadData];
                
                [self scrollToBottomAnimated:NO];
            }
            else{
                NSLog(@"no messages");
            }
        }
        else{
            //error retrieving messages
            [self showError];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
}

#pragma mark - Custom menu actions for cells

- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification
{
    /**
     *  Display custom menu actions for cells.
     */
    //    UIMenuController *menu = [notification object];
    //    menu.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Custom Action" action:@selector(customAction:)] ];
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
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:messageString];
    [self.messages addObject:message];
    
    NSString *senderName = @"";
    
    //send push to other user
    senderName = [PFUser currentUser].username;

    
    PFObject *messageObject = [PFObject objectWithClassName:@"teamBumpMsgs"];
    messageObject[@"message"] = messageString;
    messageObject[@"sender"] = [PFUser currentUser];
    messageObject[@"senderId"] = [PFUser currentUser].objectId;
    messageObject[@"senderName"] = senderName;
    messageObject[@"convoId"] = self.convoId;
    messageObject[@"status"] = @"sent";
    messageObject[@"offer"] = @"NO";
    messageObject[@"mediaMessage"] = @"NO";
    
    [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded == YES) {
            
            NSLog(@"saved message, here it is: %@", messageObject);
            
            NSDictionary *params = @{@"userId": @"IIEf7cUvrO", @"message": [NSString stringWithFormat:@"TO TEAM BUMP FROM %@: %@",[PFUser currentUser].username ,messageString], @"sender": [PFUser currentUser].username};
            [PFCloud callFunctionInBackground:@"sendPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    NSLog(@"response %@", response);
                }
                else{
                    NSLog(@"push error %@", error);
                }
            }];
        }
        else{
            NSLog(@"error sending message %@", error);
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Error sending message" message:@"Make sure you're connected to the internet" preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }];
    
    [self finishSendingMessageAnimated:YES];
    
    // add new message object to relevant arrays
    [self.sentMessagesParseArray insertObject:messageObject atIndex:0];
    [self.messagesParseArray insertObject:messageObject atIndex:0];
    
    //update convo object after every message sent
    [self.convoObject incrementKey:@"totalMessages"];
    [self.convoObject setObject:messageObject forKey:@"lastSent"];
    [self.convoObject setObject:[NSDate date] forKey:@"lastSentDate"];
    
    [self.convoObject incrementKey:@"BumpUnseen"];
    
    [self.convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded){
            NSLog(@"done");
        }
        else{
            NSLog(@"error with conv %@", error);
        }
    }];
}

-(void)textViewDidChange:(UITextView *)textView{
    if (textView == self.inputToolbar.contentView.textView) {
        [self.inputToolbar toggleSendButtonEnabled];
        NSString *blankString = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([blankString isEqualToString:@""]) {
            [self.inputToolbar.contentView.rightBarButtonItem setHidden:YES];
        }
        else{
            [self.inputToolbar.contentView.rightBarButtonItem setHidden:NO];
        }
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
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose pictures" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Choose pictures tapped"
                       customAttributes:@{
                                          @"where":@"Team Bump"
                                          }];
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            switch (status) {
                case PHAuthorizationStatusAuthorized:{
                    
                    QBImagePickerController *imagePickerController = [QBImagePickerController new];
                    imagePickerController.delegate = self;
                    imagePickerController.allowsMultipleSelection = YES;
                    imagePickerController.maximumNumberOfSelection = 4;
                    imagePickerController.mediaType = QBImagePickerMediaTypeImage;
                    imagePickerController.numberOfColumnsInPortrait = 2;
                    imagePickerController.showsNumberOfSelectedAssets = YES;
                    [self.navigationController presentViewController:imagePickerController animated:YES completion:NULL];
                }
                    break;
                case PHAuthorizationStatusRestricted:{
                    NSLog(@"restricted");
                }
                    break;
                case PHAuthorizationStatusDenied:
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showAlertWithTitle:@"Photos Permission" andMsg:@"Bump needs access to your photos so we can send one 📷"];
                    });
                    NSLog(@"denied");
                }
                    break;
                default:
                    break;
            }
        }];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    [self dismissViewControllerAnimated:YES completion:^{
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        requestOptions.networkAccessAllowed = YES;

        PHImageManager *manager = [PHImageManager defaultManager];
        
        for (PHAsset *asset in assets) {
            [manager requestImageForAsset:asset
                               targetSize:PHImageManagerMaximumSize
                              contentMode:PHImageContentModeDefault
                                  options:requestOptions
                            resultHandler:^void(UIImage *image, NSDictionary *info) {
                                //new policy: all resizing done in finalImage, instead of scattered
                                [self finalImage:image];
                            }];
        }
    }];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)finalImage:(UIImage *)image{
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    UIImage *newImage = [image scaleImageToSizeFIT:CGSizeMake(750, 750)];
    
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:newImage];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:self.senderId
                                                   displayName:self.senderDisplayName
                                                         media:photoItem];
    [self.masker applyOutgoingBubbleImageMaskToMediaView:photoItem.mediaView];
    [self.messages addObject:photoMessage];
    [self finishSendingMessageAnimated:YES];
    
    NSData* data = UIImageJPEGRepresentation(newImage, 0.8);
    
    if (data == nil) {
        //prevent crash when creating a PFFile with nil data
        [Answers logCustomEventWithName:@"PFFile Nil Data"
                       customAttributes:@{
                                          @"pageName":@"Team Bump Chat"
                                          }];
        [self showAlertWithTitle:@"Image Error" andMsg:@"Something went wrong getting your image, please try again!"];
        return;
    }
    
    PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:data];
    
    PFObject *picObject = [PFObject objectWithClassName:@"teamBumpmMsgImages"];
    [picObject setObject:filePicture forKey:@"Image"];
    [picObject setObject:self.convoObject forKey:@"convo"];
    [self.convoImagesArray addObject:picObject];
    
    [picObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            
            self.messageObject = [PFObject objectWithClassName:@"teamBumpMsgs"];
            self.messageObject[@"message"] = picObject.objectId;
            self.messageObject[@"sender"] = [PFUser currentUser];
            self.messageObject[@"senderId"] = [PFUser currentUser].objectId;
            self.messageObject[@"senderName"] = [PFUser currentUser].username;
            self.messageObject[@"convoId"] = self.convoId;
            self.messageObject[@"status"] = @"sent";
            self.messageObject[@"mediaMessage"] = @"YES";
            if (self.tagString) {
                [self.messageObject setObject:self.tagString forKey:@"tagString"];
            }
            [self.messageObject saveInBackground];
            
            //set as last message sent
            self.lastMessage = self.messageObject;
            
            //set msg object so photo is tagged
            photoMessage.msgObject = self.messageObject;
            
            if (![self.senderId isEqualToString:self.otherUser.objectId]) {
                [self.convoObject incrementKey:@"convoImages"];
            }
            
            [self.convoObject setObject:self.messageObject forKey:@"lastSent"];
            
            [self.convoObject incrementKey:@"totalMessages"];
            [self.convoObject incrementKey:@"BumpUnseen"];
            [self.convoObject setObject:[NSDate date] forKey:@"lastSentDate"];
            [self.convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:nil];
                }
                else{
                    NSLog(@"error saving convo in final image %@", error);
                }
            }];
            
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
            NSLog(@"error saving pic msg %@", error);
            
            [self.convoImagesArray removeObject:picObject];
            
            [Answers logCustomEventWithName:@"Error Saving Pic File"
                           customAttributes:@{
                                              @"where":@"Team Bump Chat"
                                              }];
            
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Error sending image" message:@"Make sure you're connected to the internet" preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }];
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
    
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    else{
        //get array of messages other user has sent
        NSMutableArray *otherUserSentMessages = [self.messagesParseArray mutableCopy];
        [otherUserSentMessages removeObjectsInArray:self.sentMessagesParseArray];
        
        if (otherUserSentMessages.count > 0) {
            PFObject *lastMessage = otherUserSentMessages[0];
            if ([lastMessage.createdAt isEqualToDate:message.date]) {
                //this is the last sent message by other user
                //so show avatar
                return self.avaImage;
            }
            else{
                return nil;
            }
        }
        else{
            return nil;
        }
    }
    
    
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
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName,[UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
    
    
    //show timestamp if message was sent >= 1 hour after previous message
    if (indexPath.item == 0) {
        JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
        NSAttributedString *finalStamp = [[NSAttributedString alloc]initWithString:[[[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date] string] attributes:textAttributes];
        return finalStamp;
    }
    else{
        //get previous message
        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item-1];
        JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
        
        //check difference between 2 dates
        NSDate* date1 = previousMessage.date;
        NSDate* date2 = message.date;
        NSTimeInterval distanceBetweenDates = [date2 timeIntervalSinceDate:date1];
        double secondsInAnHour = 3600;
        NSInteger hoursBetweenDates = distanceBetweenDates / secondsInAnHour;
        
        if (hoursBetweenDates >= 1) {
            NSAttributedString *finalStamp = [[NSAttributedString alloc]initWithString:[[[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date] string] attributes:textAttributes];
            return finalStamp;
        }
        else{
            return nil;
        }
    }
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
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
    if (indexPath.item == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault+10;
    }
    else{
        //get previous message
        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item-1];
        JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
        
        //check difference between 2 dates
        NSDate* date1 = previousMessage.date;
        NSDate* date2 = message.date;
        NSTimeInterval distanceBetweenDates = [date2 timeIntervalSinceDate:date1];
        double secondsInAnHour = 3600;
        NSInteger hoursBetweenDates = distanceBetweenDates / secondsInAnHour;
        
        if (hoursBetweenDates >= 1) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault+10;
        }
        else{
            return 0.0;
        }
    }
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

    return 0.0f;

}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{

}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *tappedMessage = [self.messages objectAtIndex:indexPath.item];
    
    if ([[self.messages objectAtIndex:indexPath.item] isMediaMessage] == YES){
        
        [Answers logCustomEventWithName:@"Tapped Image in Team Bump Chat"
                       customAttributes:@{}];
        
        DetailImageController *vc = [[DetailImageController alloc]init];
        vc.listingPic = NO;
        vc.numberOfPics = (int)self.convoImagesArray.count;
        
        //calculate the index of the image tapped so correct selectedIndex shown in DetailImageVC
        int selectedIndex;
        PFObject *msgObject = tappedMessage.msgObject;
        NSString *messageString = [msgObject objectForKey:@"message"];
        
        for (int i = 0; i<self.convoImagesArray.count; i++) {
            PFObject *imageMessage = self.convoImagesArray[i];
            if ([messageString isEqualToString:imageMessage.objectId]) {
                selectedIndex = i;
                break;
            }
        }
        
        vc.chosenIndex = selectedIndex;
        vc.convoImagesArray = self.convoImagesArray;
        vc.convoMode = YES;
        vc.tagText = [tappedMessage.msgObject objectForKey:@"tagString"];
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
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *string = pasteboard.string;
    if (string) {
        return YES;
    }
    else{
        return NO;
    }
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)showError{
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Error"
                                  message:@"Make sure you're connected to the internet!"
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)loadConvoImages{
    PFQuery *imageQuery = [PFQuery queryWithClassName:@"teamBumpmMsgImages"];
    [imageQuery whereKey:@"convo" equalTo:self.convoObject];
    [imageQuery orderByDescending:@"createdAt"];
    [imageQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            [self.convoImagesArray addObjectsFromArray:objects];
            
            //reverse order
            NSArray *convoImg = [[self.convoImagesArray reverseObjectEnumerator] allObjects];
            [self.convoImagesArray removeAllObjects];
            [self.convoImagesArray addObjectsFromArray:convoImg];
            
            NSLog(@"convo img count %lu", (unsigned long)self.convoImagesArray.count);
        }
        else{
            NSLog(@"error getting convo images %@", error);
        }
    }];
}

@end

