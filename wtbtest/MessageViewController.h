//
//  MessageViewController.h
//  
//
//  Created by Jack Ryder on 17/06/2016.
//
//

//#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "JSQMessages.h"
#import <Parse/Parse.h>
#import "CameraController.h"
#import <BASSquareCropperViewController.h>
#import "TOJRWebView.h"
#import "customAlertViewClass.h"
#import <QBImagePickerController/QBImagePickerController.h>
#import <SwipeView/SwipeView.h>
#import "FeedbackController.h"
#import <DGActivityIndicatorView.h>
#import "ListingBannerView.h"
#import "CheckoutSummary.h"

@class MessageViewController;

@protocol messagesDelegate <NSObject>
- (void)lastMessageInConvo:(NSString *)message incomingMsg:(BOOL)incoming;
@end

@interface MessageViewController : JSQMessagesViewController < CameraControllerDelegate, UICollectionViewDelegate, UIImagePickerControllerDelegate, BASSquareCropperDelegate, UINavigationControllerDelegate,JRWebViewDelegate, customAlertDelegate,QBImagePickerControllerDelegate, SwipeViewDelegate, SwipeViewDataSource, feedbackDelegate,bannerDelegate, JSQMessagesComposerTextViewPasteDelegate, CheckoutDelegate>

//basic setup
@property (nonatomic, strong) NSString *convoId;
@property (nonatomic, strong) NSString *otherUserName;
@property (nonatomic, strong) NSString *tagString;
@property (nonatomic, strong) PFObject *convoObject;
@property (nonatomic, strong) PFUser *otherUser;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) NSMutableArray *messageIds;
@property (nonatomic, strong) NSMutableArray *pictureMessages;

//carousel of suggested messages
@property (nonatomic, strong) SwipeView *carousel;
@property (nonatomic, strong) NSMutableArray *suggestedMessagesArray;
@property (nonatomic) BOOL showSuggested;
@property (nonatomic) BOOL changeKeyboard;
@property (nonatomic) BOOL paypalMessage;
@property (nonatomic) BOOL paypalPush;

//Bubble tings
@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *offerBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *waitingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *purchasedBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *sharedListingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImageFactory *bubbleFactory;
@property (nonatomic, strong) JSQMessagesMediaViewBubbleImageMasker *masker;

//load earlier messages
@property (nonatomic) int skipped;
@property (nonatomic) BOOL earlierPressed;

//for working out whats been seen
@property (nonatomic, strong) NSMutableArray *messagesParseArray;
@property (nonatomic, strong) NSMutableArray *sentMessagesParseArray;

//setup extra stuff
@property (nonatomic, strong) PFObject *listing;

//seller mode
@property (nonatomic) BOOL messageSellerPressed;
@property (nonatomic, strong) NSString *sellerItemTitle;

//nav bar buttons
@property (nonatomic, strong) UIBarButtonItem *profileButton;
@property (nonatomic, strong) UIBarButtonItem *listingButton;
@property (nonatomic, strong) UIBarButtonItem *reviewButton;

//seen labels for messages setup
@property (nonatomic, strong) PFObject *messageObject;
@property (nonatomic, strong) PFObject *lastMessage;

@property (nonatomic) BOOL userIsBuyer;
@property (nonatomic) BOOL profileBTapped;

@property (nonatomic) BOOL somethingTapped;
@property (nonatomic) float lastInputHeight;

//banners
@property (nonatomic) BOOL payBannerShowing;
@property (nonatomic, strong) UIView *paidView;
@property (nonatomic, strong) UIButton *paidButton;
@property (nonatomic) BOOL successBannerShowing;
@property (nonatomic, strong) UIView *successView;
@property (nonatomic, strong) UIButton *successButton;

//currency
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

//modes
@property (nonatomic) BOOL checkPayPalTapped;
@property (nonatomic) BOOL receivedNew;
@property (nonatomic) BOOL pureWTS;
@property (nonatomic) BOOL profileConvo;
@property (nonatomic) BOOL setOtherUserImage;

//just happened
@property (nonatomic) BOOL sentPush;
@property (nonatomic) BOOL savedSomin;
@property (nonatomic, strong) NSString *savedString;

//avatars
@property (nonatomic, strong) UIImage *otherUserImage;
@property (nonatomic, strong) JSQMessagesAvatarImage *avaImage;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic) BOOL offerReminderMode;
@property (nonatomic) BOOL emailReminderMode;
@property (nonatomic) BOOL promptedBefore;

//web
@property (nonatomic, strong) TOJRWebView *webViewController;

//delegate
@property (nonatomic, weak) id <messagesDelegate> delegate;

//convo images
@property (nonatomic, strong) NSMutableArray *convoImagesArray;

//tab bar
@property (nonatomic) int tabBarHeightInt;

//scroll
@property (nonatomic) BOOL firstLayout;
@property (nonatomic) float topEdge;
@property (nonatomic) BOOL infiniteLoading;
@property (nonatomic) BOOL finishedFirstScroll;
@property (nonatomic) BOOL moreToLoad;

//addImages
@property (nonatomic, strong) NSMutableArray *placeholderAssetArray;
@property (nonatomic, strong) NSMutableArray *imagesToProcess;

//spinner
@property (nonatomic, strong) DGActivityIndicatorView *spinner;
@property (nonatomic) BOOL showPull;

//paypal header
@property (nonatomic, strong) UIView *paypalView;
@property (nonatomic) BOOL shouldShowPayPalView;

//paypal popup
@property (nonatomic, strong) NSString *updatedPayPal;

//where is VC being pushed from
@property (nonatomic) BOOL fromLatest;
@property (nonatomic) BOOL fromOrder;

//for sale listing banner
@property (nonatomic) BOOL listingBannerShowing;
@property (nonatomic, strong) ListingBannerView *listingView;
@property (nonatomic) BOOL showingListingBanner;
@property (nonatomic) BOOL buyButtonOn;
@property (nonatomic) BOOL instantBuyDisabled;

@property (nonatomic) BOOL demoMode;
@property (nonatomic) int demoMessageNumber;

//review
@property (nonatomic) BOOL justLeftReview;

//ban mode for alert
@property (nonatomic) BOOL banMode;

//blocked mode
@property (nonatomic) int paypalSentCounter;

//refresh
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end
