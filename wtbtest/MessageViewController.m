//
//  MessageViewController.m
//  
//
//  Created by Jack Ryder on 17/06/2016.
//
//

#import "MessageViewController.h"
#import "DetailImageController.h"
#import "UserProfileController.h"
#import "SettingsController.h"
#import "ListingController.h"
#import "MessagesTutorial.h"
#import "NavigationController.h"
#import "UIImage+Resize.h"
#import "Tut1ViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "CustomMessagesCollectionViewCell.h"
#import "CustomMessagesCollectionViewCellIncoming.h"
#import "ForSaleListing.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "ExplainView.h"
#import "AppDelegate.h"
#import "JRMessage.h"

@interface MessageViewController ()

@end

@implementation MessageViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //new property in iOS 11 which automatically adjusts insets on scroll views. Disable so we can do it ourselves
    if (@available(iOS 11.0, *)) {
        [self.collectionView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }
    
    if (![self.otherUserName isEqualToString:@""]) {
        self.title = [NSString stringWithFormat:@"@%@",self.otherUserName];
    }
        
    self.paypalSentCounter = 0;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    [self.otherUser fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.title = [NSString stringWithFormat:@"@%@",self.otherUser.username];
            
            //check if banned - if so show alert
            PFQuery *bannedInstallsQuery = [PFQuery queryWithClassName:@"bannedUsers"];
            [bannedInstallsQuery whereKey:@"user" equalTo:self.otherUser];
            [bannedInstallsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    NSLog(@"user is banned");
                    self.banMode = YES;
                    [self showAlertWithTitle:@"User Restricted" andMsg:@"For your safety we've restrcited this user's account for violating our terms"];
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
    
    //if it's a WTB then stick that in the nav bar
    if (self.pureWTS != YES) {
        UIButton *btn =  [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0,0,25,25);
        [btn addTarget:self action:@selector(listingTapped) forControlEvents:UIControlEventTouchUpInside];
        
        PFImageView *buttonView = [[PFImageView alloc]initWithFrame:btn.frame];
        
        [self.listing fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                
                PFFile *listingFile;

                if ([self.listing objectForKey:@"thumbnail"]) {
                    listingFile = [self.listing objectForKey:@"thumbnail"];
                }
                else{
                    listingFile = [self.listing objectForKey:@"image1"];
                }
                
                [buttonView setFile:listingFile];
                [buttonView loadInBackground];
            }
        }];
        

        [self setImageBorder:buttonView];
        [btn addSubview:buttonView];
        
        self.listingButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.listingButton, self.profileButton, nil]];
    }
    else{
        [self.navigationItem setRightBarButtonItem:self.profileButton];
    }
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    
    self.inputToolbar.contentView.textView.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
        
    self.inputToolbar.contentView.textView.placeHolder = @"Write a message...";
    
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"sendPicBlk"] forState:UIControlStateNormal];
    [self.inputToolbar.contentView.leftBarButtonItem setImage:[UIImage imageNamed:@"sendPicBlue"] forState:UIControlStateHighlighted];
    self.inputToolbar.contentView.backgroundColor = [UIColor whiteColor];
    [self.inputToolbar.contentView.textView.layer setBorderWidth:0.0];
    self.inputToolbar.contentView.textView.delegate = self;
    self.inputToolbar.contentView.textView.jsqPasteDelegate = self;
    
    [self.inputToolbar.contentView.rightBarButtonItem setHidden:YES];
    
    //avatar images
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(35, 35);
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    //Register custom menu actions for cells.
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];
    
    self.senderId = [PFUser currentUser].objectId;
    
    self.messages = [NSMutableArray array];
    self.messagesParseArray = [NSMutableArray array];
    self.sentMessagesParseArray = [NSMutableArray array];
    self.suggestedMessagesArray = [NSMutableArray array];
    self.convoImagesArray = [NSMutableArray array];
    self.placeholderAssetArray = [NSMutableArray array];
    self.imagesToProcess = [NSMutableArray array];
    
    
    //set suggested messages
    if (self.userIsBuyer == YES) {
        
        //should we show?
        if (![[self.convoObject objectForKey:@"buyerShowSuggested"]isEqualToString:@"NO"]) {
            self.showSuggested = YES;
            
            //load messages left
            if ([self.convoObject objectForKey:@"buyerSuggestedMessages"]) {
                [self.suggestedMessagesArray addObjectsFromArray:[self.convoObject objectForKey:@"buyerSuggestedMessages"]];
                
                //track when a paypal is sent so we can prompt buyer to ask for the tracking number
                if ([self.convoObject objectForKey:@"paypalSent"] && ![self.convoObject objectForKey:@"addedTrackingMsg"] && ![self.suggestedMessagesArray containsObject:@"Tracking number?"]) {
                    [self.convoObject setObject:@"YES" forKey:@"addedTrackingMsg"];
                    [self.convoObject saveInBackground];

                    [self.suggestedMessagesArray insertObject:@"Tracking number?" atIndex:0];
                }
            }
            else{
                if (self.messageSellerPressed == YES) {
                [self.suggestedMessagesArray addObjectsFromArray:@[@"What size?",@"Yeah I'm interested", @"Got photos?", @"How's the fit?",@"What's your price?",@"Price negotiable?", @"Not interested thanks", @"Dismiss"]];
                }
                else{
                    if (self.profileConvo) {
                        [self.suggestedMessagesArray addObjectsFromArray:@[@"Send PayPal email", @"Dismiss"]];
                    }
                    else{
                        [self.suggestedMessagesArray addObjectsFromArray:@[@"What are you selling?",@"What size?",@"Yeah I'm interested", @"Got photos?", @"How's the fit?",@"What's your price?",@"Price negotiable?", @"Not interested thanks", @"Dismiss"]];
                        
                        //track when a paypal is sent so we can prompt buyer to ask for the tracking number
                        if ([self.convoObject objectForKey:@"paypalSent"] && ![self.convoObject objectForKey:@"addedTrackingMsg"]) {
                            [self.convoObject setObject:@"YES" forKey:@"addedTrackingMsg"];
                            [self.convoObject saveInBackground];
                            
                            [self.suggestedMessagesArray insertObject:@"Tracking number?" atIndex:0];
                        }
                    }
                }
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
                if (self.profileConvo) {
                    [self.suggestedMessagesArray addObjectsFromArray:@[@"Send PayPal email", @"Dismiss"]];
                }
                else{
                    [self.suggestedMessagesArray addObjectsFromArray:@[@"Hey, it's still available", @"What's your offer?",@"Yes, it's negotiable", @"Sorry, been sold!", @"Dismiss"]];
                }
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
    self.earlierPressed = NO;
    
    [self loadConvoImages];
    [self loadMessages];
    
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
        
        //check if from latest VC - y point seems to be off on here so need special treatment - works fine from search
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
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
    
    if (self.showPull) {
        //only show pull if there's enough messages otherwise it's a watse of resources
        [self.collectionView addPullToRefreshWithActionHandler:^{
            if (self.infiniteLoading != YES && self.finishedFirstScroll == YES && self.moreToLoad == YES) {

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
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
//    NSLog(@"LISTING FRAME: %@     view frame %@", NSStringFromCGRect(self.listingView.frame),NSStringFromCGRect(self.view.frame));

    if (@available(iOS 11.0, *)) {
        //so to calculate height insets we need to return (navigation bar height + status bar height + listing banner height) - adjusted content insets
        return UIEdgeInsetsMake(self.listingView.frame.size.height + self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, 0, self.carousel.frame.size.height, 0); // top, left, bottom, right
    }
    else{
        if (self.showSuggested == YES && self.showingListingBanner == YES) {
//            NSLog(@"banner showing so use correct insets");
            return UIEdgeInsetsMake(80, 0, 50, 0); // top, left, bottom, right
        }
        else if (self.showSuggested == YES && self.showingListingBanner != YES){
//            NSLog(@"just bottom insets");
            return UIEdgeInsetsMake(0, 0, 50, 0);
        }
        else if (self.showSuggested == NO && self.showingListingBanner == YES){
//            NSLog(@"banner just showing so use correct insets 1");
            return UIEdgeInsetsMake(80, 0, 0, 0);
        }
        else{
            return self.collectionView.layoutMargins;
        }
    }
}

-(void)loadMessages{
    PFQuery *messageQuery = [PFQuery queryWithClassName:@"messages"];
    [messageQuery whereKey:@"convoId" equalTo:self.convoId];
    messageQuery.limit = 10;
    messageQuery.skip = self.skipped;
    [messageQuery orderByDescending :@"createdAt"];
    [messageQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                
                if (objects.count == 0) {
                    [self setupPayPalView];
                }
                else{
                    if (self.paypalView) {
                        [self removePayPalView];
                    }
                }
                
                if (self.earlierPressed == NO) {
                    self.lastMessage = [objects objectAtIndex:0];
                }
                
                if (objects.count < 10) {
                    self.moreToLoad = NO;
                    self.collectionView.showsPullToRefresh = NO;
                    
                    //save memory
                    [self.spinner stopAnimating];
                    self.spinner = nil;
                }
                else{
                    self.moreToLoad = YES;
                    self.collectionView.showsPullToRefresh = YES;
                }
                
                int count = (int)[objects count];
                self.skipped = count + self.skipped;
                
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
                    
                    __block JRMessage *message = nil;
                    
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
                        
                        message = [[JRMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt media:photoItem];
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
                        
                        if (![[messageOb objectForKey:@"senderId"] isEqualToString:[PFUser currentUser].objectId] && [[messageOb objectForKey:@"paypalMessage"]isEqualToString:@"YES"]){
                            
                            //other user sent a paypal message, add call to action
                            messageText = [NSString stringWithFormat:@"%@\nTap to Pay now",[messageOb objectForKey:@"message"]];
                        }
                        
                        message = [[JRMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt text:messageText];
                        
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
                            message.isWaiting = NO;
                            message.isPurchased = NO;
                        }
                        
                        else if ([[messageOb objectForKey:@"paypalMessage"]isEqualToString:@"YES"]){
                            
                            //it's a paypal message
                            message.isShared = NO;
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
                
                [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
                [self.collectionView reloadData];
                
                if (self.earlierPressed == NO) {
//                    [self scrollToBottomAnimated:NO];
                    
                    //fix the last message being hidden when first go on convo
                    [self.view layoutIfNeeded];
                    [self.collectionView.collectionViewLayout invalidateLayout];
                    
                    if (self.automaticallyScrollsToMostRecentMessage) {
                        self.firstLayout = YES;
                        [self viewDidLayoutSubviews];
                    }
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
    
    [self.navigationController.navigationBar setTranslucent:YES]; //watch out, setting this to no throws the listing banner's constraints off!
    [self.navigationController.navigationBar setHidden:NO];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (!self.setOtherUserImage) {
        self.setOtherUserImage = YES;
        if (self.userIsBuyer){
            if (![self.convoObject objectForKey:@"sellerPicture"]) {
                UIImage *image = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"emptyAva"] withDiameter:35];
                UIImage *placeholder = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"emptyAva"] withDiameter:35];
                self.avaImage = [[JSQMessagesAvatarImage alloc]initWithAvatarImage:image highlightedImage:image placeholderImage:placeholder];
            }
            else{
                PFFile *imageFile = [self.convoObject objectForKey:@"sellerPicture"];
                [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if (!error) {
                        self.otherUserImage = [UIImage imageWithData:data];
                        //need to scale it to keep the aspect ratio
                        self.otherUserImage = [self.otherUserImage scaleImageToSize:CGSizeMake(50, 50)];
                        UIImage *image = [JSQMessagesAvatarImageFactory circularAvatarImage:self.otherUserImage withDiameter:35];
                        UIImage *placeholder = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"emptyAva"] withDiameter:35];
                        self.avaImage = [[JSQMessagesAvatarImage alloc]initWithAvatarImage:image highlightedImage:image placeholderImage:placeholder];
                    }
                }];
            }
        }
        else{
            //got a pic?
            if (![self.convoObject objectForKey:@"buyerPicture"]) {
                UIImage *image = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"emptyAva"] withDiameter:35];
                UIImage *placeholder = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"emptyAva"] withDiameter:35];
                self.avaImage = [[JSQMessagesAvatarImage alloc]initWithAvatarImage:image highlightedImage:image placeholderImage:placeholder];
            }
            else{
                PFFile *imageFile = [self.convoObject objectForKey:@"buyerPicture"];
                [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if (!error) {
                        self.otherUserImage = [UIImage imageWithData:data];
                        //need to scale it to keep the aspect ratio
                        self.otherUserImage = [self.otherUserImage scaleImageToSize:CGSizeMake(50, 50)];
                        UIImage *image = [JSQMessagesAvatarImageFactory circularAvatarImage:self.otherUserImage withDiameter:35];
                        UIImage *placeholder = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"emptyAva"] withDiameter:35];
                        self.avaImage = [[JSQMessagesAvatarImage alloc]initWithAvatarImage:image highlightedImage:image placeholderImage:placeholder];
                    }
                }];
            }
        }
    }
    
    //to prevent double tapping profile button
    self.profileBTapped = NO;
    
    //decide whether to show review banner
    int messageTotal = [[self.convoObject objectForKey:@"totalMessages"]intValue];
    
    if (messageTotal > 10) {
        self.showPull = YES;
    }
    
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
        else if ([self.currency isEqualToString:@"USD"] || [self.currency isEqualToString:@"AUD"]) {
            self.currencySymbol = @"$";
        }
        
