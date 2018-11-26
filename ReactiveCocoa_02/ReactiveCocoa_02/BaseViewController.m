//
//  BaseViewController.m
//  ReactiveCocoa_01
//
//  Created by TsouMac2016 on 2018/11/20.
//  Copyright © 2018 TsouMac2016. All rights reserved.
//

#import "BaseViewController.h"
#import <ReactiveObjC.h>
#import <RACEXTScope.h>
#import <RACReturnSignal.h>
//#import "TwoViewController.h"

@interface BaseViewController ()
@property (nonatomic, strong) UIButton *btn;
@property (nonatomic, strong) RACCommand *command;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextField *showTextField;

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // RASubject delegate
    self.btn = [UIButton buttonWithType:UIButtonTypeCustom];
    _btn.frame = CGRectMake(100, 200, 100, 50);
    _btn.backgroundColor = [UIColor redColor];
    [_btn addTarget:self action:@selector(handleBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btn];
    
    self.textField = [[UITextField alloc]initWithFrame:CGRectMake(100, 350, 100, 40)];
    _textField.textColor = [UIColor blackColor];
    _textField.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_textField];
    //
    self.showTextField = [[UITextField alloc]initWithFrame:CGRectMake(100, 400, 300, 40)];
    _showTextField.textColor = [UIColor blackColor];
    _showTextField.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_showTextField];
    
    // test
    [self testreplay];
    
}

#pragma mark -test bind
-(void)testBind{
    // 需求：假设想监听文本框的内容，并且在每次输出结果的时候，都在文本框的内容拼接一段文字  “你输入的内容：“
    // 方式一：返回结果以后，进行处理
    @weakify(self);
    [[_textField.rac_textSignal skip:1] subscribeNext:^(NSString * _Nullable x) {
        @strongify(self);
        self.showTextField.text = [NSString stringWithFormat:@"你输入的内容：%@",x];

    }];
    
    // 返回结果之前，进行处理
    // bind方法参数:需要传入一个返回值是RACStreamBindBlock的block参数
    // RACStreamBindBlock是一个block的类型，返回值是信号，参数（value,stop），因此参数的block返回值也是一个block。
    // RACStreamBindBlock:
    // 参数一(value):表示接收到信号的原始值，还没做处理
    // 参数二(*stop):用来控制绑定Block，如果*stop = yes,那么就会结束绑定。
    // 返回值：信号，做好处理，在通过这个信号返回出去，一般使用RACReturnSignal,需要手动导入头文件RACReturnSignal.h。
    
    // bind方法使用步骤:
    // 1.传入一个返回值RACStreamBindBlock的block。
    // 2.描述一个RACStreamBindBlock类型的bindBlock作为block的返回值。
    // 3.描述一个返回结果的信号，作为bindBlock的返回值。
    // 注意：在bindBlock中做信号结果的处理。
    
    // 底层实现:
    // 1.源信号调用bind,会重新创建一个绑定信号。
    // 2.当绑定信号被订阅，就会调用绑定信号中的didSubscribe，生成一个bindingBlock。
    // 3.当源信号有内容发出，就会把内容传递到bindingBlock处理，调用bindingBlock(value,stop)
    // 4.调用bindingBlock(value,stop)，会返回一个内容处理完成的信号（RACReturnSignal）。
    // 5.订阅RACReturnSignal，就会拿到绑定信号的订阅者，把处理完成的信号内容发送出来。
    
    // 注意:不同订阅者，保存不同的nextBlock，看源码的时候，一定要看清楚订阅者是哪个。
    // 这里需要手动导入#import <ReactiveCocoa/RACReturnSignal.h>，才能使用RACReturnSignal。
    
    
    [[_textField.rac_textSignal bind:^RACSignalBindBlock _Nonnull{
        // 什么时候调用：
        // block左右：表示绑定一个信号
        return ^RACSignal *(id value, BOOL *stop){
            
            // 什么时候调用block:当信号有新的值发出，就会来到这个block。
            
            // block作用:做返回值的处理
            
            // 做好处理，通过信号返回出去.
            //1.
            return [RACReturnSignal return:[NSString stringWithFormat:@"这里是内容:%@",value]];
            //2.
            return [RACReturnSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                [subscriber sendNext:[NSString stringWithFormat:@"这里是内容:%@",value]];
                [subscriber sendCompleted];
                return nil;
            }];
        };
        
        
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
}

#pragma mark -映射方法列举

-(void)testMapOrFlattenMap{
    [[_textField.rac_textSignal flattenMap:^__kindof RACSignal * _Nullable(NSString * _Nullable value) {
        // 1.
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [subscriber sendNext:[NSString stringWithFormat:@"输出:%@",value]];
            [subscriber sendCompleted];
            return nil;
        }];
        // 2.
//        return [RACSignal return:[NSString stringWithFormat:@"输出:%@",value]];
        
    }] subscribeNext:^(id  _Nullable x) {
        // 订阅绑定信号，每当源信号发送内容，做完处理，就会调用这个block。
        
        NSLog(@"%@",x);
    }];
}

