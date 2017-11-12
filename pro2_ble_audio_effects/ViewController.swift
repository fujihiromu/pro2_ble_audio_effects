import UIKit
import CoreBluetooth

class ViewController: UIViewController,CBCentralManagerDelegate,CBPeripheralDelegate {
    
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var sdrReverb: UISlider!
    @IBOutlet weak var sdrDelayTime: UISlider!
    @IBOutlet weak var sdrFeedback: UISlider!
    @IBOutlet weak var sdrLowPassCutOff: UISlider!
    @IBOutlet weak var sdrWetDryMix: UISlider!
    @IBOutlet weak var sdrSpeed: UISlider!
    @IBOutlet weak var sdrPitch: UISlider!
    
    @IBOutlet weak var eq00: UISlider!
    @IBOutlet weak var eq01: UISlider!
    @IBOutlet weak var eq02: UISlider!
    @IBOutlet weak var eq03: UISlider!
    @IBOutlet weak var eq04: UISlider!
    let MAX_GAIN: Float = 24.0
    let MIN_GAIN: Float = -96.0
    
    private var isScanning = false
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var audio = Audio()
    var isplay = false
    
    @IBOutlet weak var bypassBtn: UISwitch!
    @IBAction func bypassSet(_ sender: Any) {
//        self.audioUnitEQ.bypass = !self.audioUnitEQ.bypass
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        eq00.transform = CGAffineTransform(rotationAngle: CGFloat((-90.0 * M_PI) / 180.0))
        eq01.transform = CGAffineTransform(rotationAngle: CGFloat((-90.0 * M_PI) / 180.0))
        eq02.transform = CGAffineTransform(rotationAngle: CGFloat((-90.0 * M_PI) / 180.0))
        eq03.transform = CGAffineTransform(rotationAngle: CGFloat((-90.0 * M_PI) / 180.0))
        eq04.transform = CGAffineTransform(rotationAngle: CGFloat((-90.0 * M_PI) / 180.0))
        // セントラルマネージャ初期化
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    //    // セントラルマネージャの状態が変化すると呼ばれる
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print ("state: \(central.state)")
    }
    // ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print ("接続成功!!");
        // サービス探索結果を受け取るためにデリゲートをセット
        peripheral.delegate = self
        // サービス探索開始
        peripheral.discoverServices(nil)
    }
    // ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("接続失敗・・・");
    }
    // サービス発見時に呼ばれる P.207 4-3 キャラクテリスティク、サービスを探す
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
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
    func peripheral(_ peripheral: CBPeripheral,
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
    func peripheral(_ peripheral: CBPeripheral,
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
    func peripheral(_ peripheral: CBPeripheral,
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
//        if(str == "01"){
//            audio.musicChanged()
//        }
        
        ///////オーディオ操作
        if(str == "02" && String(describing: characteristic.uuid) == "00002A6F-0000-1000-8000-00805F9B34FB"){
            audio.musicChanged()
        }
        //////ディレイ
        if( String(describing: characteristic.uuid) == "00002A6E-0000-1000-8000-00805F9B34FB"){
            ////１６進数ー＞１０進数
            var hex:UInt32 = 0x0
            let scanner:Scanner = Scanner(string: str)
            scanner.scanHexInt32(&hex)
            print(hex)
            sdrWetDryMix.value = Float(hex)
            audio.sliderWetDryMix(value: Float(hex))
        }
    }
    
    @IBOutlet weak var UUID: UILabel!
    
    ////    // 周辺にあるデバイスを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        let messID = peripheral.name
        UUID.text = messID
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
    @IBAction func scanBtnTapp(sender: UIButton) {
        if !isScanning {
            isScanning = true
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            sender.setTitle("STOP SCAN", for: .normal)
        } else {
            centralManager.stopScan()
            sender.setTitle("START SCAN", for: .normal)
            isScanning = false
        }
    }
    @IBAction func btnPlayPressed(sender: UIButton) {
        if (!isplay){
            audio.buttonPlayPressed(isPlay: false)
            btnPlay.setTitle("PLAY", for: .normal)
            isplay = true
        } else {
            audio.buttonPlayPressed(isPlay: true)
            btnPlay.setTitle("PAUSE", for: .normal)
            isplay = false
        }
    }
    @IBAction func btnchange(sender: UIButton) {
        audio.musicChanged()
        
    }
    
    @IBAction func sdrReverbChanged(sender: UISlider) {
        audio.sliderReverbChanged(value: sdrReverb.value)
    }
    
    @IBAction func sdrDelayTimeChanged(sender: UISlider) {
        audio.sliderDelayTimeChanged(value: sdrDelayTime.value)
    }
    
    @IBAction func sdrFeedbackChanged(sender: UISlider) {
        audio.sliderFeedbackChanged(value: sdrFeedback.value)
    }
    
    @IBAction func sdrLowPassCutOff(sender: UISlider) {
        audio.sliderLowPassCutOff(value: sdrLowPassCutOff.value)
    }
    
    @IBAction func sdrWetDryMix(sender: UISlider) {
        audio.sliderWetDryMix(value: sdrWetDryMix.value)
    }
    @IBAction func sdrSpeed(sender: UISlider) {
        audio.sliderSpeed(value: sdrSpeed.value)
    }
    @IBAction func sdrPitch(sender: UISlider) {
        audio.sliderPitch(value: sdrPitch.value)
    }
    
    @IBAction func sdrGain_00(sender: UISlider) {
        audio.sliderGain(value: sender.value, num: 0)
    }
    @IBAction func sdrGain_01(sender: UISlider) {
        audio.sliderGain(value: sender.value, num: 1)
    }
    @IBAction func sdrGain_02(sender: UISlider) {
        audio.sliderGain(value: sender.value, num: 2)
    }
    @IBAction func sdrGain_03(sender: UISlider) {
        audio.sliderGain(value: sender.value, num: 3)
    }
    @IBAction func sdrGain_04(sender: UISlider) {
        audio.sliderGain(value: sender.value, num: 4)
    }
}