//        NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
//        if (self.pureWTS && messageTotal > 0 && self.listing && (!self.fromLatest || (self.tabBarController.selectedIndex != 0 && nav.visibleViewController == nil)))
        if (self.pureWTS && messageTotal > 0 && self.listing)
        {
            double delayInSeconds = 0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                self.showingListingBanner = YES;
                [self showListingBanner];
            });
        }
    }
    
//    if (messageTotal >= 20) {
//        if (self.userIsBuyer == YES) {
//            if (![self.convoObject objectForKey:@"buyerHasReviewed"]) {
//                //show rate banner
//                if (!self.reviewButton && self.justLeftReview != YES) {
//                    self.reviewButton = [[UIBarButtonItem alloc] initWithTitle:@"Review" style:UIBarButtonItemStylePlain target:self action:@selector(gotoReview)];
//                    [self.reviewButton setTintColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]];
//                    NSMutableArray *currentItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
//                    [currentItems addObject:self.reviewButton];
//                    [self.navigationItem setRightBarButtonItems:currentItems];
//                }
//            }
//
//            //show how to buy prompt
//            if (![[PFUser currentUser]objectForKey:@"buyingIntro2"]) {
//                ExplainView *vc = [[ExplainView alloc]init];
//                vc.buyingIntro = YES;
//                [self presentViewController:vc animated:YES completion:nil];
//            }
//        }
//        else{
//            if (![self.convoObject objectForKey:@"sellerHasReviewed"]) {
//                //show rate banner
//                if (!self.reviewButton && self.justLeftReview != YES) {
//                    self.reviewButton = [[UIBarButtonItem alloc] initWithTitle:@"Review" style:UIBarButtonItemStylePlain target:self action:@selector(gotoReview)];
//                    [self.reviewButton setTintColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]];
//                    NSMutableArray *currentItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
//                    [currentItems addObject:self.reviewButton];
//                    [self.navigationItem setRightBarButtonItems:currentItems];
//                }
//            }
//
//            //show how to sell prompt
//            if (![[PFUser currentUser]objectForKey:@"sellingIntro2"]) {
//                ExplainView *vc = [[ExplainView alloc]init];
//                vc.sellingIntro = YES;
//                [self presentViewController:vc animated:YES completion:nil];
//            }
//        }
//    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    //fixes bug which hides last message in convo
    //if we scroll here instead of after loadMessages then it works
    if (self.firstLayout && self.automaticallyScrollsToMostRecentMessage) {
        self.firstLayout = NO;
        [self scrollToBottomAnimated:YES];
        
        //waits a sec to turn this on to prevent infinite scroll being called by the initial scroll to the most recent message
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.finishedFirstScroll = YES;
        });
    }
}

