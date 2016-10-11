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
#import "SettingsController.h"
#import <TOWebViewController.h>
#import "FeedbackController.h"
#import "OrderSummaryController.h"
#import "ListingController.h"
#import "MessageTutorial.h"
#import <PulsingHaloLayer.h>

@interface MessageViewController ()

@end

@implementation MessageViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.otherUserName isEqualToString:@""]) {
        [self.otherUser fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                self.title = self.otherUser.username;
            }
            else{
                NSLog(@"getting user error %@", error);
            }
        }];
    }
    else{
       self.title = self.otherUserName;
    }
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(clearOffer)];
    self.profileButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"profileIcon2"] style:UIBarButtonItemStylePlain target:self action:@selector(profileTapped)];

    UIButton *btn =  [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0,0,25,25);
    [btn addTarget:self action:@selector(listingTapped) forControlEvents:UIControlEventTouchUpInside];
    PFImageView *buttonView = [[PFImageView alloc]initWithFrame:btn.frame];
    PFFile *listingFile = [self.listing objectForKey:@"image1"];
    [buttonView setFile:listingFile];
    [buttonView loadInBackground];
    [self setImageBorder:buttonView];
    [btn addSubview:buttonView];
    self.listingButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.listingButton, self.profileButton, nil]];
    
    
    self.inputToolbar.contentView.textView.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    self.inputToolbar.contentView.textView.placeHolder = @"Tap the tag for more actions";
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"tagFill"] forState:UIControlStateNormal];
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"tagIconG"] forState:UIControlStateHighlighted];
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"pulsingDone"] == YES) {
        PulsingHaloLayer *halo = [PulsingHaloLayer layer];
        halo.position = self.inputToolbar.contentView.leftBarButtonItem.center;
        [self.inputToolbar.contentView.leftBarButtonItem.layer addSublayer:halo];
        UIColor *color = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
        halo.backgroundColor = color.CGColor;
        [halo start];
    }
    
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
    
    //hide by default
    self.showLoadEarlierMessagesHeader = NO;
    
    self.skipped = 0;
    self.fromForeGround = NO;
    self.offerMode = NO;
    self.earlierPressed = NO;
    
    [self loadMessages];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:@"NewMessage" object:nil];
    
    self.bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularTaillessImage] capInsets:UIEdgeInsetsZero];
    
    JSQMessagesBubbleImageFactory *bubbleFactoryOutline = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularStrokedTaillessImage] capInsets:UIEdgeInsetsZero];
    
    self.outgoingBubbleImageData = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1]];
    
    self.incomingBubbleImageData = [bubbleFactoryOutline incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1]];
    
    self.waitingBubbleImageData = [bubbleFactoryOutline incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
    
    self.purchasedBubbleImageData = [bubbleFactoryOutline incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1]];
    
    self.offerBubbleImageData = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1]];
    
     self.masker = [[JSQMessagesMediaViewBubbleImageMasker alloc]initWithBubbleImageFactory:self.bubbleFactory];
    
    //load when app comes into foreground
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fromForeGroundRefresh)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:[UIApplication sharedApplication]];
    
    //to update status to seen of last sent when new messages come through
    self.receivedNew = NO;
    
    if (self.userIsBuyer == NO) {
        //check if paypal email has been entered
        if (![[[PFUser currentUser]objectForKey:@"paypalUpdated"]isEqualToString:@"YES"]) {
            [self showPayPalAlert];
            [[PFUser currentUser]saveInBackground];
        }
    }
}

