//
//  ViewController.m
//  GetSensorData
//
//  Created by mengyijie on 17/2/25.
//  Copyright © 2017年 mengyijie. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <stdio.h>
@interface ViewController ()<UIAccelerometerDelegate>

/** 运动管理者 */
@property (nonatomic, strong) CMMotionManager *mgr; // 保证不死
@property (weak, nonatomic) IBOutlet UILabel *cqLabel;//磁场强度
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UILabel *xLabel;
@property (weak, nonatomic) IBOutlet UILabel *yLabel;
@property (weak, nonatomic) IBOutlet UILabel *zLabel;
@property (weak, nonatomic) IBOutlet UILabel *fxLabel;
@property (weak, nonatomic) IBOutlet UIImageView *ImageView;
@property (nonatomic, assign) double intensity;
@end

@implementation ViewController
#pragma mark - 懒加载
- (CMMotionManager *)mgr
{
    if (_mgr == nil) {
        _mgr = [[CMMotionManager alloc] init];
        
    }
    return _mgr;
}

-(CLLocationManager *)locationManager{
    if(!_locationManager){
        _locationManager = [[CLLocationManager alloc]init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;

    //判断是否可用
    if(!self.mgr.isAccelerometerAvailable){
        return;
    }else{
        self.mgr.accelerometerUpdateInterval = 1;
    
    }
    if(self.locationManager.locationServicesEnabled)
     [self ciliji];
    [self.locationManager startUpdatingHeading];
    //[self addSpeed];加速计测试
    //[self tuoluoyi];
    //[self jiajiao];
//    距离感应
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityStateDidChange) name:UIDeviceProximityStateDidChangeNotification object:nil];
    [self getBacklightLevel];
}

- (void)getBacklightLevel {
    
    NSNumber * bl = (NSNumber *)CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR ("SBBacklightLevel"),CFSTR ("com.apple.springboard" )));
    float previousBacklightLevel = [ bl floatValue ]; //一个存储上一级别的变量，以便您可以重置它。
    NSLog(@"%f",previousBacklightLevel);
}


-(void)locationManager:(nonnull CLLocationManager *)manager didUpdateHeading:(nonnull CLHeading *)newHeading
{
    //获得当前设备
    UIDevice *device =[UIDevice currentDevice];
   
    //    判断磁力计是否有效,负数时为无效，越小越精确
    if (newHeading.headingAccuracy>0)
    {
        //地磁航向数据-》magneticHeading
        float Text1 =[self heading:newHeading.magneticHeading fromOrirntation:device.orientation];
        
        //地理航向数据-》trueHeading
        float Text2 =[self heading:newHeading.trueHeading fromOrirntation:device.orientation];
        //（0-90)东北 0是正北 90是正东
        //（90-180）东南 180 正南 (180 -270 )西南 270正西 （270-360（0））西北
         self.ImageView.image=[UIImage imageNamed:@"plate"];
        self.fxLabel.text = [NSString stringWithFormat:@"地磁方向:%.4f，地理方向:%.4f",Text1,Text2];
        
        float heading =-1.0f *M_PI *newHeading.magneticHeading /180.0f;
        //旋转变换
        self.ImageView.transform=CGAffineTransformMakeRotation(heading);
    
    }
}
-(float)heading:(float)heading fromOrirntation:(UIDeviceOrientation)orientation{
    
    float realHeading =heading;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            realHeading=heading-180.0f;
            break;
        case UIDeviceOrientationLandscapeLeft:
            realHeading=heading+90.0f;
            break;
        case UIDeviceOrientationLandscapeRight:
            realHeading=heading-90.0f;
            break;
        default:
            break;
    }
    if (realHeading>360.0f)
    {
        realHeading-=360.0f;
    }
    else if (realHeading<0.0f)
    {
        realHeading+=360.0f;
    }
    return  realHeading;
}

//判断设备是否需要校验，受到外来磁场干扰时
-(BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    return YES;
    
}


