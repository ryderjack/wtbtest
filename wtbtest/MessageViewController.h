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
#import "GMImagePickerController.h"
#import <TOWebViewController.h>
#import "MakeOfferController.h"
#import <PulsingHaloLayer.h>
#import "customAlertViewClass.h"


@interface MessageViewController : JSQMessagesViewController <JSQMessagesComposerTextViewPasteDelegate, CameraControllerDelegate, UICollectionViewDelegate, UIImagePickerControllerDelegate, BASSquareCropperDelegate, UINavigationControllerDelegate, GMImagePickerControllerDelegate,TOWebDelegate, MakeOfferDelegate, customAlertDelegate>

@property (nonatomic, strong) NSString *convoId;
@property (nonatomic, strong) NSString *otherUserName;
@property (nonatomic, strong) NSString *tagString;

@property (nonatomic, strong) PFObject *convoObject;
@property (nonatomic, strong) PFUser *otherUser;

@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *offerBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *waitingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *purchasedBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImageFactory *bubbleFactory;
@property (nonatomic, strong) JSQMessagesMediaViewBubbleImageMasker *masker;

@property (nonatomic) int skipped;
@property (nonatomic) BOOL earlierPressed;

@property (nonatomic, strong) NSMutableArray *messagesParseArray;
@property (nonatomic, strong) NSMutableArray *sentMessagesParseArray;

@property (nonatomic) BOOL offerMode;
@property (nonatomic) BOOL fromForeGround;

@property (nonatomic, strong) PFObject *listing;
@property (nonatomic, strong) PFObject *offerObject;

@property (nonatomic) BOOL sellThisPressed;

@property (nonatomic) BOOL messageSellerPressed;
@property (nonatomic, strong) NSString *sellerItemTitle;

@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *profileButton;
@property (nonatomic, strong) UIBarButtonItem *listingButton;

@property (nonatomic, strong) PFObject *messageObject;
@property (nonatomic, strong) PFObject *lastMessage;

@property (nonatomic) BOOL userIsBuyer;
@property (nonatomic) BOOL profileBTapped;

@property (nonatomic) BOOL payBannerShowing;
@property (nonatomic, strong) UIView *paidView;
@property (nonatomic, strong) UIButton *paidButton;

@property (nonatomic) BOOL successBannerShowing;
@property (nonatomic, strong) UIView *successView;
@property (nonatomic, strong) UIButton *successButton;

@property (nonatomic) BOOL infoBannerShowing;
@property (nonatomic, strong) UIView *infoView;

@property (nonatomic) BOOL checkoutTapped;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (nonatomic) BOOL checkPayPalTapped;

@property (nonatomic) BOOL receivedNew;

@property (nonatomic, strong) TOWebViewController *webViewController;

@property (nonatomic) BOOL pureWTS;
@property (nonatomic) BOOL profileConvo;

@property (nonatomic) BOOL sentPush;

@property (nonatomic) BOOL savedSomin;
@property (nonatomic, strong) NSString *savedString;

@property (nonatomic, strong) UIImage *otherUserImage;
@property (nonatomic, strong) JSQMessagesAvatarImage *avaImage;

@property (nonatomic, strong) PulsingHaloLayer *halo;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;

@end
