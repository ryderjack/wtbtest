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
#import "OrderSummaryController.h"
#import "ListingController.h"
#import "MessagesTutorial.h"
#import "NavigationController.h"
#import "UIImage+Resize.h"
#import "Tut1ViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "CustomMessagesCollectionViewCell.h"
#import "CustomMessagesCollectionViewCellIncoming.h"
#import "ForSaleListing.h"

@interface MessageViewController ()

@end

@implementation MessageViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //register custom cell stuff
//    self.incomingCellIdentifier = CustomMessagesCollectionViewCellIncoming.cellReuseIdentifier;
//    self.incomingMediaCellIdentifier = CustomMessagesCollectionViewCellIncoming.mediaCellReuseIdentifier;
//    
//    UINib *incomingNib = [UINib nibWithNibName:@"CustomMessagesCollectionViewCellIncoming" bundle:nil];
//    [self.collectionView registerNib:incomingNib forCellWithReuseIdentifier:self.incomingCellIdentifier];
//    [self.collectionView registerNib:incomingNib forCellWithReuseIdentifier:self.incomingMediaCellIdentifier];
    
    if (![self.otherUserName isEqualToString:@""]) {
        self.title = self.otherUserName;
    }
    
    [self.otherUser fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.title = self.otherUser.username;
            PFFile *imageFile = [self.otherUser objectForKey:@"picture"];
            [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (!error) {
                    self.otherUserImage = [UIImage imageWithData:data];
                    UIImage *image = [JSQMessagesAvatarImageFactory circularAvatarImage:self.otherUserImage withDiameter:35];
                    UIImage *placeholder = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"empty"] withDiameter:35];
                    self.avaImage = [[JSQMessagesAvatarImage alloc]initWithAvatarImage:image highlightedImage:image placeholderImage:placeholder];
                }
            }];
        }
        else{
            NSLog(@"getting user error %@", error);
            [self showUserAlertWithTitle:@"User not found!" andMsg:nil];
        }
    }];
    
    self.savedString = @"";
    
    self.profileButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"profileIcon2"] style:UIBarButtonItemStylePlain target:self action:@selector(profileTapped)];
    
    if ([self.listing objectForKey:@"image1"]) {
        UIButton *btn =  [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0,0,25,25);
        [btn addTarget:self action:@selector(listingTapped) forControlEvents:UIControlEventTouchUpInside];
        
        PFImageView *buttonView = [[PFImageView alloc]initWithFrame:btn.frame];
        PFFile *listingFile = [self.listing objectForKey:@"image1"];
        [buttonView setFile:listingFile];
        [buttonView loadInBackground];
        
        if (self.pureWTS == YES) {
            //circular
            [self setSaleImageBorder:buttonView];
        }
        else{
            [self setImageBorder:buttonView];
        }
        
        [btn addSubview:buttonView];
        
        self.listingButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.listingButton, self.profileButton, nil]];
    }
    else{
        [self.navigationItem setRightBarButtonItem:self.profileButton];
    }
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    
    self.inputToolbar.contentView.textView.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    self.inputToolbar.contentView.textView.placeHolder = @"Write a message...";
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"sendPicBlk"] forState:UIControlStateNormal];
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"sendPicBlue"] forState:UIControlStateHighlighted];
    self.inputToolbar.contentView.backgroundColor = [UIColor whiteColor];
    [self.inputToolbar.contentView.textView.layer setBorderWidth:0.0];
    self.inputToolbar.contentView.textView.delegate = self;
    [self.inputToolbar.contentView.rightBarButtonItem setHidden:YES];
    
    //avatar images
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(35, 35);
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    //check if tab bar height is zero (from search)
    if (self.tabBarController.tabBar.frame.size.height == 0) {
        self.tabBarHeightInt = self.presentingViewController.tabBarController.tabBar.frame.size.height;
    }
    else{
        self.tabBarHeightInt = self.tabBarController.tabBar.frame.size.height;
    }
    
    //Register custom menu actions for cells.
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];
    
    self.senderId = [PFUser currentUser].objectId;
    
    self.messages = [[NSMutableArray alloc]init];
    self.messagesParseArray = [[NSMutableArray alloc]init];
    self.sentMessagesParseArray = [[NSMutableArray alloc]init];
    self.suggestedMessagesArray = [[NSMutableArray alloc]init];
    self.convoImagesArray = [[NSMutableArray alloc]init];
    
    //set suggested messages
    if (self.userIsBuyer == YES) {
        
        //should we show?
        if (![[self.convoObject objectForKey:@"buyerShowSuggested"]isEqualToString:@"NO"]) {
            self.showSuggested = YES;
            
            //load messages left
            if ([self.convoObject objectForKey:@"buyerSuggestedMessages"]) {
                [self.suggestedMessagesArray addObjectsFromArray:[self.convoObject objectForKey:@"buyerSuggestedMessages"]];
            }
            else{
                [self.suggestedMessagesArray addObjectsFromArray:@[@"What are you selling?",@"What size?",@"Yeah I'm interested",@"What's your price?",@"Is the price negotiable?",@"What's your PayPal?",@"Got photos?", @"Not interested thanks", @"Dismiss"]];
            }
        }
        else{
            self.showSuggested = NO;

        }
    }
    else{
        //seller
        if (![[self.convoObject objectForKey:@"sellerShowSuggested"]isEqualToString:@"NO"]) {
            self.showSuggested = YES;
            
            if ([self.convoObject objectForKey:@"sellerSuggestedMessages"]) {
                [self.suggestedMessagesArray addObjectsFromArray:[self.convoObject objectForKey:@"sellerSuggestedMessages"]];
            }
            else{
                [self.suggestedMessagesArray addObjectsFromArray:@[@"Hey, I'm selling this", @"Send PayPal email", @"What's your offer?",@"Yes, it's negotiable", @"Sorry, been sold!", @"Dismiss"]];
            }

        }
        else{
            self.showSuggested = NO;

        }
    }

    
    if (self.suggestedMessagesArray.count == 1) {
        //if only have 'Dismiss' in the messages array then don't show
        self.showSuggested = NO;
    }
    
    //hide by default
    self.showLoadEarlierMessagesHeader = NO;
    self.automaticallyScrollsToMostRecentMessage = YES;
    
    self.skipped = 0;
    self.fromForeGround = NO;
    self.offerMode = NO;
    self.earlierPressed = NO;
    
    [self loadConvoImages];
    [self loadMessages];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:@"NewMessage" object:nil];
    
    self.bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularTaillessImage] capInsets:UIEdgeInsetsZero];
    
    JSQMessagesBubbleImageFactory *bubbleFactoryOutline = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularStrokedTaillessImage] capInsets:UIEdgeInsetsZero];
    
    self.outgoingBubbleImageData = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1]];
    
    self.incomingBubbleImageData = [bubbleFactoryOutline incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1]];
    
    self.waitingBubbleImageData = [bubbleFactoryOutline incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
    
    self.purchasedBubbleImageData = [bubbleFactoryOutline incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1]];
    
    self.offerBubbleImageData = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.31 green:0.89 blue:0.76 alpha:1.0]];
    
    self.sharedListingBubbleImageData = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]];
    
     self.masker = [[JSQMessagesMediaViewBubbleImageMasker alloc]initWithBubbleImageFactory:self.bubbleFactory];
    
    //to update status to seen of last sent when new messages come through
    self.receivedNew = NO;
    
    //setup suggested message bubbles
    
    if (self.showSuggested == YES) {
        
        self.carousel = [[SwipeView alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(50+self.tabBarHeightInt + self.inputToolbar.contentView.frame.size.height), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
        
        self.lastInputToolbarHeight = self.inputToolbar.contentView.frame.size.height;
        
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
        
        self.changeKeyboard = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(comeBackToForeground)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:[UIApplication sharedApplication]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(goneToBackground)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:[UIApplication sharedApplication]];
    }
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Convo",
                                      }];
    
    self.topEdge = (self.collectionView.contentOffset.y + self.collectionView.frame.size.height)-100;
    NSLog(@"TOP EDGE %f", self.topEdge);

}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    if (self.showSuggested == YES) {
        return UIEdgeInsetsMake(0, 0, 50, 0); // top, left, bottom, rightw
    }
    else{
        return self.collectionView.layoutMargins;
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
                
                if (self.fromForeGround == YES || self.checkoutTapped == YES) {
                    //clear so index path can be found of last item and updated 'seen' label displayed
                    [self.sentMessagesParseArray removeAllObjects];
                    [self.messagesParseArray removeAllObjects];
                }
                
                for (PFObject *messageOb in objects) {
                    
                    //dont show status messages where senderId == @"no show"
                    //show all other status messages where senderId is equal to something else
                    
                    // is status message set as seen so badge number decrements and then continue to add other messages to arrays
                    
                    if ([[messageOb objectForKey:@"isStatusMsg"]isEqualToString:@"YES"]){
                        [messageOb setObject:@"seen" forKey:@"status"];
                        [messageOb saveInBackground];
                        
                        if (self.userIsBuyer == YES) {
                            [self.convoObject setObject:@0 forKey:@"buyerUnseen"];
                        }
                        else{
                            [self.convoObject setObject:@0 forKey:@"sellerUnseen"];
                        }
                        
                        if ([[messageOb objectForKey:@"senderId"]isEqualToString:@"noshow"]){
                            //don't show
                            continue;
                        }
                        else{
                            //do show - will be from what ever senderId status message is sent with
                        }
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
                        photoItem.image = [UIImage imageNamed:@"empty"];
                        
                        if ([[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                            photoItem.appliesMediaViewMaskAsOutgoing = YES;
                        }
                        else{
                            photoItem.appliesMediaViewMaskAsOutgoing = NO;
                        }
                        
                        message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt media:photoItem];
                        message.msgObject = messageOb;
                        
                        //allow user to tap image and goto listing
                        if ([[messageOb objectForKey:@"sharedMessage"]isEqualToString:@"YES"]){
                            
                            if ([messageOb objectForKey:@"Sale"]) {
                                //shared a for sale listing
                                message.sharedListing = [messageOb objectForKey:@"sharedSaleListing"];
                                message.saleShare = YES;
                            }
                            else{
                                //shared a WTB
                                message.sharedListing = [messageOb objectForKey:@"sharedListing"];
                                message.saleShare = NO;
                            }
                            message.isShared = YES;
                        }
                        
                        [self.messages insertObject:message atIndex:0];
                        
                        //added so placeholder view is correct
                        
                        if ([[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                            photoItem.appliesMediaViewMaskAsOutgoing = YES;
                        }
                        else{
                            photoItem.appliesMediaViewMaskAsOutgoing = NO;
                        }
                        
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
                        //normal text message
                        
                        NSString *messageText = [messageOb objectForKey:@"message"];
                        
                        if (![[messageOb objectForKey:@"senderId"] isEqualToString:[PFUser currentUser].objectId] && [[messageOb objectForKey:@"offer"]isEqualToString:@"YES"]) {
                            
                            //other user sent an offer
                            
                            PFObject *offerOb = [messageOb objectForKey:@"offerObject"];
                            if ([[offerOb objectForKey:@"status"]isEqualToString:@"open"]) {
                                messageText = [NSString stringWithFormat:@"%@\nTap to buy now",[messageOb objectForKey:@"message"]];
                            }
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"purchased"]) {
                                messageText = [NSString stringWithFormat:@"%@\nPurchased",[messageOb objectForKey:@"message"]];
                            }
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"waiting"]) {
                                messageText = [NSString stringWithFormat:@"%@\nWaiting for seller to confirm payment",[messageOb objectForKey:@"message"]];
                            }
                        }
                        else if([[messageOb objectForKey:@"senderId"] isEqualToString:[PFUser currentUser].objectId] && [[messageOb objectForKey:@"offer"]isEqualToString:@"YES"]){
                            
                            // current user sent an offer
                            
                            PFObject *offerOb = [messageOb objectForKey:@"offerObject"];
                            if ([[offerOb objectForKey:@"status"]isEqualToString:@"waiting"]) {
                                messageText = [NSString stringWithFormat:@"%@\nWaiting for seller to confirm payment",[messageOb objectForKey:@"message"]];
                            }
                            else if ([[offerOb objectForKey:@"status"]isEqualToString:@"purchased"]) {
                                messageText = [NSString stringWithFormat:@"%@\nSold",[messageOb objectForKey:@"message"]];
                            }
                        }
                        else if (![[messageOb objectForKey:@"senderId"] isEqualToString:[PFUser currentUser].objectId] && [[messageOb objectForKey:@"paypalMessage"]isEqualToString:@"YES"]){
                            
                            //other user sent a paypal message, add call to action
                            messageText = [NSString stringWithFormat:@"%@\nTap to Pay now",[messageOb objectForKey:@"message"]];
                        }
                        
                        message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt text:messageText];
                        
                        if ([[messageOb objectForKey:@"offer"]isEqualToString:@"YES"]) {
                            
                            //add the offer object to the message
                            
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
                        else if ([[messageOb objectForKey:@"sharedMessage"]isEqualToString:@"YES"]){
                            
                            //add the listing info to the shared message
                            
                            if ([messageOb objectForKey:@"Sale"]) {
                                //shared a for sale listing
                                message.sharedListing = [messageOb objectForKey:@"sharedSaleListing"];
                                message.saleShare = YES;
                            }
                            else{
                                //shared a WTB
                                message.sharedListing = [messageOb objectForKey:@"sharedListing"];
                                message.saleShare = NO;
                            }
                            message.isShared = YES;
                            message.isOfferMessage = NO;
                            message.isWaiting = NO;
                            message.isPurchased = NO;
                        }
                        
                        else if ([[messageOb objectForKey:@"paypalMessage"]isEqualToString:@"YES"]){
                            
                            //it's a paypal message
                            message.isShared = NO;
                            message.isOfferMessage = NO;
                            message.isWaiting = NO;
                            message.isPurchased = NO;
                            
                            message.isPayPal = YES;
                        }
                        
                        if (![self.messages containsObject:message]) {
                            [self.messages insertObject:message atIndex:0];
                        }
                    }
                }
                [self.convoObject saveInBackground];
                
                if (self.checkoutTapped == YES) {
                    NSLog(@"loading from foreground");
                    //call attributedString method to update labels
                    NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
                    NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
                    NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];
                    
                    NSLog(@"path to last item %ld", (long)lastItemIndex);
                    
                    [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
                    [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
                    self.fromForeGround = NO;
                    self.checkoutTapped = NO;
                }
                
                [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
                [self.collectionView reloadData];
                
                if (self.earlierPressed == NO) {
//                    [self scrollToBottomAnimated:NO];
                    
                    //fix the last message being hidden
                    [self.view layoutIfNeeded];
                    [self.collectionView.collectionViewLayout invalidateLayout];
                    
                    if (self.automaticallyScrollsToMostRecentMessage) {
                        NSLog(@"lets go");
                        self.firstLayout = YES;
                        [self viewDidLayoutSubviews];
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            self.firstLayout = NO;
//                        });
                    }
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
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    //to prevent double tapping profile button
    self.profileBTapped = NO;
    
    if (self.checkPayPalTapped == YES) {
        self.checkPayPalTapped = NO;
    }
    else{
        
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
    
    //decide whether to show review banner
    int messageTotal = [[self.convoObject objectForKey:@"totalMessages"]intValue];
    if (messageTotal > 10) {
        if (self.userIsBuyer == YES) {
            if (![self.convoObject objectForKey:@"buyerHasReviewed"]) {
                //show rate banner
                [self showSuccessBannerWithText:[NSString stringWithFormat:@"R E V I E W"]];
            }
        }
        else{
            if (![self.convoObject objectForKey:@"sellerHasReviewed"]) {
                //show rate banner
                [self showSuccessBannerWithText:[NSString stringWithFormat:@"R E V I E W"]];
            }
        }
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    NSLog(@"did layout");

    //fixes bug which hides last message in convo
    //if we scroll here instead of after loadMessages then it works
    if (self.firstLayout && self.automaticallyScrollsToMostRecentMessage) {
        NSLog(@"scroll");
        self.firstLayout = NO;
        [self scrollToBottomAnimated:YES];
    }
}

- (void)handleNotification:(NSNotification*)note {
    NSMutableArray *unseenConvos = [note object];
    PFObject *currentConvo = self.convoObject;
    for (PFObject *convo in unseenConvos) {
        if ([convo.objectId isEqualToString:currentConvo.objectId]) {
            //stop listening until new msgs loaded
//            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NewMessage" object:nil];
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
                    
                    if ([[messageOb objectForKey:@"isStatusMsg"]isEqualToString:@"YES"]){
                        [messageOb setObject:@"seen" forKey:@"status"];
                        [messageOb saveInBackground];
                        
                        if (self.userIsBuyer == YES) {
                            [self.convoObject setObject:@0 forKey:@"buyerUnseen"];
                        }
                        else{
                            [self.convoObject setObject:@0 forKey:@"sellerUnseen"];
                        }
                        
                        if ([[messageOb objectForKey:@"senderId"]isEqualToString:@"noshow"]){
                            //don't show
                            continue;
                        }
                        else{
                            //do show - will be from what ever senderId status message is sent with
                        }
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
                        photoItem.image = [UIImage imageNamed:@"empty"];
                        
                        message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt media:photoItem];
                        
                        message.msgObject = messageOb;

                        
                        if (![self.messages containsObject:message]) {
                            [self.messages addObject:message];
                        }
                        
                        if ([[messageOb objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                            photoItem.appliesMediaViewMaskAsOutgoing = YES;
                        }
                        else{
                            photoItem.appliesMediaViewMaskAsOutgoing = NO;
                        }
                        
                        PFQuery *imageQuery = [PFQuery queryWithClassName:@"messageImages"];
                        [imageQuery whereKey:@"objectId" equalTo:[messageOb objectForKey:@"message"]];
                        [imageQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                            if (!error) {
                                [self.convoImagesArray addObject:object];

                                PFFile *img = [object objectForKey:@"Image"];
                                
                                [img getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                    if (!error) {
                                        
                                        UIImage *messageImage = [UIImage imageWithData:data];
                                        photoItem.image = messageImage;
                                        
                                        newMediaAttachmentCopy = [UIImage imageWithCGImage:photoItem.image.CGImage];
                                        newMediaData = photoItem;
                                        [message setValue:newMediaData forKey:@"media"];
                                        
                                        [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];

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
                        
                        if (![[messageOb objectForKey:@"senderId"] isEqualToString:[PFUser currentUser].objectId] && [[messageOb objectForKey:@"paypalMessage"]isEqualToString:@"YES"]){
                            
                            //other user sent a paypal message, append call to action
                            messageText = [NSString stringWithFormat:@"%@\nTap to Pay now",[messageOb objectForKey:@"message"]];
                        }
                        
                        message = [[JSQMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt text:messageText];
                       
                        if ([[messageOb objectForKey:@"sharedMessage"]isEqualToString:@"YES"]){
                            
                            //add the listing info to the shared message
                            
                            if ([messageOb objectForKey:@"Sale"]) {
                                //shared a for sale listing
                                message.sharedListing = [messageOb objectForKey:@"sharedSaleListing"];
                                message.saleShare = YES;
                            }
                            else{
                                //shared a WTB
                                message.sharedListing = [messageOb objectForKey:@"sharedListing"];
                                message.saleShare = NO;
                            }
                            message.isShared = YES;
                            message.isOfferMessage = NO;
                            message.isWaiting = NO;
                            message.isPurchased = NO;
                        }
                        
                        else if ([[messageOb objectForKey:@"paypalMessage"]isEqualToString:@"YES"]){
                            
                            //it's a paypal message
                            message.isShared = NO;
                            message.isOfferMessage = NO;
                            message.isWaiting = NO;
                            message.isPurchased = NO;
                            
                            message.isPayPal = YES;
                        }

                        
                        if (![self.messages containsObject:message]) {
                            [self.messages addObject:message];
                        }
                    }
                    self.lastMessage = messageOb;
                }
                
                //save new unseen counter number
                [self.convoObject saveInBackground];
                //received a message so scroll to top of inbox
                [self.delegate lastMessageInConvo:nil];
                
                self.receivedNew = YES;

                //call attributedString method to update labels
                NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
                NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
                NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];

                self.checkoutTapped = NO;
                
                [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
                [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
               
                [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
                [self.collectionView reloadData];
                
                //scroll to bottom
                [self scrollToBottomAnimated:YES];
//                [self.collectionView scrollToItemAtIndexPath: pathToLastItem
//                                            atScrollPosition: UICollectionViewScrollPositionBottom
//                                                    animated: YES];
                
                //minus number of new messages that have just been seen off tab bar badge
                NSString *badgeString =[[self.tabBarController.tabBar.items objectAtIndex:2] badgeValue];
                int badgeInt = [badgeString intValue];
                int newCount = (int)[objects count];
                int updatedBadge = badgeInt - newCount;
                
                PFInstallation *current = [PFInstallation currentInstallation];
                
                if (updatedBadge == 0) {
                    [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:nil];
                    current.badge = 0;
                }
                //only set updated badge if its a +ve no.
                else if (updatedBadge > 0){
                    [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:[NSString stringWithFormat:@"%d", updatedBadge]];
                    current.badge = updatedBadge;
                }
                [current saveEventually];
                
                //reregister for notifications again
//                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:@"NewMessage" object:nil];
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
    
    //add keyboard observers for suggested message bubbles
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [center addObserver:self selector:@selector(keyboardOnScreen:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardOFFScreen:) name:UIKeyboardWillHideNotification object:nil];
    
    //the drag gesture to dismiss keyboard is handled all by JSQMVC
    //so would need to look there more for a solution to momentatry stranded carousel
    
    if (self.messageSellerPressed == YES) {
        self.messageSellerPressed = NO;

        self.inputToolbar.contentView.textView.text = [NSString stringWithFormat:@"Is your '%@' still available?", self.sellerItemTitle];
        
        NSLog(@"INPUT HEIGHT %f",self.inputToolbar.contentView.frame.size.height);
        
        //move carousel up after entering text
        if (self.inputToolbar.contentView.frame.size.height > self.lastInputToolbarHeight && self.movingCarousel != YES) {
            self.movingCarousel = YES;
            float diff = self.inputToolbar.contentView.frame.size.height - self.lastInputToolbarHeight;
            
            [UIView animateWithDuration:0.5
                                  delay:0.0
                 usingSpringWithDamping:0.7
                  initialSpringVelocity:0.5
                                options:UIViewAnimationOptionCurveEaseIn animations:^{
                                    
                                    //animate carousel up
                                    [self.carousel setFrame:CGRectMake(0,(self.carousel.frame.origin.y-diff), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                                    
                                }
                             completion:^(BOOL finished) {
                                 self.lastInputToolbarHeight = self.inputToolbar.contentView.frame.size.height;
                                 self.movingCarousel = NO;
                             }];
        }
        
        self.savedString = self.inputToolbar.contentView.textView.text;
        [self.inputToolbar.contentView.rightBarButtonItem setHidden:NO];
        [self.inputToolbar toggleSendButtonEnabled];
    }
    
    if (![self.savedString isEqualToString:@""] && self.savedSomin == YES) {
        self.inputToolbar.contentView.textView.text = self.savedString;
        self.savedSomin = NO;
        self.savedString = @"";
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

    //clear observers
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
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

-(void)showUserAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showPayPalAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Enter PayPal Email" message:[NSString stringWithFormat:@"Save your PayPal email on Bump so you can send it to buyers faster! Don't worry, Bump doesn't handle any passwords! Is '%@' correct?", [[PFUser currentUser] objectForKey:@"paypal"]] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Change" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        SettingsController *vc = [[SettingsController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    [alertView addAction:[UIAlertAction actionWithTitle:@"Yes, it's correct" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        //save as updated
        [[PFUser currentUser] setObject:@"YES" forKey:@"paypalUpdated"];
        [[PFUser currentUser]saveInBackground];
        
        //send paypal messages
        NSString *messageString = [NSString stringWithFormat:@"%@ sent their PayPal email %@",[PFUser currentUser].username ,[[PFUser currentUser] objectForKey:@"paypal"]];
        self.paypalMessage = YES;
        UIButton *button = [[UIButton alloc]init];
        [self didPressSendButton:button withMessageText:messageString senderId:self.senderId senderDisplayName:self.senderDisplayName date:[NSDate date]];
        
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
    if (self.promptedBefore != YES && self.paypalMessage != YES) {
        NSArray *checkingforemailarray = [text componentsSeparatedByString:@" "];
        for (NSString *stringer in checkingforemailarray) {
            NSString *string = [stringer stringByReplacingOccurrencesOfString:@"?" withString:@""];
            //check for user trying to direct other user elsewhere & remind them to send an offer
            
            //email check
            if ([self NSStringIsValidEmail:string]) {
                [Answers logCustomEventWithName:@"Deal on Bump warning"
                               customAttributes:@{
                                                  @"trigger":@"email",
                                                  @"message":text,
                                                  @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
                                                  }];
                //present 'Send Offer' reminder alert
                self.promptedBefore = YES;
                self.offerReminderMode = YES;
                [self showCustomAlert];
                return;
            }
            
            //facebook check
            if ([[string lowercaseString] isEqualToString:@"facebook"]) {
                [Answers logCustomEventWithName:@"Deal on Bump warning"
                               customAttributes:@{
                                                  @"trigger":@"facebook",
                                                  @"message":text,
                                                  @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
                                                  }];
                //present 'Send Offer' reminder alert
                self.promptedBefore = YES;
                self.offerReminderMode = YES;
                [self showCustomAlert];
                return;
            }
            
            //check for number
            NSError *error = NULL;
            NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
            NSArray *matches = [detector matchesInString:string options:0 range:NSMakeRange(0, [string length])];
            if (matches != nil) {
                for (NSTextCheckingResult *match in matches) {
                    if ([match resultType] == NSTextCheckingTypePhoneNumber) {
                        [Answers logCustomEventWithName:@"Deal on Bump warning"
                                       customAttributes:@{
                                                          @"trigger":@"phone number",
                                                          @"message":text,
                                                          @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
                                                          }];
                         //present 'Send Offer' reminder alert
                         self.promptedBefore = YES;
                         self.offerReminderMode = YES;
                         [self showCustomAlert];
                        return;
                    }
                }
            }
            
            //depop
            if ([[string lowercaseString] isEqualToString:@"depop"]) {
                [Answers logCustomEventWithName:@"Deal on Bump warning"
                               customAttributes:@{
                                                  @"trigger":@"depop",
                                                  @"message":text,
                                                  @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
                                                  }];
                //present 'Send Offer' reminder alert
                self.promptedBefore = YES;
                self.offerReminderMode = YES;
                [self showCustomAlert];
                return;
            }
            
            //instagram
            if ([[string lowercaseString] isEqualToString:@"instagram"]) {
                [Answers logCustomEventWithName:@"Deal on Bump warning"
                               customAttributes:@{
                                                  @"trigger":@"instagram",
                                                  @"message":text,
                                                  @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
                                                  }];
                //present 'Send Offer' reminder alert
                self.promptedBefore = YES;
                self.offerReminderMode = YES;
                [self showCustomAlert];
                return;
            }
            
            //big cartel
            if ([[string lowercaseString] containsString:@".bigcartel"]) {
                [Answers logCustomEventWithName:@"Deal on Bump warning"
                               customAttributes:@{
                                                  @"trigger":@"bigcartel",
                                                  @"message":text,
                                                  @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
                                                  }];
                //present 'Send Offer' reminder alert
                self.promptedBefore = YES;
                self.offerReminderMode = YES;
                [self showCustomAlert];
                return;
            }
        }
        if ([text containsString:@"your number"]) {
            [Answers logCustomEventWithName:@"Deal on Bump warning"
                           customAttributes:@{
                                              @"trigger":@"phone number",
                                              @"message":text,
                                              @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
                                              }];
            //present 'Send Offer' reminder alert
            self.promptedBefore = YES;
            self.offerReminderMode = YES;
            [self showCustomAlert];
            return;
        }
    }
    
    NSString *messageString = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.sentPush = NO;
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:messageString];
    if (![self.messages containsObject:message]) {
        [self.messages addObject:message];
    }
    
    PFObject *messageObject = [PFObject objectWithClassName:@"messages"];
    messageObject[@"message"] = messageString;
    messageObject[@"sender"] = [PFUser currentUser];
    messageObject[@"senderId"] = [PFUser currentUser].objectId;
    messageObject[@"senderName"] = [PFUser currentUser].username;
    messageObject[@"convoId"] = self.convoId;
    messageObject[@"status"] = @"sent";
    messageObject[@"offer"] = @"NO";
    message.isOfferMessage = NO;
    
    if (self.paypalMessage == YES) {
        messageObject[@"paypalMessage"] = @"YES";
        message.isPayPal = YES;
        self.paypalMessage = NO;
    }
    
    messageObject[@"mediaMessage"] = @"NO";
    [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded == YES) {
            
            NSLog(@"saved msg");
            
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
                    NSLog(@"done saving convo");
                    //sent a message so force reload in inbox VC
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:nil];
                    [self.delegate lastMessageInConvo:nil];
                }
                else{
                    NSLog(@"error with conv %@", error);
                }
            }];
            
            
            NSString *pushText;
            
            if (self.paypalPush == YES) {
                pushText = [NSString stringWithFormat:@"%@ sent their PayPal. Pay now 🛒", [[PFUser currentUser]username]];
                self.paypalPush = NO;
            }
            else{
                pushText = [NSString stringWithFormat:@"%@: %@", [[PFUser currentUser]username], messageString];
            }
            
            self.lastMessage = messageObject;
            
            if (self.sentPush == NO) {
                self.sentPush = YES;
                //send push to other user
                NSDictionary *params = @{@"userId": self.otherUser.objectId, @"message": pushText, @"sender": [PFUser currentUser].username};
                [PFCloud callFunctionInBackground:@"sendPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                    if (!error) {
                        NSLog(@"push response %@", response);
                        [Answers logCustomEventWithName:@"Push Sent"
                                       customAttributes:@{
                                                          @"Type":@"Message"
                                                          }];
                    }
                    else{
                        NSLog(@"push error %@", error);
                    }
                }];
            }
        }
        else{
            self.paypalPush = NO;
            self.paypalMessage = NO;
            
            NSLog(@"error sending message %@", error);
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Error sending message" message:@"Make sure you're connected to the internet" preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }];
    
    [self finishSendingMessageAnimated:YES];
    
    //move carousel back down if its been moved up due to user typing lots
    if (self.inputToolbar.contentView.frame.size.height < self.lastInputToolbarHeight && self.movingCarousel != YES){
        self.movingCarousel = YES;
        
        float diff = self.lastInputToolbarHeight - self.inputToolbar.contentView.frame.size.height;
        
        NSLog(@"HEIGHT DIFF %f", diff);
        
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseIn animations:^{
                                
                                //animate carousel up
                                
                                [self.carousel setFrame:CGRectMake(0,(self.carousel.frame.origin.y+diff), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                                
                            }
                         completion:^(BOOL finished) {
                             self.lastInputToolbarHeight = self.inputToolbar.contentView.frame.size.height;
                             self.movingCarousel = NO;
                         }];
    }
    
    [self.inputToolbar.contentView.rightBarButtonItem setHidden:YES];
    
    // add new message object to relevant arrays
    if (![self.sentMessagesParseArray containsObject:messageObject]) {
        [self.sentMessagesParseArray insertObject:messageObject atIndex:0];
    }
    
    if (![self.messagesParseArray containsObject:messageObject]) {
        [self.messagesParseArray insertObject:messageObject atIndex:0];
    }
    
    //call attributedString method to update labels
    NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
    NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
    NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];
    
    [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
    [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
    
    [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
    [self.collectionView reloadItemsAtIndexPaths:@[pathToLastItem]];
    
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
        
        //user has typed loads of text, shift carousel up!
        if (self.inputToolbar.contentView.frame.size.height > self.lastInputToolbarHeight && self.movingCarousel != YES) {
            self.movingCarousel = YES;
            float diff = self.inputToolbar.contentView.frame.size.height - self.lastInputToolbarHeight;
            
            [UIView animateWithDuration:0.5
                                  delay:0.0
                 usingSpringWithDamping:0.7
                  initialSpringVelocity:0.5
                                options:UIViewAnimationOptionCurveEaseIn animations:^{
                                    
                                    //animate carousel up
                                    [self.carousel setFrame:CGRectMake(0,(self.carousel.frame.origin.y-diff), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                                    
                                }
                             completion:^(BOOL finished) {
                                 self.lastInputToolbarHeight = self.inputToolbar.contentView.frame.size.height;
                                 self.movingCarousel = NO;
                             }];
        }
        
        //user has deleted loads of text, shift carousel back down!
        else if (self.inputToolbar.contentView.frame.size.height < self.lastInputToolbarHeight && self.movingCarousel != YES){
            self.movingCarousel = YES;
            float diff = self.lastInputToolbarHeight - self.inputToolbar.contentView.frame.size.height;
            
            [UIView animateWithDuration:0.5
                                  delay:0.0
                 usingSpringWithDamping:0.7
                  initialSpringVelocity:0.5
                                options:UIViewAnimationOptionCurveEaseIn animations:^{
                                    
                                    //animate carousel up
                                    [self.carousel setFrame:CGRectMake(0,(self.carousel.frame.origin.y+diff), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                                    
                                }
                             completion:^(BOOL finished) {
                                 self.lastInputToolbarHeight = self.inputToolbar.contentView.frame.size.height;
                                 self.movingCarousel = NO;
                             }];
        }
    }
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    //if user's only option is to send photos then just send photos
     if (self.userIsBuyer == YES && self.profileConvo == NO) {
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
                         [self showCustomAlert];
                     });
                     NSLog(@"denied");
                 }
                     break;
                 default:
                     break;
             }
         }];
     }
     else{
         [self alertSheet];
     }
}

-(void)alertSheet{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    PFObject *order = [self.convoObject objectForKey:@"order"];
    
    //if convo created from a profile then let both users see max. alertsheet options
    if (self.userIsBuyer == NO || self.profileConvo == YES) {
        
//        if (order == nil) {
//            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Send an offer" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//                [Answers logCustomEventWithName:@"Send an offer tapped"
//                               customAttributes:@{}];
//                
//                MakeOfferController *vc = [[MakeOfferController alloc]init];
//                vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
//                vc.currencySymbol = self.currencySymbol;
//                vc.delegate = self;
//                [self.navigationController presentViewController:vc animated:YES completion:nil];
//            }]];
//        }
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Take a picture tapped"
                           customAttributes:@{
                                              @"where":@"MessageVC"
                                              }];
            
            CameraController *vc = [[CameraController alloc]init];
            vc.delegate = self;
            vc.offerMode = YES;
            [self presentViewController:vc animated:YES completion:nil];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose pictures" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Choose pictures tapped"
                           customAttributes:@{
                                              @"where":@"MessageVC"
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
                            [self showCustomAlert];
                        });
                        NSLog(@"denied");
                    }
                        break;
                    default:
                        break;
                }
            }];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Goto my PayPal" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self showMyPaypal];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Send Pics from my Depop" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            BOOL seen = [[NSUserDefaults standardUserDefaults] boolForKey:@"seenDepop"];
            if (!seen) {
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Send Pics from your Depop" message:@"When you have the images of the items you'd like to send in the middle of your screen, hit 'Screenshot'!" preferredStyle:UIAlertControllerStyleAlert];
                [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self showDepop];
                }]];
                [self presentViewController:alertView animated:YES completion:nil];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenDepop"];
            }
            else{
                [self showDepop];
            }
        }]];
    }
    else{
        if (order != nil) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Pay with PayPal" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                //used as a backup way to pay if buyer has clicked paid but didn't actually pay.
                //order object already created so just need to an easy way to pay
            }]];
        }
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose pictures" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
                            [self showCustomAlert];
                        });
                        NSLog(@"denied");
                    }
                        break;
                    default:
                        break;
                }
            }];
        }]];
    }
    
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
                                
                                if (image.CGImage == nil) {
                                    [Answers logCustomEventWithName:@"Image Error: CGImage is nil from Asset"
                                                   customAttributes:@{
                                                                      @"pageName":@"MessageVC"
                                                                      }];
                                }
                                
                                [self finalImage:image];
                                
                                
                            }];
        }
    }];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)showDepop{
    if ([[PFUser currentUser]objectForKey:@"depopHandle"]) {
        //has added their depop handle
        NSString *handle = [[PFUser currentUser]objectForKey:@"depopHandle"];
        NSString *URLString = [NSString stringWithFormat:@"http://depop.com/%@",handle];
        self.webViewController = nil;
        self.webViewController = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
        self.webViewController.title = [NSString stringWithFormat:@"%@", handle];
        self.webViewController.showUrlWhileLoading = NO;
        self.webViewController.showPageTitles = NO;
        self.webViewController.delegate = self;
        self.webViewController.depopMode = YES;
        self.webViewController.doneButtonTitle = @"";
        self.webViewController.paypalMode = NO;
        self.webViewController.infoMode = NO;
        NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webViewController];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
    else{
        //hasn't added handle, prompt to do so
        [self showAlertWithTitle:@"No Depop Username added" andMsg:@"Add your Depop Username in Settings on Bump and you'll be able to add images of items you've already listed on there without leaving your conversation #zerofees"];
    }
}

