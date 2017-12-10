pragma solidity ^0.4.11;

contract MarketPlace{

  struct User{
      uint balance;
      address user_address;
      uint flag;
      string first_name;
      string last_name;
      string email;
      string password;
  }

  struct Product{
    uint id;
    string name;
    string category;
    string description;
    uint unit_price;
    uint quantity;
    address seller;
    string image_ids;
  }

  struct Transaction{
    uint id;
    uint product_id;
    transaction_status status;
    uint unit_price;
    uint quantity;
    address buyer;
    address seller;
    uint ordered_date;
    string first_name;
    string last_name;
    string delivery_address;
  } 

  enum transaction_status { CREATED, SHIPPED, DELIVERED, REFUND_REQUESTED, CANCELLED }
  enum user_type {BUYER,SELLER}

  uint product_id;
  uint user_count;
  uint transaction_id;

  mapping(address => User) public users;
  mapping(uint => Product) public products;
  mapping(address=>uint[]) public buyerTransactions;
  mapping(address=>uint[]) public sellerTransactions;
  mapping(uint => Transaction) public transactions;

  event sellProductEvent(
      uint indexed _product_id,
      address indexed _seller,
      string _name,
      uint _unit_price,
      uint _quantity
  );

  event TransactionEvent(
      uint indexed _transaction_id,
      address indexed _seller,
      address indexed _buyer,
      uint _product_id,
      string _name,
      uint _unit_price,
      uint _quantity
  );

  //register a user
  function register(string first_name, string last_name, string email,string password) public{

      if(users[msg.sender].flag==1){
        return;
      }

      users[msg.sender] = User(msg.sender.balance,msg.sender,1,first_name,last_name,email,password);
      user_count++;

  }

  //get number of users
  function getUserCount() public constant returns (uint) {
      return user_count;
  }

  //get user details
  function getUser() public constant returns(uint, address,string,string,string,string) {
      return (users[msg.sender].balance, users[msg.sender].user_address, users[msg.sender].first_name, users[msg.sender].last_name, users[msg.sender].email, users[msg.sender].password);
  }

  function getUserByAddress(address requestAddress) public constant returns(string,string,string) {
    return (users[requestAddress].first_name, users[requestAddress].last_name, users[requestAddress].email);  
  }

  //Sell a product
  function sellProduct(string name, string category, string description,uint unit_price,uint quantity,string image_ids) public {
    product_id++;

    products[product_id] = Product(product_id,name,category,description,unit_price,quantity,msg.sender,image_ids);

    sellProductEvent(product_id,msg.sender,name,unit_price,quantity);
  }

  function buyProduct(uint id,uint demanded_quantity,string first_name, string last_name,string delivery_address) payable public{

    require(products[id].quantity >= demanded_quantity);

    require(msg.sender != products[id].seller);

    require(products[id].unit_price * demanded_quantity == msg.value);

    products[id].seller.transfer(msg.value);

    products[id].quantity -= demanded_quantity;

    transaction_id++;

    transactions[transaction_id] = Transaction(transaction_id,id,transaction_status.CREATED,products[id].unit_price,demanded_quantity,msg.sender,products[id].seller,block.timestamp,first_name,last_name,delivery_address);

    buyerTransactions[msg.sender].push(transaction_id);

    sellerTransactions[products[id].seller].push(transaction_id);

    TransactionEvent(transaction_id,products[id].seller,msg.sender,products[id].id,products[id].name,products[id].unit_price,demanded_quantity);

  }


  //get all transaction fields
  function getTransaction(uint id) public constant returns (uint,uint,transaction_status,uint,uint,address,address,uint,string,string,string){

    var t = transactions[id];

    return (t.id,t.product_id,t.status,t.unit_price,t.quantity,t.buyer,t.seller,t.ordered_date,t.first_name,t.last_name,t.delivery_address);

  }

  //get all ids of transactions by user address and type of user
  function getTransactionIds(address addr, user_type which) public constant returns(uint[]){

    var p = buyerTransactions[addr];

    if (which == user_type.SELLER){
      p = sellerTransactions[addr];
    }

    uint[] memory ids = new uint[](p.length);

    for(uint i=0;i<p.length;i++){
        ids[i]=p[i];
    }

    return (ids);

  }
