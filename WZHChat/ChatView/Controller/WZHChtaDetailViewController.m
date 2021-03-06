//
//  WZHChtaDetailViewController.m
//  WZHChat
//
//  Created by 吳梓杭 on 2017/10/18.
//  Copyright © 2017年 吳梓杭. All rights reserved.
//

#import "WZHChtaDetailViewController.h"
#import "WZHToolbarView.h"
#import "WZHEmotionView.h"
#import "WZHChatMessage.h"
#import "WZHCellFrame.h"
#import "WZHChatViewCell.h"
#import "WZHMoreView.h"
#import "WZHChatService.h"
#import "WZHVoiceMessage.h"
#import "WZHLocalPictureMessage.h"
#import "WZHWebPictureMessage.h"
#import "WZHVoiceTableViewCell.h"
#import "WZHPictureTableViewCell.h"
#import "WZHInformationModel.h"
#import "AudioConverter.h"


@interface WZHChtaDetailViewController () <UITextViewDelegate,UIGestureRecognizerDelegate,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate,WZHToolBarDelegate,WZHEmotionViewdelegate,WZHMoreWayDelegate,WZHChatMessageDelegate,WZHPictureOriginalDelegate,WZHVoiceDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *emotionBtn;
@property (nonatomic, strong) WZHEmotionView *emotionview;
@property (nonatomic, strong) WZHToolbarView *toolBarView;
@property (nonatomic, strong) WZHMoreView *moreView;
@property (nonatomic, assign) CGFloat keyBoardH;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL allRefreshBool;     //YES:整体刷新(历史消息)   NO:局部刷新
@property (nonatomic, strong) NSString *fistTimeStr;    //整体刷新后第一个cell时间(历史消息)

@property (nonatomic, strong) UIButton *btn_press;       //录音按钮
@property (nonatomic, strong) UIView *voiceView;
@property (nonatomic, strong) NSMutableArray *albumSelectArr;     //相册已选相片数组
@property (nonatomic, strong) UIImage *cameraSelectImage;          //相机拍照相片
@property (nonatomic, assign) float voiceFloat;
@property (nonatomic, strong) UIAlertView *alert;         //长按弹窗
@property (nonatomic, strong) UITapGestureRecognizer *recognizerTap;
@property (nonatomic, strong) NSString *timeJudgeStr;    //时间比较保留与剔除

@property (nonatomic, strong) NSMutableArray *timeArray;         //消息事件
@property (nonatomic, strong) NSMutableArray *chatTypeArray;     //@"text"      @"voice"      @"picture"
@property (nonatomic, strong) NSMutableArray *informationArray;   //个人信息集合

//文本消息
@property (nonatomic, strong) NSMutableArray *dataSourceArray;
//语音消息
@property (nonatomic, strong) NSMutableArray *voiceArray;
@property (nonatomic, strong) NSString *audioStr;            //录音地址
@property (nonatomic, copy) NSString *docDirPath;
@property (nonatomic, copy) NSString *amrFilePath;
@property (nonatomic, strong) NSMutableArray *audioArray;
@property (nonatomic, strong) UIButton *btn_voice;            //录音播放按钮
@property (nonatomic, strong) NSMutableArray *voiceBtnArray;      //录音按钮集合
//图片消息
@property (nonatomic, strong) NSMutableArray *pictureBoolArray;       //网络图片：1   本地图片：2    其他：0
@property (nonatomic, strong) NSMutableArray *localPictureArray;     //本地图片
@property (nonatomic, strong) NSMutableArray *webPictureArray;    //网络图片
@property (nonatomic, strong) NSMutableArray *webThumbnailArray;    //网络图片缩小图，防止刷新本地数据奔溃(历史消息)
@property (nonatomic, strong) NSMutableArray *webOriginalArray;   //网络图片放大，防止刷新本地数据奔溃(历史消息)

//本地历史消息
@property (nonatomic, strong) FMDatabase *originalData;
@property (nonatomic, strong) NSMutableArray *historyGatherArr;   //历史消息集合
@property (nonatomic, assign) NSInteger hostory_Num;
@property (nonatomic, assign) NSInteger hostory_Id;    //消息模拟ID

@end

@implementation WZHChtaDetailViewController

#pragma mark 懒加载
//表情
- (WZHEmotionView *)emotionview {
    if (!_emotionview) {
        _emotionview = [[WZHEmotionView alloc]initWithFrame:emotionDownFrame];
        self.emotionview.IputView = self.toolBarView.textView;
        self.emotionview.delegate = self;
        [self.view addSubview:self.emotionview];
    }
    return _emotionview;
}
//更多
-(WZHMoreView *)moreView {
    if (!_moreView) {
        self.moreView = [[WZHMoreView alloc] initWithFrame:emotionDownFrame];
        _moreView.userInteractionEnabled = YES;
        _moreView.delegate = self;
        [self.view addSubview:_moreView];
    }
    return _moreView;
}
- (NSMutableArray *)informationArray {
    if (!_informationArray) {
        _informationArray = [[NSMutableArray alloc] init];
    }
    return _informationArray;
}
- (NSMutableArray *)dataSourceArray {
    if (!_dataSourceArray) {
        _dataSourceArray = [[NSMutableArray alloc] init];
    }
    return _dataSourceArray;
}
- (NSMutableArray *)localPictureArray {
    if (!_localPictureArray) {
        _localPictureArray = [[NSMutableArray alloc] init];
    }
    return _localPictureArray;
}
- (NSMutableArray *)chatTypeArray {
    if (!_chatTypeArray) {
        _chatTypeArray = [[NSMutableArray alloc] init];
    }
    return _chatTypeArray;
}
- (NSMutableArray *)voiceArray {
    if (!_voiceArray) {
        _voiceArray = [[NSMutableArray alloc] init];
    }
    return _voiceArray;
}
- (NSMutableArray *)webPictureArray {
    if (!_webPictureArray) {
        _webPictureArray = [[NSMutableArray alloc] init];
    }
    return _webPictureArray;
}
- (NSMutableArray *)pictureBoolArray {
    if (!_pictureBoolArray) {
        _pictureBoolArray = [[NSMutableArray alloc] init];
    }
    return _pictureBoolArray;
}
- (NSMutableArray *)timeArray {
    if (!_timeArray) {
        _timeArray = [[NSMutableArray alloc] init];
    }
    return _timeArray;
}
- (NSString *)timeJudgeStr {
    if (!_timeJudgeStr) {
        _timeJudgeStr = [[NSString alloc] init];
    }
    return _timeJudgeStr;
}
- (NSMutableArray *)audioArray {
    if (!_audioArray) {
        _audioArray = [[NSMutableArray alloc] init];
    }
    return _audioArray;
}
- (NSMutableArray *)webOriginalArray {
    if (!_webOriginalArray) {
        _webOriginalArray = [[NSMutableArray alloc] init];
    }
    return _webOriginalArray;
}
- (NSMutableArray *)webThumbnailArray {
    if (!_webThumbnailArray) {
        _webThumbnailArray = [[NSMutableArray alloc] init];
    }
    return _webThumbnailArray;
}
-(NSMutableArray *)historyGatherArr{
    if (!_historyGatherArr) {
        _historyGatherArr = [[NSMutableArray alloc] init];
    }
    return _historyGatherArr;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //数据的路径，放在沙盒的cache下面
    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString * originalStr = [NSString stringWithFormat:@"HistoryMessage,sqlite"];
    NSString *filePath = [cacheDir stringByAppendingPathComponent:originalStr];
    NSLog(@"%@",filePath);
    //创建并且打开一个数据库
    self.originalData = [FMDatabase databaseWithPath:filePath];
    if ([_originalData open]) {
        NSLog(@"打开数据库成功");
    } else {
        NSLog(@"打开数据库失败");
    }
    BOOL result = [_originalData executeUpdate:@"CREATE TABLE IF NOT EXISTS t_Contacts (id text NOT NULL, type text NOT NULL, icon text NOT NULL, name text NOT NULL, fromId text NOT NULL, toId text NOT NULL, createTime text NOT NULL, content text NOT NULL, audioTimeSecond text NOT NULL, audio text NOT NULL, thumbnail text NOT NULL, original text NOT NULL);"];
    if (result) {
        NSLog(@"创建表成功");
    } else {
        NSLog(@"创建表失败");
    }
    self.hostory_Num = 1;
    FMResultSet *resultSet = [self.originalData executeQuery:@"SELECT * FROM t_Contacts ORDER BY id DESC"];
    self.hostory_Id = 1000;
    while (resultSet.next) {
        _hostory_Id = [[resultSet objectForColumn:@"id"] intValue] + 1;
        break;
    }
    NSLog(@"_hostory_Id === %ld",_hostory_Id);
    self.navigationItem.title = @"聊天";
    NSInteger a = self.informationArray.count + self.dataSourceArray.count  + self.localPictureArray.count  + self.chatTypeArray.count  + self.voiceArray.count  + self.webPictureArray.count  + self.pictureBoolArray.count + self.timeArray.count + self.voiceBtnArray.count + self.audioArray.count + self.webOriginalArray.count + self.webThumbnailArray.count + self.historyGatherArr.count;            //解决不执行懒加载，对程序毫无意义
    _voiceBtnArray = [[NSMutableArray alloc] init];
    _fistTimeStr = [NSString string];          //第一个cell的时间加载，用于刷新历史消息
    
    
    [self setNotificationCenter];     //键盘监控
    [self creatTableView];
    [self creatToolBar];           //tooBar控件
    [self addNavRightBtton];
    self.view.backgroundColor = EEEEEE;
    //录音视图
    self.voiceView = [[UIView alloc] init];
    self.voiceView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.voiceView];
    
    __weak __typeof(self) weakSelf = self;
    // 下拉刷新
    self.tableView.mj_header= [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf historyMessage];
        _hostory_Num ++;
        // 结束刷新
        [weakSelf.tableView.mj_header endRefreshing];
    }];
    [self.tableView.mj_header beginRefreshing];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.emotionview.IputView = self.toolBarView.textView;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    self.tabBarController.tabBar.hidden = NO;
}

