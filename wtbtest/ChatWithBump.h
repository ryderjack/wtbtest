//
//  ChatWithBump.h
//  wtbtest
//
//  Created by Jack Ryder on 05/10/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import <Parse/Parse.h>
#import "JSQMessages.h"
#import <ParseUI/ParseUI.h>
#import <QBImagePickerController/QBImagePickerController.h>

@interface ChatWithBump : JSQMessagesViewController <JSQMessagesComposerTextViewPasteDelegate, UICollectionViewDelegate, UINavigationControllerDelegate,QBImagePickerControllerDelegate>

@property (nonatomic, strong) NSString *convoId;
@property (nonatomic, strong) NSString *otherUserName;
@property (nonatomic, strong) NSString *tagString;

@property (nonatomic, strong) PFObject *convoObject;
@property (nonatomic, strong) PFUser *otherUser;

@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImageFactory *bubbleFactory;
@property (nonatomic, strong) JSQMessagesMediaViewBubbleImageMasker *masker;

@property (nonatomic, strong) NSMutableArray *messagesParseArray;
@property (nonatomic, strong) NSMutableArray *sentMessagesParseArray;

@property (nonatomic) BOOL fromForeGround;

@property (nonatomic, strong) PFObject *messageObject;
@property (nonatomic, strong) PFObject *lastMessage;

//avatar
@property (nonatomic, strong) JSQMessagesAvatarImage *avaImage;

//convo images
@property (nonatomic, strong) NSMutableArray *convoImagesArray;

@end