-(void)loadMessages{
    PFQuery *messageQuery = [PFQuery queryWithClassName:@"messages"];
    [messageQuery whereKey:@"convoId" equalTo:self.convoId];
    messageQuery.limit = 10;
    messageQuery.skip = self.skipped;
    [messageQuery orderByDescending :@"createdAt"];
    [messageQuery includeKey:@"offerObject"];
    [messageQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                if (self.earlierPressed == NO) {
                    self.lastMessage = [objects objectAtIndex:0];
                }
                
                if (objects.count < 10) {
                    self.showLoadEarlierMessagesHeader = NO;
                }
                else{
                    self.showLoadEarlierMessagesHeader = YES;
                }
                
                int count = (int)[objects count];
                self.skipped = count + self.skipped;
                
                if (self.fromForeGround == YES) {
                    //clear so index path can be found of last item and updated 'seen' label displayed
                    [self.sentMessagesParseArray removeAllObjects];
                    [self.messagesParseArray removeAllObjects];
                }
                
                for (PFObject *messageOb in objects) {
                    
                    // is status message set as seen so badge number decrements and then continue to add other messages to arrays
                    if ([[messageOb objectForKey:@"isStatusMsg"]isEqualToString:@"YES"]) {
                        [messageOb setObject:@"seen" forKey:@"status"];
                        [messageOb saveInBackground];
                        continue;
                    }
                    
                    if (![self.messagesParseArray containsObject:messageOb]) {
                        [self.messagesParseArray addObject:messageOb];
                    }
                    
                    __block JSQMessage *message = nil;
                    
                    if (![[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                        [messageOb setObject:@"seen" forKey:@"status"];
                        [messageOb saveInBackground];
                        if (self.userIsBuyer == YES) {
                            [self.convoObject setObject:@0 forKey:@"buyerUnseen"];
                        }
                        else{
                            [self.convoObject setObject:@0 forKey:@"sellerUnseen"];
                        }
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
                                        
                                        if ([[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                                            [self.masker applyOutgoingBubbleImageMaskToMediaView:photoItem.mediaView];
                                        }
                                        else{
                                            [self.masker applyIncomingBubbleImageMaskToMediaView:photoItem.mediaView]; //needs to change?
                                        }
                                        [self.collectionView reloadData];
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
                        
                        if (![[messageOb objectForKey:@"senderId"] isEqualToString:[PFUser currentUser].objectId] && [[messageOb objectForKey:@"offer"]isEqualToString:@"YES"]) {
                            PFObject *offerOb = [messageOb objectForKey:@"offerObject"];
                            if ([[offerOb objectForKey:@"status"]isEqualToString:@"open"]) {
                                messageText = [[messageOb objectForKey:@"message"]stringByReplacingOccurrencesOfString:@"\nTap to cancel offer" withString:@"\nTap to buy now"];
                            }
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"purchased"]) {
                                messageText = [[messageOb objectForKey:@"message"]stringByReplacingOccurrencesOfString:@"\nTap to cancel offer" withString:@"\nPurchased"];
                            }
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"waiting"]) {
                                messageText = [[messageOb objectForKey:@"message"]stringByReplacingOccurrencesOfString:@"\nTap to cancel offer" withString:@"\nWaiting for seller to confirm"];
                            }
                        }
                        else if([[messageOb objectForKey:@"senderId"] isEqualToString:[PFUser currentUser].objectId] && [[messageOb objectForKey:@"offer"]isEqualToString:@"YES"]){
                            // user sent the message and it is an offer message
                            PFObject *offerOb = [messageOb objectForKey:@"offerObject"];
                            if ([[offerOb objectForKey:@"status"]isEqualToString:@"waiting"]) {
                                messageText = [[messageOb objectForKey:@"message"]stringByReplacingOccurrencesOfString:@"\nTap to cancel offer" withString:@"\nWaiting for you to confirm payment"];
                            }
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"purchased"]) {
                                messageText = [[messageOb objectForKey:@"message"]stringByReplacingOccurrencesOfString:@"\nTap to cancel offer" withString:@"\nSold"];
                            }
                        }
                        
                        message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt text:messageText];
                        
                        if ([[messageOb objectForKey:@"offer"]isEqualToString:@"YES"]) {
                            
                            PFObject *offerOb = [messageOb objectForKey:@"offerObject"];
                            if ([[offerOb objectForKey:@"status"]isEqualToString:@"open"]) {
                                message.isOfferMessage = YES;
                                message.offerObject = offerOb;
                            }
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"waiting"]) {
                                message.isOfferMessage = NO;
                                message.isWaiting = YES;
                            }
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"purchased"]) {
                                message.isOfferMessage = NO;
                                message.offerObject = offerOb;
                                message.isWaiting = NO;
                                message.isPurchased = YES;
                            }
                        }
                        [self.messages insertObject:message atIndex:0];
                    }
                }
                [self.convoObject saveInBackground];
                
                if (self.fromForeGround == YES) {
                    //call attributedString method to update labels
                    NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
                    NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
                    NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];
                    
                    [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
                    [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
                    self.fromForeGround = NO;
                }
                [self.collectionView reloadData];
                
                if (self.earlierPressed == NO) {
                    [self scrollToBottomAnimated:NO];
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
    
    //to prevent double tapping profile button
    self.profileBTapped = NO;
    
    if (self.checkoutTapped == YES) {
        //reset VC/load method
        self.skipped = 0;
        [self.messages removeAllObjects];
        [self.collectionView reloadData];
        [self loadMessages];
    }
    
    if (self.checkPayPalTapped == YES) {
        self.checkPayPalTapped = NO;
    }
    else{
        //to avoid needless calls only fetch once we know somethings changed
        [self.convoObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (!error) {
                //get order status
                [self refreshStatus];
            }
        }];
        
        self.currency = [[PFUser currentUser]objectForKey:@"currency"];
        if ([self.currency isEqualToString:@"GBP"]) {
            self.currencySymbol = @"£";
        }
        else if ([self.currency isEqualToString:@"EUR"]) {
            self.currencySymbol = @"€";
        }
        else if ([self.currency isEqualToString:@"USD"]) {
            self.currencySymbol = @"$";
        }
    }
}

-(void)fromForeGroundRefresh{
    self.fromForeGround = YES;
    [self loadMessages];
}

- (void)handleNotification:(NSNotification*)note {
    NSMutableArray *unseenConvos = [note object];
    PFObject *currentConvo = self.convoObject;
    for (PFObject *convo in unseenConvos) {
        if ([convo.objectId isEqualToString:currentConvo.objectId]) {
            //stop listening until new msgs loaded
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NewMessage" object:nil];
            [self loadNewMessages];
        }
    }
}