- (void)creatTableView {
    UITableView *tableview = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, IPHONE_WIDTH, IPHONE_HEIGHT - NAV_HEIGHT -toobarH)];
    self.tableView = tableview;
    tableview.showsVerticalScrollIndicator = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    tableview.dataSource = self;
    tableview.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableview.delegate = self;
    tableview.backgroundColor = EEEEEE;
    [self.view addSubview:tableview];
    // 单击手势用于退出键盘
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(quitKeyboard)];
    tap.delegate = self;
    [tableview addGestureRecognizer:tap];
}
- (void)requestData {
    /**
     预留socket消息传入，一般为对方消息，传入之后必须做两个实现：
     1、存入数据库（见 [self historyMessage] 讲解方法）
     2、实现UI讲解
     [self sendMessageWithText:<#(NSString *)#> TimeStr:<#(NSString *)#> NameStr:<#(NSString *)#> HeaderStr:<#(NSString *)#> GuestStr:<#(NSString *)#> MemberId:<#(NSString *)#> InformationId:<#(NSString *)#>]      //文本消息UI
     [self sendVoiceMessageWithFilePathStr:<#(NSString *)#> VoiceTimeStr:<#(NSString *)#> TimeStr:<#(NSString *)#> NameStr:<#(NSString *)#> HeaderStr:<#(NSString *)#> GuestStr:<#(NSString *)#> MemberId:<#(NSString *)#> InformationId:<#(NSString *)#>]     //语音消息UI
     [self sendWebPictureMessageWithLocalStr:<#(NSString *)#> OriginalStr:<#(NSString *)#> ThumbnailStr:<#(NSString *)#> TimeStr:<#(NSString *)#> NameStr:<#(NSString *)#> HeaderStr:<#(NSString *)#> GuestStr:<#(NSString *)#> MemberId:<#(NSString *)#> InformationId:<#(NSString *)#>]    //网络图片UI
     
     其中
     Text：文本消息内容
     TimeStr：消息时间（北京时间）
     NameStr：用户昵称
     HeaderStr：用户头像
     GuestStr：是否为嘉宾，主人传"0",客人（嘉宾）传"1"
     MemberId：用户Id
     InformationId：消息Id，可能会用于消息撤回删除接口传入id值
     FilePathStr：语音消息
     VoiceTimeStr：语音消息时长
     LocalStr：区分是否为网络图片，网络图片传"0"，本地图片传"1"
     OriginalStr：网络图片消息缩略图链接
     ThumbnailStr：网络图片消息放大图链接
     
     还有：self.allRefreshBool = YES;    //为历史全局刷新；如果加载单条消息，请self.allRefreshBool改为NO,为局部刷新
     **/
    
}

- (void)historyMessage {
    /**
    先在这里编写加载网络历史消息，存入数据库即可，不需要实现UI
    讲解@"CREATE TABLE IF NOT EXISTS t_Contacts (id text NOT NULL, type text NOT NULL, icon text NOT NULL, name text NOT NULL, fromId text NOT NULL, toId text NOT NULL, createTime text NOT NULL, content text NOT NULL, audioTimeSecond text NOT NULL, audio text NOT NULL, thumbnail text NOT NULL, original text NOT NULL);"
     id:  消息ID，可能会用于消息撤回删除接口id值
     type:  文本消息 = @"1"     图片消息 = @"2"    语音消息 = @"3"
     icon:  用户头像
     name:  用户昵称
     fromId:   消息来自某人Id
     toId:     消息发给对方Id
     createTime:   消息时间（北京时间）
     content:   文本消息内容
     audioTimeSecond:    语音消息时长
     audio:    语音消息链接
     thumbnail:   图片消息缩略图链接
     original:    图片消息放大图链接
    **/
    
    //查询整个表
    FMResultSet * resultSet = [self.originalData executeQuery:@"SELECT * FROM t_Contacts ORDER BY id DESC"];
    int i = 0;
    while ([resultSet next]) {
        if (i == 0) {
            [_informationArray removeAllObjects];
            [_audioArray removeAllObjects];
            [_voiceArray removeAllObjects];
            [_chatTypeArray removeAllObjects];
            [_dataSourceArray removeAllObjects];
            [_localPictureArray removeAllObjects];
            [_webPictureArray removeAllObjects];
            [_pictureBoolArray removeAllObjects];
            [_webOriginalArray removeAllObjects];
            [self.tableView reloadData];
        }
        NSString * idStr = [resultSet objectForColumn:@"id"];
        NSLog(@"idStr ==== %@ \n",idStr);
        
        if (i < _hostory_Num * 5) {
            self.allRefreshBool = YES;    //全局刷新
            NSInteger typeStr = [[resultSet objectForColumn:@"type"] intValue];
            NSInteger fromIdStr = [[resultSet objectForColumn:@"fromId"] intValue];
            NSInteger message_Num = [MEMBERID intValue];
            [self nowTimeEqualJudge:[resultSet objectForColumn:@"createTime"]];
            if (typeStr == 1) {
                if (fromIdStr == message_Num) {
                    [self sendMessageWithText:[resultSet objectForColumn:@"content"] TimeStr:@"" NameStr:@"主人" HeaderStr:HEADERIMAGE GuestStr:@"0" MemberId:MEMBERID InformationId:[resultSet objectForColumn:@"id"]];
                }else{
                    [self sendMessageWithText:[resultSet objectForColumn:@"content"] TimeStr:@"" NameStr:@"WOHANGO" HeaderStr:GUESTHEADERIMAGE GuestStr:@"1" MemberId:GUESTMEMBERID InformationId:[resultSet objectForColumn:@"id"]];
                }
            }else if (typeStr == 2) {
                //注明：这里看不到效果，因为访问历史消息图片默认访问网络图片，没必要访问本地图片
                if (fromIdStr == message_Num) {
                    NSLog(@"%@",[resultSet objectForColumn:@"original"]);
                    [self sendWebPictureMessageWithLocalStr:@"0" OriginalStr:[resultSet objectForColumn:@"original"] ThumbnailStr:[resultSet objectForColumn:@"thumbnail"] TimeStr:@"" NameStr:@"主人" HeaderStr:HEADERIMAGE GuestStr:@"0" MemberId:MEMBERID InformationId:[resultSet objectForColumn:@"id"]];
                }else{
                    [self sendWebPictureMessageWithLocalStr:@"0" OriginalStr:[resultSet objectForColumn:@"original"] ThumbnailStr:[resultSet objectForColumn:@"thumbnail"] TimeStr:@"" NameStr:@"WOHANGO" HeaderStr:GUESTHEADERIMAGE GuestStr:@"1" MemberId:GUESTMEMBERID InformationId:[resultSet objectForColumn:@"id"]];
                }
            }else if (typeStr  == 3) {
                if (fromIdStr == message_Num) {
                    [self sendVoiceMessageWithFilePathStr:[resultSet objectForColumn:@"audio"] VoiceTimeStr:[resultSet objectForColumn:@"audioTimeSecond"] TimeStr:@"" NameStr:@"主人" HeaderStr:HEADERIMAGE GuestStr:@"0" MemberId:MEMBERID InformationId:[resultSet objectForColumn:@"id"]];
                }else{
                    [self sendVoiceMessageWithFilePathStr:[resultSet objectForColumn:@"audio"] VoiceTimeStr:[resultSet objectForColumn:@"audioTimeSecond"] TimeStr:@"" NameStr:@"WOHANGO" HeaderStr:GUESTHEADERIMAGE GuestStr:@"1" MemberId:GUESTMEMBERID InformationId:[resultSet objectForColumn:@"id"]];
                }
            }
            i ++;
        }else {
            break;
        }
    }
}

- (void)quitKeyboard {
    [self.textView resignFirstResponder];
    self.toolBarView.toolBarEmotionBtn.selected = NO;
    if (self.textView.text.length == 0) {
        [UIView animateWithDuration:0 animations:^{
            self.emotionview.frame = emotionDownFrame;
            self.toolBarView.frame = toolBarFrameDown;
            self.moreView.frame = emotionDownFrame;
        }];
    }else {
        self.emotionview.frame = emotionDownFrame;
        self.moreView.frame = emotionDownFrame;
        self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height, IPHONE_WIDTH, self.toolBarView.height);
    }
    [UIView animateWithDuration:0 animations:^{
        self.tableView.height = IPHONE_HEIGHT - self.toolBarView.height - NAV_HEIGHT;
    }];
}

