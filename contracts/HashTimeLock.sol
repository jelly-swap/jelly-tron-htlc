pragma experimental ABIEncoderV2;
pragma solidity >=0.5.0 <0.6.0;

contract HashTimeLock {

    mapping (bytes32 => LockContract) contracts;

    enum SwapStatus {
        INVALID,
        ACTIVE,
        REFUNDED,
        WITHDRAWN,
        EXPIRED
    }

    struct LockContract {
        uint256 inputAmount;
        uint256 outputAmount;
        uint256 expiration;

        bytes32 hashLock;

        SwapStatus status;

        address payable sender;
        address payable receiver;

        string outputNetwork;
        string outputAddress;
    }

    event Withdraw(
        bytes32 indexed id,
        bytes32 secret,
        bytes32 hashLock,
        address indexed sender,
        address indexed receiver
    );

    event Refund(
        bytes32 indexed id,
        bytes32 hashLock,
        address indexed sender,
        address indexed receiver
    );

    event NewContract(
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 expiration,

        bytes32 indexed id,
        bytes32 hashLock,

        address indexed sender,
        address indexed receiver,

        string outputNetwork,
        string outputAddress
    );

    modifier withdrawable(bytes32 id, bytes32 secret) {
        LockContract memory tempContract = contracts[id];
        require(tempContract.status == SwapStatus.ACTIVE, "SWAP_NOT_ACTIVE");
        require(tempContract.expiration > block.timestamp,"INVALID_TIME");
        require(tempContract.hashLock == sha256(abi.encodePacked(secret)),"INVALID_SECRET");
        _;
    }

    modifier refundable(bytes32 id) {
        LockContract memory tempContract = contracts[id];
        require(tempContract.status == SwapStatus.ACTIVE, "SWAP_NOT_ACTIVE");
        require(tempContract.expiration <= block.timestamp, "INVALID_TIME");
        require(tempContract.sender == msg.sender, "INVALID_SENDER");
        _;
    }

    function newContract(
        uint outputAmount,
        uint expiration,
        bytes32 hashLock,
        address payable receiver,
        string memory outputNetwork,
        string memory outputAddress
    )
        public
        payable
        returns (bytes32)
    {
        address payable sender = msg.sender;
        uint256 inputAmount = msg.value;

        require(expiration > block.timestamp, "INVALID_TIME");

        require(inputAmount > 0, "INVALID_AMOUNT");

        bytes32 id = sha256(abi.encodePacked(sender, receiver, inputAmount, hashLock, expiration));

        contracts[id] = LockContract(
            inputAmount,
            outputAmount,
            expiration,
            hashLock,
            SwapStatus.ACTIVE,
            sender,
            receiver,
            outputNetwork,
            outputAddress
        );

        emit NewContract(
            inputAmount,
            outputAmount,
            expiration,
            id,
            hashLock,
            sender,
            receiver,
            outputNetwork,
            outputAddress
        );
    }

    function withdraw(bytes32 id, bytes32 secret)
        public
        withdrawable(id, secret)
        returns (bool)
    {
        LockContract storage c = contracts[id];
        c.status = SwapStatus.WITHDRAWN;
        c.receiver.transfer(c.inputAmount);
        emit Withdraw(id, secret, c.hashLock, c.sender, c.receiver);
        return true;
    }

    function refund(bytes32 id)
        external
        refundable(id)
        returns (bool)
    {
        LockContract storage c = contracts[id];
        c.status = SwapStatus.REFUNDED;
        c.sender.transfer(c.inputAmount);
        emit Refund(id, c.hashLock, c.sender, c.receiver);
        return true;
    }

    function getContract(bytes32 id)
        public
        view
        returns (LockContract memory)

    {
        LockContract memory c = contracts[id];
        return c;
    }

    function contractExists(bytes32 id)
        public
        view
        returns (bool)
    {
        return contracts[id].status != SwapStatus.INVALID;
    }

    function getStatus(bytes32[] memory ids)
        public
        view
        returns(SwapStatus[] memory result)
    {
        for (uint256 index = 0; index < ids.length; index++) {
            LockContract memory tempContract = contracts[ids[index]];

            if(tempContract.status == SwapStatus.ACTIVE && tempContract.expiration < block.timestamp) {
                result[index] = SwapStatus.EXPIRED;
            }

            result[index] = tempContract.status;
        }
    }
}
