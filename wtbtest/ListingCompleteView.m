//
//  ListingCompleteView.m
//  
//
//  Created by Jack Ryder on 27/02/2016.
//
//

#import "ListingCompleteView.h"

@interface ListingCompleteView ()

@end

@implementation ListingCompleteView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Done!";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    
    self.navigationItem.hidesBackButton = YES;
    self.mainCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cellButtonOne.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cellButtonTwo.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cellButtonThree.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cellButtonFour.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        if (indexPath.row == 0) {
            return self.mainCell;
        }
        else if(indexPath.row == 1){
            return self.cellButtonOne;
        }
        else if(indexPath.row == 2){
            return self.cellButtonTwo;
        }
        else if(indexPath.row == 3){
            return self.cellButtonThree;
        }
        else if(indexPath.row == 4){
            return self.cellButtonFour;
        }

    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 295;
        }
        else if(indexPath.row == 1){
            return 51;
        }
        else if(indexPath.row == 2){
            return 51;
        }
        else if(indexPath.row == 3){
            return 51;
        }
        else if(indexPath.row == 4){
            return 51;
        }
    }
    return 44;
}

- (IBAction)sharePressed:(id)sender {
    NSMutableArray *items = [NSMutableArray new];
    [items addObject:@"I just listed an item on wantobuy! Can you sell it to me??"];
    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}
- (IBAction)shareToGroupPresse:(id)sender {
}
- (IBAction)createAnotherPressed:(id)sender {
    [self.delegate listingEdit:self didFinishEnteringItem:@"new"];
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)editListingPressed:(id)sender {
    [self.delegate lastId:self didFinishEnteringItem:self.lastObjectId];
    [self.delegate listingEdit:self didFinishEnteringItem:@"edit"];
    [self.navigationController popViewControllerAnimated:YES];
}


@end
