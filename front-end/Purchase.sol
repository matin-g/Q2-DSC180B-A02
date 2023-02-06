// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.4;


contract Purchase {


   uint public value;
   int public buyerNumber;
   int maxBuyerNumber = 3;
   string item_price_in_ETH;
   string item_name;
   string item_details;
   string item_description;


   address payable public seller;
   // address payable public buyer;


   // enum State { Created, Locked, Release, Inactive }
   enum State { created, paid, shipped, received, refunded }




   struct Buyer {
       address payable addr;
       State state;
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
   


   function getBalance() public view returns (uint) {
       return address(this).balance;
   }

   function getAddress() public view returns (address) {
       return address(this);
   }

   function deposit() public payable {
   }

   function withdraw(address payable _to, uint _amount) public {
       _to.transfer(_amount);
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
       if (map[key].addr != address(0)) {
           return true;
       }  else {
           return false;
       }
   }


   function getBuyerState(address addr) public
       condition(doesExist(addr))
       view returns(string memory)
   {
       State stateIdx = map[addr].state;
       // Have to hard code this because Solidity will convert the enum values (State, in our case)
       // to integer and return the corresponding value as int, and we need to self-define
       // a function that returns the state as string for better understanding of the state
       // source - https://ethereum.stackexchange.com/questions/91849/how-to-return-a-enum-in-string-instead-of-integer
       if (stateIdx == State.created) return "created";
       if (stateIdx == State.paid) return "paid";
       if (stateIdx == State.shipped) return "shipped";
       if (stateIdx == State.received) return "received";
       if (stateIdx == State.refunded) return "refunded";
       return "";
   }
  
   function createBuyer() public
       onlyBuyer
       condition(!doesExist(msg.sender))
       condition(buyerNumber < maxBuyerNumber)
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


   function confirmShipped(address address_)
       external
       onlySeller
       inState(address_, State.paid)
       condition(doesExist(address_))
       payable
   {
       emit ConfirmShipped();
       map[address_].state = State.shipped; 
   }




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

       // remove the item_received_buyer from the hashmap
       // 
   }


   // function that seller can end/complete the contract
   // when there's no buyer
   
}

