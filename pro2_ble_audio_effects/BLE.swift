//
//  BLE.swift
//  pro2_ble_audio_effects
//
//  Created by Fuji Hiromu on 2017/10/28.
//  Copyright © 2017 藤　大夢. All rights reserved.
//

import UIKit
import CoreBluetooth

public class BLE: NSObject ,CBCentralManagerDelegate,CBPeripheralDelegate{
        
        private var isScanning = false
        private var centralManager: CBCentralManager!
        private var peripheral: CBPeripheral!
    
        
        override init(){
            // セントラルマネージャ初期化
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    
        //    // セントラルマネージャの状態が変化すると呼ばれる
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
            print ("state: \(central.state)")
        }
        // ペリフェラルへの接続が成功すると呼ばれる
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            print ("接続成功!!");
            // サービス探索結果を受け取るためにデリゲートをセット
            peripheral.delegate = self
            // サービス探索開始
            peripheral.discoverServices(nil)
        }
        // ペリフェラルへの接続が失敗すると呼ばれる
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            print("接続失敗・・・");
        }
        // サービス発見時に呼ばれる P.207 4-3 キャラクテリスティク、サービスを探す
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            if let error = error {
                print("エラー: \(error)")
                return
            }
            guard let services = peripheral.services, services.count > 0 else {
                print("no services")
                return
            }
            print("\(services.count) 個のサービスを発見！ \(services)")
            
            for service in services {
                // キャラクタリスティック探索開始
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        // キャラクタリスティック発見時に呼ばれる　P.207 4-3 キャラクテリスティク、サービスを探す
    public func peripheral(_ peripheral: CBPeripheral,
                        didDiscoverCharacteristicsFor service: CBService,
                        error: Error?)
        {
            if let error = error {
                print("エラー: \(error)")
                return
            }
            guard let characteristics = service.characteristics, characteristics.count > 0 else {
                print("no characteristics")
                return
            }
            print("\(characteristics.count) 個のキャラクタリスティックを発見！ \(characteristics)")
            // konashi の PIO_INPUT_NOTIFICATION キャラクタリスティック
            for characteristic in characteristics where characteristic.uuid.isEqual(CBUUID(string: "00002A6E-0000-1000-8000-00805F9B34FB")) {
                // 更新通知受け取りを開始する
                peripheral.setNotifyValue(
                    true,
                    for: characteristic)
            }
            for characteristic in characteristics where characteristic.uuid.isEqual(CBUUID(string: "00002A6F-0000-1000-8000-00805F9B34FB")) {
                // 更新通知受け取りを開始する
                peripheral.setNotifyValue(
                    true,
                    for: characteristic)
            }
        }
        // Notify開始／停止時に呼ばれる  P.231 4-6 notify
    public func peripheral(_ peripheral: CBPeripheral,
                        didUpdateNotificationStateFor characteristic: CBCharacteristic,
                        error: Error?)
        {
            if let error = error {
                print("Notify状態更新失敗...error: \(error)")
            } else {
                print("Notify状態更新成功！characteristic UUID:\(characteristic.uuid), isNotifying: \(characteristic.isNotifying)")
            }
            
            ////スキャン開始
            isScanning = true
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        // データ更新時に呼ばれる　notifyの通知が来た場合
    public func peripheral(_ peripheral: CBPeripheral,
                        didUpdateValueFor characteristic: CBCharacteristic,
                        error: Error?)
        {
            if let error = error {
                print("データ更新通知エラー: \(error)")
                return
            }
            print("データ更新！ characteristic UUID: \(characteristic.uuid), value: \(characteristic.value!), value: \(characteristic.description)")
            var data = NSData(data: characteristic.value!)
            print(data)
            var str : String = String(describing: data)
            if let range = str.range(of: "<"){
                str.removeSubrange(range)
            }
            if let range = str.range(of: ">"){
                str.removeSubrange(range )
            }
            print(str)
        }
        
        @IBOutlet weak var ID: UILabel!
    
        ////    // 周辺にあるデバイスを発見すると呼ばれる
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
        {
            let messID = peripheral.name
            ID.text = messID
            self.peripheral = peripheral
            let str = peripheral.name
            print("peripheral: \(peripheral)")
            if(str != nil){
                if((str! as NSString).substring(to: 3) == "BLE"){
                    print("????????")
                    centralManager.connect(peripheral, options: nil)
                    print("peripheral: \(peripheral)")
                    print("!!!!!")
                    //スキャン停止
                    isScanning = false
                    centralManager.stopScan()
                }
            }
        }
    public func scan(btn : Bool) {
            if btn {
                isScanning = true
                centralManager.scanForPeripherals(withServices: nil, options: nil)
                
            } else {
                centralManager.stopScan()
                isScanning = false
            }
        }
      
    

}
