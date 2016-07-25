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

@class ListingController;

@protocol ListingControllerDelegate <NSObject>
- (void)addItemViewController:(ListingController *)controller listing:(PFObject *)object;
@end

@interface ListingController : UITableViewController

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

//main cell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIPageControl *picIndicator;
@property (weak, nonatomic) IBOutlet UIButton *messageButton;

@property (weak, nonatomic) IBOutlet UIButton *sellthisbutton;
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

@property (nonatomic, strong) PFFile *firstImage;
@property (nonatomic, strong) PFFile *secondImage;
@property (nonatomic, strong) PFFile *thirdImage;
@property (nonatomic, strong) PFFile *fourthImage;
@property (nonatomic) int numberOfPics;
@property (nonatomic) BOOL extraCellNeeded;

@property (nonatomic, strong) PFUser *buyer;

@property (nonatomic) BOOL sellThisPressed;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;
@end
