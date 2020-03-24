pragma solidity >=0.4.22 <0.7.0;

/**
 * @title Purchasing goods remotely currently requires multiple parties that need to trust each other. 
 * The simplest configuration involves a seller and a buyer. 
 * The buyer would like to receive an item from the seller and the seller would like to get money (or an equivalent) in return. 
 * The problematic part is the shipment here: There is no way to determine for sure that the item arrived at the buyer.
 * There are multiple ways to solve this problem, but all fall short in one or the other way. 
 * In the following example, both parties have to put twice the value of the item into the contract as escrow. 
 * As soon as this happened, the money will stay locked inside the contract until the buyer confirms that they received the item. 
 * After that, the buyer is returned the value (half of their deposit) and the seller gets three times the value (their deposit plus the value). 
 * The idea behind this is that both parties have an incentive to resolve the situation or otherwise their money is locked forever.
 */ 

contract Purchase {
    enum State {Created, Locked, Release, Inactive}
    
    uint public value;
    address payable public seller;
    address payable public buyer;
    
    State public state;
    
    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event sellerRefunded();
    
    modifier condition(bool _condition) {
        require(_condition);
        _;
    }
    
    modifier onlyBuyuer() {
        require(msg.sender == buyer, "Only buyer can call this.");
        _;
    }
    
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this.");
        _;
    }
    
    modifier inState(State _state) {
        require(state == _state, "Invalid state.");
        _;
    }
    
    constructor() public payable {
        seller = msg.sender;
        value = msg.value / 2;
        require((value * 2) == msg.value, "Value has to be even.");
    }
    
    /** 
     * @dev Abort the purchase and reclaim the ether.
     * Can only be called by the seller before the contract is locked.
     */
    function abort() public onlySeller inState(State.Created) {
        emit Aborted();
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }
    
    /**
     * @dev Confirm the purchase as buyer.
     * Transaction has to include `2 * value` ether.
     * The ether will be locked until confirmReceived is called.
     */
    function confirmPurchase() public payable inState(State.Created) condition(msg.value == (2 * value)) {
        emit PurchaseConfirmed();
        buyer = msg.sender;
        state = State.Locked;
    }
    
    /**
     * @dev Confirm that you the buyer received the item.
     * This will release the locked ether.
     */
    function confirmReceived() public onlyBuyuer inState(State.Locked) {
        emit ItemReceived();
        state = State.Release;
        buyer.transfer(value);
    }
    
    /**
     * @dev This function refunds the seller, i.e. pays back the locked funds of the seller.
     */
    function refundSeller() public onlySeller inState(State.Inactive) {
        emit sellerRefunded();
        state = State.Inactive;
        seller.transfer((3 * value));
    }
     
}