-(void)loadNewMessages{
    PFQuery *newMessageQuery = [PFQuery queryWithClassName:@"messages"];
    [newMessageQuery whereKey:@"convoId" equalTo:self.convoId];
    NSDate *lastDate = [self.lastMessage createdAt];
    [newMessageQuery whereKey:@"createdAt" greaterThan:lastDate];
    [newMessageQuery includeKey:@"offerObject"];
    [newMessageQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (!error) {
            if (objects) {
                //update skipped number
                int count = (int)[objects count];
                self.skipped = count + self.skipped;
                
                //add new message(s) to UI
                for (PFObject *messageOb in objects) {
                    
                    // if status message, set as seen & don't add to array so not in thread
                    if ([[messageOb objectForKey:@"isStatusMsg"]isEqualToString:@"YES"]) {
                        [messageOb setObject:@"seen" forKey:@"status"];
                        [messageOb saveInBackground];
                        continue;
                    }
                    
                    if (![self.messagesParseArray containsObject:messageOb]) {
                        // insets new messages at beginning of array (bottom of CV) so status labels are correct
                        [self.messagesParseArray insertObject:messageOb atIndex:0];
                    }
                    
                    __block JSQMessage *message = nil;
                    
                    if (![[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                        [messageOb setObject:@"seen" forKey:@"status"];
                        [messageOb saveInBackground];
                        
                        if (self.userIsBuyer == YES) {
                            [self.convoObject setObject:@0 forKey:@"buyerUnseen"];
                        }
                        else{
                            [self.convoObject setObject:@0 forKey:@"sellerUnseen"];
                        }
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
                        [self.messages addObject:message];
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
                                            [self.masker applyIncomingBubbleImageMaskToMediaView:photoItem.mediaView]; //needs to change?
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
                        
                        if (![[messageOb objectForKey:@"senderId"] isEqualToString:[PFUser currentUser].objectId] && [[messageOb objectForKey:@"offer"]isEqualToString:@"YES"]) {
                            PFObject *offerOb = [messageOb objectForKey:@"offerObject"];
                            if ([[offerOb objectForKey:@"status"]isEqualToString:@"open"]) {
                                messageText = [[messageOb objectForKey:@"message"]stringByReplacingOccurrencesOfString:@"\nTap to cancel offer" withString:@"\nTap to buy now"];
                            }
                            
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"purchased"]) {
                                messageText = [[messageOb objectForKey:@"message"]stringByReplacingOccurrencesOfString:@"\nTap to cancel offer" withString:@"\nPurchased"];
                            }
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"waiting"]) {
                                messageText = [[messageOb objectForKey:@"message"]stringByReplacingOccurrencesOfString:@"\nTap to cancel offer" withString:@"\nWaiting for seller to confirm"];
                            }
                        }
                        
                        message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt text:messageText];
                        if ([[messageOb objectForKey:@"offer"]isEqualToString:@"YES"]) {
                            PFObject *offerOb = [messageOb objectForKey:@"offerObject"];
                            if ([[offerOb objectForKey:@"status"]isEqualToString:@"open"]) {
                                message.isOfferMessage = YES;
                                message.offerObject = offerOb;
                            }
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"waiting"]) {
                                message.isOfferMessage = NO;
                                message.isWaiting = YES;
                            }
                        }
                        [self.messages addObject:message];
                    }
                    self.lastMessage = messageOb;
                }
                
                //save new unseen counter number
                [self.convoObject saveInBackground];
                
                self.receivedNew = YES;

                //call attributedString method to update labels
                NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
                NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
                NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];

                self.checkoutTapped = NO;
                
                [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
                [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
                [self.collectionView reloadData];
                
                //scroll to bottom
                [self scrollToBottomAnimated:NO];
                
                //minus number of new messages that have just been seen off tab bar badge
                NSString *badgeString =[[self.tabBarController.tabBar.items objectAtIndex:2] badgeValue];
                int badgeInt = [badgeString intValue];
                int newCount = (int)[objects count];
                int updatedBadge = badgeInt - newCount;
                if (updatedBadge == 0) {
                    [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:nil];
                }
                //only set updated badge if its a +ve no.
                else if (updatedBadge > 0){
                    [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:[NSString stringWithFormat:@"%d", updatedBadge]];
                }
                
                //reregister for notifications again
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:@"NewMessage" object:nil];
            }
            else{
                NSLog(@"no new objects");
            }
        }
        else{
            //error getting new messages
            [self showError];
        }
    }];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
    
    if (self.sellThisPressed == YES) {
        self.sellThisPressed = NO;
        self.offerMode = YES;
        self.inputToolbar.contentView.textView.text = [NSString stringWithFormat:@"Selling: \nCondition: \nPrice: %@\nMeetup: ", self.currencySymbol];
    }
    
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

