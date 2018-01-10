//
//  Copyright © 2018 Netguru Sp. z o.o. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

/// Public facing interface granting methods to connect and disconnect devices
public final class BluetoothConnection: NSObject {
    
    // MARK: Public Interface
    
    /// List of possible errrors that can happen during connection.
    public enum ConnectionError: Error {
        case deviceConnectionLimitExceed
        case deviceAlreadyConnected
        case bluetoothUnavailable
        case incompatibleDevice
    }
    
    /// List of possible disconnection errors.
    public enum DisconnectionError: Error {
        case deviceNotConnected
    }
    
    /// A singleton instance.
    public static let shared = BluetoothConnection()
    
    /// Connection service implementing native CoreBluetooth stack
    private lazy var connectionService = ConnectionService()
    
    /// Maximum amount of devices capable of connecting to a iOS device
    private let deviceConnectionLimit = 8
    
    /// A advertisement validation handler. Will be called upon every peripheral discovery. Return value from this closure will indicate
    /// if manager should or shouldn't start connection with the passed peripheral according to it's identifier and advertising packet.
    public var advertisementValidationHandler: ((Peripheral, String, [String: Any]) -> (Bool))? {
        didSet {
            connectionService.advertisementValidationHandler = advertisementValidationHandler
        }
    }
    
    /// Primary method used to connect to a device. Can be called
    /// - Parameter peripheral: a configured device you wish to connect to.
    /// - Parameter handler: a completion handler called upon succesfull connection or a error.
    /// - SeeAlso: BluetoothConnection.ConnectionError
    /// - SeeAlso: Peripheral
    public func connect(_ peripheral: Peripheral, handler: @escaping (ConnectionError?) -> ()) {
        guard !peripheral.isConnected else {
            handler(.deviceAlreadyConnected)
            return
        }
        guard connectionService.connectedDevicesAmount <= deviceConnectionLimit else {
            handler(.deviceConnectionLimitExceed)
            return
        }
        connectionService.connect(peripheral) { (peripheral, error) in
            guard peripheral === peripheral else { return }
            handler(error)
        }
    }
    
    /// Primary method to disconnect a device. If it's not yet connected it'll be removed from connection queue, and connection attempts
    /// will stop.
    /// - Parameter peripheral: a peripheral you wish to disconnect. Should be exactly the same instance that was used for connection.
    /// - Throws: BluetoothConnection.ConnectionError in case there was a disconnection problem
    /// - SeeAlso: BluetoothConnection.DisconnectionError
    public func disconnect(_ peripheral: Peripheral) throws {
        guard let peripheral = peripheral.peripheral else {
            throw DisconnectionError.deviceNotConnected
        }
        connectionService.disconnect(peripheral)
    }
}