-(void)paidPressed{
    //do nothing
    [Answers logCustomEventWithName:@"Paid PayPal Pressed"
                   customAttributes:@{}];
    [self.webViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)cancelWebPressed{
    [Answers logCustomEventWithName:@"Cancel PayPal Pressed"
                   customAttributes:@{}];
    [self.webViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)cameraPressed{
    //do nothing
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
    [self.webViewController dismissViewControllerAnimated:YES completion:^{
        [self displayCropperWithImage:screenshot];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<NSString *,id> *)info{
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    //display crop picker
    [picker dismissViewControllerAnimated:YES completion:^{
        [self displayCropperWithImage:chosenImage];
    }];
}

-(void)displayCropperWithImage:(UIImage *)image{
    BASSquareCropperViewController *squareCropperViewController = [[BASSquareCropperViewController alloc] initWithImage:image minimumCroppedImageSideLength:375.0f];
    squareCropperViewController.squareCropperDelegate = self;
    squareCropperViewController.backgroundColor = [UIColor whiteColor];
    squareCropperViewController.borderColor = [UIColor whiteColor];
    squareCropperViewController.doneFont = [UIFont fontWithName:@"PingFangSC-Regular" size:18.0f];
    squareCropperViewController.cancelFont = [UIFont fontWithName:@"PingFangSC-Regular" size:16.0f];
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

-(void)showMyPaypal{
    NSString *URLString = @"https://www.paypal.com/myaccount/";
    self.webViewController = nil;
    self.webViewController = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.webViewController.title = @"My PayPal";
    self.webViewController.showUrlWhileLoading = YES;
    self.webViewController.showPageTitles = NO;
    self.webViewController.doneButtonTitle = @"";
    self.webViewController.paypalMode = NO;
    self.webViewController.infoMode = NO;
    self.checkPayPalTapped = YES;
    self.webViewController.delegate = self;
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)payOnPayPal{
    NSString *URLString = @"https://www.paypal.com/myaccount/transfer/buy";

    self.webViewController = nil;
    self.webViewController = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.webViewController.title = @"P A Y";
    self.webViewController.showUrlWhileLoading = YES;
    self.webViewController.showPageTitles = NO;
    self.webViewController.delegate = self;
    self.webViewController.payMode = YES;
    self.webViewController.doneButtonTitle = @"Paid";
    self.webViewController.paypalMode = YES;
    self.webViewController.infoMode = YES;
    
    if ([self.otherUser objectForKey:@"paypal"]) {
        self.webViewController.emailToPay = [self.otherUser objectForKey:@"paypal"];
        self.webViewController.amountToPay = @"";
    }
    else{
        self.webViewController.infoMode = NO;
    }
    
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)finalImage:(UIImage *)image{
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    //some users still aren't able to send certain images
    //think its related to this SO answer:
    
    //UIImageJPEGRepresentation seems to use the CGImage property of the UIImage. Problem is, that when you initialize the UIImage with a CIImage, that property is nil.
    
    //in meantime, used another solution - creates a copy of the image (assumes the image is not nil before resizing) and then gets data from that
//    
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImage *copiedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImage *newImage = [copiedImage scaleImageToSizeFIT:CGSizeMake(750, 750)];
    
    if (newImage.CGImage == nil) {
        [Answers logCustomEventWithName:@"Image Error: CGImage is nil after scaling"
                       customAttributes:@{
                                          @"pageName":@"MessageVC"
                                          }];
//        CIImage *CIImageItem = newImage.CIImage;
//        CGImageRef imageRef = [[CIContext contextWithOptions:nil] createCGImage:CIImageItem fromRect:CIImageItem.extent];
//        
//        newImage = [image initWithCGImage:imageRef];
    }
    
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
                                          @"pageName":@"MessageVC"
                                          }];
        [self showAlertWithTitle:@"Image Error" andMsg:@"Something went wrong getting your image, please try again!"];
        return;
    }
    
    PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:data];
    
    PFObject *picObject = [PFObject objectWithClassName:@"messageImages"];
    [picObject setObject:filePicture forKey:@"Image"];
    [picObject setObject:self.convoObject forKey:@"convo"];
    [self.convoImagesArray addObject:picObject];

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
            
            [self.convoObject setObject:self.messageObject forKey:@"lastSent"];
            
            NSString *pushString = [NSString stringWithFormat:@"%@ sent a picture 💥",[[PFUser currentUser]username]];
            
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
            
            self.offerMode = NO;
            [self.convoObject incrementKey:@"totalMessages"];
            if (self.userIsBuyer == YES) {
                [self.convoObject incrementKey:@"sellerUnseen"];
            }
            else{
                [self.convoObject incrementKey:@"buyerUnseen"];
            }
            
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
            
            [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
            [self.collectionView reloadItemsAtIndexPaths:@[pathToLastItem]];
        }
        else{
            NSLog(@"error saving pic msg %@", error);
            
            [self.convoImagesArray removeObject:picObject];

            [Answers logCustomEventWithName:@"Error Saving Pic File"
                           customAttributes:@{
                                              @"where":@"MessagesVC"
                                              }];
            
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Error sending image" message:@"Make sure you're connected to the internet" preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }];
}

-(void)dismissPressed:(BOOL)yesorno{
    //do nothing
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
    else if(message.isShared == YES || message.isPayPal == YES){
        return self.sharedListingBubbleImageData;
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
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    
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
    
    
//    if (indexPath.item % 3 == 0) {
//        JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
//        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
//    }
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
                
                NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:10],
                                                NSFontAttributeName,[UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
                
                NSString *statusString = [[[self.sentMessagesParseArray objectAtIndex:0]objectForKey:@"status"]capitalizedString];
                
                if (self.receivedNew == YES) {
                    NSAttributedString *newString = [[NSAttributedString alloc]initWithString:@"Seen" attributes:textAttributes];
                    self.receivedNew = NO;
                    return newString;
                }
                else if ([statusString isEqualToString:@"Sent"]||[statusString isEqualToString:@"Seen"]) {
                    //valid status, go ahead
                    NSAttributedString *string = [[NSAttributedString alloc]initWithString:statusString attributes:textAttributes];
                    return string;
                }
                else{
                    //invalid status, return sent as default
                    NSAttributedString *invalString = [[NSAttributedString alloc]initWithString:@"Sent" attributes:textAttributes];
                    return invalString;
                }
            }
            else{
                //index path is not last
//                NSLog(@"index path is not last");
            }
        }
        else{
            //user hasn't send a message
//            NSLog(@"user hasn't send a message");
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
    
    JSQMessage *msg = [self.messages objectAtIndex:indexPath.item];
    
//    CustomMessagesCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.incomingCellIdentifier forIndexPath:indexPath];
    
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
    
    
    if (!msg.isMediaMessage) {
        
        cell.textView.textColor = [UIColor blackColor];
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    if (msg.isOfferMessage || msg.isShared || msg.isPayPal) {
        cell.textView.textColor = [UIColor whiteColor];
        cell.textView.dataDetectorTypes = UIDataDetectorTypeNone;
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
//    JSQMessage *currentMessage = [self.messages objectAtIndex:indexPath.item];
//    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
//        return 0.0f;
//    }
//    
//    if (indexPath.item - 1 > 0) {
//        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
//        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
//            return 0.0f;
//        }
//    }
//    
//    return kJSQMessagesCollectionViewCellLabelHeightDefault;
    
    return 0.0f;
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
                return kJSQMessagesCollectionViewCellLabelHeightDefault+10;
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
    
    if ([[self.messages objectAtIndex:indexPath.item] isMediaMessage] == YES && tappedMessage.isShared == NO){
        
        [Answers logCustomEventWithName:@"Tapped Image in Convo"
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
    else if (tappedMessage.isPurchased == YES){
    }
    else if(tappedMessage.isShared == YES){
        if (tappedMessage.saleShare == YES) {
            
            [Answers logCustomEventWithName:@"Tapped Shared Listing"
                           customAttributes:@{
                                              @"mode":@"SALE"
                                              }];
            
            //if version lower than 1158 then don't execute
            NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            int buildNumber = [appVersion intValue];
            if (buildNumber < 1158) {
                //prompt to update
                [self showAlertWithTitle:@"Update" andMsg:@"Update your app version to view this for-sale item shared with you!"];
            }
            else{
                ForSaleListing *vc = [[ForSaleListing alloc]init];
                vc.listingObject = tappedMessage.sharedListing;
                vc.source = @"share";
                vc.pureWTS = YES;
                vc.fromBuyNow = YES;
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
        else{
            [Answers logCustomEventWithName:@"Tapped Shared Listing"
                           customAttributes:@{
                                              @"mode":@"WTB"
                                              }];
            
            ListingController *vc = [[ListingController alloc]init];
            vc.listingObject = tappedMessage.sharedListing;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else if (tappedMessage.isPayPal == YES && [tappedMessage.senderId isEqualToString:self.otherUser.objectId]){
        
        [Answers logCustomEventWithName:@"Tapped PayPal Pay Now Msg"
                       customAttributes:@{}];
        
        //only let other user pay by tapping cell and if they have recent version
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        int buildNumber = [appVersion intValue];
        if (buildNumber < 1159) {
            //prompt to update
            [self showAlertWithTitle:@"Update" andMsg:@"Update your app version to pay faster on Bump!"];
        }
        else{
            //copy email to clipboard
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            [pb setString:[self.otherUser objectForKey:@"paypal"]];
            
            [self payOnPayPal];
        }
    }
    else{
        //do nothing
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
    if (self.pureWTS == YES) {
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = self.listing;
        vc.source = @"buy now";
        vc.pureWTS = YES;
        vc.fromBuyNow = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = [self.convoObject objectForKey:@"wtbListing"];
        [self.navigationController pushViewController:vc animated:YES];
    }
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
//            [self.paidButton addTarget:self action:@selector(markTapped) forControlEvents:UIControlEventTouchUpInside];
            self.paidButton.backgroundColor = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
            [self.paidButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            self.paidButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
            [self.paidView addSubview:self.paidButton];
            [self.paidButton setCenter:CGPointMake(self.paidView.frame.size.width / 2, self.paidView.frame.size.height / 2)];
        }
        [self.view addSubview:self.paidView];
        self.payBannerShowing = YES;
    }
}

-(void)showSuccessBannerWithText:(NSString *)text{
    if (self.successBannerShowing == YES) {

    }
    else{
        if (!self.successView) {
            self.successView = [[UIView alloc]initWithFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20, self.navigationController.navigationBar.frame.size.width, 30)];
            self.successButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0, self.successView.frame.size.width, self.successView.frame.size.height)];
            [self.successButton setTitle:text forState:UIControlStateNormal];
            self.successButton.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.8];
            [self.successButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            self.successButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
            [self.successButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self.successView addSubview:self.successButton];
            [self.successButton setCenter:CGPointMake(self.successView.frame.size.width / 2, self.successView.frame.size.height / 2)];
            [self.successButton addTarget:self action:@selector(gotoReview) forControlEvents:UIControlEventTouchUpInside];

            UIButton *dismissButton = [[UIButton alloc]initWithFrame:CGRectMake(self.successView.frame.size.width-40,(self.successView.frame.size.height/2)-10, 20, 20)];
            [dismissButton setImage:[UIImage imageNamed:@"bannerCross"] forState:UIControlStateNormal];
            [dismissButton addTarget:self action:@selector(dismissSuccessBanner) forControlEvents:UIControlEventTouchUpInside];
            [self.successButton addSubview:dismissButton];
        }
        [self.view addSubview:self.successView];
        [self.successView setAlpha:0.8];

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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"dismissedBanner"] == YES){
        return;
    }
    
    if (self.infoBannerShowing == YES) {

    }
    else{
        if (!self.infoView) {
            self.infoView = [[UIView alloc]initWithFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20, self.navigationController.navigationBar.frame.size.width, 30)];
            [self.infoView setAlpha:0.8];
            UIButton *infoButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0, self.infoView.frame.size.width, self.infoView.frame.size.height)];
            [infoButton addTarget:self action:@selector(infoTapped) forControlEvents:UIControlEventTouchUpInside];
            infoButton.titleLabel.adjustsFontSizeToFitWidth = YES;
            infoButton.titleLabel.minimumScaleFactor=0.5;
            [infoButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:13.0f]];
            
            UIButton *dismissButton = [[UIButton alloc]initWithFrame:CGRectMake(self.infoView.frame.size.width-40,(self.infoView.frame.size.height/2)-10, 20, 20)];
            [dismissButton setTitle:@"x" forState:UIControlStateNormal];
            [dismissButton addTarget:self action:@selector(dismissInfoBanner) forControlEvents:UIControlEventTouchUpInside];
            [infoButton addSubview:dismissButton];
            
            if (self.userIsBuyer == YES) {
                [infoButton setTitle:@"How to buy with ZERO Fees on Bump" forState:UIControlStateNormal];

            }
            else{
                [infoButton setTitle:@"How to sell with ZERO Fees on Bump" forState:UIControlStateNormal];
            }
            
            infoButton.backgroundColor = [UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:0.8];
            [infoButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
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
                             [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"dismissedBanner"];
                         }];
    }
}

-(void)infoTapped{
    Tut1ViewController *vc = [[Tut1ViewController alloc]init];
    vc.index = 1;
    vc.messageExplain = YES;
    [self presentViewController:vc animated:YES completion:nil];
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
    vc.fromMessage = YES;
    self.checkoutTapped = YES;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
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
                        [self.successButton setTitle:@"Purchased - Tap to leave feedback" forState:UIControlStateNormal];
                        [self.successButton addTarget:self action:@selector(viewOrderDetails) forControlEvents:UIControlEventTouchUpInside];
                        //feedbacktapped
                    }
                    else{
                        [self.successButton setTitle:@"Sold - Tap to mark as shipped" forState:UIControlStateNormal];
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
                        [self.successButton setTitle:@"Sold - Tap for order details" forState:UIControlStateNormal];
                        self.successButton.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
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

//for infinite load of messages

//-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    
//    float edge = scrollView.contentOffset.y + scrollView.frame.size.height;
//
//
//    if (edge <= self.topEdge){
//        
//        NSLog(@"hide");
//        
//        //automatically trigger the button when scroll to the top + bit more
//        if (self.showLoadEarlierMessagesHeader == YES) {
////            self.earlierPressed = YES;
////            self.showLoadEarlierMessagesHeader = NO;
////            NSLog(@"CALLING LOAD");
////            [self loadMessages];
//            
//            //hide banner which is showing - to see 'Load Earlier Messages' button
//            if (self.successBannerShowing == YES) {
//                [UIView animateWithDuration:0.5
//                                      delay:0
//                                    options:UIViewAnimationOptionCurveEaseIn
//                                 animations:^{
//                                     [self.successView setAlpha:0.0];
//                                 }
//                                 completion:^(BOOL finished) {}];
//                
//            }
//            else if(self.payBannerShowing == YES){
//                [UIView animateWithDuration:0.5
//                                      delay:0
//                                    options:UIViewAnimationOptionCurveEaseIn
//                                 animations:^{
//                                     [self.paidView setAlpha:0.0];
//                                 }
//                                 completion:^(BOOL finished) {}];
//            }
//            else if(self.infoBannerShowing == YES){
//                [UIView animateWithDuration:0.5
//                                      delay:0
//                                    options:UIViewAnimationOptionCurveEaseIn
//                                 animations:^{
//                                     [self.infoView setAlpha:0.0];
//                                 }
//                                 completion:^(BOOL finished) {}];
//            }
//        }
//    }
//    else{
//        //re-show the banner
//        if (self.successBannerShowing == YES) {
//            [UIView animateWithDuration:0.5
//                                  delay:0
//                                options:UIViewAnimationOptionCurveEaseIn
//                             animations:^{
//                                 [self.successView setAlpha:1.0];
//                             }
//                             completion:^(BOOL finished) {}];
//        }
//        else if(self.payBannerShowing == YES){
//            [UIView animateWithDuration:0.5
//                                  delay:0
//                                options:UIViewAnimationOptionCurveEaseIn
//                             animations:^{
//                                 [self.paidView setAlpha:1.0];
//                             }
//                             completion:^(BOOL finished) {}];
//        }
//        else if(self.infoBannerShowing == YES){
//            [UIView animateWithDuration:0.5
//                                  delay:0
//                                options:UIViewAnimationOptionCurveEaseIn
//                             animations:^{
//                                 [self.infoView setAlpha:1.0];
//                             }
//                             completion:^(BOOL finished) {}];
//        }
//    }
//}

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
    imageView.layer.cornerRadius = 4;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)setSaleImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width/2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)sendOffer:(NSString *)offerString{
    if (self.offerReminderMode == YES) {
        self.inputToolbar.contentView.textView.text = @"";
        [self.inputToolbar.contentView.rightBarButtonItem setHidden:YES];
    }
    self.offerMode = YES;
    UIButton *button = [[UIButton alloc]init];
    [self didPressSendButton:button withMessageText:offerString senderId:self.senderId senderDisplayName:self.senderDisplayName date:[NSDate date]];
}

-(void)showCustomAlert{
    //make sure keyboard dismissed
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.searchBgView.alpha = 0.0;
    [self.searchBgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.searchBgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"customAlertView" owner:self options:nil];
    self.customAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.customAlert.delegate = self;
    if (self.offerReminderMode == YES) {
        if (self.userIsBuyer == YES) {
            self.customAlert.titleLabel.text = @"Buying on Bump";
            self.customAlert.messageLabel.text = @"Build your reputation, stay protected & pay ZERO transaction fees. Ask the seller for their PayPal and pay through Bump";
        }
        else{
            self.customAlert.titleLabel.text = @"Selling on Bump";
            self.customAlert.messageLabel.text = @"Build your reputation, stay protected & get paid with PayPal. Tap the image icon to send photos";
//            [self.customAlert.doneButton setTitle:@"D I S M I S S" forState:UIControlStateNormal];
//            [self.customAlert.doneButton setBackgroundColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]];
//            [self.customAlert.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        
        self.customAlert.numberOfButtons = 1;
        [self.customAlert.doneButton setTitle:@"D I S M I S S" forState:UIControlStateNormal];
        [self.customAlert.doneButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
        [self.customAlert.doneButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];

    }
    else{
        self.customAlert.titleLabel.text = @"Permssion Needed";
        self.customAlert.messageLabel.text = @"Tap to goto Settings & enable Bump's Photos Permission";
        self.customAlert.numberOfButtons = 2;
        [self.customAlert.secondButton setTitle:@"S E T T I N G S" forState:UIControlStateNormal];
    }
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, -157, 250, 157)];
    }
    else{
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, -188, 300, 188)]; //iPhone 6/7 specific
    }
    
    self.customAlert.layer.cornerRadius = 10;
    self.customAlert.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.customAlert];
    
    [UIView animateWithDuration:1.5
                          delay:0.2
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.customAlert setFrame:CGRectMake(0, 0, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake(0, 0, 300, 188)]; //iPhone 6/7 specific
                            }
                            self.customAlert.center = self.view.center;
                            
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)donePressed{
    if (self.offerReminderMode == YES) {
        
        [Answers logCustomEventWithName:@"Dismissed deal on bump warning"
                       customAttributes:@{}];

    }
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.searchBgView = nil;
                     }];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 1000, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 188)]; //iPhone 6/7 specific
                            }
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.customAlert setAlpha:0.0];
                         self.customAlert = nil;
                     }];
}