- (void)handleNotification:(NSNotification*)note {
    NSMutableArray *unseenConvos = [note object];
    PFObject *currentConvo = self.convoObject;
    
    //could do a check for duplicated here
    
    for (PFObject *convo in unseenConvos) {
        NSLog(@"UNSEEN CONVO: %@", convo);
        if ([convo.objectId isEqualToString:currentConvo.objectId]) {
            [self loadNewMessages];
        }
    }
}

-(void)loadNewMessages{
    PFQuery *newMessageQuery = [PFQuery queryWithClassName:@"messages"];
    [newMessageQuery whereKey:@"convoId" equalTo:self.convoId];
    NSDate *lastDate = [self.lastMessage createdAt];
    [newMessageQuery whereKey:@"createdAt" greaterThan:lastDate];
    [newMessageQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (!error) {
            if (objects) {
                
                if (self.paypalView && self.messages.count > 0) {
                    [self removePayPalView];
                }
                
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
                    
                    __block JRMessage *message = nil;
                    
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
                        //don't need because this only called for loading incoming new messages, leave in just in case
                        if (![self.sentMessagesParseArray containsObject:messageOb]) {
                            [self.sentMessagesParseArray addObject:messageOb];
                        }
                    }
                    
                    if ([[messageOb objectForKey:@"mediaMessage"] isEqualToString:@"YES"]) {
                        
                        //update inbox VC
                        [self.delegate lastMessageInConvo:[NSString stringWithFormat:@"%@ sent a photo 📷",[messageOb objectForKey:@"senderName"]] incomingMsg:YES];
                        
                        //media message
                        __block id<JSQMessageMediaData> newMediaData = nil;
                        __block id newMediaAttachmentCopy = nil;
                        __block JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc]init];
                        photoItem.image = [UIImage imageNamed:@"empty"];
                        
                        message = [[JRMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt media:photoItem];
                        
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
                        
                        message = [[JRMessage alloc] initWithSenderId:[messageOb objectForKey:@"senderId"]  senderDisplayName:[messageOb objectForKey:@"senderName"] date:messageOb.createdAt text:messageText];
                       
                        if ([[messageOb objectForKey:@"sharedMessage"]isEqualToString:@"YES"]){
                            
                            //add the listing info to the shared message
                            
                            if ([messageOb objectForKey:@"Sale"]) {
                                //update inbox VC
                                [self.delegate lastMessageInConvo:[NSString stringWithFormat:@"%@ shared a listing 📲",[messageOb objectForKey:@"senderName"]] incomingMsg:YES];

                                //shared a for sale listing
                                message.sharedListing = [messageOb objectForKey:@"sharedSaleListing"];
                                message.saleShare = YES;
                            }
                            else{
                                //shared a WTB
                                //update inbox VC
                                [self.delegate lastMessageInConvo:[NSString stringWithFormat:@"%@ shared a wanted listing 📲",[messageOb objectForKey:@"senderName"]] incomingMsg:YES];

                                message.sharedListing = [messageOb objectForKey:@"sharedListing"];
                                message.saleShare = NO;
                            }
                            message.isShared = YES;
                            message.isOfferMessage = NO;
                            message.isWaiting = NO;
                            message.isPurchased = NO;
                        }
                        
                        else if ([[messageOb objectForKey:@"paypalMessage"]isEqualToString:@"YES"]){
                            
                            //update inbox VC
                            [self.delegate lastMessageInConvo:[NSString stringWithFormat:@"%@ sent their PayPal 🛒",[messageOb objectForKey:@"senderName"]]incomingMsg:YES];
                            
                            //it's a paypal message
                            message.isShared = NO;
                            message.isOfferMessage = NO;
                            message.isWaiting = NO;
                            message.isPurchased = NO;
                            message.isPayPal = YES;
                        }
                        else{
                            //update inbox VC
                            [self.delegate lastMessageInConvo:messageText incomingMsg:YES];
                        }

                        
                        if (![self.messages containsObject:message]) {
                            [self.messages addObject:message];
                        }
                    }
                    self.lastMessage = messageOb;
                }
                
                //save new unseen counter number
                [self.convoObject saveInBackground];
                
                //received a message so move this convo to top of inbox
                NSLog(@"got a new message so call last message in convo");
                
                self.receivedNew = YES;

                //bug here when reloading from notification provoked newMessage call
                // the user's last message's seen/sent label jumps up by 1 when receieve a new message
                //this is because we add an item to the CV's datasource but its not in the CV yet? would need to call reload first?
                
//                //call attributedString method to update last sent label to Seen
//                NSInteger lastSectionIndex = [self.collectionView numberOfSections] - 1;
//                NSInteger lastItemIndex = [self.collectionView numberOfItemsInSection:lastSectionIndex] - 1;
//                NSIndexPath *pathToLastItem = [NSIndexPath indexPathForItem:lastItemIndex inSection:lastSectionIndex];
//                
//                [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:pathToLastItem];
//                [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout heightForCellBottomLabelAtIndexPath:pathToLastItem];
               
                [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
                [self.collectionView reloadData];
                
                //scroll to bottom
                [self scrollToBottomAnimated:YES];
                
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
    [center addObserver:self selector:@selector(keyboardOnScreen:) name:UIKeyboardWillShowNotification object:nil];
    
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center addObserver:self selector:@selector(keyboardOFFScreen:) name:UIKeyboardWillHideNotification object:nil];
    
    [center removeObserver:self name:@"NewMessage" object:nil];
    [center addObserver:self selector:@selector(handleNotification:) name:@"NewMessage" object:nil];

    
    //the drag gesture to dismiss keyboard is handled all by JSQMVC
    //so would need to look there more for a solution to momentatry stranded carousel
    
    if (self.messageSellerPressed == YES) {
        self.messageSellerPressed = NO;
        
        self.inputToolbar.contentView.textView.text = [NSString stringWithFormat:@"Hey, is your '%@' still available?", self.sellerItemTitle];
        
        self.savedString = self.inputToolbar.contentView.textView.text;
        [self.inputToolbar.contentView.rightBarButtonItem setHidden:NO];
        [self.inputToolbar toggleSendButtonEnabled];
    }
        
    [self resetCarouselHeight];

    
    if (![self.savedString isEqualToString:@""] && self.savedSomin == YES) {
        self.inputToolbar.contentView.textView.text = self.savedString;
        self.savedSomin = NO;
        self.savedString = @"";
    }
    
    self.automaticallyScrollsToMostRecentMessage = YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    //clear observers
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [center removeObserver:self name:@"NewMessage" object:nil];
    [center removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [center removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
    if (![self isMovingFromParentViewController]){
        [self.inputToolbar.contentView.textView resignFirstResponder];
        [self resetCarouselHeight];
    }

}

-(void)resetCarouselHeight{
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
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (self.banMode) {
            self.banMode = NO;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showUserAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)changePayPalEmail{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"PayPal Email"
                                          message:@"Enter your PayPal email address so it's faster for you to send it to buyers on BUMP"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = @"PayPal email address";
     }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"Save"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   UITextField *paypalField = alertController.textFields.firstObject;
                                   self.updatedPayPal = paypalField.text;
                                   
                                   [[PFUser currentUser] setObject:paypalField.text forKey:@"paypal"];
                                   [[PFUser currentUser] setObject:@"YES" forKey:@"paypalUpdated"];
                                   [[PFUser currentUser] saveInBackground];
                                   self.changeKeyboard = YES;
                               }];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       self.changeKeyboard = YES;
                                   }];
    
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)showPayPalAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Enter PayPal Email" message:[NSString stringWithFormat:@"Save your PayPal email on BUMP so you can send it to buyers faster! Don't worry, BUMP doesn't handle any passwords!\n\nIs '%@' correct?", [[PFUser currentUser] objectForKey:@"paypal"]] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Change" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.inputToolbar.contentView.textView.text = @"";
        self.changeKeyboard = NO;
        [self changePayPalEmail];