//磁力计
-(void)ciliji{
    if(!self.mgr.isMagnetometerAvailable){
        return;
    }else{
        self.mgr.magnetometerUpdateInterval = 1;
    }
    [self.mgr startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
        
        double heading = 0.0;
        double x = magnetometerData.magneticField.x;//X轴的磁感应强度
        double y = magnetometerData.magneticField.y;//y轴的磁感应强度
        double z = magnetometerData.magneticField.z;//z轴的磁感应强度
        self.xLabel.text = [NSString stringWithFormat:@"x轴的磁感应强度：%.4f",x];
        self.yLabel.text = [NSString stringWithFormat:@"y轴的磁感应强度：%.4f",y];
        self.zLabel.text = [NSString stringWithFormat:@"z轴的磁感应强度：%.4f",z];
        //磁场总强度
        self.intensity = sqrt(pow(x, 2)+pow(y, 2)+pow(z, 2));
        self.cqLabel.text = [NSString stringWithFormat:@"场强:%.4f",self.intensity];
    }];
}

-(void)jiajiao{
    if(!self.mgr.isDeviceMotionAvailable){
        return;
    }else{
        self.mgr.deviceMotionUpdateInterval = 1;//这是设置频率的地方
    }
    [self.mgr startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
         double rotation = atan2(motion.gravity.x, motion.gravity.y) - M_PI;
        
        NSLog(@"%f",rotation);
        
        //2. Gravity 获取手机的重力值在各个方向上的分量，根据这个就可以获得手机的空间位置，倾斜角度等
        double gravityX = motion.gravity.x;
        double gravityY = motion.gravity.y;
        double gravityZ = motion.gravity.z;
        
        //获取手机的倾斜角度(zTheta是手机与水平面的夹角， xyTheta是手机绕自身旋转的角度)：
        double zTheta = atan2(gravityZ,sqrtf(gravityX*gravityX+gravityY*gravityY))/M_PI*180.0;
        double xyTheta = atan2(gravityX,gravityY)/M_PI*180.0;
        
        NSLog(@"%f   %f",zTheta,xyTheta);
        
    }];
}

//陀螺仪
-(void)tuoluoyi{
    if(!self.mgr.isGyroAvailable){
        return;
    }else{
        self.mgr.gyroUpdateInterval = 1;
    }
    [self.mgr startGyroUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        CMRotationRate rate = self.mgr.gyroData.rotationRate;
        NSLog(@"陀螺仪--------x:%f y:%f z:%f", rate.x, rate.y, rate.z);

    }];
}

//加速计
-(void)addSpeed{
    // 1.判断加速计是否可用
    if (!self.mgr.isAccelerometerAvailable) {
        NSLog(@"加速计不可用");
        return;
    }
    
    // 2.设置采样间隔
    self.mgr.accelerometerUpdateInterval = 0.3;
    
    // 3.开始采样
    [self.mgr startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) { // 当采样到加速计信息时就会执行
        if (error) return;
        
        // 4.获取加速计信息
        CMAcceleration acceleration = accelerometerData.acceleration;
        NSLog(@"x:%f y:%f z:%f", acceleration.x, acceleration.y, acceleration.z);
    }];
}

//加速计
- (void)startAccelerometerUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMAccelerometerHandler)handler{
    CMAcceleration acceleration = self.mgr.accelerometerData.acceleration;
    NSLog(@"加速计------x:%f y:%f z:%f", acceleration.x, acceleration.y, acceleration.z);
}
//陀螺仪
- (void)startGyroUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMGyroHandler)handler{
    CMRotationRate rate = self.mgr.gyroData.rotationRate;
    NSLog(@"陀螺仪--------x:%f y:%f z:%f", rate.x, rate.y, rate.z);
    
}


- (void)startMagnetometerUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMMagnetometerHandler)handler{
    
}

- (void)proximityStateDidChange
{
    if ([UIDevice currentDevice].proximityState) {
        NSLog(@"有物品靠近~");
    } else {
        NSLog(@"有物品离开~");
    }
}
-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


-(CGFloat) degreesToRadians:(CGFloat) degrees {return degrees * M_PI / 180;};
- (CGFloat) radiansToDegrees:(CGFloat) radians {return radians * 180/M_PI;};




@end