- (void)setNotificationCenter  {
    // 键盘frame将要改变就会接受到通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    // 键盘将要收起时候发出通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

//键盘弹出
- (void)keyboardWillChangeFrame:(NSNotification *)noti {
    NSValue* aValue = [(NSDictionary *)noti.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyBoardFrame = [aValue CGRectValue];
    keyBoardFrame = [self.view convertRect:keyBoardFrame fromView:nil];
    
    CGFloat keyboardTop = keyBoardFrame.origin.y;
    CGRect newTextViewFrame = self.view.bounds;
    newTextViewFrame.size.height = keyboardTop - self.view.bounds.origin.y;
    
    NSValue *animationDurationValue = [(NSDictionary *)noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    self.tableView.frame = CGRectMake(0, 0, IPHONE_WIDTH, IPHONE_HEIGHT - CGRectGetMinY(keyBoardFrame) + 15 * ScaleY_Num);
    [UIView commitAnimations];
    
    CGFloat height = keyBoardFrame.origin.y + keyBoardFrame.size.height;
    if (height > IPHONE_HEIGHT) {
        self.toolBarView.toolBarEmotionBtn.selected = YES;
        [UIView animateWithDuration:0 animations:^{
            self.moreView.frame = emotionDownFrame;
            self.emotionview.frame = emotionDownFrame;
            self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height - self.emotionview.height, IPHONE_WIDTH, self.toolBarView.height);
        }];
    }else {
        [UIView animateWithDuration:0 animations:^{
            self.moreView.frame = emotionDownFrame;
            self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height - keyBoardFrame.size.height, IPHONE_WIDTH, self.toolBarView.height);
        }];
    }
    self.keyBoardH = keyBoardFrame.size.height;
}

//键盘弹回
- (void)keyboardWillHide:(NSNotification *)noti {
    NSValue *animationDurationValue = [(NSDictionary *)noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    self.tableView.frame = CGRectMake(0, 0, IPHONE_WIDTH, IPHONE_HEIGHT - NAV_HEIGHT -toobarH);
    [UIView commitAnimations];
}

#pragma mark - 创建toolbar
- (void)creatToolBar {
    WZHToolbarView *toolBarView = [[WZHToolbarView alloc] init];
    self.toolBarView = toolBarView;
    toolBarView.textView.delegate = self;
    toolBarView.delegate = self;
    self.textView = toolBarView.textView;
    [self.view addSubview:toolBarView];
    
    //录音
    _btn_press = [UIButton buttonWithType:UIButtonTypeCustom];
    _btn_press.layer.cornerRadius = 8;
    _btn_press.layer.borderWidth = 0.5f;
    _btn_press.layer.borderColor = C707070.CGColor;
    _btn_press.backgroundColor = EEEEEE;
    _btn_press.clipsToBounds = YES;
    [_btn_press setTitle:@"按住 说话" forState:UIControlStateNormal];
    [_btn_press setTitle:@"松开 结束" forState:UIControlStateHighlighted];
    [_btn_press setTitleColor:C999999 forState:UIControlStateNormal];
    [_btn_press addTarget:self action:@selector(voiceBtnClickDown:) forControlEvents:UIControlEventTouchDown];
    [_btn_press addTarget:self action:@selector(voiceBtnClickCancel:) forControlEvents:UIControlEventTouchCancel];
    [_btn_press addTarget:self action:@selector(voiceBtnClickUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_btn_press addTarget:self action:@selector(voiceBtnClickDragExit:) forControlEvents:UIControlEventTouchDragExit];
    [_btn_press addTarget:self action:@selector(voiceBtnClickUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    [_btn_press addTarget:self action:@selector(voiceBtnClickDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
    [_toolBarView addSubview:_btn_press];
}

#pragma mark - ToolBar代理方法
- (void)ToolbarEmotionBtnDidClicked:(UIButton *)emotionBtn {
    if (emotionBtn.selected) {
        self.toolBarView.toolBarVoiceBtn.selected = YES;
        self.toolBarView.toolBarVoiceBtn.selected = NO;
        self.btn_press.frame = emotionDownFrame;
        emotionBtn.selected = NO;
        [self.textView becomeFirstResponder];
        [UIView animateWithDuration:0 animations:^{
            self.moreView.frame = emotionDownFrame;
            self.tableView.height = IPHONE_HEIGHT - self.keyBoardH - self.toolBarView.height - NAV_HEIGHT;
        }];
    }else {
        [self.textView resignFirstResponder];
        emotionBtn.selected = YES;
        self.toolBarView.toolBarVoiceBtn.selected = NO;
        self.btn_press.frame = emotionDownFrame;
        [UIView animateWithDuration:0 animations:^{
            self.emotionview.frame = emotionUpFrame;
            self.moreView.frame = emotionDownFrame;
            self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height - self.emotionview.height, IPHONE_WIDTH, self.toolBarView.height);
            self.tableView.height = IPHONE_HEIGHT - self.emotionview.height - self.toolBarView.height - NAV_HEIGHT;
            if (self.tableView.contentSize.height > self.tableView.height) {
                [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height + 3) animated:NO];
            }
        }];
    }
}

- (void)ToolbarVoiceBtnDidClicked:(UIButton *)voiceBtn {
    if (voiceBtn.selected == YES) {
        voiceBtn.selected = NO;
        self.toolBarView.toolBarEmotionBtn.selected = NO;
        self.tableView.height = IPHONE_HEIGHT - self.toolBarView.height - NAV_HEIGHT;
        [self.textView resignFirstResponder];
        [UIView animateWithDuration:0 animations:^{
            self.emotionview.frame = emotionDownFrame;
            self.moreView.frame = emotionDownFrame;
            self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height, IPHONE_WIDTH, self.toolBarView.height);
            self.tableView.height = IPHONE_HEIGHT - self.toolBarView.height - NAV_HEIGHT;
            self.btn_press.frame = emotionDownFrame;
            if (self.tableView.contentSize.height > self.tableView.height) {
                [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height + 3) animated:NO];
            }
        }];
    }else{
        voiceBtn.selected = YES;
        self.toolBarView.toolBarEmotionBtn.selected = NO;
        [self.textView resignFirstResponder];
        self.tableView.height = IPHONE_HEIGHT - self.toolBarView.height - NAV_HEIGHT;
        [UIView animateWithDuration:0 animations:^{
            self.emotionview.frame = emotionDownFrame;
            self.moreView.frame = emotionDownFrame;
            self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height, IPHONE_WIDTH, self.toolBarView.height);
            self.tableView.height = IPHONE_HEIGHT - self.toolBarView.height - NAV_HEIGHT;
            self.btn_press.frame = CGRectMake(30 * ScaleX_Num, IPHONE_WIDTH * 5 / 320, IPHONE_WIDTH - 85 * ScaleX_Num, _textView.size.height);
            if (self.tableView.contentSize.height > self.tableView.height) {
                [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height + 3) animated:NO];
            }
        }];
    }
}

- (void)ToolbarMoreBtnDidClicked:(UIButton *)moreBtn {
    if (moreBtn.selected == YES) {
        moreBtn.selected = NO;
        self.toolBarView.toolBarVoiceBtn.selected = NO;
        self.toolBarView.toolBarEmotionBtn.selected = NO;
        [self.textView resignFirstResponder];
        self.tableView.height = IPHONE_HEIGHT - self.toolBarView.height - NAV_HEIGHT;
        [UIView animateWithDuration:0 animations:^{
            self.emotionview.frame = emotionDownFrame;
            self.btn_press.frame = emotionDownFrame;
            self.moreView.frame = emotionDownFrame;
            self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height, IPHONE_WIDTH, self.toolBarView.height);
            self.tableView.height = IPHONE_HEIGHT - self.toolBarView.height - NAV_HEIGHT;
            if (self.tableView.contentSize.height > self.tableView.height) {
                [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height + 3) animated:NO];
            }
        }];
    }else{
        moreBtn.selected = YES;
        self.toolBarView.toolBarVoiceBtn.selected = NO;
        self.toolBarView.toolBarEmotionBtn.selected = NO;
        [self.textView resignFirstResponder];
        [UIView animateWithDuration:0 animations:^{
            self.moreView.frame = emotionUpFrame;
            self.emotionview.frame = emotionDownFrame;
            self.btn_press.frame = emotionDownFrame;
            self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height - self.moreView.height, IPHONE_WIDTH, self.toolBarView.height);
            self.tableView.height = IPHONE_HEIGHT - self.moreView.height - self.toolBarView.height - NAV_HEIGHT;
            if (self.tableView.contentSize.height > self.tableView.height) {
                [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height + 3) animated:NO];
            }
        }];
    }
}

