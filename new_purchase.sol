// SPDX-License-Identifier: GPL-3.0

// TODO : Close contract function

pragma solidity ^0.8.12;
import "@openzeppelin/contracts/utils/Strings.sol";


contract Purchase {


   uint public value;
   uint public escrowLeft;
   uint public buyerNumber = 0;
   uint public quantity;
   uint maxBuyerNumber = 2;
   string item_price_in_Wei;
   string item_name;
   string item_details;
   string item_description;
   bool terminated = false;
   bool ready = false;


   address payable public seller;
   // address payable public buyer;


   // enum State { Created, Locked, Release, Inactive }
   enum State { created, paid, shipped, received}




   struct Buyer {
       address payable addr;
       State state;
   }


   mapping (address => Buyer) map;

   address[] addresses;


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
      /// The provided value has to be even.
   error notEnoughEscrow();
   error ItemNotAdded();


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
       if ( (escrowLeft / 2 / value) <= buyerNumber)
           revert notEnoughEscrow();
       _;
   }
    modifier addedItem(){
       if (!ready)
            revert ItemNotAdded();
        _;
   }



//    event Aborted();
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
   
   function setValue_Quant(uint inp_value) internal
       onlySeller
   {
       value = inp_value;
       quantity = escrowLeft/value/2;
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
    string memory inp_item_name, 
    string memory inp_item_details, 
    string memory inp_item_descriptions) public onlySeller {
        setValue_Quant(inp_value);
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

//     function getBuyerNumAddress(uint buyerNum) public view returns (address) {
//        return map[map[buyerNum]].addr;
//    }

//    function deposit() public payable {
//    }

//    function withdraw(address payable _to, uint _amount) public {
    //    _to.transfer(_amount);
//    }



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
    //    if (stateIdx == State.refunded) return "refunded";
       return "";
   }
  
   function createBuyer() public
       onlyBuyer
       addedItem
       enoughEscrow
       condition(!doesExist(msg.sender))
       condition(buyerNumber < maxBuyerNumber)
       condition(!terminated)
   {
       buyerNumber ++;
       map[msg.sender] = Buyer(payable(msg.sender), State.created);
       addresses.push(msg.sender);
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
       quantity -= 1;
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

    function addEscrow()
       external
       onlySeller
       condition(msg.value >= (2 * value))
       payable
   {
       uint new_quantity = msg.value / 2 / value;
       quantity += new_quantity;
       escrowLeft += msg.value;
       emit addedEscrow();
   }

   // function that seller can end/complete the contract
   // when there's no buyer

    // function checkNoActiveBuyers(){
    //     flagActiveBuyers = False;
    //     for (uint i = 0 ; i<buyerNumber; i++) {
    //         curr = map[i].state;
    //     ...
    // }
    
    // function checkNoActiveBuyers() public view returns (bool) {
    //     bool flagActiveBuyers = false;
    //     for (uint i = 0; i < map.length; i++) {
    //         if (map[address(i)].state != State.created && map[address(i)].state != State.refunded) {
    //             flagActiveBuyers = true;
    //             break;
    //         }
    //     }
    //     return flagActiveBuyers;
    // }

    // function checkNoActiveBuyers() public view returns (bool) {
    // bool allStatesCreated = true;
    // bytes32 hash = 0x0;
    //     while (hash < 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
    //         if (map[address(hash)].state != State.created && map[address(hash)].state != State.refunded) {
    //         //if (map[address(hash)].state != State.created) {
    //             allStatesCreated = false;
    //             break;
    //         }
    //         hash = keccak256(abi.encodePacked(hash + 1));
    //     }
    //     return allStatesCreated;
    // }

//     function checkNoActiveBuyers() public view returns (bool) {
//     bool flagActiveBuyers = false;
//     bytes32 hash = 0x0;
//     while (hash < 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
//     if (map[address(hash)].state != State.created && map[address(hash)].state != State.refunded) {
//             flagActiveBuyers = true;
//             break;
//         }
//         hash = keccak256(abi.encodePacked(hash + 1));
//     }
//     return !flagActiveBuyers;
// }

// function checkActiveBuyers() public view returns (bool) {
//     bool flagActiveBuyers = false;
//     for (address buyerAddr in map) {
//         if (map[buyerAddr].state != State.created && map[buyerAddr].state != State.refunded) {
//             flagActiveBuyers = true;
//             break;
//         }
//     }
//     return flagActiveBuyers;
// }

    function checkNoActiveBuyers() public view returns (bool) {
        bool flagActiveBuyers = true;

        for (uint i = 0; i < addresses.length; i++) {
            address currentAddress = addresses[i];
            if (map[currentAddress].state != State.created && map[currentAddress].state != State.received) {
                flagActiveBuyers = false;
                break;
            }
        }
        return flagActiveBuyers;
    }

    function closeContract()
       external
       onlySeller
       condition(checkNoActiveBuyers())
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
    //    map[item_received_buyer].state = State.refunded;
       delete map[item_received_buyer];
       buyerNumber--;
       seller.transfer(3 * value);
       escrowLeft = escrowLeft - value * 2;

       // remove the item_received_buyer from the hashmap
       // 
   }
 
}
