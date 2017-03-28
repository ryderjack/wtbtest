//
//  MessageViewController.h
//  
//
//  Created by Jack Ryder on 17/06/2016.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "JSQMessages.h"
#import <Parse/Parse.h>
#import "CameraController.h"
#import <BASSquareCropperViewController.h>
#import "TOJRWebView.h"
#import "MakeOfferController.h"
#import <PulsingHaloLayer.h>
#import "customAlertViewClass.h"
#import <QBImagePickerController/QBImagePickerController.h>
#import <iCarousel.h>
#import <SwipeView/SwipeView.h>
#import "FeedbackController.h"

@class MessageViewController;

@protocol messagesDelegate <NSObject>
- (void)lastMessageInConvo:(PFObject *)message;
@end

@interface MessageViewController : JSQMessagesViewController <JSQMessagesComposerTextViewPasteDelegate, CameraControllerDelegate, UICollectionViewDelegate, UIImagePickerControllerDelegate, BASSquareCropperDelegate, UINavigationControllerDelegate,JRWebViewDelegate, MakeOfferDelegate, customAlertDelegate,QBImagePickerControllerDelegate, UITextViewDelegate, SwipeViewDelegate, SwipeViewDataSource, feedbackDelegate>

//basic setup
@property (nonatomic, strong) NSString *convoId;
@property (nonatomic, strong) NSString *otherUserName;
@property (nonatomic, strong) NSString *tagString;
@property (nonatomic, strong) PFObject *convoObject;
@property (nonatomic, strong) PFUser *otherUser;
@property (nonatomic, strong) NSMutableArray *messages;
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

//modes
@property (nonatomic) BOOL offerMode;
@property (nonatomic) BOOL fromForeGround;

//setup extra stuff
@property (nonatomic, strong) PFObject *listing;
@property (nonatomic, strong) PFObject *offerObject;

//seller mode
@property (nonatomic) BOOL messageSellerPressed;
@property (nonatomic, strong) NSString *sellerItemTitle;

//nav bar buttons
@property (nonatomic, strong) UIBarButtonItem *profileButton;
@property (nonatomic, strong) UIBarButtonItem *listingButton;

//seen labels for messages setup
@property (nonatomic, strong) PFObject *messageObject;
@property (nonatomic, strong) PFObject *lastMessage;

@property (nonatomic) BOOL userIsBuyer;
@property (nonatomic) BOOL profileBTapped;

//banners
@property (nonatomic) BOOL payBannerShowing;
@property (nonatomic, strong) UIView *paidView;
@property (nonatomic, strong) UIButton *paidButton;
@property (nonatomic) BOOL successBannerShowing;
@property (nonatomic, strong) UIView *successView;
@property (nonatomic, strong) UIButton *successButton;
@property (nonatomic) BOOL infoBannerShowing;
@property (nonatomic, strong) UIView *infoView;

//offers and checkout
@property (nonatomic) BOOL checkoutTapped;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;
@property (nonatomic) BOOL checkPayPalTapped;

@property (nonatomic) BOOL receivedNew;

//modes
@property (nonatomic) BOOL pureWTS;
@property (nonatomic) BOOL profileConvo;

//just happened
@property (nonatomic) BOOL sentPush;
@property (nonatomic) BOOL savedSomin;
@property (nonatomic, strong) NSString *savedString;

//avatars
@property (nonatomic, strong) UIImage *otherUserImage;
@property (nonatomic, strong) JSQMessagesAvatarImage *avaImage;

//pulsating tag
@property (nonatomic, strong) PulsingHaloLayer *halo;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic) BOOL offerReminderMode;
@property (nonatomic) BOOL promptedBefore;

//web
@property (nonatomic, strong) TOJRWebView *webViewController;

//delegate
@property (nonatomic, weak) id <messagesDelegate> delegate;

//convo images
@property (nonatomic, strong) NSMutableArray *convoImagesArray;

//tab bar
@property (nonatomic, strong) NSNumber *tabBarHeight;
@property (nonatomic) int tabBarHeightInt;

//readjust carousel height based on text input
@property (nonatomic) float lastInputToolbarHeight;
@property (nonatomic) BOOL movingCarousel;

//scroll
@property (nonatomic) BOOL firstLayout;
@property (nonatomic) float topEdge;


@end