#pragma mark -组合方法列举

-(void)testConcat{
    
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        
        [subscriber sendCompleted];
        
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    
    RACSignal *concatSignal = [signalA concat:signalB];
    [concatSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    
}

-(void)testThen{
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@"这个原始信息"];
        
        [subscriber sendCompleted];
        
        return nil;
    }]then:^RACSignal * _Nonnull{
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [subscriber sendNext:@"这个then里面的信息"];
            [subscriber sendCompleted];
            return nil;
        }];
    }]subscribeNext:^(id  _Nullable x) {
        // 只能接收到第二个信号的值，也就是then返回信号的值
        NSLog(@"%@",x);
    }];
}

-(void)textMerge{
    // merge:把多个信号合并成一个信号
    //创建多个信号
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@111111];
        
        
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@22222];
        
        return nil;
    }];
    
    // 合并信号,任何一个信号发送数据，都能监听到.
    RACSignal *mergeSignal = [signalA merge:signalB];
    
    [mergeSignal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
        
    }];
    
    // 底层实现：
    // 1.合并信号被订阅的时候，就会遍历所有信号，并且发出这些信号。
    // 2.每发出一个信号，这个信号就会被订阅
    // 3.也就是合并信号一被订阅，就会订阅里面所有的信号。
    // 4.只要有一个信号被发出就会被监听。
    
}

-(void)testZipWith{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@123];
        
        
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
//        [subscriber sendNext:@245];
        
        return nil;
    }];
    
    // 压缩信号A，信号B
    RACSignal *zipSignal = [signalA zipWith:signalB];
    
    [zipSignal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
}

-(void)testReduce{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    // 先组合再聚合
    RACSignal *reduceSignal = [RACSignal combineLatest:@[signalA,signalB] reduce:^id (NSNumber *num1, NSNumber *num2){
        return [NSString stringWithFormat:@"%@ %@",num1,num2];
    }];
    // 订阅
    [reduceSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"这厮：%@",x);
    }];
    
}

#pragma mark -操作方法之秩序

-(void)testDoNextOrDoCompleted{
    
    [[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return nil;
    }] doNext:^(id x) {
        // 执行[subscriber sendNext:@1];之前会调用这个Block
        NSLog(@"doNext");;
    }] doCompleted:^{
        // 执行[subscriber sendCompleted];之前会调用这个Block
        NSLog(@"doCompleted");;
    }] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    
}

#pragma mark -操作方法之时间

-(void)testTime{
    
    // timeout 定时
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //
        return nil;
        
    }]timeout:1 onScheduler:[RACScheduler currentScheduler]]subscribeNext:^(id  _Nullable x) {
        //
        
    }error:^(NSError * _Nullable error) {
        
        //1 秒后就会自动报错
        NSLog(@"%@",error);
        
    }];
    
    // interval 定时
    [[RACSignal interval:1 onScheduler:[RACScheduler currentScheduler]]subscribeNext:^(NSDate * _Nullable x) {
        NSLog(@"间隔1秒钟就返回一个信号");
    }];
    
    // 延迟 delay
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        return nil;
    }] delay:2] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    
    
}

#pragma mark -操作方法之重复

-(void)testretry{
    // 10次执行成功
    __block int i = 0;
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        if (i == 10) {
            [subscriber sendNext:@1];
        }else{
            NSLog(@"接收到错误");
            [subscriber sendError:nil];
        }
        i++;
        
        return nil;
        
    }] retry] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
        
    } error:^(NSError *error) {
        
        
    }];
    
    // 一次执行成功
    __block int k = 0;
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        if (k == 0) {
            [subscriber sendNext:@"1"];
        }else{
            [subscriber sendError:nil];
        }
        return nil;
        
    }] retry] subscribeNext:^(id  _Nullable x) {
        
        NSLog(@"一次性成功：%@",x);
        
    }error:^(NSError * _Nullable error) {
        
    }];
    
}

-(void)testreplay{
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        
        return nil;
    }] replay];
    
    [signal subscribeNext:^(id x) {
        
        NSLog(@"第一个订阅者%@",x);
        
    }];
    
    [signal subscribeNext:^(id x) {
        
        NSLog(@"第二个订阅者%@",x);
        
    }];
    
    
}





-(void)handleBtn:(UIButton *)btn{
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
