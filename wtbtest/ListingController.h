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

@class ListingController;

@protocol ListingControllerDelegate <NSObject>
- (void)addItemViewController:(ListingController *)controller listing:(PFObject *)object;
@end

@interface ListingController : UITableViewController <iCarouselDataSource, iCarouselDelegate, DetailImageDelegate>

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
@property (nonatomic) BOOL searchOn;

//modes
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic) BOOL editPressed;

//profileButton
@property (nonatomic, strong) UIBarButtonItem *profileButton;

//big button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;

//carousel Cell
@property (weak, nonatomic) IBOutlet iCarousel *carouselView;




@end
