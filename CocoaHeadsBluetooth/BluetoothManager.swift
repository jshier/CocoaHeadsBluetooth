//
//  BluetoothManager.swift
//  CocoaHeadsBluetooth
//
//  Created by Jon Shier on 4/25/15.
//  Copyright (c) 2015 Jon Shier. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, CBCentralManagerDelegate {
    static let sharedManager = BluetoothManager()
    
    let blueQueue = dispatch_queue_create("com.detroitlabs.cocoaheadsbluetooth.bluetoothmanager", DISPATCH_QUEUE_SERIAL)
    var manager: CBCentralManager!
    var bluetoothStateCallback: ((BluetoothState)->Void)?
    
    private override init() {
        super.init()
        
        manager = CBCentralManager(delegate: self, queue: blueQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        bluetoothStateCallback?(BluetoothState(managerState: central.state))
    }
}
