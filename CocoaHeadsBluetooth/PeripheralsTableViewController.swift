//
//  PeripheralsTableViewController.swift
//  CocoaHeadsBluetooth
//
//  Created by Jon Shier on 3/19/15.
//  Copyright (c) 2015 Jon Shier. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralsTableViewController: UITableViewController, CBCentralManagerDelegate {
    var manager: CBCentralManager!
    var isBluetoothEnabled = false
    var visiblePeripherals = Array<CBPeripheral>()
    var visiblePeriperhalUUIDs = NSMutableSet()
    var scanTimer: NSTimer?
    var connectionAttemptTimer: NSTimer?
    var connectedPeripheral: CBPeripheral?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
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
        visiblePeripherals.removeAll(keepCapacity: true)
        visiblePeriperhalUUIDs.removeAllObjects()
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
            startScanning()
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
        if !visiblePeriperhalUUIDs.containsObject(peripheral.identifier) {
            visiblePeriperhalUUIDs.addObject(peripheral.identifier)
            visiblePeripherals.append(peripheral)
            tableView.reloadData()
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("Peripheral connected: \(peripheral.name ?? peripheral.identifier.UUIDString)")
        connectionAttemptTimer?.invalidate()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let peripheralViewController = storyboard.instantiateViewControllerWithIdentifier("PeripheralViewController") as PeripheralViewController
        peripheralViewController.peripheral = peripheral
        navigationController?.pushViewController(peripheralViewController, animated: true)
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
            tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
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
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("PeripheralCell", forIndexPath: indexPath) as UITableViewCell
        var peripheral = visiblePeripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name ?? "No Name"
        cell.detailTextLabel?.text = peripheral.identifier.UUIDString
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedPeripheral = visiblePeripherals[indexPath.row] as CBPeripheral
        
        connectedPeripheral = selectedPeripheral
        connectionAttemptTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("timeoutPeripheralConnectionAttempt"), userInfo: nil, repeats: false)
        manager.connectPeripheral(selectedPeripheral, options: nil)
    }
}