-(void)showPayPalAlert{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"PayPal" message:[NSString stringWithFormat:@"Make sure your PayPal email address is correct to ensure seemless payment. Please enter it in Settings now"] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        SettingsController *vc = [[SettingsController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

//-(void)createConvoPOPUP{
//    UIAlertController *alertController = [UIAlertController
//                                          alertControllerWithTitle:@"New convo"
//                                          message:@"Enter username"
//                                          preferredStyle:UIAlertControllerStyleAlert];
//    
//    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
//     {
//         textField.placeholder = @"PayPal email";
//     }];
//    
//    UIAlertAction *okAction = [UIAlertAction
//                               actionWithTitle:@"Done"
//                               style:UIAlertActionStyleDefault
//                               handler:^(UIAlertAction *action)
//                               {
//                                   UITextField *paypalField = alertController.textFields.firstObject;
//                                   NSLog(@"paypal email %@", paypalField.text);
//                                   [PFUser currentUser][@"paypal"] = paypalField.textColor;
//                               }];
//    
//    [alertController addAction:okAction];
//    
//    [self presentViewController:alertController animated:YES completion:nil];
//}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    NSString *messageString = text;
    
    if (self.offerMode == YES) {
        
        //create offer object in bg
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
                NSLog(@"price array %@", priceArray);
                if ([priceArray[0] isEqualToString:self.currencySymbol]) {
                    
                    priceString = [NSString stringWithFormat:@"%@0.00", self.currencySymbol];
                }
                else if (priceArray.count > 1){
                    NSString *intAmount = priceArray[0];
                    
                    if (intAmount.length == 1){
                        NSLog(@"just the currency symbol then a decimal point");
                        intAmount = [NSString stringWithFormat:@"%@00", self.currencySymbol];
                    }
                    else{
                        //all good
                        NSLog(@"length of int %lu", (unsigned long)intAmount.length);
                    }
                    
                    NSMutableString *centAmount = priceArray[1];
                    if (centAmount.length == 2){
                        //all good
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
                    if (offerPriceString.length > 5){
                        [self showAlertWithTitle:@"Enter a valid price" andMsg:@"Your offer does not contain a valid Price value"];
                        return;
                    }
                    
                    priceString = [NSString stringWithFormat:@"%@.00", offerPriceString];
                    NSLog(@"no decimal point so price is %@", priceString);
                }
                
                NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                NSString *newbie = [priceString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@", self.currencySymbol] withString:@""];
                NSString *newbie1 = [newbie stringByReplacingOccurrencesOfString:@"." withString:@""];
                
                if (!([newbie1 rangeOfCharacterFromSet:notDigits].location == NSNotFound))
                {
                    //price supplied must contain non number characters
                    [self showAlertWithTitle:@"Enter a valid price" andMsg:@"Your offer does not contain a valid Price value"];
                    return;
                }
                
                if ([priceString isEqualToString:[NSString stringWithFormat:@"%@0.00", self.currencySymbol]] || [priceString isEqualToString:@""] || [priceString isEqualToString:[NSString stringWithFormat:@"%@.00", self.currencySymbol]] || [priceString isEqualToString:@"  "]) {
                    //invalid price number
                    [self showAlertWithTitle:@"Enter a valid price" andMsg:@"Your offer does not contain a valid Price value"];
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
        
        NSString *prefixToRemove = self.currencySymbol;
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
        [self.offerObject setObject:self.currencySymbol forKey:@"symbol"];
        [self.offerObject setObject:self.currency forKey:@"currency"];
    }
    
    if (self.offerMode == YES) {
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
            NSString *pushText = [NSString stringWithFormat:@"%@: %@", [[PFUser currentUser]username], messageString];
            
            if (message.isOfferMessage == YES) {
                pushText = [NSString stringWithFormat:@"%@ sent an offer to purchase their item 🔌", [[PFUser currentUser]username]];
            }
            else{
                self.lastMessage = messageObject;
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
    
    //call attributedString method to update labels
    NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
    NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
    NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];
    
    [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
    [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
    [self.collectionView reloadItemsAtIndexPaths:@[pathToLastItem]];
    
    if (self.offerMode == YES) {
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.listingButton, self.profileButton, nil]];
    
        if ([self.convoObject objectForKey:@"convoImages"] == 0) {
            //images have been previously sent in the chat so don't need to send anymore
            if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
            {
                CameraController *vc = [[CameraController alloc]init];
                vc.delegate = self;
                vc.offerMode = YES;
                [self presentViewController:vc animated:YES completion:nil];
            }
        }
        else{
            self.offerMode = NO;
            PFQuery *convoImagesQuery = [PFQuery queryWithClassName:@"messageImages"];
            [convoImagesQuery whereKey:@"convo" equalTo:self.convoObject];
            [convoImagesQuery orderByDescending:@"createdAt"];
            [convoImagesQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    PFFile *imgFile = [object objectForKey:@"Image"];
                    [self.offerObject setObject:imgFile forKey:@"image"];
                    [self.offerObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded == YES) {
                            NSLog(@"success saving img!");
                        }
                        else{
                            NSLog(@"error saving! %@", error);
                        }
                    }];
                }
                else{
                    NSLog(@"error %@", error);
                }
            }];
        }
    }
    
    //update convo object after every message sent
    [self.convoObject incrementKey:@"totalMessages"];
    [self.convoObject setObject:messageObject forKey:@"lastSent"];
    [self.convoObject setObject:[NSDate date] forKey:@"lastSentDate"];
    
    if (self.userIsBuyer == YES) {
       [self.convoObject incrementKey:@"sellerUnseen"];
    }
    else{
        [self.convoObject incrementKey:@"buyerUnseen"];
    }
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
        if (![textView.text containsString:@"\nSelling:"] && ![textView.text containsString:@"\nCondition:"] && ![textView.text containsString:@"\nPrice:"] && ![textView.text containsString:@"\nMeetup:"]) {
            self.offerMode = NO;
        }
        [self.inputToolbar toggleSendButtonEnabled];
    }
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"pulsingDone"];
    [self.inputToolbar.contentView.textView resignFirstResponder];
    [self alertSheet];
}

-(void)alertSheet{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    
    PFObject *order = [self.convoObject objectForKey:@"order"];
    
    if (self.userIsBuyer == NO) {
        
        if (order == nil) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Send an offer" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                self.offerMode = YES;
                self.inputToolbar.contentView.textView.text = [NSString stringWithFormat:@"Selling: \nCondition: \nPrice: %@\nMeetup: ", self.currencySymbol];
                [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.listingButton, self.cancelButton, nil]];
            }]];
        }
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            CameraController *vc = [[CameraController alloc]init];
            vc.delegate = self;
            vc.offerMode = YES;
            [self presentViewController:vc animated:YES completion:nil];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose pictures" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//            picker.delegate = self;
//            picker.allowsEditing = NO;
//            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            
            GMImagePickerController *picker = [[GMImagePickerController alloc] init];
            picker.delegate = self;
            picker.displaySelectionInfoToolbar = YES;
            picker.displayAlbumsNumberOfAssets = YES;
            picker.title = @"Choose pictures";
            picker.mediaTypes = @[@(PHAssetMediaTypeImage)];
            [self presentViewController:picker animated:YES completion:nil];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Goto my PayPal" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self showMyPaypal];
        }]];
    }
    else{
        if (order != nil) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Pay with PayPal" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                //used as a backup way to pay if buyer has clicked paid but didn't actually pay.
                //order object already created so just need to an easy way to pay
                [self payPaypal];
            }]];
        }
        
        //pay with paypal at all times here? not just used as a backup when an order has been created?
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose pictures" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            GMImagePickerController *picker = [[GMImagePickerController alloc] init];
            picker.delegate = self;
            picker.displaySelectionInfoToolbar = YES;
            picker.displayAlbumsNumberOfAssets = YES;
            picker.title = @"Choose pictures";
            picker.mediaTypes = @[@(PHAssetMediaTypeImage)];
            [self presentViewController:picker animated:YES completion:nil];
        }]];
    }
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (BOOL)assetsPickerController:(GMImagePickerController *)picker shouldSelectAsset:(PHAsset *)asset{
    if (picker.selectedAssets.count == 4) {
        return NO;
    }
    return YES;
}

