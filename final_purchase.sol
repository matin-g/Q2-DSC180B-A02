// SPDX-License-Identifier: GPL-3.0

// TODO : Close contract function

pragma solidity ^0.8.12;
import "@openzeppelin/contracts/utils/Strings.sol";


contract Purchase {


   uint value;
   uint escrowLeft;
   uint buyerNumber = 0;
   uint quantity;
   uint totalBuyerNumber = 0;
   string item_price_in_Wei;
   string item_name;
   string item_details;
   string item_description;
   bool terminated = false;
   bool ready = false;


   address payable seller;
   // address payable public buyer;


   // enum State { Created, Locked, Release, Inactive }
   // created
   enum State {paid, shipped, received}




   struct Buyer {
       address payable addr;
       State state;
       uint quant;
   }


   mapping (address => Buyer) map;

//    address[] addresses;


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
   /// There isn't enough escrow from the seller.
   error notEnoughEscrow();
   /// Seller has not added items yet.
   error ItemNotAdded();
   /// The contract has been terminated.
   error ContractTerminated();
   /// Exceed max quantity.
   error ExceedMaxQuantity();
   /// Items have been added. Can't modify the old item.
   error ItemAddedAlready();
   /// This buyer address is invalid.
   error InvalidAddress();
   /// There are still active buyers in the contract. Can't terminate.
   error ActiveBuyer();
   /// You have already purchased this item.
   error AlreadyPurchased();

   modifier ActiveBuyerCheck() {
       if (!checkNoActiveBuyers())
            revert ActiveBuyer();
        _;
   }
   modifier onlyBuyer() {
       if (msg.sender == seller)
           revert OnlyBuyer();
       _;
   }


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

    modifier enoughEscrow() {
       if ( (escrowLeft / 2 / value) < 1)
           revert notEnoughEscrow();
       _;
   }
    modifier addedItem(){
       if (!ready)
            revert ItemNotAdded();
        _;
   }

    modifier ItemAddedAlreadyCheck(){
       if(ready)
            revert ItemAddedAlready();
        _; 
   }

    modifier ContractTerminatedCheck(){
       if (terminated)
            revert ContractTerminated();
        _;
   }
    modifier quantityCheck(uint quant){
       if (quant > quantity)
            revert ExceedMaxQuantity();
        _;
   }

   modifier InvalidAddressCheck(address address_){
       if (!doesExist(address_))
            revert InvalidAddress();
        _;
   }

    modifier AlreadyPurchasedCheck(address address_){
       if (doesExist(address_))
            revert AlreadyPurchased();
        _;
   }




//    event Aborted();
   event Added_item();
   event PurchaseConfirmed();
   event ConfirmShipped();
   event ItemReceived();
   event SellerRefunded();
   event addedEscrow();
   event closedContract();


   // Ensure that `msg.value` is an even number.
   // Division will truncate if it is an odd number.
   // Check via multiplication that it wasn't an odd number.
   constructor() payable {
       seller = payable(msg.sender);
    //    value = msg.value / 2 / 10; // requires 10 * 2 * $item for deployment
       escrowLeft = msg.value; 
    //    item_price_in_ETH = "0.01 ETH";
    //    item_name = "Nike Air Max 90";
    //    item_details = "Size: 10, Color: Iron Grey/Dark Smoke Grey/Black/White, Style: Textile upper with leather and synthetic overlays, Foam midsole, Rubber Waffle outsole";
    //    item_description = "Nothing as fly, nothing as comfortable, nothing as proven. The Nike Air Max 90 stays true to its OG running roots with the iconic Waffle sole, stitched overlays and classic TPU details. Classic colors celebrate your fresh look while Max Air cushioning adds comfort to the journey.";


    //    if (value % 2 != 0 )
    //        revert ValueNotEven();
   }

    //

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
   // Setters for quantity and value 
   
   // I added the inp_quant make sure html changes too.
   function setValue_Quant(uint inp_value, uint inp_quant) internal
       onlySeller
   {
       value = inp_value;
       quantity = inp_quant;
       item_price_in_Wei = string.concat(Strings.toString(inp_value) , " Wei");
   }

   function setItem_Name(string memory inp_item_name) internal
       onlySeller
       {
        item_name = inp_item_name;
       }

   function setItem_Details(string memory inp_item_details) internal
       onlySeller
       {
        item_details = inp_item_details;
       }

    function setItem_Descriptions( string memory inp_item_descriptions) internal
       onlySeller
       {
        item_description = inp_item_descriptions;
       }

    function add_item
    (uint inp_value, 
    uint inp_quant,
    string memory inp_item_name, 
    string memory inp_item_details, 
    string memory inp_item_descriptions) public 
    onlySeller
    ContractTerminatedCheck
    ItemAddedAlreadyCheck
    
    {
        emit Added_item();
        setValue_Quant(inp_value, inp_quant);
        setItem_Name(inp_item_name);
        setItem_Details(inp_item_details);
        setItem_Descriptions(inp_item_descriptions);
        ready = true;
    }

   // GETTERS for read-only product attributes


   function getItemPriceInWEI() public view returns (string memory) {
       return item_price_in_Wei;
   }
   

   function getValue() public view returns (uint) {
       return value;
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
  
   function getBuyerNumber() public view returns (uint) {
       return buyerNumber;
   }
   

   function getBalance() public view returns (uint) {
       return address(this).balance;
   }

   function getAddress() public view returns (address) {
       return address(this);
   }

   function getQuantity() public view returns (uint) {
       return quantity;
   }

   function getEscrowLeft() public view returns (uint) {
       return escrowLeft;
   }
   function getTotalBuyer() public view returns (uint) {
       return totalBuyerNumber;
   }

   function getBuyerQuantity(address addr) public
       InvalidAddressCheck(addr)
       view returns (uint)
   {
       return map[addr].quant;
   }
   function getTerminated() public view returns(bool){
        return terminated;
   }

   function getReady() public view returns(bool) {
        return ready;
   }


   function doesExist(address key) public view returns (bool) {
       if (map[key].addr != address(0)) {
           return true;
       }  else {
           return false;
       }
   }

   function getBuyerState(address addr) public
       InvalidAddressCheck(addr)
       view returns(string memory)
   {
       State stateIdx = map[addr].state;
       // Have to hard code this because Solidity will convert the enum values (State, in our case)
       // to integer and return the corresponding value as int, and we need to self-define
       // a function that returns the state as string for better understanding of the state
       // source - https://ethereum.stackexchange.com/questions/91849/how-to-return-a-enum-in-string-instead-of-integer
    //    if (stateIdx == State.created) return "created";
       if (stateIdx == State.paid) return "paid";
       if (stateIdx == State.shipped) return "shipped";
       if (stateIdx == State.received) return "received";
    //    if (stateIdx == State.refunded) return "refunded";
       return "";
   }
  


   /// Confirm the purchase as buyer.
   /// Transaction has to include `2 * value` ether.
   /// The ether will be locked until confirmReceived
   /// is called.
   function confirmPurchase(uint quant)
       external
    //    inState(msg.sender, State.created)
       onlyBuyer
       addedItem
       enoughEscrow
       quantityCheck(quant)
       ContractTerminatedCheck
       AlreadyPurchasedCheck(msg.sender)
    //    condition(msg.value == (2 * value* quant))
       payable
   {
       require(msg.value == (2 * value * quant), "Please send in 2x the purchase amount");
       quantity -= quant;
       buyerNumber ++ ;
       totalBuyerNumber ++;
    //    addresses.push(msg.sender);
       map[msg.sender] = Buyer(payable(msg.sender), State.paid, quant);
       emit PurchaseConfirmed();
    //    map[msg.sender].state = State.paid;
   }


   function confirmShipped(address address_)
       external
       onlySeller
       inState(address_, State.paid)
    //    condition(doesExist(address_))
       payable
   {
       emit ConfirmShipped();
       map[address_].state = State.shipped; 
   }

    function addEscrow(uint quant)
       external
       onlySeller
       addedItem
       ContractTerminatedCheck
    //    condition(!terminated)
    //    condition(msg.value == (2 * value * quant))
       payable
   {
       require(msg.value == (2 * value * quant), "Please send in 2x the purchase amount");
       uint new_quantity = quant;
       quantity += new_quantity;
       escrowLeft += msg.value;
       emit addedEscrow();
   }

   // function that seller can end/complete the contract
   // when there's no buyer

    
    function checkNoActiveBuyers() public view returns (bool) {
        bool flagActiveBuyers = false;
        // test = addresses.length;
        // if (addresses.length >= 1){
        //     flagActiveBuyers = false;
        // }
        // for (uint i = 0; i < addresses.length; i++) {
        //     address currentAddress = addresses[i];
        //     if (map[currentAddress].state != State.received) {
        //         flagActiveBuyers = false;
        //         break;
        //     }
        // }
        if (buyerNumber == 0) {
            flagActiveBuyers  = true;
        }
        return flagActiveBuyers;
    }

    function closeContract()
       external
       onlySeller
       ActiveBuyerCheck
       payable
   {
       terminated = true;
       seller.transfer(address(this).balance);
       emit closedContract();
   }

    // not allow any new buyers once closed --> add contract state 

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
       payable(msg.sender).transfer(value * map[msg.sender].quant);
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
    //    map[item_received_buyer].state = State.refunded;
       
       buyerNumber--;
       uint bought_quant =  map[item_received_buyer].quant;
       seller.transfer(3 * value * bought_quant);
       escrowLeft = escrowLeft - value * 2 *bought_quant;
    //    map[item_received_buyer].state = State.completed;

       delete map[item_received_buyer];

       // remove the item_received_buyer from the hashmap
       // 
   }
 
}