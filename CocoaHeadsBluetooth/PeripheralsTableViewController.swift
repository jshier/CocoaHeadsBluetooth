//
//  PeripheralsTableViewController.swift
//  CocoaHeadsBluetooth
//
//  Created by Jon Shier on 3/19/15.
//  Copyright (c) 2015 Jon Shier. All rights reserved.
//

import UIKit
import CoreBluetooth

func dispatchMain(block: dispatch_block_t) {
    dispatch_async(dispatch_get_main_queue(), block)
}

extension Bool {
    var stringValue: String {
        if self {
            return "Yes"
        }
        else {
            return "No"
        }
    }
}

struct BluetoothState {
    let managerState: CBCentralManagerState
    let description: String
    let isBluetoothEnabled: Bool
    
    init(managerState: CBCentralManagerState) {
        self.managerState = managerState
        switch managerState {
        case .PoweredOff:
            description = "Bluetooth hardware powered off."
            isBluetoothEnabled = false
        case .PoweredOn:
            description = "Bluetooth hardware powered on."
            isBluetoothEnabled = true
        case .Resetting:
            description = "Bluetooth hardware is resetting."
            isBluetoothEnabled = false
        case .Unauthorized:
            description = "Bluetooth hardware is unauthorized."
            isBluetoothEnabled = false
        case .Unsupported:
            description = "Bluetooth hardware is unsupported."
            isBluetoothEnabled = false
        case .Unknown:
            description = "Bluetooth hardware state is unknown."
            isBluetoothEnabled = false
        }
    }
}

struct Peripheral {
    var peripheral: CBPeripheral
    var name: String?
    var UUID: String
    var RSSI: String
    var connectable = false
    
    init(peripheral: CBPeripheral, RSSI: String, advertisementDictionary: NSDictionary) {
        self.peripheral = peripheral
        name = peripheral.name ?? "No name."
        UUID = peripheral.identifier.UUIDString
        self.RSSI = RSSI
        if let isConnectable = advertisementDictionary[CBAdvertisementDataIsConnectable] as? NSNumber {
            connectable = isConnectable.boolValue
        }
    }
}

class PeripheralsTableViewController: UITableViewController, CBCentralManagerDelegate {
    let managerQueue = dispatch_queue_create("com.detroitlabs.cocoaheadsbluetooth.bluetoothmanager", DISPATCH_QUEUE_SERIAL)
    var manager: CBCentralManager!
    var isBluetoothEnabled = false
    var visiblePeripheralUUIDs = NSMutableOrderedSet()
    var visiblePeripherals = [String: Peripheral]()
    var scanTimer: NSTimer?
    var connectionAttemptTimer: NSTimer?
    var connectedPeripheral: CBPeripheral?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        BluetoothManager.sharedManager.bluetoothStateCallback = { state in
            println("State updated to: \(state.description)")
        }
    }
    
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        //manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        BluetoothManager.sharedManager.bluetoothStateCallback = { state in
            println("State updated to: \(state.description)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 134
        
        self.refreshControl?.addTarget(self, action: Selector("startScanning"), forControlEvents: .ValueChanged)
    }
    
    override func viewDidAppear(animated: Bool) {
        if isBluetoothEnabled {
            if let peripheral = connectedPeripheral {
                manager.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    func startScanning() {
        println("Started scanning.")
        visiblePeripheralUUIDs.removeAllObjects()
        visiblePeripherals.removeAll(keepCapacity: true)
        tableView.reloadData()
        manager.scanForPeripheralsWithServices(nil, options: nil)
        scanTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("stopScanning"), userInfo: nil, repeats: false)
    }
    
    func stopScanning() {
        println("Stopped scanning.")
        println("Found \(visiblePeripherals.count) peripherals.")
        manager.stopScan()
        refreshControl?.endRefreshing()
        scanTimer?.invalidate()
    }
    
    func timeoutPeripheralConnectionAttempt() {
        println("Peripheral connection attempt timed out.")
        manager.cancelPeripheralConnection(connectedPeripheral)
        connectionAttemptTimer?.invalidate()
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        var printString: String
        switch central.state {
        case .PoweredOff:
            printString = "Bluetooth hardware powered off."
            isBluetoothEnabled = false
        case .PoweredOn:
            printString = "Bluetooth hardware powered on."
            isBluetoothEnabled = true
            dispatchMain {
                self.startScanning()
            }
        case .Resetting:
            printString = "Bluetooth hardware is resetting."
            isBluetoothEnabled = false
        case .Unauthorized:
            printString = "Bluetooth hardware is unauthorized."
            isBluetoothEnabled = false
        case .Unsupported:
            printString = "Bluetooth hardware is unsupported."
            isBluetoothEnabled = false
        case .Unknown:
            printString = "Bluetooth hardware state is unknown."
            isBluetoothEnabled = false
        }
        
        println("State updated to: \(printString)")
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("Peripheral found with name: \(peripheral.name)\nUUID: \(peripheral.identifier.UUIDString)\nRSSI: \(RSSI)\nAdvertisement Data: \(advertisementData)")
        visiblePeripheralUUIDs.addObject(peripheral.identifier.UUIDString)
        visiblePeripherals[peripheral.identifier.UUIDString] = Peripheral(peripheral: peripheral, RSSI: RSSI.stringValue, advertisementDictionary: advertisementData)
        dispatchMain {
            self.tableView.reloadData()
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("Peripheral connected: \(peripheral.name ?? peripheral.identifier.UUIDString)")
        dispatchMain {
            self.connectionAttemptTimer?.invalidate()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let peripheralViewController = storyboard.instantiateViewControllerWithIdentifier("PeripheralViewController") as! PeripheralViewController
            peripheralViewController.peripheral = peripheral
            self.navigationController?.pushViewController(peripheralViewController, animated: true)
        }
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        if peripheral != connectedPeripheral {
            println("Disconnected peripheral was not the currently connected peripheral.")
        }
        else {
            connectedPeripheral = nil
        }
        if let error = error {
            println("Failed to disconnect from peripheral with error: \(error)")
        }
        else {
            println("Successfully disconnected from peripheral: \(peripheral.name ?? peripheral.identifier.UUIDString)")
        }
        if let selectedIndexPath = tableView.indexPathForSelectedRow() {
            dispatchMain {
                self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
            }
        }
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("Failed to connect peripheral: \(peripheral.name ?? peripheral.identifier.UUIDString)\nBecause of error: \(error)")
        connectedPeripheral = nil
        connectionAttemptTimer?.invalidate()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visiblePeripherals.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("PeripheralCell", forIndexPath: indexPath) as! PeripheralTableViewCell
        
        if let visibleUUID = visiblePeripheralUUIDs[indexPath.row] as? String,
            visiblePeripheral = visiblePeripherals[visibleUUID] {
            
            cell.setupWithPeripheral(visiblePeripheral)
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let selectedUUID = visiblePeripheralUUIDs[indexPath.row] as? String {
            if let selectedPeripheral = visiblePeripherals[selectedUUID] {
                if selectedPeripheral.connectable {
                    connectedPeripheral = selectedPeripheral.peripheral
                    connectionAttemptTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("timeoutPeripheralConnectionAttempt"), userInfo: nil, repeats: false)
                    manager.connectPeripheral(connectedPeripheral, options: nil)
                }
            }
        }
    }
}