//        SettingsController *vc = [[SettingsController alloc]init];
//        vc.changePayPal = YES;
//        [self.navigationController pushViewController:vc animated:YES];
    }]];
    [alertView addAction:[UIAlertAction actionWithTitle:@"Yes, it's correct" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        //save as updated
        [[PFUser currentUser] setObject:@"YES" forKey:@"paypalUpdated"];
        [[PFUser currentUser]saveInBackground];
        
        //send paypal messages
        NSString *messageString = [NSString stringWithFormat:@"@%@ sent their PayPal email %@",[PFUser currentUser].username ,[[PFUser currentUser] objectForKey:@"paypal"]];
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
    //CHANGE check if instant buy is available to this user first before we prompt them to buy on bump
//    if (self.promptedBefore != YES && self.paypalMessage != YES) {
//        NSArray *checkingforemailarray = [text componentsSeparatedByString:@" "];
//        for (NSString *stringer in checkingforemailarray) {
//            NSString *string = [stringer stringByReplacingOccurrencesOfString:@"?" withString:@""];
//            //check for user trying to direct other user elsewhere & remind them to send an offer
//
//            //email check
//            if ([self NSStringIsValidEmail:string]) {
//                [Answers logCustomEventWithName:@"Deal on Bump warning"
//                               customAttributes:@{
//                                                  @"trigger":@"email",
//                                                  @"message":text,
//                                                  @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
//                                                  }];
//                //present 'Send Offer' reminder alert
//                self.promptedBefore = YES;
//                self.offerReminderMode = YES;
//                self.emailReminderMode = YES;
//
//                [self showCustomAlert];
//                return;
//            }
//
//            //facebook check
//            if ([[string lowercaseString] isEqualToString:@"facebook"]) {
//                [Answers logCustomEventWithName:@"Deal on Bump warning"
//                               customAttributes:@{
//                                                  @"trigger":@"facebook",
//                                                  @"message":text,
//                                                  @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
//                                                  }];
//                //present 'Send Offer' reminder alert
//                self.promptedBefore = YES;
//                self.offerReminderMode = YES;
//                self.emailReminderMode = YES;
//                [self showCustomAlert];
//                return;
//            }
//
//            //check for number
//            NSError *error = NULL;
//            NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
//            NSArray *matches = [detector matchesInString:string options:0 range:NSMakeRange(0, [string length])];
//            if (matches != nil) {
//                for (NSTextCheckingResult *match in matches) {
//                    if ([match resultType] == NSTextCheckingTypePhoneNumber) {
//                        [Answers logCustomEventWithName:@"Deal on Bump warning"
//                                       customAttributes:@{
//                                                          @"trigger":@"phone number",
//                                                          @"message":text,
//                                                          @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
//                                                          }];
//                         //present 'Send Offer' reminder alert
//                         self.promptedBefore = YES;
//                         self.offerReminderMode = YES;
//                        self.emailReminderMode = YES;
//                         [self showCustomAlert];
//                        return;
//                    }
//                }
//            }
//
//            //depop
//            if ([[string lowercaseString] isEqualToString:@"depop"]) {
//                [Answers logCustomEventWithName:@"Deal on Bump warning"
//                               customAttributes:@{
//                                                  @"trigger":@"depop",
//                                                  @"message":text,
//                                                  @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
//                                                  }];
//                //present 'Send Offer' reminder alert
//                self.promptedBefore = YES;
//                self.offerReminderMode = YES;
//                self.emailReminderMode = YES;
//                [self showCustomAlert];
//                return;
//            }
//
//            //instagram
//            if ([[string lowercaseString] isEqualToString:@"instagram"]) {
//                [Answers logCustomEventWithName:@"Deal on Bump warning"
//                               customAttributes:@{
//                                                  @"trigger":@"instagram",
//                                                  @"message":text,
//                                                  @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
//                                                  }];
//                //present 'Send Offer' reminder alert
//                self.promptedBefore = YES;
//                self.offerReminderMode = YES;
//                self.emailReminderMode = YES;
//                [self showCustomAlert];
//                return;
//            }
//
//            //big cartel
//            if ([[string lowercaseString] containsString:@".bigcartel"]) {
//                [Answers logCustomEventWithName:@"Deal on Bump warning"
//                               customAttributes:@{
//                                                  @"trigger":@"bigcartel",
//                                                  @"message":text,
//                                                  @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
//                                                  }];
//                //present 'Send Offer' reminder alert
//                self.promptedBefore = YES;
//                self.offerReminderMode = YES;
//                self.emailReminderMode = YES;
//                [self showCustomAlert];
//                return;
//            }
//        }
//        if ([text containsString:@"your number"]) {
//            [Answers logCustomEventWithName:@"Deal on Bump warning"
//                           customAttributes:@{
//                                              @"trigger":@"phone number",
//                                              @"message":text,
//                                              @"buyer":[NSNumber numberWithBool:self.userIsBuyer]
//                                              }];
//            //present 'Send Offer' reminder alert
//            self.promptedBefore = YES;
//            self.offerReminderMode = YES;
//            self.emailReminderMode = YES;
//            [self showCustomAlert];
//            return;
//        }
//    }
    
    //for instant reload in inbox after tapping send, pass the sent message back to inboxVC
    if (self.paypalMessage) {
        [self.delegate lastMessageInConvo:@"You sent your PayPal 💰" incomingMsg:NO];
    }
    else{
        [self.delegate lastMessageInConvo:[NSString stringWithFormat:@"You: %@", text] incomingMsg:NO];
    }
    
    //hide intro paypal view
    if (self.paypalView && self.messages.count == 0) {
        [self removePayPalView];
    }
    
    NSString *messageString = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.sentPush = NO;
    
    JRMessage *message = [[JRMessage alloc] initWithSenderId:senderId
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
    
    if (self.paypalMessage == YES) {
        messageObject[@"paypalMessage"] = @"YES";
        message.isPayPal = YES;
        self.paypalMessage = NO;
        
        self.paypalSentCounter++;
        if (self.paypalSentCounter >= 3) {
            //stop this message appearing when send more messages
            [self.messages removeObject:message];
            
            //prevent user tapping paypal button infinite times
            [Answers logCustomEventWithName:@"PayPal Spamming Detected"
                           customAttributes:@{
                                              @"username":[PFUser currentUser].username
                                              }];
            return;
        }
    }
    
    messageObject[@"mediaMessage"] = @"NO";
    [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded == YES) {
            
            //add last sent message string to nsuserdefaults (only if not a suggested message)
            //then if all 5 in array are the same string ban this user from messaging
            NSMutableArray *sentArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"sentArray"]];
            
            //check if message string is a suggested message first
            if (![self.suggestedMessagesArray containsObject:[messageString lowercaseString]]) {
                [sentArray addObject:[messageString lowercaseString]];
                
                if (sentArray.count >= 10) {
                    //check if the messages are the same
                    [sentArray removeObject:[messageString lowercaseString]];
                    
                    if (sentArray.count == 0) {
                        //user has sent 5 of the same message! Just track in Fabric for now
                        [Answers logCustomEventWithName:@"Spam messages detected"
                                       customAttributes:@{
                                                          @"username":[PFUser currentUser].username
                                                          }];
                        //calc an expiry date
                        //then add to restricted messaging list (via cloudcode)
                    }
                }
                else{
                    //save nsuser defaults with updated array
                    [[NSUserDefaults standardUserDefaults] setObject:sentArray forKey:@"sentArray"];
                }
            }
            
            [Answers logCustomEventWithName:@"Message Sent"
                           customAttributes:@{
                                              @"Success":@"YES"
                                              }];
            
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
            
            //reset deletion keys so a previously deleted convo can appear in inbox since there's unseen messages there
            [self.convoObject setObject:@"NO" forKey:@"sellerDeleted"];
            [self.convoObject setObject:@"NO" forKey:@"buyerDeleted"];
            
            [self.convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded){
                    //sent a message so force reload in inbox VC
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:nil];
//                    [self.delegate lastMessageInConvo:nil];
                    
                    //if its the first message in the convo that the user has sent, prompt for a review
                    if ([[self.convoObject objectForKey:@"totalMessages"]intValue] ==1) {
                        [self reviewPrompt];
                    }
                }
                else{
                    NSLog(@"error with conv %@", error);
                }
            }];
            
            NSString *pushText;
            
            if (self.paypalPush == YES) {
                pushText = [NSString stringWithFormat:@"@%@ sent their PayPal. Pay now 🛒", [[PFUser currentUser]username]];
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
            
            [Answers logCustomEventWithName:@"Message Sent"
                           customAttributes:@{
                                              @"Success":@"NO"
                                              }];
            
            NSLog(@"error sending message %@", error);
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Error sending message" message:@"Make sure you're connected to the internet" preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }];
    
    //remove duplicates
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:self.messages];
    NSArray *arrayWithoutDuplicates = [orderedSet array];
    [self.messages removeAllObjects];
    [self.messages addObjectsFromArray:arrayWithoutDuplicates];
    
    [self finishSendingMessageAnimated:YES];
    
    //reset carousel origin
    [self resetCarouselHeight];
    
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
    
