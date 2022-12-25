pragma solidity ^0.6.0;

// Smart contract for facilitating a secure escrow transaction between a buyer and a seller
contract Escrow {
    // Address of the buyer
    address public buyer;

    // Address of the seller
    address public seller;

    // Address of the escrow account holder
    address public escrowAccount;

    // Total amount of the transaction in wei
    uint256 public transactionAmount;

    // Expiration time of the contract in seconds since the Unix epoch
    uint256 public expirationTime;

    // Developer fee as a percentage of the transaction amount
    uint256 public developerFee;

    // Escrow fee as a percentage of the transaction amount
    uint256 public escrowFee;

    // Review of the buyer by the seller
    string public buyerReview;

    // Review of the seller by the buyer
    string public sellerReview;

    // Review of the escrow account holder by the buyer
    string public escrowAccountReview;

    // Review of the buyer by the escrow account holder
    string public buyerEscrowAccountReview;

    // Review of the seller by the escrow account holder
    string public sellerEscrowAccountReview;

    event LogEscrowAddressAgreed(address indexed, address, address);
    event LogFundsSent(address indexed, address, uint256);
    event LogPaymentRequested(address indexed, address, address);
    event LogFundsReleased(address indexed, address, address);
    event LogFundsReleasedToBuyer(address indexed, address, address);
    event LogFundsAdded(address indexed, address, uint256);
    event LogFundsRefunded(address indexed, address, address, uint256);
    event LogFundsPaid(address indexed, address, address, uint256);
    event LogReview(address indexed, address indexed, address, string, bool);

    // Constructor function for creating a new instance of the contract
    constructor(address _buyer, address _seller, uint256 _transactionAmount, uint256 _expirationTime, uint256 _developerFee, uint256 _escrowFee) public {
        // Initialize the contract with the specified values
        buyer = _buyer;
        seller = _seller;
        transactionAmount = _transactionAmount;
        expirationTime = _expirationTime;
        developerFee = _developerFee;
        escrowFee = _escrowFee;
    }

    // Function for the buyer and seller to agree on an escrow address
    function agreeOnEscrowAddress(address _escrowAccount) public {
        require(msg.sender == buyer || msg.sender == seller, "Only the buyer or seller can agree on an escrow address");
        require(escrowAccount == address(0), "An escrow address has already been agreed upon");
        require(now < expirationTime, "The contract has expired");
        escrowAccount = _escrowAccount;
        // Display a message to the buyer, seller, and escrow account holder indicating that an escrow address has been agreed upon
        emit LogEscrowAddressAgreed(buyer, seller, escrowAccount);
    }

    // Function for the buyer to send the funds to the contract
    function sendFunds() public payable {
        require(msg.sender == buyer, "Only the buyer can send funds to the contract");
        require(escrowAccount != address(0), "An escrow address has not yet been agreed upon");
        require(now < expirationTime, "The contract has expired");
        require(transactionAmount == msg.value, "The buyer is sending the incorrect amount of funds");

        // Calculate the developer fee as a percentage of the transaction amount
        uint256 developerFeeAmount = transactionAmount * developerFee / (100);

        // Calculate the escrow fee as a percentage of the transaction amount
        uint256 escrowFeeAmount = transactionAmount * escrowFee / (100);

        // Send the developer fee to the specified address
        msg.sender.transfer(developerFeeAmount);

        // Send the escrow fee to the escrow account
        payable(escrowAccount).transfer(escrowFeeAmount);

        // Display a message to the buyer, seller, and escrow account holder indicating that the funds have been sent to the contract
        emit LogFundsSent(buyer, escrowAccount, transactionAmount);
    }

    // Function for the seller to request payment from the escrow account holder
    function requestPayment() public {
        require(msg.sender == seller, "Only the seller can request payment from the escrow account holder");
        require(escrowAccount != address(0), "An escrow address has not yet been agreed upon");
        // Display a message to the buyer, seller, and escrow account holder indicating that the payment has been requested
        emit LogPaymentRequested(buyer, seller, escrowAccount);
    }

    // Function for the escrow account holder to release the funds to the seller
    function releaseFunds() public {
        require(msg.sender == escrowAccount, "Only the escrow account holder can release the funds");
        require(escrowAccount != address(0), "An escrow address has not yet been agreed upon");
        // Transfer the funds to the seller
        payable(seller).transfer(transactionAmount);
        // Display a message to the buyer, seller, and escrow account holder indicating that the escrow account holder has released the funds to the seller
        emit LogFundsReleased(buyer, seller, escrowAccount);
    }

    // Function for the escrow account holder to release the funds to the buyer
    function releaseFundsToBuyer() public {
        require(msg.sender == escrowAccount, "Only the escrow account holder can release the funds to the buyer");
        require(escrowAccount != address(0), "An escrow address has not yet been agreed upon");
        // Transfer the funds to the buyer
        payable(buyer).transfer(transactionAmount);
        // Display a message to the buyer, seller, and escrow account holder indicating that the escrow account holder has released the funds to the buyer
        emit LogFundsReleasedToBuyer(buyer, seller, escrowAccount);
    }

    // Function for the buyer to add more funds to the contract
    function addMoreFunds() public payable {
        require(msg.sender == buyer, "Only the buyer can add more funds to the contract");
        require(escrowAccount != address(0), "An escrow address has not yet been agreed upon");
        // Calculate the developer fee as a percentage of the additional funds
        uint256 developerFeeAmount = msg.value * (developerFee) / (100);

        // Calculate the escrow fee as a percentage of the additional funds
        uint256 escrowFeeAmount = msg.value * (escrowFee) / (100);

        // Send the developer fee to the specified address
        msg.sender.transfer(developerFeeAmount);

        // Send the escrow fee to the escrow account
        payable(escrowAccount).transfer(escrowFeeAmount);

        // Increase the transaction amount by the additional funds
        transactionAmount += msg.value;
        // Display a message to the buyer, seller, and escrow account holder indicating that the buyer has added more funds to the contract
        emit LogFundsAdded(buyer, escrowAccount, transactionAmount);
    }

    // Function for the seller to refund a portion of the funds to the buyer
    function refund(uint256 _refundAmount) public {
        require(msg.sender == seller, "Only the seller can refund a portion of the funds to the buyer");
        require(_refundAmount <= transactionAmount, "The refund amount cannot be greater than the total transaction amount");
        // Decrease the transaction amount by the refund amount
        transactionAmount -= _refundAmount;
        // Transfer the refund amount to the buyer
        payable(buyer).transfer(_refundAmount);
        // Display a message to the buyer, seller, and escrow account holder indicating that the seller has refunded a portion of the funds to the buyer
        emit LogFundsRefunded(buyer, seller, escrowAccount, transactionAmount);
    }

    // Function for the escrow account holder to pay a portion of the funds to the buyer or seller
    function pay(uint256 _payAmount, address _payee) public {
        require(msg.sender == escrowAccount, "Only the escrow account holder can pay a portion of the funds to the buyer or seller");
        require(_payAmount <= transactionAmount, "The pay amount cannot be greater than the total transaction amount");
        // Decrease the transaction amount by the pay amount
        transactionAmount -= _payAmount;
        // Transfer the pay amount to the specified payee
        payable(_payee).transfer(_payAmount);
        // Display a message to the buyer, seller, and escrow account holder indicating that the escrow account holder has paid a portion of the funds to the buyer or seller
        emit LogFundsPaid(buyer, seller, escrowAccount, transactionAmount);
    }

    // Function for the buyer or seller to review the other party
    function review(string memory _review, bool _isBuyerReview) public {
    require(msg.sender == buyer || msg.sender == seller || msg.sender == escrowAccount, "Only the buyer, seller, or escrow account holder can review the other party");
    if (msg.sender == buyer) {
        // Update the review of the seller by the buyer
        sellerReview = _review;
        bool isBuyerReview = _isBuyerReview;
    } else if (msg.sender == seller) {
        // Update the review of the buyer by the seller
        buyerReview = _review;
        bool isBuyerReview = _isBuyerReview;
    } else {
        // Update the review of the buyer or seller by the escrow account holder
        if (_isBuyerReview) {
            buyerReview = _review;
        } else {
            sellerReview = _review;
        }
    }
    // Display a message to the buyer, seller, and escrow account holder indicating that a review has been left
    emit LogReview(buyer, seller, escrowAccount, _review, _isBuyerReview);
    }
}