- (void)MoreWayBtnDidClicked:(UIButton *)moreWayBtn {
    LLImagePickerView * pickerV = [[LLImagePickerView alloc] init];
    pickerV.showDelete = YES;
    pickerV.showAddButton = YES;
    //自定义从本地相册中所选取的最大数量 9
    pickerV.maxImageSelected = 9 ;
    //如果不希望已经选择的图片或视频，再次被选择，那么可以设置为 NO
    pickerV.allowMultipleSelection = NO;
    //如果希望在选择图片的时候，出现视频资源，那么可以设置为 YES
    pickerV.allowPickingVideo = NO;
    if (moreWayBtn.tag == 901) {
        [pickerV openAlbum];
        [pickerV observeSelectedMediaArray:^(NSArray<LLImagePickerModel *> *list) {
            for (LLImagePickerModel *model in list) {
                // 在这里取到模型的数据
                NSLog(@"%@",model.image);
                _allRefreshBool = NO;
                [self nowTimeEqualJudge:[NSDate getNowDate5]];
                NSString * guestStr = [NSString stringWithFormat:@"%d",random_Num];
                
                [self sendLocalPictureMessageWithLocalStr:@"1" OriginalImage:model.image ThumbnailImage:model.image TimeStr:@"" NameStr:@"WOHANGO" HeaderStr:HEADERIMAGE GuestStr:guestStr MemberId:MEMBERID InformationId:@""];
                
                /*
                 发送消息到服务器接口预留位置
                 */
                
                //@"CREATE TABLE IF NOT EXISTS t_Contacts (id text NOT NULL, type text NOT NULL, icon text NOT NULL, name text NOT NULL, fromId text NOT NULL, toId text NOT NULL, createTime text NOT NULL, content text NOT NULL, audioTimeSecond text NOT NULL, audio text NOT NULL, thumbnail text NOT NULL, original text NOT NULL);"
                // 创建插入语句
                NSString *insertSql = @"insert into t_Contacts(id, type, icon, name, fromId, toId, createTime, content, audioTimeSecond, audio, thumbnail, original) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                BOOL result1;
                if ([guestStr intValue] == 0) {
                    result1 = [_originalData executeUpdate:insertSql, [NSString stringWithFormat:@"%ld",_hostory_Id], @"2", HEADERIMAGE, @"主人", MEMBERID, GUESTMEMBERID, [NSDate getNowDate5], @"", @"", @"", model.image, model.image];
                }else {
                    result1 = [_originalData executeUpdate:insertSql, [NSString stringWithFormat:@"%ld",_hostory_Id], @"2", GUESTHEADERIMAGE, @"WOHANGO", GUESTMEMBERID, MEMBERID, [NSDate getNowDate5], @"", @"", @"", model.image, model.image];
                }
                _hostory_Id ++;
                if (result1) {
                    NSLog(@"添加成功");
                } else {
                    NSLog(@"添加失败");
                }
            }
        }];
    }
    if (moreWayBtn.tag == 902) {
        [pickerV openCamera];
        [pickerV observeSelectedMediaArray:^(NSArray<LLImagePickerModel *> *list) {
            for (LLImagePickerModel *model in list) {
                // 在这里取到模型的数据
                NSLog(@"%@",model.image);
                _allRefreshBool = NO;
                [self nowTimeEqualJudge:[NSDate getNowDate5]];
                self.cameraSelectImage = model.image;
                NSString * guestStr = [NSString stringWithFormat:@"%d",random_Num];
                [self sendLocalPictureMessageWithLocalStr:@"1" OriginalImage:model.image ThumbnailImage:model.image TimeStr:@"" NameStr:@"WOHANGO" HeaderStr:HEADERIMAGE GuestStr:guestStr MemberId:MEMBERID InformationId:@""];
                
                /*
                 发送消息到服务器接口预留位置
                 */
                
                //@"CREATE TABLE IF NOT EXISTS t_Contacts (id text NOT NULL, type text NOT NULL, icon text NOT NULL, name text NOT NULL, fromId text NOT NULL, toId text NOT NULL, createTime text NOT NULL, content text NOT NULL, audioTimeSecond text NOT NULL, audio text NOT NULL, thumbnail text NOT NULL, original text NOT NULL);"
                // 创建插入语句
                NSString *insertSql = @"insert into t_Contacts(id, type, icon, name, fromId, toId, createTime, content, audioTimeSecond, audio, thumbnail, original) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                BOOL result1;
                if ([guestStr intValue] == 0) {
                    result1 = [_originalData executeUpdate:insertSql, [NSString stringWithFormat:@"%ld",_hostory_Id], @"2", HEADERIMAGE, @"主人", MEMBERID, GUESTMEMBERID, [NSDate getNowDate5], @"", @"", @"", model.image, model.image];
                }else {
                    result1 = [_originalData executeUpdate:insertSql, [NSString stringWithFormat:@"%ld",_hostory_Id], @"2", GUESTHEADERIMAGE, @"WOHANGO", GUESTMEMBERID, MEMBERID, [NSDate getNowDate5], @"", @"", @"", model.image, model.image];
                }
                _hostory_Id ++;
                if (result1) {
                    NSLog(@"添加成功");
                } else {
                    NSLog(@"添加失败");
                }
            }
        }];
    }
    [self.view addSubview:pickerV];
}

#pragma mark - textView代理方法
- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.toolBarView.toolBarEmotionBtn.selected = NO;
    [UIView animateWithDuration:0 animations:^{
        self.btn_press.frame = emotionDownFrame;
        self.moreView.frame = CGRectMake(0, IPHONE_HEIGHT, 0, 0);
        self.tableView.height = IPHONE_HEIGHT - self.keyBoardH - self.toolBarView.height - NAV_HEIGHT ;
        if (self.tableView.contentSize.height > self.tableView.height) {
            [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height + 3) animated:NO];
        }
    }];
}