//    if (self.fixInsets) {
//        NSLog(@"scroll!");
//        if (self.collectionView.contentSize.height > self.collectionView.frame.size.height) {
////            [self.collectionView setContentOffset: CGPointMake(0, self.collectionView.contentSize.height- self.collectionView.frame.size.height + self.inputToolbar.bounds.size.height)];
//        }
//    }
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    
    NSString *blankString = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([blankString isEqualToString:@""] && [text isEqualToString:@"\n"]) {
        //stop user just hitting return loads of times
        return NO;
    }
    
    return YES;
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
        
        [self resetCarouselHeight];

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
    
    //if convo created from a profile then let both users see max. alertsheet options
    if (self.userIsBuyer == NO || self.profileConvo == YES) {
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Take a picture tapped"
                           customAttributes:@{
                                              @"where":@"MessageVC"
                                              }];
            
            CameraController *vc = [[CameraController alloc]init];
            vc.delegate = self;
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
        
//        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Send Pics from my Depop" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            BOOL seen = [[NSUserDefaults standardUserDefaults] boolForKey:@"seenDepop"];
//            if (!seen) {
//                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Send Pics from your Depop" message:@"When you have the images of the items you'd like to send in the middle of your screen, hit 'Screenshot'!" preferredStyle:UIAlertControllerStyleAlert];
//                [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//                    [self showDepop];
//                }]];
//                [self presentViewController:alertView animated:YES completion:nil];
//                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenDepop"];
//            }
//            else{
//                [self showDepop];
//            }
//        }]];
    }
    
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
                               targetSize:PHImageManagerMaximumSize //was PHImageManagerMaximumSize CGSizeMake(750, 750)
                              contentMode:PHImageContentModeDefault
                                  options:requestOptions
                            resultHandler:^void(UIImage *image, NSDictionary *info) {
                                //new policy: all resizing done in finalImage, instead of scattered
                                
                                if (image.CGImage == nil || image == nil) {
                                    [Answers logCustomEventWithName:@"Image Error: CGImage is nil from Asset"
                                                   customAttributes:@{
                                                                      @"pageName":@"MessageVC"
                                                                      }];
                                    [self showAlertWithTitle:@"Image Error" andMsg:@"If this problem persists, screenshot the picture and resend!\n\nThe original may be too big to send"];
                                    return;
                                }
                                
                                [self.imagesToProcess addObject:image]; ///////////////CRASH HERE
                                [self.placeholderAssetArray addObject:asset];
                                
                                
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

-(void)showDepop{
//    if ([[PFUser currentUser]objectForKey:@"depopHandle"]) {
//        //has added their depop handle
//        NSString *handle = [[PFUser currentUser]objectForKey:@"depopHandle"];
//        NSString *URLString = [NSString stringWithFormat:@"http://depop.com/%@",handle];
//        self.webViewController = nil;
//        self.webViewController = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
//        self.webViewController.title = [NSString stringWithFormat:@"%@", handle];
//        self.webViewController.showUrlWhileLoading = NO;
//        self.webViewController.showPageTitles = NO;
//        self.webViewController.delegate = self;
//        self.webViewController.depopMode = YES;
//        self.webViewController.doneButtonTitle = @"";
//        self.webViewController.infoMode = NO;
//        NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webViewController];
//        [self presentViewController:navigationController animated:YES completion:nil];
//    }
//    else{
//        //hasn't added handle, prompt to do so
//        [self showAlertWithTitle:@"No Depop Username added" andMsg:@"Add your Depop Username in Settings on Bump and you'll be able to add images of items you've already listed on there without leaving your conversation #zerofees"];
//    }
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
//    self.webViewController.infoMode = NO;
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
    self.webViewController.doneButtonTitle = @"";
    self.webViewController.infoMode = YES;
    
    if ([self.otherUser objectForKey:@"paypal"]) {
        self.webViewController.infoMode = YES;
    }
    else{
        self.webViewController.infoMode = NO;
    }
    
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)finalImage:(UIImage *)image{
    
//    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    [self.delegate lastMessageInConvo:@"You sent a photo 📷" incomingMsg:NO];

    
    //some users still aren't able to send certain images
    //think its related to this SO answer:
    
    //UIImageJPEGRepresentation seems to use the CGImage property of the UIImage. Problem is, that when you initialize the UIImage with a CIImage, that property is nil.
    
    //in meantime, used another solution - creates a copy of the image (assumes the image is not nil before resizing) and then gets data from that
    
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
    JRMessage *photoMessage = [JRMessage messageWithSenderId:self.senderId
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
        [self showAlertWithTitle:@"Image Error" andMsg:@"Something went wrong getting your image, please try sending another picture!"];
        return;
    }
    
    PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:data];
    
    PFObject *picObject = [PFObject objectWithClassName:@"messageImages"];
    [picObject setObject:filePicture forKey:@"Image"];
    [picObject setObject:self.convoObject forKey:@"convo"];
    [self.convoImagesArray addObject:picObject];

    [picObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            
            [Answers logCustomEventWithName:@"Sent picture message"
                           customAttributes:@{
                                              @"where":@"MessagesVC"
                                              }];

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
            //set msg object so photo is tagged
            photoMessage.msgObject = self.messageObject;
            
            [self.messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //set as last message sent
                    self.lastMessage = self.messageObject;
                    
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
                            [Answers logCustomEventWithName:@"Push Sent"
                                           customAttributes:@{
                                                              @"Type":@"Image Message"
                                                              }];
                        }
                        else{
                            NSLog(@"image push error %@", error);
                        }
                    }];
                    
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
//                            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:nil];
                        }
                        else{
                            NSLog(@"error saving convo in final image %@", error);
                            [Answers logCustomEventWithName:@"Error Saving Convo in Final Image"
                                           customAttributes:@{
                                                              @"where":@"MessagesVC"
                                                              }];
                        }
                    }];
                }
                else{
                    [self showAlertWithTitle:@"Error sending message" andMsg:[NSString stringWithFormat:@"Make sure you're connected to the internet %ld", (long)error.code]];
                    [Answers logCustomEventWithName:@"Error Saving Picture message"
                                   customAttributes:@{
                                                      @"where":@"MessagesVC",
                                                      @"error":error
                                                      }];
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
            [self showAlertWithTitle:@"Error sending image" andMsg:[NSString stringWithFormat:@"Make sure you're connected to the internet %ld", (long)error.code]];
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
    
    JRMessage *message = self.messages[indexPath.item];
    
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
    JRMessage *message = [self.messages objectAtIndex:indexPath.item];
    
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
        JRMessage *message = [self.messages objectAtIndex:indexPath.item];
        NSAttributedString *finalStamp = [[NSAttributedString alloc]initWithString:[[[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date] string] attributes:textAttributes];
        return finalStamp;
    }
    else{
        //get previous message
        JRMessage *previousMessage = [self.messages objectAtIndex:indexPath.item-1];
        JRMessage *message = [self.messages objectAtIndex:indexPath.item];
        
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
//        JRMessage *message = [self.messages objectAtIndex:indexPath.item];
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
    
    JRMessage *msg = [self.messages objectAtIndex:indexPath.item];
    
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
        
        //from iOS 11 saw the cell was picking up textview behaviour over cell taps so disable that
        cell.textView.userInteractionEnabled = NO;
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
        JRMessage *previousMessage = [self.messages objectAtIndex:indexPath.item-1];
        JRMessage *message = [self.messages objectAtIndex:indexPath.item];
        
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
//    JRMessage *currentMessage = [self.messages objectAtIndex:indexPath.item];
//    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
//        return 0.0f;
//    }
//    
//    if (indexPath.item - 1 > 0) {
//        JRMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
//        if ([[previousMessage senderId isEqualToString:[currentMessage senderId]]) {
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

    JRMessage *tappedMessage = [self.messages objectAtIndex:indexPath.item];
    
    NSLog(@"tapped message %@", tappedMessage);
    
    if ([[self.messages objectAtIndex:indexPath.item] isMediaMessage] == YES && tappedMessage.isShared == NO){
        
        [Answers logCustomEventWithName:@"Tapped Image in Convo"
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
    else if (tappedMessage.isPurchased == YES){
    }
    else if(tappedMessage.isShared == YES){
        if (tappedMessage.saleShare == YES) {
            
            NSLog(@"sale share!");
            
            [Answers logCustomEventWithName:@"Tapped Shared Listing"
                           customAttributes:@{
                                              @"mode":@"SALE"
                                              }];
            
            //if version lower than 1158 then don't execute
            NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            int buildNumber = [appVersion intValue];
            if (buildNumber < 1158) {
                //prompt to update
                [self showAlertWithTitle:@"Update" andMsg:@"Update your app version to view this for sale item shared with you!"];
            }
            else{
                ForSaleListing *vc = [[ForSaleListing alloc]init];
                vc.listingObject = tappedMessage.sharedListing;
                vc.source = @"share";
                vc.pureWTS = YES;
                vc.fromBuyNow = YES;
                vc.seller = [tappedMessage.sharedListing objectForKey:@"sellerUser"];
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
        else{
            
            NSLog(@"wanted share!");

            
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
            [self showAlertWithTitle:@"Update" andMsg:@"Update your app version to pay faster on BUMP!"];
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
    NSLog(@"should paste");
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *string = pasteboard.string;
    if (string) {
        return YES;
    }
    else{
        return NO;
    }

    return YES;
}
-(void)profileTapped{
    if (self.otherUser && self.profileBTapped == NO) {
        self.somethingTapped = YES;
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
        vc.source = @"messages";
        vc.pureWTS = YES;
        vc.fromBuyNow = YES;
        vc.seller = [self.listing objectForKey:@"sellerUser"];
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
        [UIView animateWithDuration:0.3
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

//for infinite load of messages

//-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    
////    float edge = scrollView.contentOffset.y + scrollView.frame.size.height;
//    
//    float scrollOffset = scrollView.contentOffset.y;
//    NSLog(@"offset: %f", scrollOffset);
//    
//    if (scrollOffset <= 0 - self.navigationController.navigationBar.frame.size.height){
//        
//        if (self.infiniteLoading != YES && self.finishedFirstScroll == YES && self.moreToLoad == YES) {
//            self.infiniteLoading = YES;
////            NSLog(@"GONNA INFIN LOAD");
//            
//            self.earlierPressed = YES;
//            [self loadMessages];
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
            self.customAlert.titleLabel.text = @"Buying on BUMP";
            self.customAlert.messageLabel.text = @"Build your reputation, stay protected & pay ZERO BUMP fees. Hit the Buy Button on listings to purchase an item";
            self.customAlert.numberOfButtons = 1;
        }
        else{
            if (self.emailReminderMode == YES) {
                self.customAlert.messageLabel.text = @"Build your reputation, stay protected & get paid with PayPal. Tap 'Send PayPal email' to get paid even faster!";
//                self.customAlert.numberOfButtons = 2;
//                [self.customAlert.secondButton setTitle:@"Send PayPal email" forState:UIControlStateNormal];
            }
            else{
                self.customAlert.messageLabel.text = @"Build your reputation, stay protected & get paid with PayPal. Tap the image icon to send photos";
                self.customAlert.numberOfButtons = 1;
            }
            self.customAlert.titleLabel.text = @"Selling on BUMP";
        }
        
        [self.customAlert.doneButton setTitle:@"D I S M I S S" forState:UIControlStateNormal];
        [self.customAlert.doneButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
        [self.customAlert.doneButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];

    }
    else{
        self.customAlert.titleLabel.text = @"Permssion Needed";
        self.customAlert.messageLabel.text = @"Tap to goto Settings & enable BUMP's Photos Permission";
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
    [self donePressed];

    if (self.emailReminderMode == YES) {
        self.emailReminderMode = NO;
        
        [Answers logCustomEventWithName:@"Send PayPal email Reminder Success"
                       customAttributes:@{}];

        //send my paypal tapped
        if (![[[PFUser currentUser]objectForKey:@"paypalUpdated"]isEqualToString:@"YES"]) {
            //show paypal alert to confirm
            [self showPayPalAlert];
        }
        else{
            NSString *messageString = [NSString stringWithFormat:@"@%@ sent their PayPal email %@",[PFUser currentUser].username,[[PFUser currentUser] objectForKey:@"paypal"]];
            UIButton *button = [[UIButton alloc]init];
            self.paypalMessage = YES;
            self.paypalPush = YES;
            [self didPressSendButton:button withMessageText:messageString senderId:self.senderId senderDisplayName:self.senderDisplayName date:[NSDate date]];
        }
    }
    else{
        [Answers logCustomEventWithName:@"Settings pressed - photos permission needed"
                       customAttributes:@{}];
        
        //goto settings
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
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
    else if ([[self.suggestedMessagesArray objectAtIndex:index] isEqualToString:@"Send PayPal email"]) {
        messageLabel.text = [self.suggestedMessagesArray objectAtIndex:index];
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.backgroundColor = [UIColor colorWithRed:0.42 green:0.42 blue:0.84 alpha:1.0];
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
//    else if ([messageString isEqualToString:@"Send PayPal email"]){
//
//        if (![[[PFUser currentUser]objectForKey:@"paypalUpdated"]isEqualToString:@"YES"]) {
//            //show paypal alert to confirm
//            [self showPayPalAlert];
//        }
//        else{
//            NSString *messageString;
//
//            //this is in case user has updated paypal but for some reason it hasn't saved immediately
//            if (self.updatedPayPal) {
//                messageString = [NSString stringWithFormat:@"@%@ sent their PayPal email %@",[PFUser currentUser].username,self.updatedPayPal];
//            }
//            else{
//                messageString = [NSString stringWithFormat:@"@%@ sent their PayPal email %@",[PFUser currentUser].username,[[PFUser currentUser] objectForKey:@"paypal"]];
//            }
//
//            [self.convoObject setObject:@"YES" forKey:@"paypalSent"];
//            [self.convoObject saveInBackground];
//
//            UIButton *button = [[UIButton alloc]init];
//            self.paypalMessage = YES;
//            self.paypalPush = YES;
//            [self didPressSendButton:button withMessageText:messageString senderId:self.senderId senderDisplayName:self.senderDisplayName date:[NSDate date]];
//        }
//    }
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
    
    if (self.paypalView) {
        [self hidePayPalView];
    }

    [self resetCarouselHeight];

}

-(void)keyboardOFFScreen:(NSNotification *)notification
{
    NSLog(@"KEYBOARD WILL HIDE 1");
    
    if (self.changeKeyboard == NO) {
        return;
    }
    
    //need to reset insets on iOS 11 since scroll view has some new properties which mess up insets after keyboard displayed
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    }
    
    if (self.shouldShowPayPalView && self.paypalView) {
        [self showPayPalView];
    }
    
    [self resetCarouselHeight];



}

-(void)goneToBackground{
    //block further keyboard changes
//    self.changeKeyboard = NO;

}

-(void)comeBackToForeground{
    self.changeKeyboard = YES;
}

//review tapped
-(void)gotoReview{
    self.somethingTapped = YES;
    
//CHANGE
}

-(void)leftReview{
    self.justLeftReview = YES;
    NSMutableArray *currentItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    [currentItems removeObject:self.reviewButton];
    [self.navigationItem setRightBarButtonItems:currentItems];
    self.reviewButton = nil;
}

-(void)reviewPrompt{
    
    PFUser *current = [PFUser currentUser];

    if ([current objectForKey:@"reviewDate"]) {
        //has reviewed before
        //check the version then time diff
        
        NSString *reviewedVersion = [current objectForKey:@"versionReviewed"];
        NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
        if ([reviewedVersion isEqualToString:currentVersion]) {
            //already reviewed this version
            [self invitePrompt];
        }
        else{
            //never reviewed this version, check if last review was later than 14 days ago
            NSDate *lastReviewDate = [current objectForKey:@"reviewDate"];
            
            //check difference between 2 dates
            NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:lastReviewDate];
            double secondsInADay = 86400;
            NSInteger daysBetweenDates = distanceBetweenDates / secondsInADay;
            
//            NSLog(@"DAYS SINCE LAST REVIEW: %ld", daysBetweenDates);
            
            if (daysBetweenDates >= 21) {
                //prompt again
                [self triggerRate];
            }
            else{
                //rated in past 14 days already so don't show
                [self invitePrompt];
            }
        }
    }
    else{
        //never been asked to review so prompt
        [self triggerRate];
    }
}

-(void)invitePrompt{
    PFUser *current = [PFUser currentUser];
    
    NSDate *lastReviewDate = [current objectForKey:@"reviewDate"];
    NSTimeInterval distanceBetweenReviewDates = [[NSDate date] timeIntervalSinceDate:lastReviewDate];
    double secondsInADay = 86400;
    NSInteger daysBetweenReviewDates = distanceBetweenReviewDates / secondsInADay;
    
    if ([current objectForKey:@"inviteDate"]) {
        //has seen invite dialog before
        //check when last shown
        
        //check if last invite prompt was later than 14 days ago
        NSDate *lastInviteDate = [current objectForKey:@"inviteDate"];
        
        //check difference between 2 dates
        NSTimeInterval distanceBetweenInviteDates = [[NSDate date] timeIntervalSinceDate:lastInviteDate];
        NSInteger daysBetweenInviteDates = distanceBetweenInviteDates / secondsInADay;
        
        //also check if user was prompted to review more than a day ago, don't want to bombard them
        if (daysBetweenInviteDates >= 14 && daysBetweenReviewDates > 1) {
            //prompt again
            [self triggerInvite];
        }
        else{
            //invite seen in past 14 days already or review was shown in past day too - so don't show
        }
    }
    else{
        if (daysBetweenReviewDates > 1) {
            //never been asked to review so prompt (only if haven't been asked to review recently)
            [self triggerInvite];
        }
    }
}

-(void)triggerRate{
    //hide keyboard before presenting invite dialog
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    [Answers logCustomEventWithName:@"Show Rate"
                   customAttributes:@{
                                      @"where": @"messagesVC"
                                      }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showRate" object:self.navigationController];
    
}

-(void)triggerInvite{
    [Answers logCustomEventWithName:@"Asked to invite in messages"
                   customAttributes:@{}];
    
    //hide keyboard before presenting invite dialog
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showInvite" object:nil];
}

-(void)setupPayPalView{
    //setup intro PayPal message header
    self.paypalView = [[UIView alloc]init];
    [self.paypalView setFrame:CGRectMake(0,0, 300, 200)];    

    //paypal logo
    UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(self.paypalView.frame.size.width/2-50,20, 100, 26)];
    [imgView setImage:[UIImage imageNamed:@"paypalLogo"]];
    [self.paypalView addSubview:imgView];
    
    //paypal message
    UILabel *introLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,imgView.frame.origin.y+20, 300, 180)];
    introLabel.text = @"Stay protected & build your reputation by purchasing through BUMP\n\nWhen you're ready to Purchase just hit the Buy Button on the listing and pay through PayPal\n\nNote: you are NOT covered when trading or sending a gift/friends & family payment on PayPal\n\nIf you're still unsure check out our FAQs in Settings";
    introLabel.numberOfLines = 0;
    [introLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:12]];
    introLabel.textAlignment = NSTextAlignmentCenter;
    introLabel.textColor = [UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0];
    [self.paypalView addSubview:introLabel];
    
//    [self.paypalView setBackgroundColor:[UIColor redColor]];

    [self.view addSubview:self.paypalView];
    
    self.paypalView.center = CGPointMake(CGRectGetMidX([[UIScreen mainScreen]bounds]), CGRectGetMidY([[UIScreen mainScreen]bounds])-(50.0+self.inputToolbar.frame.size.height));
    
    //TEST ON DIFFERENT SCREEN SIZES!!!!

    
    
    self.shouldShowPayPalView = YES;
}

-(void)removePayPalView{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.paypalView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         self.paypalView = nil;
                         self.shouldShowPayPalView = NO;
                     }];
}
-(void)hidePayPalView{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.paypalView.alpha = 0.0;
                     }
                     completion:nil];
}

-(void)showPayPalView{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.paypalView.alpha = 1.0;
                     }
                     completion:nil];
}

