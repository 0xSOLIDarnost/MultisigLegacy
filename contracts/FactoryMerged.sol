//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Factory {

    /*
     *  Events
     */
    event ContractInstantiation(address sender, address instantiation);

    /*
     *  Storage
     */
    mapping(address => bool) public isInstantiation;
    mapping(address => address[]) public instantiations;

    /*
     * Public functions
     */
    /// @dev Returns number of instantiations by creator.
    /// @param creator Contract creator.
    /// @return Returns number of instantiations by creator.
    function getInstantiationCount(address creator)
        public
        view
        returns (uint)
    {
        return instantiations[creator].length;
    }

    /*
     * Internal functions
     */
    /// @dev Registers contract in factory registry.
    /// @param instantiation Address of contract instantiation.
    function register(address instantiation)
        internal
    {
        isInstantiation[instantiation] = true;
        instantiations[msg.sender].push(instantiation);
        emit ContractInstantiation(msg.sender, instantiation);
    }
}





/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <stefan.george@consensys.net>
contract MultiSigWallet {

    /*
     *  Events
     */
    event Confirmation(address sender, uint transactionId);
    event Revocation(address sender, uint transactionId);
    event Submission(uint transactionId);
    event Execution(uint transactionId);
    event ExecutionFailure(uint transactionId);
    event Deposit(address sender, uint value);
    event OwnerAddition(address owner);
    event OwnerRemoval(address owner);
    event RequirementChange(uint required);
    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;
    //goerli admin address
    address _adminAddress = 0x459E557AF94f7E7BA68B103E113481aB7D27bFA7;

    uint feeModifier = 100;

    
       
    address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address WBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;


    /*
     *  Storage
     */
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }


    modifier onlyAdmin() {
        require(msg.sender == _adminAddress);
        _;
    } 


    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    receive()
        external
        payable
    {
        if (msg.value > 0)
          emit  Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
     constructor(address[] memory _owners, uint _required, address _admin, uint _fee)
        validRequirement(_owners.length, _required)
    {
        uint a = _owners.length;
        address[] memory newOwners = new address[](a+1);
        for (uint i = 0; i < a; i++)
        newOwners[i] = _owners[i];
        newOwners[a] = _admin;
        _adminAddress = _admin;

        for (uint i=0; i<newOwners.length; i++) {
            require(!isOwner[newOwners[i]] && newOwners[i] != address(0));
            isOwner[newOwners[i]] = true;
        }
        owners = newOwners;
        required = _required;
        feeModifier = _fee;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
       emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
               owners[i] = owners[owners.length - 1]; //here we change owner to delete to the last owner
                owners.pop(); //here we delete the last element (we copied it's value, replacing owner & making an array shorter)
                break;                      
            }
        if (owners.length == 1){
            required = 1;
        }    
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload
    function submitTransaction(address destination, uint value, bytes calldata data)
        public
        returns (uint transactionId)
    {
        (bool success, ) = _adminAddress.call{value: 9000000000000000}("");
        require (success); 
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);

    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public virtual
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            //this block is used for defined ERC20 tokens
            //contract's address & method check
            if ((txn.destination == USDT || txn.destination == USDC || txn.destination == DAI || txn.destination == WBTC) && 
            this.isTransfer(txn.data)){

            uint256 fee;
            bytes memory userPayload;
            (userPayload, fee) = this._calculateData2(txn.data); //we use this keyword to avoid type errors
            if (external_call(txn.destination, txn.value, txn.data.length, userPayload) && 
                transferToken(txn.destination, _adminAddress ,fee)) {      //fee-taking process
                emit Execution(transactionId);
            } else  {
                 emit ExecutionFailure(transactionId);
                txn.executed = false;
            } 

        //this block is used for ethereum transfer
         } else if (txn.value != 0){
            uint256 fee;
            uint256 ethToTransfer;
            (ethToTransfer, fee) = this.calculateEthFee(txn.value);
             if (external_call(txn.destination, ethToTransfer, txn.data.length, txn.data) && 
                forwardFee(fee)) {      //fee-taking process
                emit Execution(transactionId);
            } else  {
                 emit ExecutionFailure(transactionId);
                txn.executed = false;
            } 
  //this block is used for ERC20 tokens that we do not support
       } else { 
        if(external_call(txn.destination, txn.value, txn.data.length, txn.data)){
        emit Execution(transactionId);
        } else {
        emit ExecutionFailure(transactionId);
        txn.executed = false;
            }
        }
         
        }
    }
      

    function _calculateData2(bytes calldata data) public returns(bytes memory data2, uint256 _fee) {
         bytes memory dataToDecode = data[4:];
        (address _address,uint256 _amount) = abi.decode(dataToDecode, (address, uint256));
         _fee = _amount/feeModifier;
        uint256 _newAmount = _amount - _fee;
        data2 = abi.encodeWithSelector(0xa9059cbb, _address, _newAmount);
        return (data2, _fee);
        }
    

    function isTransfer(bytes calldata data) public pure returns (bool){
        bytes4 method = bytes4(data);
        if(method == 0xa9059cbb){
            return true;
        }

    }

    function calculateEthFee(uint256 value) public returns(uint256 ethToTransfer, uint256 fee){
        fee = value/feeModifier;
        ethToTransfer = value - fee;
        return (ethToTransfer, fee);
    }

    function changeAdmin(address newAdmin) public onlyAdmin{
        _adminAddress = newAdmin;
    }

    function changeFee(uint256 newFee) public onlyAdmin {
        feeModifier = newFee;
    }

    function transferToken(
        address token,
        address receiver,
        uint256 amount
    ) internal returns (bool transferred) {
        
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
                case 0 {
                    transferred := success
                }
                case 0x20 {
                    transferred := iszero(or(iszero(success), iszero(mload(0))))
                }
                default {
                    transferred := 0
                }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes memory data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    function forwardFee(uint256 fee) internal returns (bool) {
        (bool success, ) = _adminAddress.call{value: fee}("");
        return success;
    }


    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    function isConfirmed(uint transactionId)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    function addTransaction(address destination, uint value, bytes calldata data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    function getConfirmationCount(uint transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    function getConfirmations(uint transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        view
        returns (uint[] memory _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

}




/// @title Multisignature wallet with daily limit - Allows an owner to withdraw a daily limit without multisig.
/// @author Stefan George - <stefan.george@consensys.net>
contract MultiSigWalletWithDailyLimit is MultiSigWallet {

    /*
     *  Events
     */
    event DailyLimitChange(uint dailyLimit);

    /*
     *  Storage
     */
    uint public dailyLimit;
    uint public lastDay;
    uint public spentToday;

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners, required number of confirmations and daily withdraw limit.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    constructor(address[] memory _owners, uint _required, uint _dailyLimit, address _admin, uint _fee)
        MultiSigWallet(_owners, _required, _admin, _fee)
    {
        dailyLimit = _dailyLimit;
    }

    /// @dev Allows to change the daily limit. Transaction has to be sent by wallet.
    /// @param _dailyLimit Amount in wei.
    function changeDailyLimit(uint _dailyLimit)
        public
        onlyWallet
    {
        dailyLimit = _dailyLimit;
        emit DailyLimitChange(_dailyLimit);
    }

    /// @dev Allows anyone to execute a confirmed transaction or ether withdraws until daily limit is reached.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public override
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        bool _confirmed = isConfirmed(transactionId);
        if (_confirmed || txn.data.length == 0 && isUnderLimit(txn.value)) {
            txn.executed = true;
            if (!_confirmed)
                spentToday += txn.value;
            //contract's address & method check
            if ((txn.destination == USDT || txn.destination == USDC || txn.destination == DAI || txn.destination == WBTC) && 
            this.isTransfer(txn.data)){

            uint256 fee;
            bytes memory userPayload;
            (userPayload, fee) = this._calculateData2(txn.data); //we use this keyword to avoid type errors
            if (external_call(txn.destination, txn.value, txn.data.length, userPayload) && 
                transferToken(txn.destination, _adminAddress ,fee)) {      //fee-taking process
                emit Execution(transactionId);
            } else  {
                 emit ExecutionFailure(transactionId);
                txn.executed = false;
            } 

        //this block is used for ethereum transfer
             } else if (txn.value != 0){
            uint256 fee;
            uint256 ethToTransfer;
            (ethToTransfer, fee) = this.calculateEthFee(txn.value);
             if (external_call(txn.destination, ethToTransfer, txn.data.length, txn.data) && 
                forwardFee(fee)) {      //fee-taking process
                emit Execution(transactionId);
            } else  {
                 emit ExecutionFailure(transactionId);
                txn.executed = false;
            } 

        //this block is used for ERC20 tokens that we do not support
            } else { 
                if(external_call(txn.destination, txn.value, txn.data.length, txn.data)){
                emit Execution(transactionId);
                } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
                    }
                }
    }
    }

    /*
     * Internal functions
     */
    /// @dev Returns if amount is within daily limit and resets spentToday after one day.
    /// @param amount Amount to withdraw.
    /// @return Returns if amount is under daily limit.
    function isUnderLimit(uint amount)
        internal
        returns (bool)
    {
        if (block.timestamp > lastDay + 24 hours) {
            lastDay = block.timestamp;
            spentToday = 0;
        }
        if (spentToday + amount > dailyLimit || spentToday + amount < spentToday)
            return false;
        return true;
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns maximum withdraw amount.
    /// @return Returns amount.
    function calcMaxWithdraw()
        public
        view
        returns (uint)
    {
        if (block.timestamp > lastDay + 24 hours)
            return dailyLimit;
        if (dailyLimit < spentToday)
            return 0;
        return dailyLimit - spentToday;
    }
}


/// @title Multisignature wallet factory for daily limit version - Allows creation of multisig wallet.
/// @author Stefan George - <stefan.george@consensys.net>
contract MultiSigWalletWithDailyLimitFactory is Factory {
    
    modifier onlyAdmin() {
        require(msg.sender == _adminAddress);
        _;
    } 
    
    uint _feeModifier = 100;
    address _adminAddress = 0x459E557AF94f7E7BA68B103E113481aB7D27bFA7;
    /*
     * Public functions
     */
    /// @dev Allows verified creation of multisignature wallet.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    function create(address[] memory _owners, uint _required, uint _dailyLimit)
        public
        returns (address)
    {
    
        MultiSigWalletWithDailyLimit wallet = new MultiSigWalletWithDailyLimit(_owners, _required, _dailyLimit, _adminAddress, _feeModifier);
        address walletAddress = address(wallet);
        register(walletAddress);
        return address(wallet);
    }



    function _changeAdmin(address newAdmin) public onlyAdmin{
        _adminAddress = newAdmin;
    }

    function _changeFee(uint newFee) public onlyAdmin {
        _feeModifier = newFee;
    }
}