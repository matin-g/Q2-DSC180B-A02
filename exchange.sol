// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Purchase {

    uint public value;
    int public buyerNumber;
    int maxBuyerNumber = 10;
    string item_price_in_ETH;
    string item_name;
    string item_details;
    string item_description;

    address payable public seller;
    // address payable public buyer;

    // enum State { Created, Locked, Release, Inactive }
    enum State { created, paid, shipped, received, refunded, completed }


    struct Buyer {
        address payable addr;
        State state;
        //int exist;
    }

    mapping (address => Buyer) map;

    // since seller is launching --> there should be item name and description, item details --> make those readable by buyer
    modifier condition(bool condition_) {
        require(condition_);
        _;
    }

    /// Only the buyer can call this function.
    error OnlyBuyer();
    /// Only the seller can call this function.
    error OnlySeller();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();

    modifier onlyBuyer() {
        if (msg.sender == seller)
            revert OnlyBuyer();
        _;
    }

    // modifier onlyBuyer() {
    //     // not msg.sender --> variable that the seller will be providing 
    //     if ( doesExist(msg.sender) ) // not in buyersArray then revert // chatgpt --> show solidity code for python code of value not in x
    //         revert OnlyBuyer();
    //     _;
    // }


    modifier onlySeller() {
        if (msg.sender != seller)
            revert OnlySeller();
        _;
    }

    modifier inState(address address_, State state_) {
        if (map[address_].state != state_)
            revert InvalidState();
        _;
    }


    event Aborted();
    event PurchaseConfirmed();
    event ConfirmShipped();
    event ItemReceived();
    event SellerRefunded();

    // Ensure that `msg.value` is an even number.
    // Division will truncate if it is an odd number.
    // Check via multiplication that it wasn't an odd number.
    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        item_price_in_ETH = "0.01 ETH";
        item_name = "Nike Air Max 90";
        item_details = "Size: 10, Color: Iron Grey/Dark Smoke Grey/Black/White, Style: Textile upper with leather and synthetic overlays, Foam midsole, Rubber Waffle outsole";
        item_description = "Nothing as fly, nothing as comfortable, nothing as proven. The Nike Air Max 90 stays true to its OG running roots with the iconic Waffle sole, stitched overlays and classic TPU details. Classic colors celebrate your fresh look while Max Air cushioning adds comfort to the journey.";

        if ((2 * value) != msg.value)
            revert ValueNotEven();
    }

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the seller before
    /// the contract is locked.
    // function abort()
    //     external
    //     onlySeller
    //     inState(State.Created)
    // {
    //     emit Aborted();
    //     state = State.Completed;
    //     // We use transfer here directly. It is
    //     // reentrancy-safe, because it is the
    //     // last call in this function and we
    //     // already changed the state.
    //     seller.transfer(address(this).balance);
    // }

    // GETTERS for read-only product attributes

    function getItemPriceInETH() public view returns (string memory) {
        return item_price_in_ETH;
    }

    function getItemName() public view returns (string memory) {
        return item_name;
    }

    function getItemDetails() public view returns (string memory) {
        return item_details;
    }

    function getItemDescription() public view returns (string memory) {
        return item_description;
    }
    
    function getBuyerNumber() public view returns (int) {
        return buyerNumber;
    }

    // SETTERS potentially need implementation for future use (quarter 2)

    // function editItemDetails(string memory new_item_details) public {
    //     item_details = new_item_details;
    // }
    // function editItemName(string memory new_item_name) public {
    //     item_name = new_item_name;
    // }
    // function editItemDescription(string memory new_item_description) public {
    //     item_description = new_item_description;
    // }

    function doesExist(address key) public view returns (bool) {
        if (map[key].addr != address(0)) { // map[key].addr == True
            return true;
        }  else {
            return false;
        }
    }
    
    function createBuyer() public
        onlyBuyer
        condition(!doesExist(msg.sender))
        condition(buyerNumber <= maxBuyerNumber)
    {
        buyerNumber ++;
        map[msg.sender] = Buyer(payable(msg.sender), State.created);
    }

    /// Confirm the purchase as buyer.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function confirmPurchase()
        external
        inState(msg.sender, State.created) 
        // require((msg.value == (2 * value), "Please send in 2x the purchase amount"))
        condition(msg.value == (2 * value))
        payable
    {
        emit PurchaseConfirmed();
        map[msg.sender].state = State.paid;
    }

    // what if seller forgerts to mark ship, and did ship, and the buyer gets it and marks recieved
    // the previous 
    function confirmShipped(address address_)
        external
        onlySeller
        inState(msg.sender, State.paid)
        condition(doesExist(address_))
        payable
    {
        emit ConfirmShipped();
        map[address_].state = State.shipped;  
    }

    // add function to show the state of current buyer

    /// Confirm that you (the buyer) received the item.
    /// This will release the locked ether.
    function confirmReceived()
        external
        onlyBuyer
        inState(msg.sender, State.shipped)
    {
        emit ItemReceived();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        map[msg.sender].state = State.received;
        payable(msg.sender).transfer(value);
    }

    /// This function refunds the seller, i.e.
    /// pays back the locked funds of the seller.
    function refundSeller(address item_received_buyer)
        external
        onlySeller
        inState(item_received_buyer, State.received)
    {
        emit SellerRefunded();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        map[item_received_buyer].state = State.refunded;
        seller.transfer(3 * value);
    }
}