#pragma mark - for sale listing preview banner
-(void)showListingBanner{
    if (self.listingBannerShowing == YES) {
        return;
    }
    
    NSLog(@"SHOW LISTING BANNER");

    if (!self.listingView) {
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"listingBannerViewFile" owner:self options:nil];
        self.listingView = (ListingBannerView *)[nib objectAtIndex:0];
        self.listingView.delegate = self;
        
        [self.listing fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {

                [self.listingView.itemImageView setFile:[self.listing objectForKey:@"thumbnail"]];
                [self.listingView.itemImageView loadInBackground];
                
                if ([self.listing objectForKey:@"itemTitle"]) {
                    self.listingView.itemTitleLabel.text = [self.listing objectForKey:@"itemTitle"];
                }
                else{
                    self.listingView.itemTitleLabel.text = [self.listing objectForKey:@"description"];
                }
                
                float price = [[self.listing objectForKey:[NSString stringWithFormat:@"salePrice%@", self.currency]]floatValue];
                self.listingView.priceLabel.text = [NSString stringWithFormat:@"%@%.0f",self.currencySymbol ,price];
            }
            else{
                [self showAlertWithTitle:@"Error fetching listing" andMsg:@"Make sure you have a good internet connection!"];
            }
        }];
    }
    
    [self.listingView setFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20,[UIApplication sharedApplication].keyWindow.frame.size.width, 80)];
    