- (void)assetsPickerController:(GMImagePickerController *)picker didFinishPickingAssets:(NSArray *)assetArray
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"GMImagePicker: User ended picking assets. Number of selected items is: %lu", (unsigned long)assetArray.count);
    
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    PHImageManager *manager = [PHImageManager defaultManager];
    
    for (PHAsset *asset in assetArray) {
        [manager requestImageForAsset:asset
                           targetSize:PHImageManagerMaximumSize
                          contentMode:PHImageContentModeDefault
                              options:requestOptions
                        resultHandler:^void(UIImage *image, NSDictionary *info) {
                            NSLog(@"image %@", image);
                            [self finalImage:image];
                        }];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    //display crop picker
    [picker dismissViewControllerAnimated:YES completion:^{
        [self displayCropperWithImage:chosenImage];
    }];
}

-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker
{
    //cancel
}

-(void)displayCropperWithImage:(UIImage *)image{
    BASSquareCropperViewController *squareCropperViewController = [[BASSquareCropperViewController alloc] initWithImage:image minimumCroppedImageSideLength:375.0f];
    squareCropperViewController.squareCropperDelegate = self;
    squareCropperViewController.backgroundColor = [UIColor whiteColor];
    squareCropperViewController.borderColor = [UIColor whiteColor];
    squareCropperViewController.doneFont = [UIFont fontWithName:@"AvenirNext-Regular" size:18.0f];
    squareCropperViewController.cancelFont = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0f];
    squareCropperViewController.excludedBackgroundColor = [UIColor blackColor];
    [self.navigationController presentViewController:squareCropperViewController animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)squareCropperDidCropImage:(UIImage *)croppedImage inCropper:(BASSquareCropperViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
    [self finalImage:croppedImage];
}

- (void)squareCropperDidCancelCropInCropper:(BASSquareCropperViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)payPaypal{
    NSString *URLString = @"https://www.paypal.com/myaccount/transfer/buy";
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:[NSURL URLWithString:URLString]];
    webViewController.title = @"PayPal";
    webViewController.showUrlWhileLoading = YES;
    webViewController.showPageTitles = NO;
    webViewController.doneButtonTitle = @"Paid";
    webViewController.paypalMode = YES;
    if ([self.convoObject objectForKey:@"order"]) {
        //got an order object so get email and amount info
        webViewController.infoMode = YES;
        if ([self.otherUser objectForKey:@"email"]) {
            webViewController.emailToPay = [self.otherUser objectForKey:@"email"];
            webViewController.amountToPay = @"";
        }
        else{
            webViewController.infoMode = NO;
        }
    }
    else{
        //hide toolbar banner
        webViewController.infoMode = NO;
    }
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)showMyPaypal{
    NSString *URLString = @"https://www.paypal.com/myaccount/";
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:[NSURL URLWithString:URLString]];
    webViewController.title = @"My PayPal";
    webViewController.showUrlWhileLoading = YES;
    webViewController.showPageTitles = NO;
    webViewController.doneButtonTitle = @"";
    webViewController.paypalMode = NO;
    webViewController.infoMode = NO;
    self.checkPayPalTapped = YES;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
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
    
    PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:UIImageJPEGRepresentation(image, 0.5)];
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
            