-(void)firstPressed{
    [self donePressed];
}

-(void)secondPressed{
    //goto settings
    [self donePressed];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

-(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO;
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

-(void)loadConvoImages{
    PFQuery *imageQuery = [PFQuery queryWithClassName:@"messageImages"];
    [imageQuery whereKey:@"convo" equalTo:self.convoObject];
    [imageQuery orderByDescending:@"createdAt"];
    [imageQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            [self.convoImagesArray addObjectsFromArray:objects];
//            NSLog(@"convoimages: %ld", self.convoImagesArray.count);
            
            //reverse order
            NSArray *convoImg = [[self.convoImagesArray reverseObjectEnumerator] allObjects];
            [self.convoImagesArray removeAllObjects];
            [self.convoImagesArray addObjectsFromArray:convoImg];
        }
        else{
            NSLog(@"error getting convo images %@", error);
        }
    }];
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
    
    //check if last in the array
    if (index == self.suggestedMessagesArray.count-1) {
        messageLabel.text = [self.suggestedMessagesArray objectAtIndex:index];
        messageLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
        messageLabel.backgroundColor = [UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0];
    }
    else{
        messageLabel.text = [self.suggestedMessagesArray objectAtIndex:index];
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.backgroundColor = [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0];
    }
    
    return view;
}