- (void)textViewDidChange:(UITextView *)textView {
    if (self.toolBarView.textView.contentSize.height <= TextViewH) {
        self.toolBarView.textView.height = TextViewH;
    }else if (self.toolBarView.textView.contentSize.height >= 90) {
        self.toolBarView.textView.height = 90;
    }else {
        self.toolBarView.textView.height = self.toolBarView.textView.contentSize.height;
    }
    self.toolBarView.height = IPHONE_WIDTH * 10 / 320 + self.toolBarView.textView.height;
    if (self.keyBoardH < self.emotionview.height) {
        self.toolBarView.y = IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height - self.emotionview.height;
    }else {
        self.toolBarView.y = IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height - self.keyBoardH;
    }
    if (textView.text.length > 0) {
        self.emotionview.sendBtn.selected = YES;
    }else {
        self.emotionview.sendBtn.selected = NO;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        NSString *messageText = [[_textView.textStorage getPlainString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        _allRefreshBool = NO;
        [self nowTimeEqualJudge:[NSDate getNowDate5]];
        NSString * guestStr = [NSString stringWithFormat:@"%d",random_Num];
        [self sendMessageWithText:messageText TimeStr:@"" NameStr:@"WOHANGO" HeaderStr:HEADERIMAGE GuestStr:guestStr MemberId:MEMBERID InformationId:@""];
        
        /*
         发送消息到服务器接口预留位置
         */
        
        // 创建插入语句
        NSString *insertSql = @"insert into t_Contacts(id, type, icon, name, fromId, toId, createTime, content, audioTimeSecond, audio, thumbnail, original) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        BOOL result1;
        if ([guestStr intValue] == 0) {
            result1 = [_originalData executeUpdate:insertSql, [NSString stringWithFormat:@"%ld",_hostory_Id], @"1", HEADERIMAGE, @"主人", MEMBERID, GUESTMEMBERID, [NSDate getNowDate5], messageText, @"", @"", @"", @""];
        }else {
            result1 = [_originalData executeUpdate:insertSql, [NSString stringWithFormat:@"%ld",_hostory_Id], @"1", GUESTHEADERIMAGE, @"WOHANGO", GUESTMEMBERID, MEMBERID, [NSDate getNowDate5], messageText, @"", @"", @"", @""];
        }
        _hostory_Id ++;
        if (result1) {
            NSLog(@"添加成功");
        } else {
            NSLog(@"添加失败");
        }
        return NO;
    }
    return YES;
}

#pragma mark - emotionView代理方法
- (void)emotionView_sBtnDidClick:(UIButton *)btn {
    if (btn.tag == 3456) {
        //解析处理
        NSString *messageText = [[_textView.textStorage getPlainString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [self nowTimeEqualJudge:[NSDate getNowDate5]];
        NSString * guestStr = [NSString stringWithFormat:@"%d",random_Num];
        [self sendMessageWithText:messageText TimeStr:@"" NameStr:@"WOHANGO" HeaderStr:HEADERIMAGE GuestStr:guestStr MemberId:MEMBERID InformationId:@""];
        
        /*
         发送消息到服务器接口预留位置
         */
        
        // 创建插入语句
        NSString *insertSql = @"insert into t_Contacts(id, type, icon, name, fromId, toId, createTime, content, audioTimeSecond, audio, thumbnail, original) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        BOOL result1;
        if ([guestStr intValue] == 0) {
            result1 = [_originalData executeUpdate:insertSql, [NSString stringWithFormat:@"%ld",_hostory_Id], @"1", HEADERIMAGE, @"主人", MEMBERID, GUESTMEMBERID, [NSDate getNowDate5], messageText, @"", @"", @"", @""];
        }else {
            result1 = [_originalData executeUpdate:insertSql, [NSString stringWithFormat:@"%ld",_hostory_Id], @"1", GUESTHEADERIMAGE, @"WOHANGO", GUESTMEMBERID, MEMBERID, [NSDate getNowDate5], messageText, @"", @"", @"", @""];
        }
        _hostory_Id ++;
        if (result1) {
            NSLog(@"添加成功");
        } else {
            NSLog(@"添加失败");
        }
    }else{
        [self textViewDidChange:self.textView];
        //判断输入框有内容让发送按钮变颜色
        if (self.emotionview.IputView.text.length > 0) {
            self.emotionview.sendBtn.selected = YES;
        }else{
            self.emotionview.sendBtn.selected = NO;
        }
    }
}

#pragma mark - 发送消息
//发送文本消息
- (void)sendMessageWithText:(NSString *)text TimeStr:(NSString *)timeStr NameStr:(NSString *)nameStr HeaderStr:(NSString *)headerStr GuestStr:(NSString *)gustStr MemberId:(NSString *)memberId InformationId:(NSString *)informationId {
    if (text.length != 0) {
        WZHInformationModel * infomationModel = [[WZHInformationModel alloc] init];
        infomationModel.timeStr = timeStr;
        infomationModel.nameStr = nameStr;
        infomationModel.headerStr = headerStr;
        infomationModel.guestStr = gustStr;
        infomationModel.memberIdStr = memberId;
        infomationModel.informationId = informationId;
        
        WZHCellFrame *model = [self creatNormalMessageWithText:text];
        WZHVoiceMessage * voiceModel = [[WZHVoiceMessage alloc] init];
        WZHLocalPictureMessage * localModel = [[WZHLocalPictureMessage alloc] init];
        WZHWebPictureMessage * webModel = [[WZHWebPictureMessage alloc] init];
        NSLog(@"text === %@",text);
        self.textView.text = nil;
        [self textViewDidChange:self.textView];
        if (_allRefreshBool == YES) {               //预留刷新历史消息
            [_informationArray insertObject:infomationModel atIndex:0];
            [self.dataSourceArray insertObject:model atIndex:0];
            [self.chatTypeArray insertObject:@"text" atIndex:0];
            [self.voiceArray insertObject:voiceModel atIndex:0];
            [self.localPictureArray insertObject:localModel atIndex:0];
            [self.webPictureArray insertObject:webModel atIndex:0];
            [self.pictureBoolArray insertObject:@"0" atIndex:0];
            [_audioArray insertObject:@"" atIndex:0];
            [_webOriginalArray insertObject:@"" atIndex:0];
            [_webThumbnailArray insertObject:@"" atIndex:0];
            
            [self.tableView reloadData];
            self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height, IPHONE_WIDTH, self.toolBarView.height);
            self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
            self.moreView.frame = emotionDownFrame;
            self.emotionview.frame = emotionDownFrame;
            self.tableView.height = IPHONE_HEIGHT - self.keyBoardH - self.toolBarView.height - NAV_HEIGHT;
        }else {
            [_informationArray addObject:infomationModel];
            [self.dataSourceArray addObject:model];
            [self.chatTypeArray addObject:@"text"];
            [self.voiceArray addObject:voiceModel];
            [self.localPictureArray addObject:localModel];
            [self.webPictureArray addObject:webModel];
            [self.pictureBoolArray addObject:@"0"];
            [_audioArray addObject:@""];
            [_webOriginalArray addObject:@""];
            [_webThumbnailArray addObject:@""];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.chatTypeArray.count - 1 inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

//创建消息模型添加到数据源数组
- (WZHCellFrame *)creatNormalMessageWithText:(NSString *)text {
    WZHCellFrame *cellFrame = [[WZHCellFrame alloc]init];
    WZHChatMessage *message = [[WZHChatMessage alloc]init];
    message.text = text;
    cellFrame.message = message;
    return cellFrame;
}

//发送语音消息
- (void)sendVoiceMessageWithFilePathStr:(NSString *)filePathStr VoiceTimeStr:(NSString *)voiceTimeStr TimeStr:(NSString *)timeStr NameStr:(NSString *)nameStr HeaderStr:(NSString *)headerStr GuestStr:(NSString *)gustStr MemberId:(NSString *)memberId InformationId:(NSString *)informationId {
    WZHInformationModel * infomationModel = [[WZHInformationModel alloc] init];
    infomationModel.timeStr = timeStr;
    infomationModel.nameStr = nameStr;
    infomationModel.headerStr = headerStr;
    infomationModel.guestStr = gustStr;
    infomationModel.memberIdStr = memberId;
    infomationModel.informationId = informationId;
    
    WZHCellFrame *model = [[WZHCellFrame alloc] init];
    WZHVoiceMessage * voiceModel = [[WZHVoiceMessage alloc] init];
    WZHLocalPictureMessage * localModel = [[WZHLocalPictureMessage alloc] init];
    WZHWebPictureMessage * webModel = [[WZHWebPictureMessage alloc] init];
    
    
    /**
     如果你的语音全部为网络语音，请在此下载网络语音，并保存本地，保留本地连接，voiceModel.filePathStr、_audioArray传入本地链接
     **/

    voiceModel.filePathStr = filePathStr;
    voiceModel.voiceTimeStr = voiceTimeStr;
    if (_allRefreshBool == YES) {             //预留刷新历史消息
        [_informationArray insertObject:infomationModel atIndex:0];
        [_audioArray insertObject:filePathStr atIndex:0];
        [_voiceArray insertObject:voiceModel atIndex:0];
        [_chatTypeArray insertObject:@"voice" atIndex:0];
        [_dataSourceArray insertObject:model atIndex:0];
        [_localPictureArray insertObject:localModel atIndex:0];
        [_webPictureArray insertObject:webModel atIndex:0];
        [_pictureBoolArray insertObject:@"0" atIndex:0];
        [_webOriginalArray insertObject:@"" atIndex:0];
        [_webThumbnailArray insertObject:@"" atIndex:0];
        
        [self.tableView reloadData];
        self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height, IPHONE_WIDTH, self.toolBarView.height);
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        self.moreView.frame = emotionDownFrame;
        self.emotionview.frame = emotionDownFrame;
        self.tableView.height = IPHONE_HEIGHT - self.keyBoardH - self.toolBarView.height - NAV_HEIGHT;
    }else{
        [_informationArray addObject:infomationModel];
        [_audioArray addObject:filePathStr];
        [_voiceArray addObject:voiceModel];
        [_chatTypeArray addObject:@"voice"];
        [_dataSourceArray addObject:model];
        [_localPictureArray addObject:localModel];
        [_webPictureArray addObject:webModel];
        [_pictureBoolArray addObject:@"0"];
        [_webOriginalArray addObject:@""];
        [_webThumbnailArray addObject:@""];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.chatTypeArray.count - 1 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}
//发送本地图片消息
- (void)sendLocalPictureMessageWithLocalStr:(NSString *)localStr OriginalImage:(UIImage *)originalImage ThumbnailImage:(UIImage *)thumbnailImage TimeStr:(NSString *)timeStr NameStr:(NSString *)nameStr HeaderStr:(NSString *)headerStr GuestStr:(NSString *)gustStr MemberId:(NSString *)memberId InformationId:(NSString *)informationId {
    WZHInformationModel * infomationModel = [[WZHInformationModel alloc] init];
    infomationModel.timeStr = timeStr;
    infomationModel.nameStr = nameStr;
    infomationModel.headerStr = headerStr;
    infomationModel.guestStr = gustStr;
    infomationModel.memberIdStr = memberId;
    infomationModel.informationId = informationId;
    
    WZHCellFrame *model = [[WZHCellFrame alloc] init];
    WZHVoiceMessage * voiceModel = [[WZHVoiceMessage alloc] init];
    WZHLocalPictureMessage * localModel = [[WZHLocalPictureMessage alloc] init];
    WZHWebPictureMessage * webModel = [[WZHWebPictureMessage alloc] init];localModel.originalImage = originalImage;
    localModel.thumbnailImage = thumbnailImage;
    if (_allRefreshBool == YES) {             //预留刷新历史消息
        [_informationArray insertObject:infomationModel atIndex:0];
        [_voiceArray insertObject:voiceModel atIndex:0];
        [_chatTypeArray insertObject:@"picture" atIndex:0];
        [_dataSourceArray insertObject:model atIndex:0];
        [_localPictureArray insertObject:localModel atIndex:0];
        [_webPictureArray insertObject:webModel atIndex:0];
        [_pictureBoolArray insertObject:@"2" atIndex:0];
        [_audioArray insertObject:@"" atIndex:0];
        [_webOriginalArray insertObject:@"" atIndex:0];
        [_webThumbnailArray insertObject:@"" atIndex:0];
        
        [self.tableView reloadData];
        self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height, IPHONE_WIDTH, self.toolBarView.height);
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        self.moreView.frame = emotionDownFrame;
        self.emotionview.frame = emotionDownFrame;
        self.tableView.height = IPHONE_HEIGHT - self.keyBoardH - self.toolBarView.height - NAV_HEIGHT;
    }else{
        [_informationArray addObject:infomationModel];
        [_voiceArray addObject:voiceModel];
        [_chatTypeArray addObject:@"picture"];
        [_dataSourceArray addObject:model];
        [_localPictureArray addObject:localModel];
        [_webPictureArray addObject:webModel];
        [_pictureBoolArray addObject:@"2"];
        [_audioArray addObject:@""];
        [_webOriginalArray addObject:@""];
        [_webThumbnailArray addObject:@""];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.chatTypeArray.count - 1 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}
//发送网络图片消息
- (void)sendWebPictureMessageWithLocalStr:(NSString *)localStr OriginalStr:(NSString *)originalStr ThumbnailStr:(NSString *)thumbnailStr TimeStr:(NSString *)timeStr NameStr:(NSString *)nameStr HeaderStr:(NSString *)headerStr GuestStr:(NSString *)gustStr MemberId:(NSString *)memberId InformationId:(NSString *)informationId {
    WZHInformationModel * infomationModel = [[WZHInformationModel alloc] init];
    infomationModel.timeStr = timeStr;
    infomationModel.nameStr = nameStr;
    infomationModel.headerStr = headerStr;
    infomationModel.guestStr = gustStr;
    infomationModel.memberIdStr = memberId;
    infomationModel.informationId = informationId;
    
    WZHCellFrame *model = [[WZHCellFrame alloc] init];
    WZHVoiceMessage * voiceModel = [[WZHVoiceMessage alloc] init];
    WZHLocalPictureMessage * localModel = [[WZHLocalPictureMessage alloc] init];
    WZHWebPictureMessage * webModel = [[WZHWebPictureMessage alloc] init];
    webModel.originalStr = originalStr;
    NSLog(@"%@",webModel.originalStr);
    webModel.thumbnailStr = thumbnailStr;
    
    if (_allRefreshBool == YES) {             //预留刷新历史消息
        [_informationArray insertObject:infomationModel atIndex:0];
        [_voiceArray insertObject:voiceModel atIndex:0];
        [_chatTypeArray insertObject:@"picture" atIndex:0];
        [_dataSourceArray insertObject:model atIndex:0];
        [_localPictureArray insertObject:localModel atIndex:0];
        [_webPictureArray insertObject:webModel atIndex:0];
        [_pictureBoolArray insertObject:@"1" atIndex:0];
        [_audioArray insertObject:@"" atIndex:0];
        [_webOriginalArray insertObject:originalStr atIndex:0];
        [_webThumbnailArray insertObject:thumbnailStr atIndex:0];
        
        [self.tableView reloadData];
        self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height, IPHONE_WIDTH, self.toolBarView.height);
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        self.moreView.frame = emotionDownFrame;
        self.emotionview.frame = emotionDownFrame;
        self.tableView.height = IPHONE_HEIGHT - self.keyBoardH - self.toolBarView.height - NAV_HEIGHT;
    }else{
        [_informationArray addObject:infomationModel];
        [_voiceArray addObject:voiceModel];
        [_chatTypeArray addObject:@"picture"];
        [_dataSourceArray addObject:model];
        [_localPictureArray addObject:localModel];
        [_webPictureArray addObject:webModel];
        [_pictureBoolArray addObject:@"1"];
        [_audioArray addObject:@""];
        [_webOriginalArray addObject:originalStr];
        [_webThumbnailArray addObject:thumbnailStr];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.chatTypeArray.count - 1 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - tableview代理方法和数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chatTypeArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_allRefreshBool == YES) {
        [_timeArray replaceObjectAtIndex:[_timeArray indexOfObject:_fistTimeStr] withObject:@""];
        [_timeArray replaceObjectAtIndex:0 withObject:_fistTimeStr];
    }
    NSString * typeStr = [NSString stringWithFormat:@"%@",_chatTypeArray[indexPath.row]];
    if ([typeStr isEqualToString:@"revocation"]) {
        static NSString * revocationID = @"revocationCell";
        UITableViewCell * revocationCell = [tableView dequeueReusableCellWithIdentifier:revocationID];
        if (!revocationCell) {
            revocationCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:revocationID];
        }
        UILabel * lab_revocation = [[UILabel alloc] init];
        lab_revocation.text = @"你撤回了一条消息";
        lab_revocation.textColor = FFFFFF;
        lab_revocation.backgroundColor = C999999;
        lab_revocation.frame = CGRectMake((IPHONE_WIDTH - [NSString getSizeByString:lab_revocation.text AndFontSize:12 size:CGSizeMake(IPHONE_WIDTH, 12 * ScaleY_Num)].width) / 2, 5 * ScaleY_Num, [NSString getSizeByString:lab_revocation.text AndFontSize:12 size:CGSizeMake(IPHONE_WIDTH, 12 * ScaleY_Num)].width, 12 * ScaleY_Num);
        [revocationCell addSubview:lab_revocation];
    }else if ([typeStr isEqualToString:@"text"]) {
        static NSString *ID = @"WZHChatCell";
        WZHChatViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
        if (!cell) {
            cell = [[WZHChatViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
        }
        NSInteger i = indexPath.row;
        
        [cell initWithTime:_timeArray[i] HeaderStr:[_informationArray valueForKey:@"headerStr"][i] Name:[_informationArray valueForKey:@"nameStr"][i] Guest:[_informationArray valueForKey:@"guestStr"][i] MessageWidth:[_dataSourceArray valueForKey:@"messageWidth"][i] MessageHight:[_dataSourceArray valueForKey:@"messageHight"][i] ChatMessageTag:i];
        [cell setCellFrame:[_dataSourceArray objectAtIndex:i]];
        cell.delegate = self;
        cell.backgroundColor = EEEEEE;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [_voiceBtnArray addObject:@""];
        return cell;
    }else if([typeStr isEqualToString:@"voice"]) {
        static NSString * VoiceID = @"WZHVoiceCell";
        WZHVoiceTableViewCell *firstCell = [tableView dequeueReusableCellWithIdentifier:VoiceID];
        if (!firstCell) {
            firstCell = [[WZHVoiceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:VoiceID];
        }
        NSInteger j = indexPath.row;
        [firstCell initWithTimeStr:_timeArray[j] HeaderStr:[_informationArray valueForKey:@"headerStr"][j] NameStr:[_informationArray valueForKey:@"nameStr"][j] CurrentRecordTime:[_voiceArray valueForKey:@"voiceTimeStr"][j] Guest:[_informationArray valueForKey:@"guestStr"][j] RecordTag:j];
        firstCell.backgroundColor = EEEEEE;
        firstCell.delegate = self;
        self.btn_voice = firstCell.btn_voice;
        [_voiceBtnArray addObject:_btn_voice];
        firstCell.selectionStyle = UITableViewCellSelectionStyleNone;
        return firstCell;
    }else if([typeStr isEqualToString:@"picture"]) {
        static NSString * pictureID = @"WZHPictureCell";
        WZHPictureTableViewCell *secondCell = [tableView dequeueReusableCellWithIdentifier:pictureID];
        if (!secondCell) {
            secondCell = [[WZHPictureTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:pictureID];
        }
        secondCell.backgroundColor = EEEEEE;
        NSInteger k = indexPath.row;
        NSString * pictureBoolStr = [NSString stringWithFormat:@"%@",_pictureBoolArray[k]];
        NSLog(@"pictureBoolStr === %@",pictureBoolStr);
        if ([pictureBoolStr isEqualToString:@"1"]) {
            [secondCell initWithTime:_timeArray[k] HeaderStr:[_informationArray valueForKey:@"headerStr"][k] Name:[_informationArray valueForKey:@"nameStr"][k] Guest:[_informationArray valueForKey:@"guestStr"][k] thumbnailStr:_webThumbnailArray[k] thumbnailImage:nil pictureBool:@"1" PictureTag:k];
        }else if ([pictureBoolStr isEqualToString:@"2"]) {
            [secondCell initWithTime:_timeArray[k] HeaderStr:[_informationArray valueForKey:@"headerStr"][k] Name:[_informationArray valueForKey:@"nameStr"][k] Guest:[_informationArray valueForKey:@"guestStr"][k] thumbnailStr:@"local" thumbnailImage:[_localPictureArray valueForKey:@"thumbnailImage"][k] pictureBool:@"2" PictureTag:k];
        }
        secondCell.delegate = self;
        [_voiceBtnArray addObject:@""];
        secondCell.selectionStyle = UITableViewCellSelectionStyleNone;
        return secondCell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * typeStr = [NSString stringWithFormat:@"%@",_chatTypeArray[indexPath.row]];
    NSString * timeStr = [NSString stringWithFormat:@"%@",_timeArray[indexPath.row]];
    if ([typeStr isEqualToString:@"revocation"]) {
        return 22 * ScaleY_Num;
    }else if ([typeStr isEqualToString:@"text"]) {
        WZHCellFrame *cellFrame = [self.dataSourceArray objectAtIndex:indexPath.row];
        if ([timeStr isEqualToString:@""]) {
            return cellFrame.cellHeight + 25 * ScaleY_Num;
        }else {
            return cellFrame.cellHeight + 45 * ScaleY_Num;
        }
    }else if([typeStr isEqualToString:@"voice"]){
        if ([timeStr isEqualToString:@""]) {
            return 60 * ScaleY_Num;
        }else {
            return 70 * ScaleY_Num;
        }
    }else if([typeStr isEqualToString:@"picture"]){
        if ([timeStr isEqualToString:@""]) {
            return 130 * ScaleY_Num;
        }else {
            return 140 * ScaleY_Num;
        }
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    self.toolBarView.frame = CGRectMake(0, IPHONE_HEIGHT - NAV_HEIGHT  - self.toolBarView.height, IPHONE_WIDTH, self.toolBarView.height);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.moreView.frame = emotionDownFrame;
    self.emotionview.frame = emotionDownFrame;
    self.tableView.height = IPHONE_HEIGHT - self.keyBoardH - self.toolBarView.height - NAV_HEIGHT;
}

#pragma mark 图片放大
- (void)PictureOriginalClicked:(UIButton *)pictureBtn {
    NSInteger k = pictureBtn.tag - 501;
    NSString * pictureBoolStr = [NSString stringWithFormat:@"%@",_pictureBoolArray[k]];
    if ([pictureBoolStr isEqualToString:@"1"]) {
        [[XLImageViewer shareInstanse] showNetImages:@[_webOriginalArray[k]] index:0 fromImageContainer:0];
    }else if ([pictureBoolStr isEqualToString:@"2"]) {
        UIImage * m_imgFore = [_localPictureArray valueForKey:@"originalImage"][k];
        //png格式
        NSData * imagedata = UIImagePNGRepresentation(m_imgFore);
        //JEPG格式
        //NSData * imagedata = UIImageJEPGRepresentation(m_imgFore, 1.0);
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString * documentsDirectory = [paths objectAtIndex:0];
        NSString * savedImagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png",(int)[NSDate date].timeIntervalSince1970]];
        [imagedata writeToFile:savedImagePath atomically:YES];
        [[XLImageViewer shareInstanse] showLocalImages:@[savedImagePath] index:0 fromImageContainer:0];
    }
}
#pragma mark 语音播放
- (void)VoiceClicked:(UIButton *)voiceBtn {
    voiceBtn.selected = !voiceBtn.selected;
    NSLog(@"%ld",voiceBtn.tag);
    NSString * tagStr = [NSString stringWithFormat:@"%04ld",voiceBtn.tag - 501];
    NSString * imageNumStr = [tagStr substringToIndex:tagStr.length - 2];
    NSString * arrayStr = [tagStr substringFromIndex:tagStr.length - 2];
    
    //    ((UIButton *)[_voiceBtnArray objectAtIndex:0]).selected=NO; //点击其他button之后这里设置为非选中状态
    //    NSLog(@"%@",_voiceBtnArray);
    //    //声音动态
    //    if (voiceBtn.selected == YES) {
    //        if ([imageNumStr intValue] == 0) {
    //            voiceBtn.imageView.animationImages = @[[UIImage imageNamed:@"right-3"],
    //                                                   [UIImage imageNamed:@"right-1"],
    //                                                   [UIImage imageNamed:@"right-2"]
    //                                                   ];
    //            voiceBtn.imageView.animationDuration = 0.6;
    //            [voiceBtn.imageView startAnimating];
    //        }else if ([imageNumStr intValue] == 1){
    //            voiceBtn.imageView.animationImages = @[[UIImage imageNamed:@"left-3"],
    //                                                   [UIImage imageNamed:@"left-1"],
    //                                                   [UIImage imageNamed:@"left-2"]
    //                                                   ];
    //            voiceBtn.imageView.animationDuration = 0.6;
    //            [voiceBtn.imageView startAnimating];
    //        }
    //    }else{
    //        if ([imageNumStr intValue] == 0) {
    //            voiceBtn.imageView.animationImages = @[[UIImage imageNamed:@"right-3"]];
    //        }else if ([imageNumStr intValue] == 1){
    //            voiceBtn.imageView.animationImages = @[[UIImage imageNamed:@"left-3"]];
    //        }
    //    }
    
    NSString *wavSavePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *name = [NSString stringWithFormat:@"play.wav"];
    wavSavePath=[wavSavePath stringByAppendingPathComponent:name];
    
    NSInteger i = [arrayStr intValue];
    NSArray * array = _audioArray;
    [AudioConverter convertAmrToWavAtPath:array[i] wavSavePath:wavSavePath asynchronize:NO completion:^(BOOL success, NSString * _Nullable resultPath) {
        if (success) {
            _docDirPath = wavSavePath;
            NSLog(@"wavSavePath === %@",wavSavePath);
            if ([_player isPlaying]) {
                [_player stop];
                _player = nil;
            }
            _player = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:wavSavePath] error:nil];
            NSLog(@"%@",array[i]);
            if ([_player isPlaying]) {
                return;
            }
            [_player play];
        }
    }];
}

#pragma mark 剔除相同时间
- (void)nowTimeEqualJudge:(NSString *)nowStr {
    NSDate * timeDate = [NSDate timeStringToDate:nowStr];
    NSString *requiredString = [timeDate dateToRequiredString1];
    if (_allRefreshBool == YES) {            //预留刷新历史消息时间倒序
        if (_timeArray.count > 0) {
            NSString * timeBoolStr = [NSString stringWithFormat:@"%@",_timeArray[0]];
            _fistTimeStr = requiredString;
            if ([timeBoolStr isEqualToString:@""]) {
                timeBoolStr = _timeJudgeStr;
            }
            if ([timeBoolStr isEqualToString:requiredString]) {
                [_timeArray insertObject:@"" atIndex:0];
                _timeJudgeStr = requiredString;
            }else {
                [_timeArray insertObject:requiredString atIndex:0];
            }
        }else {
            [_timeArray insertObject:requiredString atIndex:0];
        }
    }else {
        if (_timeArray.count > 0) {
            NSString * timeBoolStr = [NSString stringWithFormat:@"%@",_timeArray[_timeArray.count - 1]];
            if ([timeBoolStr isEqualToString:@""]) {
                timeBoolStr = _timeJudgeStr;
            }
            if ([timeBoolStr isEqualToString:requiredString]) {
                [_timeArray addObject:@""];
                _timeJudgeStr = requiredString;
            }else {
                [_timeArray addObject:requiredString];
            }
        }else {
            [_timeArray addObject:requiredString];
        }
    }
}

#pragma mark 复制撤销删除收藏
- (void)ChatMessageClicked:(UILongPressGestureRecognizer *)longBtn {
    self.alert = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"撤回",@"删除", nil];
    [_alert show];
    self.recognizerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [_recognizerTap setNumberOfTapsRequired:1];
    _recognizerTap.cancelsTouchesInView = NO;
    [[UIApplication sharedApplication].keyWindow addGestureRecognizer:_recognizerTap];
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded){
        CGPoint location = [sender locationInView:nil];
        if (![_alert pointInside:[_alert convertPoint:location fromView:_alert.window] withEvent:nil]){
            [_alert.window removeGestureRecognizer:sender];
            [_alert dismissWithClickedButtonIndex:0 animated:YES];
        }
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSLog(@"@22222222222222");
    }
    if (buttonIndex == 2) {
        NSLog(@"444444444444444");
    }
}

#pragma mark 语音
- (void)voiceBtnClickDown:(UIButton *)btn {//按下
    _filePath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *name = [NSString stringWithFormat:@"%d.wav",(int)[NSDate date].timeIntervalSince1970];
    _filePath=[_filePath stringByAppendingPathComponent:name];
    
    if ([_player isPlaying]) {
        [_player stop];
        _player = nil;
    }
    NSLog(@"按下");
    [btn setTitle:@"松开 结束" forState:UIControlStateNormal];
    NSURL *url=[NSURL fileURLWithPath:_filePath];
    
    /*
     说明：项目在聊天时，Android 发送的语音格式为Android默认的 amr 格式，iOS 发送的格式为iOS默认的 wav 格式转 amr 格式(iOS优先为Android适配，原因是wav文件比较大，amr文件小，传送速度快)。
         Android 接收到 iOS 发送的语音，原则上播放没有问题；iOS 接收到 Android 发送的语音，可能会出现两种情况：
         1、播放有杂音；
         2、不能播放，原因是 Android 所发送的语音虽然是 amr 格式，其实是 MPEG-4 格式，可以下载下载 mediainfo for Mac ，对比录制的 amr 参数是否一致。
         以上两种情况，极大可能是因为 Android 中 MediaRecorder 的录制参数有问题以及输出文件格式设置错误，所以只要将 MediaRecorder 的音频设置，设置为 AMR 即可。
     
     Android 端相关参考代码：
     
     // 设置所录制的声音的采样率。
     mMediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
     //设置音频文件的编码：AAC/AMR_NB/AMR_MB/Default 声音的（波形）的采样
    mMediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.AMR_NB);
    // 设置输出文件的格式：THREE_GPP/MPEG-4/RAW_AMR/Default THREE_GPP(3gp格式，H263视频/ARM音频编码)、MPEG-4、RAW_AMR(只支持音频且音频编码要求为AMR_NB)
    mMediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
    // 文件保存地址及名字
    targetFile = new File(targetDir, targetName);
    //设置输出文件的路径
    mMediaRecorder.setOutputFile(targetFile.getPath());
    // 设置录制的音频通道数
    mMediaRecorder.setAudioChannels(1);
    // 设置所录制的声音的采样率。
    mMediaRecorder.setAudioSamplingRate(8000);
    // 设置所录制的声音的编码位率。
    mMediaRecorder.setAudioEncodingBitRate(64);
    
     */
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc]init];
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    [recordSetting setValue:[NSNumber numberWithFloat:8000] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    if (!_session) {
        _session = [AVAudioSession sharedInstance];
        if ([_session respondsToSelector:@selector(requestRecordPermission:)]) {
            [_session performSelector:@selector(requestRecordPermission:) withObject:^(BOOL isTrue){
                if (isTrue) {
                }else{
                    NSLog(@"app需要访问您的麦克风。");
                }
            }];
        }
        [_session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }
    _record = [[AVAudioRecorder alloc]initWithURL:url settings:recordSetting error:nil];
    _record.meteringEnabled = YES;//监听音量大小
    [_record prepareToRecord];
    [_record record];
    
    UIView * recordView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 150 * ScaleX_Num, 150 * ScaleY_Num)];
    recordView.layer.cornerRadius = 8.0f;
    recordView.backgroundColor = [UIColor clearColor];
    recordView.tag = 101;
    
    UIImageView * micImg = [[UIImageView alloc]initWithFrame:CGRectMake(25 * ScaleX_Num, -20 * ScaleY_Num, 100 * ScaleX_Num, 180 * ScaleY_Num)];
    micImg.contentMode = UIViewContentModeLeft;
    [micImg setImage:[UIImage imageNamed:@"voice_1"]];
    micImg.tag = 135;
    
    self.voiceFloat = 0;
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(voiceChange:) userInfo:nil repeats:YES];
    
    UIImageView * micImgCan = [[UIImageView alloc]initWithFrame:CGRectMake(25 * ScaleX_Num, -20 * ScaleY_Num, 100 * ScaleX_Num, 180 * ScaleY_Num)];
    micImgCan.contentMode = UIViewContentModeLeft;
    micImgCan.image = [UIImage imageNamed:@"cancelVoice"];
    micImgCan.tag = 134;
    
    micImgCan.hidden = YES;
    micImg.hidden = NO;
    
    [recordView addSubview:micImg];
    [recordView addSubview:micImgCan];
    self.voiceView.frame = CGRectMake(0, 0, 150 * ScaleX_Num, 150 * ScaleX_Num);
    self.voiceView.center = CGPointMake(IPHONE_WIDTH / 2, (IPHONE_HEIGHT - 2 * NAV_HEIGHT) / 2);
    [self.voiceView addSubview:recordView];
}

- (void)voiceChange:(NSTimer *)timer {
    UIView * view = [self.view viewWithTag:101];
    UIImageView * micImg = [view viewWithTag:135];
    [_record updateMeters];//刷新音量数据
    CGFloat lowPassResults = pow(10, (0.05 * [_record peakPowerForChannel:0]));
    //  根据音量大小选择显示图片  图片 小-》大
    if (0.01 < lowPassResults <=0.05) {
        [micImg setImage:[UIImage imageNamed:@"voice_1"]];
    }else if (0.05 < lowPassResults <=0.1) {
        [micImg setImage:[UIImage imageNamed:@"voice_1"]];
    }else if (0.1 < lowPassResults <=0.15) {
        [micImg setImage:[UIImage imageNamed:@"voice_2"]];
    }else if (0.15 < lowPassResults <=0.2) {
        [micImg setImage:[UIImage imageNamed:@"voice_2"]];
    }else if (0.2 < lowPassResults <=0.25) {
        [micImg setImage:[UIImage imageNamed:@"voice_3"]];
    }else if (0.25 < lowPassResults <=0.3) {
        [micImg setImage:[UIImage imageNamed:@"voice_2"]];
    }else if (0.3 < lowPassResults <=0.35) {
        [micImg setImage:[UIImage imageNamed:@"voice_3"]];
    }else if (0.35 < lowPassResults <=0.4) {
        [micImg setImage:[UIImage imageNamed:@"voice_2"]];
    }else if (0.4 < lowPassResults <=0.45) {
        [micImg setImage:[UIImage imageNamed:@"voice_3"]];
    }else if (0.45 < lowPassResults <=0.5) {
        [micImg setImage:[UIImage imageNamed:@"voice_2"]];
    }else if (0.5 < lowPassResults <=0.55) {
        [micImg setImage:[UIImage imageNamed:@"voice_3"]];
    }else if (0.55 < lowPassResults <=0.6) {
        [micImg setImage:[UIImage imageNamed:@"voice_4"]];
    }else if (0.6 < lowPassResults <=0.65) {
        [micImg setImage:[UIImage imageNamed:@"voice_3"]];
    }else if (0.65 < lowPassResults <=0.7) {
        [micImg setImage:[UIImage imageNamed:@"voice_4"]];
    }else if (0.7 < lowPassResults <=0.75) {
        [micImg setImage:[UIImage imageNamed:@"voice_3"]];
    }else if (0.75 < lowPassResults <=0.8) {
        [micImg setImage:[UIImage imageNamed:@"voice_4"]];
    }else if (0.8 < lowPassResults <=0.85) {
        [micImg setImage:[UIImage imageNamed:@"voice_5"]];
    }else if (0.85 < lowPassResults <=0.9) {
        [micImg setImage:[UIImage imageNamed:@"voice_4"]];
    }else if (0.9 < lowPassResults <=0.95) {
        [micImg setImage:[UIImage imageNamed:@"voice_5"]];
    }else if (lowPassResults > 0.95) {
        [micImg setImage:[UIImage imageNamed:@"voice_6"]];
    }
    _voiceFloat = _voiceFloat + 0.1;
}

- (void)voiceBtnClickCancel:(UIButton *)btn {//意外取消
    NSLog(@"意外取消");
    [btn setTitle:@"松开 结束" forState:UIControlStateNormal];
    UIView * view = [self.view viewWithTag:101];
    [view removeFromSuperview];
    if ([_record isRecording]) {
        [_record stop];
        [_record deleteRecording];
    }
    _record = nil;
    if (_timer.isValid) {//判断timer是否在线程中
        [_timer invalidate];
    }
    _timer=nil;
}
- (void)voiceBtnClickUpInside:(UIButton *)btn {//点击(录音完成)
//    NSLog(@"_filePath === %@  count == %f",_filePath,_voiceFloat);
    UIView * view = [self.view viewWithTag:101];
    NSString *amrSavePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *name = [NSString stringWithFormat:@"%d.amr",(int)[NSDate date].timeIntervalSince1970];
    amrSavePath=[amrSavePath stringByAppendingPathComponent:name];
    NSLog(@"点击");
    
    [AudioConverter convertWavToAmrAtPath:_filePath amrSavePath:amrSavePath asynchronize:YES completion:^(BOOL success, NSString * _Nullable resultPath) {
        if (success) {
            if (_voiceFloat < 1) {
                UIImageView * micImg = [view viewWithTag:135];
                micImg.hidden = YES;
                UIImageView * micImgCan = [view viewWithTag:134];
                [micImgCan setImage:[UIImage imageNamed:@"voiceShort"]];
                micImgCan.hidden = NO;
                
            }else {
                int result = (int)roundf(_voiceFloat);      //时间四舍五入
                _allRefreshBool = NO;
                [self nowTimeEqualJudge:[NSDate getNowDate5]];
                NSString * guestStr = [NSString stringWithFormat:@"%d",random_Num];
                [self sendVoiceMessageWithFilePathStr:amrSavePath VoiceTimeStr:[NSString stringWithFormat:@"%d",result] TimeStr:@"" NameStr:@"WOHANGO" HeaderStr:HEADERIMAGE GuestStr:guestStr MemberId:MEMBERID InformationId:@""];     //做网络接口的时候可能要删除掉此代码
                
                /*
                 发送消息到服务器接口预留位置，建议：先把语音消息发到服务器，再由服务器获取语音网络连接，再加载语音消息UI，不然实现的时候要判断是语音消息还是本地消息
                 [self sendVoiceMessageWithFilePathStr:<#(NSString *)#> VoiceTimeStr:<#(NSString *)#> TimeStr:<#(NSString *)#> NameStr:<#(NSString *)#> HeaderStr:<#(NSString *)#> GuestStr:<#(NSString *)#> MemberId:<#(NSString *)#> InformationId:<#(NSString *)#>]
                 */
                
                // 创建插入语句
                NSString *insertSql = @"insert into t_Contacts(id, type, icon, name, fromId, toId, createTime, content, audioTimeSecond, audio, thumbnail, original) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                BOOL result1;
                if ([guestStr intValue] == 0) {
                    result1 = [_originalData executeUpdate:insertSql, [NSString stringWithFormat:@"%ld",_hostory_Id], @"3", HEADERIMAGE, @"主人", MEMBERID, GUESTMEMBERID, [NSDate getNowDate5], @"", [NSString stringWithFormat:@"%d",result], amrSavePath, @"", @""];
                }else {
                    result1 = [_originalData executeUpdate:insertSql, [NSString stringWithFormat:@"%ld",_hostory_Id], @"3", GUESTHEADERIMAGE, @"WOHANGO", GUESTMEMBERID, MEMBERID, [NSDate getNowDate5], @"", [NSString stringWithFormat:@"%d",result], amrSavePath, @"", @""];
                }
                _hostory_Id ++;
                if (result1) {
                    NSLog(@"添加成功");
                } else {
                    NSLog(@"添加失败");
                }
            }
        }
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [view removeFromSuperview];
    });
    [btn setTitle:@"按住 说话" forState:UIControlStateNormal];
    [_record stop];
    if (_timer.isValid) {
        [_timer invalidate];
    }
    _timer=nil;
}

- (void)voiceBtnClickDragExit:(UIButton *)btn {//拖出
    NSLog(@"拖出");
    [btn setTitle:@"按住 说话" forState:UIControlStateNormal];
    UIView * view = [self.view viewWithTag:101];
    UIImageView * micImg = [view viewWithTag:135];
    micImg.hidden = YES;
    UIImageView * micImgCan = [view viewWithTag:134];
    micImgCan.hidden = NO;
}

- (void)voiceBtnClickUpOutside:(UIButton *)btn {//外部手势抬起
    NSLog(@"外部手势抬起");
    [btn setTitle:@"按住 说话" forState:UIControlStateNormal];
    UIView * view = [self.view viewWithTag:101];
    [view removeFromSuperview];
    if ([_record isRecording]) {
        [_record stop];
        [_record deleteRecording];
    }
    _record = nil;
    if (_timer.isValid) {
        [_timer invalidate];
    }
    _timer=nil;
}

- (void)voiceBtnClickDragEnter:(UIButton *)btn {//拖回
    NSLog(@"拖回");
    [btn setTitle:@"松开 结束" forState:UIControlStateNormal];
    UIView * view = [self.view viewWithTag:101];
    UIImageView * micImg = [view viewWithTag:135];
    micImg.hidden = NO;
    
    UIImageView * micImgCan = [view viewWithTag:134];
    micImgCan.hidden = YES;
    
}

#pragma mark ----- nav右按钮
- (void)addNavRightBtton {
    UIButton * btn_navRight = [UIButton buttonWithType:UIButtonTypeCustom];
    btn_navRight.frame = CGRectMake(0, 0, 50 * ScaleX_Num, 16 * ScaleY_Num);
    [btn_navRight setTitle:@"清除历史记录" forState:UIControlStateNormal];
    btn_navRight.titleLabel.font = UIFONT_SYS(10);
    [btn_navRight addTarget:self action:@selector(clickNacRightBtn) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn_navRight];
}
- (void)clickNacRightBtn {
    [_informationArray removeAllObjects];
    [_audioArray removeAllObjects];
    [_voiceArray removeAllObjects];
    [_chatTypeArray removeAllObjects];
    [_dataSourceArray removeAllObjects];
    [_localPictureArray removeAllObjects];
    [_webPictureArray removeAllObjects];
    [_pictureBoolArray removeAllObjects];
    [_webOriginalArray removeAllObjects];
    [self.tableView reloadData];
    
    //如果表格存在 则销毁
    BOOL result = [_originalData executeUpdate:@"drop table if exists t_Contacts"];
    if (result) {
        NSLog(@"删除表成功");
        BOOL result1 = [_originalData executeUpdate:@"CREATE TABLE IF NOT EXISTS t_Contacts (id text NOT NULL, type text NOT NULL, icon text NOT NULL, name text NOT NULL, fromId text NOT NULL, toId text NOT NULL, createTime text NOT NULL, content text NOT NULL, audioTimeSecond text NOT NULL, audio text NOT NULL, thumbnail text NOT NULL, original text NOT NULL);"];
        if (result1) {
            NSLog(@"创建表成功");
        } else {
            NSLog(@"创建表失败");
        }
        _hostory_Id = 1000;
    } else {
        NSLog(@"删除表失败");
    }
    
}

@end