//            NSLog(self.offerMode ? @"YES":@"NO");
            
            if (self.offerMode == YES) {
                NSLog(@"file %@", filePicture);
                [self.offerObject setObject:filePicture forKey:@"image"];
                [self.offerObject saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded == YES) {
                        NSLog(@"saved image with offer");
                    }
                    
                    else{
                        NSLog(@"error saving image with offer %@", error);
                    }
                }];
                
                //check if paypal email has been checked before proceeding
                if (![[[PFUser currentUser]objectForKey:@"paypalChecked"]isEqualToString:@"YES"]) {
                    [self showPayPalAlert];
                    [[PFUser currentUser] setObject:@"YES" forKey:@"paypalChecked"];
                    [[PFUser currentUser]saveInBackground];
                }
            }
            else{
                [self.convoObject setObject:self.messageObject forKey:@"lastSent"];
                
                NSString *pushString = [NSString stringWithFormat:@"%@ sent a picture 📸",[[PFUser currentUser]username]];
                
                //send push to other user
                NSDictionary *params = @{@"userId": self.otherUser.objectId, @"message": pushString, @"sender": [PFUser currentUser].username};
                [PFCloud callFunctionInBackground:@"sendPush" withParameters: params block:^(NSDictionary *response, NSError *error) {
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
            if (self.userIsBuyer == YES) {
                [self.convoObject incrementKey:@"sellerUnseen"];
            }
            else{
                [self.convoObject incrementKey:@"buyerUnseen"];
            }
            
            [self.convoObject setObject:[NSDate date] forKey:@"lastSentDate"];
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
            NSLog(@"error saving pic msg %@", error);
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Error sending image" message:@"Make sure you're connected to the internet" preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
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
    else if (message.isWaiting == YES){
        return self.waitingBubbleImageData;
    }
    else if (message.isPurchased == YES){
        return self.purchasedBubbleImageData;
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
                
                if (self.receivedNew == YES) {
                    NSAttributedString *newString = [[NSAttributedString alloc]initWithString:@"seen"];
                    self.receivedNew = NO;
                    return newString;
                }
                else if ([statusString isEqualToString:@"sent"]||[statusString isEqualToString:@"seen"]) {
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
    self.showLoadEarlierMessagesHeader = NO;
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
    else if (tappedMessage.isPurchased == YES){
        //goto order summary
        OrderSummaryController *vc = [[OrderSummaryController alloc]init];
        if ([tappedMessage.senderId isEqualToString:[PFUser currentUser].objectId]) {
            vc.purchased = NO;
        }
        else{
            vc.purchased = YES;
        }
        vc.orderDate = tappedMessage.offerObject.createdAt;
        vc.orderObject = [self.convoObject objectForKey:@"order"];
        [self.navigationController pushViewController:vc animated:YES];
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
                self.checkoutTapped = YES;
                CheckoutController *vc = [[CheckoutController alloc]init];
                vc.confirmedOfferObject = tappedMessage.offerObject;
                vc.convo = self.convoObject;
                vc.sellerEmail = [self.otherUser objectForKey:@"email"];
                vc.otherUserId = self.otherUser.objectId;
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
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *string = pasteboard.string;
    if (string) {
        return YES;
    }
    else{
        return NO;
    }
}

-(void)clearOffer{
    self.inputToolbar.contentView.textView.text = @"";
    self.offerMode = NO;
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.listingButton, self.profileButton, nil]];
}

-(void)profileTapped{
    if (self.otherUser && self.profileBTapped == NO) {
        self.profileBTapped = YES;
        UserProfileController *vc = [[UserProfileController alloc]init];
        vc.user = self.otherUser;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)listingTapped{
    ListingController *vc = [[ListingController alloc]init];
    vc.listingObject = [self.convoObject objectForKey:@"wtbListing"];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)markTapped{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Payment Received" message:@"Tap 'Confirm' to tell us you have received the agreed amount into your PayPal account. Tap 'Check' to make sure." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self confirmOrder];
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Check" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showMyPaypal];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showConfirmBanner{
    if (self.payBannerShowing == YES) {
        [self.paidView removeFromSuperview];
        self.payBannerShowing = NO;
    }
    else{
        if (!self.paidView) {
            self.paidView = [[UIView alloc]initWithFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20, self.navigationController.navigationBar.frame.size.width, 30)];
            [self.paidView setAlpha:1.0];
            self.paidButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0, self.paidView.frame.size.width, self.paidView.frame.size.height)];
            [self.paidButton setTitle:@"Tap to confirm you've received payment" forState:UIControlStateNormal];
            [self.paidButton addTarget:self action:@selector(markTapped) forControlEvents:UIControlEventTouchUpInside];
            self.paidButton.backgroundColor = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
            [self.paidButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            self.paidButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
            [self.paidView addSubview:self.paidButton];
            [self.paidButton setCenter:CGPointMake(self.paidView.frame.size.width / 2, self.paidView.frame.size.height / 2)];
        }
        [self.view addSubview:self.paidView];
        self.payBannerShowing = YES;
    }
}

-(void)showSuccessBannerWithText:(NSString *)text{
    if (self.successBannerShowing == YES) {
        [self.successView removeFromSuperview];
        self.successBannerShowing = NO;
    }
    else{
        if (!self.successView) {
            self.successView = [[UIView alloc]initWithFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20, self.navigationController.navigationBar.frame.size.width, 30)];
            [self.successView setAlpha:1.0];
            self.successButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0, self.successView.frame.size.width, self.successView.frame.size.height)];
            [self.successButton setTitle:text forState:UIControlStateNormal];
            self.successButton.backgroundColor = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
            [self.successButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            self.successButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
            [self.successView addSubview:self.successButton];
            [self.successButton setCenter:CGPointMake(self.successView.frame.size.width / 2, self.successView.frame.size.height / 2)];
            
            UIButton *dismissButton = [[UIButton alloc]initWithFrame:CGRectMake(self.successView.frame.size.width-40,(self.successView.frame.size.height/2)-10, 20, 20)];
            [dismissButton setTitle:@"x" forState:UIControlStateNormal];
            [dismissButton addTarget:self action:@selector(dismissSuccessBanner) forControlEvents:UIControlEventTouchUpInside];
            [self.successButton addSubview:dismissButton];
        }
        [self.view addSubview:self.successView];
        self.successBannerShowing = YES;
    }
}

-(void)dismissSuccessBanner{
    if (self.successBannerShowing == YES) {
        [UIView animateWithDuration:0.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.successView setAlpha:0.0];
                         }
                         completion:^(BOOL finished) {
                             [self.successView removeFromSuperview];
                             self.successBannerShowing = NO;
                         }];
    }
}

-(void)showInfoBanner{
    if (self.infoBannerShowing == YES) {

    }
    else{
        if (!self.infoView) {
            self.infoView = [[UIView alloc]initWithFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20, self.navigationController.navigationBar.frame.size.width, 30)];
            [self.infoView setAlpha:1.0];
            UIButton *infoButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0, self.infoView.frame.size.width, self.infoView.frame.size.height)];
            [infoButton addTarget:self action:@selector(infoTapped) forControlEvents:UIControlEventTouchUpInside];
            infoButton.titleLabel.adjustsFontSizeToFitWidth = YES;
            infoButton.titleLabel.minimumScaleFactor=0.5;
            
            UIButton *dismissButton = [[UIButton alloc]initWithFrame:CGRectMake(self.infoView.frame.size.width-40,(self.infoView.frame.size.height/2)-10, 20, 20)];
            [dismissButton setTitle:@"x" forState:UIControlStateNormal];
            [dismissButton addTarget:self action:@selector(dismissInfoBanner) forControlEvents:UIControlEventTouchUpInside];
            [infoButton addSubview:dismissButton];
            
            if (self.userIsBuyer == YES) {
                [infoButton setTitle:@"Buyer Protection & Zero Fees on Bump" forState:UIControlStateNormal];
            }
            else{
                [infoButton setTitle:@"Seller Protection & Zero Fees on Bump" forState:UIControlStateNormal];
            }
            
            infoButton.backgroundColor = [UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0];
            [infoButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            infoButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
            [self.infoView addSubview:infoButton];
            [infoButton setCenter:CGPointMake(self.infoView.frame.size.width / 2, self.infoView.frame.size.height / 2)];
        }
        [self.view addSubview:self.infoView];
        self.infoBannerShowing = YES;
    }
}