//    if (@available(iOS 11.0, *)) {
//        if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
//            //iPhone7 - done
//            [self.listingView setFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20, [UIApplication sharedApplication].keyWindow.frame.size.width, 15)];
//        }
//        else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
//            //iPhone 7 plus
//            [self.listingView setFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20,[UIApplication sharedApplication].keyWindow.frame.size.width, 15)];
//        }
//        else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
//            //iPhone SE
//            [self.listingView setFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20,375, 15)];
//        }
//        else{
//            //fall back
//            [self.listingView setFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20, [UIApplication sharedApplication].keyWindow.frame.size.width, 15)];
//        }
//    }
//    else{
//        NSLog(@"not 11 ");
//
//        if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
//            //iPhone7 - done
//            [self.listingView setFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20, [UIApplication sharedApplication].keyWindow.frame.size.width, 30)];
//        }
//        else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
//            //iPhone 7 plus
//            NSLog(@"6/7 plus ");
//
//
////            [self.listingView setNeedsLayout];
//        }
//        else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
//            //iPhone SE
//            [self.listingView setFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20,375, 129)];
//        }
//        else{
//            //fall back
//            [self.listingView setFrame:CGRectMake(0,self.navigationController.navigationBar.frame.size.height+20, [UIApplication sharedApplication].keyWindow.frame.size.width, 15)];
//        }
//    }
    
    [self.view addSubview:self.listingView];

