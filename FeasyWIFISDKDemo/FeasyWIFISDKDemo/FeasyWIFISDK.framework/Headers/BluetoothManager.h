//
//  FscBleCentralApi.h
//  FscBleCentral
//
//  Created by Feasycom on 2017/12/26.
//  Copyright © 2017 Feasycom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
 
@class CBPeripheral;

@interface BluetoothManager : NSObject

+ (BluetoothManager *)sharedBluetoothManager;


- (void)activeCentralManager:(CBCentralManager *)activeCentralManager connectPerpheral:(CBPeripheral *)inPeripheral  wifiName:(NSString *)wifi password:(NSString *)password;


- (void)activeCentralManager:(CBCentralManager *)activeCentralManager connectPerpheral:(CBPeripheral *)inPeripheral queryIpSuccessBlock:(void (^)(NSString *str))queryIpSuccessBlock;

  

@end