-(void)dismissInfoBanner{
    if (self.infoBannerShowing == YES) {
        [UIView animateWithDuration:0.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.infoView setAlpha:0.0];
                             
                         }
                         completion:^(BOOL finished) {
                             [self.infoView removeFromSuperview];
                             self.infoBannerShowing = NO;
                         }];
    }
}

-(void)infoTapped{
    MessageTutorial *vc = [[MessageTutorial alloc]init];
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)confirmOrder{
    [self.paidButton setEnabled:NO];
    
    [self.paidView removeFromSuperview];
    self.paidView = nil;
    self.payBannerShowing = NO;
    [self.paidButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.paidButton removeFromSuperview];
    
//    [self showSuccessBannerWithText:@"Payment received - Tap to leave feedback"]; // show
//    [self.successButton addTarget:self action:@selector(feedbackTapped) forControlEvents:UIControlEventTouchUpInside];
    
    PFObject *order = [self.convoObject objectForKey:@"order"];
    [order setObject:@"paid" forKey:@"status"];
    [order setObject:[NSNumber numberWithBool:YES] forKey:@"paid"];

    [order saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"order has been paid for!");
            [self refreshStatus];
            
            //send push to other user
            NSString *pushString = [NSString stringWithFormat:@"%@ confirmed they received your payment!",[[PFUser currentUser]username]];
            NSDictionary *params = @{@"userId": self.otherUser.objectId, @"message": pushString, @"sender": [PFUser currentUser].username};
            [PFCloud callFunctionInBackground:@"sendPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    NSLog(@"response sending confirm push %@", response);
                }
                else{
                    NSLog(@"image push error %@", error);
                }
            }];
            
            //create a status message & save as last sent
            NSString *messageString = @"Payment received!";
            
            PFObject *messageObject = [PFObject objectWithClassName:@"messages"];
            messageObject[@"message"] = messageString;
            messageObject[@"sender"] = [PFUser currentUser];
            messageObject[@"senderId"] = [PFUser currentUser].objectId;
            messageObject[@"senderName"] = [PFUser currentUser].username;
            messageObject[@"convoId"] = self.convoId;
            messageObject[@"status"] = @"sent";
            messageObject[@"offer"] = @"NO";
            messageObject[@"mediaMessage"] = @"NO";
            messageObject[@"isStatusMsg"] = @"YES";
            
            [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    NSLog(@"saved status message!");
                    
                    [self.convoObject setObject:messageObject forKey:@"lastSent"];
                    [self.convoObject setObject:[NSDate date] forKey:@"lastSentDate"];
                    [self.convoObject saveInBackground];
                }
            }];
            
            PFObject *offer = [self.convoObject objectForKey:@"offer"];
            [offer setObject:@"purchased" forKey:@"status"];
            [offer saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //reset collectionView
                    self.skipped = 0;
                    [self.messages removeAllObjects];
                    [self.collectionView reloadData];
                    [self loadMessages];
                }
            }];
            
            PFObject *listing = [self.convoObject objectForKey:@"listing"];
            [listing setObject:@"purchased" forKey:@"status"];
            [listing saveInBackground];
            
            [self viewOrderDetails];
        }
        else{
            NSLog(@"error saving order %@", error);
            
            //revert back to OG banners
            [self showConfirmBanner];
            [self refreshStatus];
            
            [self.paidButton setEnabled:YES];
        }
    }];
}

-(void)viewOrderDetails{
    OrderSummaryController *vc = [[OrderSummaryController alloc]init];
    if (self.userIsBuyer == NO) {
        vc.purchased = NO;
    }
    else{
        vc.purchased = YES;
    }
    PFObject *order = [self.convoObject objectForKey:@"order"];
    vc.orderDate = order.createdAt;
    vc.orderObject = order;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)markAsShipped{
    [self.successButton setEnabled:NO];
    [self.successButton setTitle:@"Shipped!" forState:UIControlStateNormal];
    
    PFObject *order = [self.convoObject objectForKey:@"order"];
    [order setObject:[NSNumber numberWithBool:YES] forKey:@"shipped"];
    [order saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [self refreshStatus];
            [self.successButton setEnabled:YES];
            
            //send push to other user
            NSString *pushString = [NSString stringWithFormat:@"%@ has shipped %@!",[[PFUser currentUser]username], order[@"title"]];
            NSDictionary *params = @{@"userId": self.otherUser.objectId, @"message": pushString, @"sender": [PFUser currentUser].username};
            [PFCloud callFunctionInBackground:@"sendPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    NSLog(@"response sending shipping push %@", response);
                }
                else{
                    NSLog(@"image push error %@", error);
                }
            }];
            
//            //create a status message & save as last sent
//            NSString *messageString = @"Item shipped";
//            
//            PFObject *messageObject = [PFObject objectWithClassName:@"messages"];
//            messageObject[@"message"] = messageString;
//            messageObject[@"sender"] = [PFUser currentUser];
//            messageObject[@"senderId"] = [PFUser currentUser].objectId;
//            messageObject[@"senderName"] = [PFUser currentUser].username;
//            messageObject[@"convoId"] = self.convoId;
//            messageObject[@"status"] = @"sent";
//            messageObject[@"offer"] = @"NO";
//            messageObject[@"mediaMessage"] = @"NO";
//            messageObject[@"isStatusMsg"] = @"YES";
//            
//            [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                if (succeeded) {
//                    NSLog(@"saved status message!");
//                    
//                    [self.convoObject setObject:messageObject forKey:@"lastSent"];
//                    [self.convoObject setObject:[NSDate date] forKey:@"lastSentDate"];
//                    [self.convoObject saveInBackground];
//                }
//            }];
        }
        else{
            NSLog(@"error updating order %@", error);
            
            [self refreshStatus];
            [self.successButton setEnabled:YES];
        }
    }];
}

