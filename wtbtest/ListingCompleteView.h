//
//  ListingCompleteView.h
//  
//
//  Created by Jack Ryder on 27/02/2016.
//
//

#import <UIKit/UIKit.h>

@class ListingCompleteView;

@protocol ListingCompleteDelegate <NSObject>
- (void)listingEdit:(ListingCompleteView *)controller didFinishEnteringItem:(NSString *)item;
- (void)lastId:(ListingCompleteView *)controller didFinishEnteringItem:(NSString *)item;
@end

@interface ListingCompleteView : UITableViewController

@property (nonatomic, weak) id <ListingCompleteDelegate> delegate;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *mainCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellButtonOne;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellButtonTwo;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellButtonThree;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellButtonFour;

@property (nonatomic, strong) NSString *lastObjectId;



@end
