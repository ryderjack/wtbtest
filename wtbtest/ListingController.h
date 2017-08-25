//
//  ListingController.h
//  
//
//  Created by Jack Ryder on 03/03/2016.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import <DGActivityIndicatorView.h>
#import <iCarousel.h>
#import "DetailImageController.h"
#import "SendDialogBox.h"
#import <FBSDKShareKit/FBSDKShareKit.h>
#import "customAlertViewClass.h"
#import "CreateSuccessView.h"
#import "CreateViewController.h"
#import "inviteViewClass.h"
#import "boostController.h"
#import "ForSaleListing.h"
#import "BumpingIntroVC.h"

@class ListingController;

@protocol ListingControllerDelegate <NSObject>
- (void)addItemViewController:(ListingController *)controller listing:(PFObject *)object;
- (void)deletedWantedItem;
- (void)changedPurchasedStatus; //could mark as purchased or unpurchased
-(void)likedWantedItem;
@end

@interface ListingController : UITableViewController <iCarouselDataSource, iCarouselDelegate, DetailImageDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, FBSDKAppInviteDialogDelegate, customAlertDelegate, successDelegate, CreateViewControllerDelegate,inviteDelegate,boostDelegate,UIViewControllerTransitioningDelegate, ForSaleListingDelegate,BumpingIntroDelegate>

@property (nonatomic, weak) id <ListingControllerDelegate> delegate;
@property (nonatomic, strong) PFObject *listingObject;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *mainCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *payCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sizeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *conditionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *locationCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *deliveryCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *extraCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *adminCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buyerinfoCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buttonCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *carouselMainCell;

//main cell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIPageControl *picIndicator;

@property (weak, nonatomic) IBOutlet PFImageView *picView;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *deliveryLabel;
@property (weak, nonatomic) IBOutlet UILabel *extraLabel;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *postedLabel;

//buyer info
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;
@property (weak, nonatomic) IBOutlet UILabel *buyernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *pastDealsLabel;
@property (weak, nonatomic) IBOutlet PFImageView *buyerImgView;
@property (weak, nonatomic) IBOutlet UIButton *buyerButton;
@property (weak, nonatomic) IBOutlet PFImageView *checkImageView;

@property (nonatomic, strong) PFFile *firstImage;
@property (nonatomic, strong) PFFile *secondImage;
@property (nonatomic, strong) PFFile *thirdImage;
@property (nonatomic, strong) PFFile *fourthImage;
@property (nonatomic) int numberOfPics;

@property (nonatomic, strong) PFUser *buyer;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) DGActivityIndicatorView *imageSpinner;
@property (nonatomic, strong) MBProgressHUD *imageHud;

//purchased
@property (weak, nonatomic) IBOutlet UILabel *purchasedLabel;
@property (weak, nonatomic) IBOutlet UIImageView *purchasedCheckView;

//upvote
@property (weak, nonatomic) IBOutlet UIButton *upVoteButton;
@property (weak, nonatomic) IBOutlet UIButton *viewBumpsButton;

//search
@property (nonatomic) BOOL fromSearch;
@property (nonatomic) BOOL modalMode;

//modes
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic) BOOL editModePressed;

//profileButton
@property (nonatomic, strong) UIBarButtonItem *profileButton;

//big button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;
@property (nonatomic) BOOL barButtonPressed;

//carousel Cell
@property (weak, nonatomic) IBOutlet iCarousel *carouselView;

//buttons cell
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (nonatomic) BOOL wantMode;
@property (weak, nonatomic) IBOutlet UIButton *sendButtonLabel;
@property (weak, nonatomic) IBOutlet UIButton *reportButton;
@property (weak, nonatomic) IBOutlet UIButton *reportLabel;

//send dialog box
@property (nonatomic, strong) SendDialogBox *sendBox;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic) BOOL setupBox;
@property (nonatomic, strong) NSMutableArray *facebookUsers;
@property (nonatomic) BOOL sendMode;
@property (nonatomic) int friendIndexSelected;
@property (nonatomic) BOOL selectedFriend;
@property (nonatomic) BOOL hidingSendBox;
@property (nonatomic) BOOL changeKeyboard;
@property (nonatomic) BOOL wasShowing;

//tab bar
@property (nonatomic, strong) NSNumber *tabBarHeight;
@property (nonatomic) int tabBarHeightInt;
@property (nonatomic) BOOL searchTabsObserverOn;
@property (nonatomic) BOOL justSwitchedTabs;


//confirmation dialogue box
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic) BOOL alertShowing;

//create similar listing
@property (nonatomic, strong) PFObject *similarListing;
@property (nonatomic, strong) PFGeoPoint *similarGeopoint;
@property (nonatomic, strong) NSString *similarLocationString;

//success view
@property (nonatomic, strong) CreateSuccessView *successView;
@property (nonatomic, strong) NSMutableArray *buyNowArray;
@property (nonatomic, strong) NSMutableArray *buyNowIDs;
@property (nonatomic) BOOL setupYes;
@property (nonatomic) BOOL completionShowing;
@property (nonatomic) BOOL shouldShowSuccess;
@property (nonatomic) BOOL createdListing;
@property (nonatomic) BOOL iwantDone;


//invite pop up
@property (nonatomic, strong, nullable) inviteViewClass *inviteView;
@property (nonatomic) BOOL inviteAlertShowing;
@property (nonatomic, strong, nullable) UIView *inviteBgView;
@property (nonatomic, strong) UITapGestureRecognizer *inviteTap;

//boosts
@property (nonatomic) BOOL highlightBoost;
@property (nonatomic) BOOL searchBoost;
@property (nonatomic) BOOL featureBoost;
@property (nonatomic) BOOL fromSearchBoost;

//success view mode
@property (nonatomic) BOOL showCancelButton;

//screenshot & other drop down tracking
@property (nonatomic) BOOL dropShowing;

//user push preferences
@property (nonatomic) BOOL dontLikePush;
@end
