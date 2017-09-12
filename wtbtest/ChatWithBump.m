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
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "NavigationController.h"

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
    [buttonView setImage:[UIImage imageNamed:@"35"]];
    [self setImageBorder:buttonView];
    [btn addSubview:buttonView];
    UIBarButtonItem *imageButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    self.navigationItem.rightBarButtonItem = imageButton;
    
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    self.inputToolbar.contentView.textView.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;
//    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"sendPicBlk"] forState:UIControlStateNormal];
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"sendPicBlue"] forState:UIControlStateHighlighted];
    
    self.inputToolbar.contentView.backgroundColor = [UIColor whiteColor];
    [self.inputToolbar.contentView.textView.layer setBorderWidth:0.0];
    [self.inputToolbar.contentView.rightBarButtonItem setHidden:YES];
    
    //avatar images
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(35, 35);
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    UIImage *image = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"35"] withDiameter:35];
    UIImage *placeholder = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"empty"] withDiameter:35];
    self.avaImage = [[JSQMessagesAvatarImage alloc]initWithAvatarImage:image highlightedImage:image placeholderImage:placeholder];
    
    //Register custom menu actions for cells.
    
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];
    
    self.senderId = [PFUser currentUser].objectId;
    
    self.messages = [[NSMutableArray alloc]init];
    self.messagesParseArray = [[NSMutableArray alloc]init];
    self.sentMessagesParseArray = [[NSMutableArray alloc]init];
    self.convoImagesArray = [[NSMutableArray alloc]init];
    
    self.placeholderAssetArray = [NSMutableArray array];
    self.imagesToProcess = [NSMutableArray array];
    
    //hide by default
    self.showLoadEarlierMessagesHeader = NO;
    
    [self loadConvoImages];
    [self loadMessages];
    
    self.bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularTaillessImage] capInsets:UIEdgeInsetsZero];
    JSQMessagesBubbleImageFactory *bubbleFactoryOutline = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularStrokedTaillessImage] capInsets:UIEdgeInsetsZero];
    self.outgoingBubbleImageData = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1]];
    self.incomingBubbleImageData = [bubbleFactoryOutline incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1]];
    self.masker = [[JSQMessagesMediaViewBubbleImageMasker alloc]initWithBubbleImageFactory:self.bubbleFactory];
    
    self.skipped = 0;
    
    self.inputToolbar.contentView.textView.placeHolder = @"Ask us anything";

    if (self.showSuggested) {

        self.suggestedMessagesArray = [NSMutableArray arrayWithObjects:@"Tap for more info ➡️",@"Authenticity", @"Payment",@"Email Verification",@"Location",@"Username Change",@"Password Change",@"Trading",@"Proxies", nil];
        self.actualMessagesToSend = [NSMutableArray arrayWithObjects:@"placeholder",[NSString stringWithFormat:@"Hey %@,\n\nHere's our fraud prevention policy. We've found this to be an effective way of ensuring authenticity on Bump:\n\n1️⃣ 📸 We encourage tagged photos on Bump so buyers can be sure items exist\n\n2️⃣ 👟 Our team of moderators are monitoring listings for fakes / suspicious behaviour\n\n3️⃣ 🔑 We make it really easy for anyone to report a listing to us\n\n4️⃣ 🤑 We encourage users to pay each other using PayPal Goods & Services so if something does go wrong, you're protected!\n\nIf however, you were to get sent a fake then you would be able to take up a claim with PayPal and get a full refund. And of course, we would be here to help you through the process 👊\n\nAny other questions please let me know!\n\nThanks,\nSophie", [self.otherUser objectForKey:@"firstName"]],
                                     
                            [NSString stringWithFormat:@"Hey %@,\n\nWhen you see something you like, send the seller a message to let them know you’re interested. Make sure you agree on specifics like price, postage and condition before you pay.\n\nWhen the deal is agreed, the seller can send their PayPal details within the chat on Bump. You can then pay the seller through PayPal without leaving Bump.\n\nWe encourage paying via Goods & Services to ensure you receive full buyer protection 💪\n\nThanks,\nSophie", [self.otherUser objectForKey:@"firstName"]],
                             
                                     [NSString stringWithFormat:@"Hey %@,\n\nIf you don't think you've received your email confirmation from us then please check your Junk Folder! In most cases it will be here, from Team Bump (hello@sobump.com).\n\nIf you still can't find it, just tap the envelope icon on your profile to resend it - make sure your email address in Settings on Bump is correct first 📫 \n\nThanks,\nSophie", [self.otherUser objectForKey:@"firstName"]],
                                     
                                     [NSString stringWithFormat:@"Hey %@,\n\nWhen you first signup Bump automatically displays the nearest city and country to your current location on your profile.\n\nWant to change this? Just goto Settings (tap the cog icon from your profile) and you can select a different location to display on your profile.\n\nYour profile location does NOT impact on the products you see on Bump. If you would like to filter by location when browsing just tap the filters button and scroll down to filter by products 'Around me' 📍\n\nThanks,\nSophie", [self.otherUser objectForKey:@"firstName"]],
                                     
                                     [NSString stringWithFormat:@"Hey %@,\n\nFancy a change of username? Send us a message in chat here and we'll sort you out 🙌\n\nOnce it's changed just log out then back in!\n\nThanks,\nSophie", [self.otherUser objectForKey:@"firstName"]],
                                     
                                     [NSString stringWithFormat:@"Hey %@,\n\nForgot your password? Simply log out and then hit log in on the welcome screen. Then you can hit Reset in the top right corner of the screen!\n\nThanks,\nSophie", [self.otherUser objectForKey:@"firstName"]],
                                     [NSString stringWithFormat:@"Hey %@,\n\nWe do NOT encourage trading on Bump for a number of reasons.\n\nMainly because it's so easy for scammers to hijack a trade. There's nothing stopping a scammer agreeing to send the item you expect to receive but in reality sending a completely different and often worthless item. When this happens you've lost your original item and it's extremely tough, if not impossible, to get some money back.\n\nAvoid trading and you'll be much safer 💰\n\nThanks,\nSophie", [self.otherUser objectForKey:@"firstName"]],
                                     [NSString stringWithFormat:@"Hey %@,\n\nWhat's a proxy?\n\nA proxy is when someone is willing to queue up for a drop on your behalf. It's almost like a preorder for items that are yet to be released. Usually you will pay someone proxying for you the retail price of the item plus a fee for the service.\n\nBe careful, it's easy for a scammer to take your money, promise to get your item and then never speak to you again.\n\nAlways pay via PayPal Goods & Services and ask the user proxying for references so you can be sure they're legitimate. If a user claims they need the payment to be gifted in order to access the funds faster, it's better to decline and find someone that will accept PayPal Goods & Services.\n\nIf you're ever unsure about a proxy, message Team Bump and we'll help you out 🤝\n\nThanks,\nSophie", [self.otherUser objectForKey:@"firstName"]],
                                     nil];


        self.carousel = [[SwipeView alloc]initWithFrame:CGRectMake(0, self.inputToolbar.frame.origin.y-50, [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
        
        self.carousel.delegate = self;
        self.carousel.dataSource = self;
        self.carousel.clipsToBounds = YES;
        self.carousel.pagingEnabled = NO;
        self.carousel.truncateFinalPage = YES;
        [self.carousel setBackgroundColor:[UIColor whiteColor]];
        [self.carousel reloadData];
        [self.view addSubview:self.carousel];
        
        //scroll to fix bug which populates swipeview with 1 item
        [self.carousel scrollToOffset:0.0 duration:0.1];

    }

}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
    [self.collectionView addPullToRefreshWithActionHandler:^{
        if (self.infiniteLoading != YES && self.moreToLoad == YES) {
            
            self.infiniteLoading = YES;
            self.earlierPressed = YES;
            [self loadMessages];
        }
        else{
            [self.collectionView.pullToRefreshView stopAnimating];
        }
    }];
    
    //we need the spinner so init
    if (!self.spinner) {
        self.spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
        [self.collectionView.pullToRefreshView setCustomView:self.spinner forState:SVPullToRefreshStateAll];
        [self.spinner startAnimating];
    }
}

-(void)loadMessages{
    PFQuery *messageQuery = [PFQuery queryWithClassName:@"teamBumpMsgs"];
    [messageQuery whereKey:@"convoId" equalTo:self.convoId];
    [messageQuery orderByDescending :@"createdAt"];
    messageQuery.limit = 10;
    messageQuery.skip = self.skipped;
    [messageQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                
                if (objects.count < 10) {
                    NSLog(@"HIDE IT");

                    self.moreToLoad = NO;
                    self.collectionView.showsPullToRefresh = NO;
                    
                    //save memory
                    [self.spinner stopAnimating];
                    self.spinner = nil;
                }
                else{
                    NSLog(@"SHOW IT");
                    self.moreToLoad = YES;
                    self.collectionView.showsPullToRefresh = YES;
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
                
                if (self.earlierPressed == NO) {
                    [self scrollToBottomAnimated:NO];

                }
                else{
                    [self.collectionView.pullToRefreshView stopAnimating];

                    self.earlierPressed = NO;
                    //NB: the last object in the messages array is the msg at the top of the CV
                    //However, this means it is also the first indexPath
                    //So, to calc. correct scroll we just take first indexPath and add the number of new objects just loaded so we end up at our OG position
                    NSIndexPath *firstItemPath = [NSIndexPath indexPathForRow:0 inSection:0];
                    NSIndexPath *lastSeenPath = [NSIndexPath indexPathForRow:firstItemPath.row+objects.count inSection:0];
                    [self.collectionView scrollToItemAtIndexPath:lastSeenPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                    self.infiniteLoading = NO;
                }
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
    
    [self.navigationController.navigationBar setHidden:NO];

    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    //clear observers
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
    self.automaticallyScrollsToMostRecentMessage = YES;
    
    //add keyboard observers for suggested message bubbles
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [center addObserver:self selector:@selector(keyboardOnScreen:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardOFFScreen:) name:UIKeyboardWillHideNotification object:nil];
    
    //reset carousel here when inputtoolbar actually as a frame
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //animate carousel up
                            [self.carousel setFrame:CGRectMake(0, self.inputToolbar.frame.origin.y-50, [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                        }
                     completion:^(BOOL finished) {
                     }];
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
            
//            NSLog(@"saved message, here it is: %@", messageObject);
            
            [Answers logCustomEventWithName:@"Sent Message to Team Bump"
                           customAttributes:@{
                                              @"type":@"text"
                                              }];
            
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
    
    //reset carousel origin
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            [self.carousel setFrame:CGRectMake(0, self.inputToolbar.frame.origin.y-50, [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                        }
                     completion:^(BOOL finished) {
                     }];
    
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

- (void)didPressAccessoryButton:(UIButton *)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
//    [self alertSheet];
    
    [Answers logCustomEventWithName:@"Choose pictures tapped"
                   customAttributes:@{
                                      @"where":@"Team Bump"
                                      }];
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized:{
                dispatch_async(dispatch_get_main_queue(), ^{
                    QBImagePickerController *imagePickerController = [QBImagePickerController new];
                    imagePickerController.delegate = self;
                    imagePickerController.allowsMultipleSelection = YES;
                    imagePickerController.maximumNumberOfSelection = 4;
                    imagePickerController.mediaType = QBImagePickerMediaTypeImage;
                    imagePickerController.numberOfColumnsInPortrait = 4;
                    imagePickerController.showsNumberOfSelectedAssets = YES;
                    [self.navigationController presentViewController:imagePickerController animated:YES completion:NULL];
                });
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        QBImagePickerController *imagePickerController = [QBImagePickerController new];
                        imagePickerController.delegate = self;
                        imagePickerController.allowsMultipleSelection = YES;
                        imagePickerController.maximumNumberOfSelection = 4;
                        imagePickerController.mediaType = QBImagePickerMediaTypeImage;
                        imagePickerController.numberOfColumnsInPortrait = 4;
                        imagePickerController.showsNumberOfSelectedAssets = YES;
                        [self.navigationController presentViewController:imagePickerController animated:YES completion:NULL];
                    });
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
    [imagePickerController dismissViewControllerAnimated:YES completion:^{
        
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        requestOptions.networkAccessAllowed = YES;

        PHImageManager *manager = [PHImageManager defaultManager];
        
        [self.placeholderAssetArray removeAllObjects];
        [self.imagesToProcess removeAllObjects];
        
        for (PHAsset *asset in assets) {
            [manager requestImageForAsset:asset
                               targetSize:PHImageManagerMaximumSize
                              contentMode:PHImageContentModeDefault
                                  options:requestOptions
                            resultHandler:^void(UIImage *image, NSDictionary *info) {
                                
                                [self.imagesToProcess addObject:image];
                                [self.placeholderAssetArray addObject:asset];
                                
                                if (image.CGImage == nil) {
                                    [Answers logCustomEventWithName:@"Image Error: CGImage is nil from Asset"
                                                   customAttributes:@{
                                                                      @"pageName":@"TeamBumpChat"
                                                                      }];
                                }
                                
                                //wait until we have all the assets as UIImages
                                //reorder
                                //call final image on each one
                                
                                if (self.imagesToProcess.count == assets.count) {
                                    
                                    //to keep track of reorder
                                    NSMutableArray *placeholder = [NSMutableArray array];
                                    NSMutableArray *imagesPlaceholder = [NSMutableArray array];
                                    
                                    //reorder
                                    for (PHAsset *orderedAsset in assets) {
                                        
                                        for (PHAsset *asset in self.placeholderAssetArray) {
                                            
                                            if ([asset.localIdentifier isEqualToString:orderedAsset.localIdentifier]) {
                                                
                                                [placeholder addObject:asset];
                                                
                                                NSUInteger indexOfAsset = [self.placeholderAssetArray indexOfObject:asset];
                                                [imagesPlaceholder addObject:self.imagesToProcess[indexOfAsset]];
                                                break;
                                            }
                                        }
                                    }
                                    
                                    //update ordered images array
                                    self.imagesToProcess = imagesPlaceholder;
                                    
                                    for (UIImage *img in self.imagesToProcess) {
                                        [self finalImage:img];
                                    }
                                }
                            }];
        }
    }];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [imagePickerController dismissViewControllerAnimated:YES completion:NULL];
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
        [self showAlertWithTitle:@"Image Error" andMsg:@"Something went wrong getting your image, please try sending another picture!"];
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
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:nil];
                }
                else{
                    NSLog(@"error saving convo in final image %@", error);
                }
            }];
            
            [Answers logCustomEventWithName:@"Sent Message to Team Bump"
                           customAttributes:@{
                                              @"type":@"image"
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
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:12],
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


- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    if (self.showSuggested == YES ){
        return UIEdgeInsetsMake(0, 0, 50, 0);
    }
    else{
        return self.collectionView.layoutMargins;
    }
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
        int selectedIndex = 0;
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
        
        //to prevent CV scrolling to bottom when detailVC is dismissed, reenabled when MVC reappears
        self.automaticallyScrollsToMostRecentMessage = NO;
        
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

#pragma keyboard observer methods

-(void)keyboardOnScreen:(NSNotification *)notification
{
    NSLog(@"KEYBOARD WILL SHOW");
    //reset carousel origin
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            [self.carousel setFrame:CGRectMake(0, self.inputToolbar.frame.origin.y-50, [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                        }
                     completion:^(BOOL finished) {
                     }];
}

-(void)keyboardOFFScreen:(NSNotification *)notification
{
    NSLog(@"KEYBOARD WILL HIDE");
    
    //reset carousel origin
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            [self.carousel setFrame:CGRectMake(0, self.inputToolbar.frame.origin.y-50, [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                        }
                     completion:^(BOOL finished) {
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
        
        //reset carousel origin
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseIn animations:^{
                                [self.carousel setFrame:CGRectMake(0, self.inputToolbar.frame.origin.y-50, [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                            }
                         completion:^(BOOL finished) {
                         }];
    }
}

#pragma mark - swipe view delegates

-(UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    UILabel *messageLabel = nil;
    
    if (view == nil)
    {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 165,35)];
        messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(5,0, 155, 35)];
        messageLabel.layer.cornerRadius = 15;
        messageLabel.layer.masksToBounds = YES;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        [messageLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:13]];
        [view addSubview:messageLabel];
        
    }
    else
    {
        messageLabel = [[view subviews] lastObject];
    }
    
    messageLabel.text = [self.suggestedMessagesArray objectAtIndex:index];
    
    //check if first in the array
    if (index == 0) {
        messageLabel.textColor = [UIColor grayColor];
        messageLabel.backgroundColor = [UIColor whiteColor];
    }
    else{
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.backgroundColor = [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0];
    }
    
    return view;
}

-(NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    return self.suggestedMessagesArray.count;
}

-(void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index{
    
    NSString *messageString = [self.actualMessagesToSend objectAtIndex:index];
    
    [Answers logCustomEventWithName:@"Tapped FAQ Auto Message"
                   customAttributes:@{
                                      @"msg":messageString
                                      }];
    if (index == 0) {
        //do nothing
    }
    else{
        [self sendAutoMessageWithText:messageString];
    }
}

-(void)sendAutoMessageWithText:(NSString *)message{
    
    //now save report message
    PFObject *messageObject1 = [PFObject objectWithClassName:@"teamBumpMsgs"];
    messageObject1[@"message"] = message;
    messageObject1[@"sender"] = [PFUser currentUser];
    messageObject1[@"senderId"] = @"BUMP";
    messageObject1[@"senderName"] = @"Team Bump";
    messageObject1[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
    messageObject1[@"status"] = @"seen";
    messageObject1[@"offer"] = @"NO";
    messageObject1[@"mediaMessage"] = @"NO";
    [messageObject1 saveInBackground];
    
    //update convo
    [self.convoObject incrementKey:@"totalMessages"];
    [self.convoObject setObject:messageObject1 forKey:@"lastSent"];
    [self.convoObject setObject:[NSDate date] forKey:@"lastSentDate"];
    [self.convoObject saveInBackground];
    
    //Add to UI
    if (![self.messagesParseArray containsObject:messageObject1]) {
        // insets new messages at beginning of array (bottom of CV) so status labels are correct
        [self.messagesParseArray insertObject:messageObject1 atIndex:0];
    }

    
    JSQMessage *JSmessage = [[JSQMessage alloc] initWithSenderId:@"BUMP" senderDisplayName:@"Team Bump" date:[NSDate date] text:message];
    
    if (![self.messages containsObject:JSmessage]) {
        [self.messages addObject:JSmessage];
    }
    
    //update CV
    //call attributedString method to update labels
    NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
    NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
    NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];
    
    [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
    [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
    
    [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
    [self.collectionView reloadData];
    
    //scroll to bottom
    [self scrollToBottomAnimated:YES];

}


@end