-(NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    return self.suggestedMessagesArray.count;
}

-(void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index{
    
    NSString *messageString = [self.suggestedMessagesArray objectAtIndex:index];
    
    [Answers logCustomEventWithName:@"Sent Suggested Message"
                   customAttributes:@{
                                      @"message":messageString
                                      }];
    
    if ([messageString isEqualToString:@"Dismiss"]) {
        
        //set object so not shoed again to this user in this convo
        if (self.userIsBuyer == YES) {
            [self.convoObject setObject:@"NO" forKey:@"buyerShowSuggested"];
        }
        else{
            [self.convoObject setObject:@"NO" forKey:@"sellerShowSuggested"];
        }
        
        [self.convoObject saveInBackground];
        
        //hide carousel
        [UIView animateWithDuration:0.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.carousel.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             [self.carousel removeFromSuperview];
                         }];
    }
    else if ([messageString isEqualToString:@"Send PayPal email"]){
        
        if (![[[PFUser currentUser]objectForKey:@"paypalUpdated"]isEqualToString:@"YES"]) {
            //show paypal alert to confirm
            [self showPayPalAlert];
        }
        else{
            NSString *messageString = [NSString stringWithFormat:@"%@ sent their PayPal email %@",[PFUser currentUser].username,[[PFUser currentUser] objectForKey:@"paypal"]];
            UIButton *button = [[UIButton alloc]init];
            self.paypalMessage = YES;
            self.paypalPush = YES;
            [self didPressSendButton:button withMessageText:messageString senderId:self.senderId senderDisplayName:self.senderDisplayName date:[NSDate date]];
        }
    }
    else{
        //send message
        UIButton *button = [[UIButton alloc]init];
        [self didPressSendButton:button withMessageText:messageString senderId:self.senderId senderDisplayName:self.senderDisplayName date:[NSDate date]];
        
        //remove from array
        [self.suggestedMessagesArray removeObjectAtIndex:index];
        
        if (self.userIsBuyer == YES) {
            [self.convoObject setObject:self.suggestedMessagesArray forKey:@"buyerSuggestedMessages"];
        }
        else{
            [self.convoObject setObject:self.suggestedMessagesArray forKey:@"sellerSuggestedMessages"];
        }
        [self.convoObject saveInBackground];
        
        if (self.suggestedMessagesArray.count == 1) {
            //hide carousel as only has dismiss left in it (only possible for buyers)
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.carousel.alpha = 0.0f;
                             }
                             completion:^(BOOL finished) {
                                 [self.carousel removeFromSuperview];
                             }];
        }
        else{
            [self.carousel reloadData];
        }
    }
}

