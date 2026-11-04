// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VehicleOwnership
 * @dev Decentralized vehicle registry and ownership management smart contract.
 * Records vehicle details, tracks verifiable ownership history on the blockchain,
 * and facilitates secure peer-to-peer ownership transfers.
 */
contract VehicleOwnership {
    // Structure to represent a registered vehicle
    struct Vehicle {
        uint256 id;
        string registrationNumber;
        string manufacturer;
        string model;
        uint256 year;
        address owner;
        bool exists;
    }

    // Total number of registered vehicles
    uint256 public vehicleCount;

    // Mapping from vehicle ID to Vehicle details
    mapping(uint256 => Vehicle) public vehicles;

    // Mapping from unique registration number to vehicle ID
    mapping(string => uint256) private registrationToVehicleId;

    // Mapping from vehicle ID to complete ownership transfer history
    mapping(uint256 => address[]) private ownershipHistory;

    // Events
    event VehicleRegistered(
        uint256 indexed vehicleId,
        string registrationNumber,
        address indexed owner
    );

    event OwnershipTransferred(
        uint256 indexed vehicleId,
        address indexed previousOwner,
        address indexed newOwner
    );

    // Modifiers
    modifier vehicleExists(uint256 _vehicleId) {
        require(_vehicleId > 0 && _vehicleId <= vehicleCount, "Invalid vehicle ID");
        require(vehicles[_vehicleId].exists, "Vehicle does not exist");
        _;
    }

    modifier onlyVehicleOwner(uint256 _vehicleId) {
        require(vehicles[_vehicleId].owner == msg.sender, "Caller is not the vehicle owner");
        _;
    }

    /**
     * @notice Registers a new vehicle into the decentralized registry.
     * @param _registrationNumber Unique registration / license plate number.
     * @param _manufacturer Manufacturer or make of the vehicle (e.g., Toyota, Tesla).
     * @param _model Model name of the vehicle (e.g., Corolla, Model 3).
     * @param _year Manufacturing year.
     */
    function registerVehicle(
        string memory _registrationNumber,
        string memory _manufacturer,
        string memory _model,
        uint256 _year
    ) external {
        require(bytes(_registrationNumber).length > 0, "Registration number cannot be empty");
        require(bytes(_manufacturer).length > 0, "Manufacturer cannot be empty");
        require(bytes(_model).length > 0, "Model cannot be empty");
        require(_year >= 1886 && _year <= 2100, "Invalid manufacturing year");
        require(isRegistrationAvailable(_registrationNumber), "Vehicle with this registration number already exists");

        vehicleCount++;
        uint256 newVehicleId = vehicleCount;

        vehicles[newVehicleId] = Vehicle({
            id: newVehicleId,
            registrationNumber: _registrationNumber,
            manufacturer: _manufacturer,
            model: _model,
            year: _year,
            owner: msg.sender,
            exists: true
        });

        registrationToVehicleId[_registrationNumber] = newVehicleId;
        ownershipHistory[newVehicleId].push(msg.sender);

        emit VehicleRegistered(newVehicleId, _registrationNumber, msg.sender);
    }

    /**
     * @notice Transfers vehicle ownership to a new address.
     * @param _vehicleId ID of the vehicle to transfer.
     * @param _newOwner Address of the new owner.
     */
    function transferOwnership(uint256 _vehicleId, address _newOwner)
        external
        vehicleExists(_vehicleId)
        onlyVehicleOwner(_vehicleId)
    {
        require(_newOwner != address(0), "New owner address cannot be zero address");
        require(_newOwner != msg.sender, "New owner cannot be current owner");

        address previousOwner = vehicles[_vehicleId].owner;
        vehicles[_vehicleId].owner = _newOwner;
        ownershipHistory[_vehicleId].push(_newOwner);

        emit OwnershipTransferred(_vehicleId, previousOwner, _newOwner);
    }

    /**
     * @notice Retrieves full vehicle details by its ID.
     * @param _vehicleId ID of the vehicle.
     * @return Vehicle struct containing all vehicle details.
     */
    function getVehicle(uint256 _vehicleId)
        external
        view
        vehicleExists(_vehicleId)
        returns (Vehicle memory)
    {
        return vehicles[_vehicleId];
    }

    /**
     * @notice Retrieves the full ownership history of a vehicle.
     * @param _vehicleId ID of the vehicle.
     * @return Array of addresses that have owned the vehicle, in chronological order.
     */
    function getOwnershipHistory(uint256 _vehicleId)
        external
        view
        vehicleExists(_vehicleId)
        returns (address[] memory)
    {
        return ownershipHistory[_vehicleId];
    }

    /**
     * @notice Checks if a registration number is available (not yet registered).
     * @param _registrationNumber Vehicle registration plate number to check.
     * @return True if available, false if already taken.
     */
    function isRegistrationAvailable(string memory _registrationNumber)
        public
        view
        returns (bool)
    {
        return registrationToVehicleId[_registrationNumber] == 0;
    }

    /**
     * @notice Verifies a vehicle by its registration number and returns its details.
     * @param _registrationNumber Vehicle registration plate number.
     * @return verified Boolean indicating whether the vehicle is verified and registered.
     * @return vehicleId ID of the vehicle in the system.
     * @return manufacturer Manufacturer of the vehicle.
     * @return model Model of the vehicle.
     * @return year Manufacturing year.
     * @return currentOwner Blockchain address of the current owner.
     */
    function verifyVehicle(string memory _registrationNumber)
        external
        view
        returns (
            bool verified,
            uint256 vehicleId,
            string memory manufacturer,
            string memory model,
            uint256 year,
            address currentOwner
        )
    {
        uint256 vId = registrationToVehicleId[_registrationNumber];
        if (vId == 0 || !vehicles[vId].exists) {
            return (false, 0, "", "", 0, address(0));
        }

        Vehicle memory v = vehicles[vId];
        return (true, v.id, v.manufacturer, v.model, v.year, v.owner);
    }
}