//    NSLog(@"listing view %@", NSStringFromCGRect(self.listingView.frame));
    
    [self.listingView setAlpha:1.0];
    self.listingBannerShowing = YES;
    
    [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
    [self.collectionView reloadData];
    
}

-(void)bannerTapped{
    //goto for sale listing
    ForSaleListing *vc = [[ForSaleListing alloc]init];
    vc.listingObject = self.listing;
    vc.source = @"messages";
    vc.pureWTS = YES;
    vc.fromBuyNow = YES;
    [self.navigationController pushViewController:vc animated:YES];
    
}

-(void)sendDemoMessage{
    PFObject *messageObject = [PFObject objectWithClassName:@"messages"];

    NSString *messageString = @"";
    
    //ME: Still available? (message bubble)
    if (self.demoMessageNumber == 0) {
        //first message
        //sup g, are you interested
        messageString = @"Sup g, yeah still got it - interested?";
    }
    
    //ME: £XX all in?
    else if (self.demoMessageNumber == 1){
        //£XX and its a deal
        messageString = @"£40 and it's a deal";

    }
    else if (self.demoMessageNumber == 2){
        //sends paypal
        messageString = [NSString stringWithFormat:@"@%@ sent their PayPal email sup13@hotmail.com",self.otherUser.username];
        messageObject[@"paypalMessage"] = @"YES";

    }
    
    //then tap paypal

    //create message object

    messageObject[@"message"] = messageString;
    messageObject[@"sender"] = self.otherUser;
    messageObject[@"senderId"] = self.otherUser.objectId;
    messageObject[@"senderName"] = self.otherUser.username;
    messageObject[@"convoId"] = self.convoId;
    messageObject[@"status"] = @"sent";
    
    messageObject[@"mediaMessage"] = @"NO";
    [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [self loadNewMessages];
        }
        else{
            NSLog(@"error saving demo message %@", error);
        }
    }];
    
    
    
    self.demoMessageNumber++;
}

@end