#pragma keyboard observer methods

-(void)keyboardOnScreen:(NSNotification *)notification
{
    NSLog(@"KEYBOARD WILL SHOW");
    
    if (self.changeKeyboard == NO) {
        return;
    }

    NSDictionary *info  = notification.userInfo;
    NSValue      *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame      = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    
    self.lastInputToolbarHeight = self.inputToolbar.contentView.frame.size.height;
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            
                            //animate carousel up
                            
                            [self.carousel setFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(50+  keyboardFrame.size.height + self.inputToolbar.contentView.frame.size.height), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                            
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)keyboardOFFScreen:(NSNotification *)notification
{
    NSLog(@"KEYBOARD WILL HIDE");
    
    if (self.changeKeyboard == NO) {
        return;
    }
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            
                            //animate carousel down
                            [self.carousel setFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(50+ self.tabBarHeightInt + self.inputToolbar.contentView.frame.size.height), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];

                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)goneToBackground{
    //block further keyboard changes
    self.changeKeyboard = NO;
    
}

-(void)comeBackToForeground{
    self.changeKeyboard = YES;
}

//review tapped
-(void)gotoReview{
    FeedbackController *vc = [[FeedbackController alloc]init];
    vc.delegate = self;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    vc.IDUser = self.otherUser.objectId;
    vc.isBuyer = self.userIsBuyer;
    vc.convoObject = self.convoObject;
    vc.messageNav = self.navigationController;
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)leftReview{
    [self dismissSuccessBanner];
}
@end