-(void)feedbackTapped{
    FeedbackController *vc = [[FeedbackController alloc]init];
    vc.IDUser = self.otherUser.objectId;
    BOOL purchased;
    if (self.userIsBuyer == YES) {
        purchased = YES;
    }
    else{
        purchased = NO;
    }
    vc.purchased = purchased;
    vc.orderObject = [self.convoObject objectForKey:@"order"];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)refreshStatus{
    PFObject *order = [self.convoObject objectForKey:@"order"];
    if (order !=nil) {

        [order fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {                
                //clear all targets on button
                
                if (self.infoBannerShowing == YES) {
                    [self.infoView removeFromSuperview];
                    self.infoBannerShowing = NO;
                }
                
                [self.successButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                
                BOOL paid = [[order objectForKey:@"paid"]boolValue];
                BOOL shipped = [[order objectForKey:@"shipped"]boolValue];
                BOOL feedback;
                if (self.userIsBuyer == YES) {
                    //buyer has left feedback if this is yes
                    feedback = [[order objectForKey:@"buyerFeedback"]boolValue];
                }
                else{
                    feedback = [[order objectForKey:@"sellerFeedback"]boolValue];
                }
                
                if (self.successBannerShowing == NO) {
                    [self showSuccessBannerWithText:@""];
                }
                
                if (paid == NO && shipped == NO && feedback == NO) {
                    //next step is for payment to be confirmed
                    if (self.userIsBuyer == YES) {
                        [self.successButton setTitle:@"Waiting for seller to confirm payment" forState:UIControlStateNormal];
                    }
                    else{
                        [self showConfirmBanner];
                    }
                }
                else if (paid == YES && shipped == NO && feedback == NO) {
                    //next step is to leave feedback for buyer and for seller to mark as shipped
                    if (self.userIsBuyer == YES) {
                        [self.successButton setTitle:@"Seller has confirmed payment - Tap to leave feedback" forState:UIControlStateNormal];
                        [self.successButton addTarget:self action:@selector(viewOrderDetails) forControlEvents:UIControlEventTouchUpInside];
                        //feedbacktapped
                    }
                    else{
                        [self.successButton setTitle:@"Payment received - Tap to mark as shipped" forState:UIControlStateNormal];
                        [self.successButton addTarget:self action:@selector(viewOrderDetails) forControlEvents:UIControlEventTouchUpInside];
                        //markasshipped
                    }
                }
                else if (paid == YES && shipped == NO && feedback == YES) {
                    //next step is for seller to mark as shipped
                    if (self.userIsBuyer == YES) {
                        [self.successButton setTitle:@"Feedback left - Tap to report a problem" forState:UIControlStateNormal];
                        [self.successButton addTarget:self action:@selector(viewOrderDetails) forControlEvents:UIControlEventTouchUpInside];
                        //reportUser
                    }
                    else{
                        [self.successButton setTitle:@"Payment received - Tap to mark as shipped" forState:UIControlStateNormal];
                        [self.successButton addTarget:self action:@selector(viewOrderDetails) forControlEvents:UIControlEventTouchUpInside];
                        //markasshipped
                    }
                }
                else if (paid == YES && shipped == YES && feedback == NO) {
                    //next step is to leave feedback for seller once shipped or buyer to leave feedback
                    if (self.userIsBuyer == YES) {
                        [self.successButton setTitle:@"Item shipped - Tap to leave feedback" forState:UIControlStateNormal];
                    }
                    else{
                        [self.successButton setTitle:@"Payment received - Tap to leave feedback" forState:UIControlStateNormal];
                    }
                    [self.successButton addTarget:self action:@selector(viewOrderDetails) forControlEvents:UIControlEventTouchUpInside];
                    //feedbacktapped
                }
                else if (paid == YES && shipped == YES && feedback == YES) {
                    //next step is to leave feedback for seller once shipped or buyer to leave feedback
                    if (self.userIsBuyer == YES) {
                        [self.successButton setTitle:@"Item shipped - Tap to report a problem" forState:UIControlStateNormal];
//                        [self.successButton addTarget:self action:@selector(reportUser) forControlEvents:UIControlEventTouchUpInside];
                    }
                    else{
                        [self.successButton setTitle:@"Paid - Tap for order details" forState:UIControlStateNormal];
                        self.successButton.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
                    }
                    [self.successButton addTarget:self action:@selector(viewOrderDetails) forControlEvents:UIControlEventTouchUpInside];
                }
                else{
                    NSLog(@"DOESNT FIT IN");
                }
            }
            else{
                NSLog(@"error getting order %@", error);
            }
        }];
    }
    else{
        NSLog(@"no confirmed order yet so put the other banner in the bar");
        [self showInfoBanner];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    float edge = scrollView.contentOffset.y + scrollView.frame.size.height;
    if (edge <= (scrollView.contentSize.height-(scrollView.contentSize.height/2))){
        if (self.successBannerShowing == YES) {
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.successView setAlpha:0.0];
                             }
                             completion:^(BOOL finished) {}];
            
        }
        else if(self.payBannerShowing == YES){
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.paidView setAlpha:0.0];
                             }
                             completion:^(BOOL finished) {}];
        }
        else if(self.infoBannerShowing == YES){
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.infoView setAlpha:0.0];
                             }
                             completion:^(BOOL finished) {}];
        }
    }
    else{
        if (self.successBannerShowing == YES) {
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.successView setAlpha:1.0];
                             }
                             completion:^(BOOL finished) {}];
        }
        else if(self.payBannerShowing == YES){
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.paidView setAlpha:1.0];
                             }
                             completion:^(BOOL finished) {}];
        }
        else if(self.infoBannerShowing == YES){
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.infoView setAlpha:1.0];
                             }
                             completion:^(BOOL finished) {}];
        }
    }
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

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}
@end
