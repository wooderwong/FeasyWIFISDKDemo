//
//  FscBleCentralApi.h
//  FscBleCentral
//
//  Created by Feasycom on 2017/12/26.
//  Copyright © 2017 Feasycom. All rights reserved.
//


#import "BluetoothManager.h"
#import <UIKit/UIKit.h>

typedef void (^returnBlock)(void);


@interface BluetoothManager() <CBCentralManagerDelegate, CBPeripheralDelegate>


@property(nonatomic, strong) CBCentralManager *activeCentralManager;

@property(nonatomic, strong) CBPeripheral *activePeripheral;
 
@property (nonatomic, copy) void (^queryIpSuccessBlock)(NSString *str);

//@property (nonatomic, copy) void (^successBlock)(void);诉毛苦

@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;
@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic;
@property (nonatomic, strong) CBCharacteristic *readCharacteristic;

@property(nonatomic, copy) NSString *wifi;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, assign) int index;

@end

@implementation BluetoothManager

static BluetoothManager *bluetoothManager = nil;

+ (BluetoothManager *)sharedBluetoothManager {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        
        if (bluetoothManager == nil) {
            bluetoothManager = [[BluetoothManager alloc] init];
        }
    });
    return bluetoothManager;
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    _activeCentralManager = central;
    switch (central.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"CBManagerStatePoweredOn");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"CBManagerStatePoweredOff");
            break;
        default:
            NSLog(@"CBManagerState-unknow");
            break;
    }
}

- (void)activeCentralManager:(CBCentralManager *)activeCentralManager connectPerpheral:(CBPeripheral *)inPeripheral queryIpSuccessBlock:(void (^)(NSString *str))queryIpSuccessBlock{
//    _queryIpSuccessBlock = queryIpSuccessBlock;
    _index = 1;
    
}

#pragma mark - CoreBluetooth
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"连接成功");
    _activePeripheral.delegate = self;
    [_activePeripheral discoverServices:nil];
}

- (void)activeCentralManager:(CBCentralManager *)activeCentralManager connectPerpheral:(CBPeripheral *)inPeripheral  wifiName:(NSString *)wifi password:(NSString *)password{
    
    _activeCentralManager = activeCentralManager;
    _activePeripheral = inPeripheral;
//    [_activeCentralManager connectPeripheral:inPeripheral options:nil];
    [_activeCentralManager connectPeripheral:inPeripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@1,CBConnectPeripheralOptionNotifyOnNotificationKey:@1}];
    NSLog(@"activeCentralManager - %@", activeCentralManager);
    NSLog(@"inPeripheral - %@", inPeripheral);

    _activeCentralManager.delegate = self;
    _activePeripheral.delegate = self;

    _wifi = wifi;
    _password = password;

    
    /*
     //发送配网指令
     NSString *dataStr = [NSString stringWithFormat:@"AT+RAP=%@,%@\r\n",wifi,password];
     NSLog(@"发送指令%@",dataStr);
     NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
     [_activePeripheral writeValue:data forCharacteristic:writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
     */
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic * characteristic in service.characteristics) {
        if (characteristic.properties & CBCharacteristicPropertyRead) {
            //拿到可读的特征了
            _readCharacteristic = characteristic;
            //            [peripheral readValueForCharacteristic:characteristic];
        }
        if (characteristic.properties & CBCharacteristicPropertyNotify || characteristic.properties & CBCharacteristicPropertyIndicate) {
            //拿到可监听的特征了
            _notifyCharacteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse){
            //拿到可写的特征了
            _writeCharacteristic = characteristic;
            if (_writeCharacteristic) {
                NSData *data = [@"$OpenFscAtEngine$" dataUsingEncoding:NSUTF8StringEncoding];
                [peripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *str = [NSString stringWithUTF8String:(char *)[characteristic.value bytes]];
    NSLog(@"打印%@",str);
     
    NSLog(@"WW_wifi——%@",_wifi);

    if (_wifi) {
        if ([str isEqualToString:@"$OK,Opened$"]) {
            NSString *dataStr = [NSString stringWithFormat:@"AT+RAP=%@,%@\r\n",_wifi, _password];
            NSLog(@"WW发送指令%@",dataStr);
            
            NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
            [_activePeripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
        }
        
    }else  if(_index == 1){
        NSLog(@"WW发送指令AT+LIP\r\n");

        NSData *lipData = [@"AT+LIP\r\n" dataUsingEncoding:NSUTF8StringEncoding];
        [_activePeripheral writeValue:lipData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
        
    }else if ([str rangeOfString:@"+LIP="].location != NSNotFound) {
            //停止
            NSLog(@"WW读到指令+LIP=");

            NSString *alertStr = [str substringFromIndex:[str rangeOfString:@"+LIP="].location+5];
            alertStr = [alertStr substringToIndex:[alertStr rangeOfString:@"\r"].location];
 
        if (_queryIpSuccessBlock) {
            _queryIpSuccessBlock(alertStr);
        }
        }
}
 

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"搜索到服务");
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}
 
- (void)writea {
    
    NSData *data = [@"$OpenFscAtEngine$"dataUsingEncoding:NSUTF8StringEncoding];
    [_activePeripheral writeValue:data forCharacteristic:_readCharacteristic type:CBCharacteristicWriteWithoutResponse];
    NSLog(@"data0 = %@",data);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSLog(@"BluetoothManager didUpdateNotificationStateForCharacteristic - %@ - %@",characteristic.UUID.UUIDString, characteristic.value);
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSLog(@"didWriteValueForCharacteristic = %@ ",characteristic.value);
    
    NSLog(@"%s",__PRETTY_FUNCTION__);
    if (characteristic.value) {
        return;
    }
}  
-(void)dealloc{
    NSLog(@"%s", __func__);
}
@end
