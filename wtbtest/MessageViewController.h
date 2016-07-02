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

@interface MessageViewController : JSQMessagesViewController <JSQMessagesComposerTextViewPasteDelegate, CameraControllerDelegate>

@property (nonatomic, strong) NSString *convoId;
@property (nonatomic, strong) NSString *otherUserName;
@property (nonatomic, strong) NSString *tagString;

@property (nonatomic, strong) PFObject *convoObject;
@property (nonatomic, strong) PFUser *otherUser;

@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *offerBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImageFactory *bubbleFactory;
@property (nonatomic, strong) JSQMessagesMediaViewBubbleImageMasker *masker;

@property (nonatomic) int skipped;
@property (nonatomic) BOOL earlierPressed;

@property (nonatomic, strong) NSMutableArray *messagesParseArray;
@property (nonatomic, strong) NSMutableArray *sentMessagesParseArray;

@property (nonatomic) BOOL offerMode;

@property (nonatomic, strong) PFObject *listing;
@property (nonatomic, strong) PFObject *offerObject;

@property (nonatomic) BOOL sellThisPressed;

@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *profileButton;
@property (nonatomic, strong) PFObject *messageObject;

@end
