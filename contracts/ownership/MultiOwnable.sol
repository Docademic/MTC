pragma solidity ^0.4.21;
/**
 * Changes by https://www.docademic.com/
 */

/**
 * @title MultiOwnable
 * @dev The MultiOwnable contract has multiple owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract MultiOwnable {
	
	address[] public owners;
	mapping(address => bool) public isOwner;
	
	event OwnerAddition(address indexed owner);
	event OwnerRemoval(address indexed owner);
	
	/**
	 * @dev The MultiOwnable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	constructor() public {
		isOwner[msg.sender] = true;
		owners.push(msg.sender);
	}
	
	/**
   * @dev Throws if called by any account other than the owner.
   */
	modifier onlyOwner() {
		require(isOwner[msg.sender]);
		_;
	}
	
	/**
	 * @dev Throws if called by an owner.
	 */
	modifier ownerDoesNotExist(address _owner) {
		require(!isOwner[_owner]);
		_;
	}
	
	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier ownerExists(address _owner) {
		require(isOwner[_owner]);
		_;
	}
	
	/**
	 * @dev Throws if called with a null address.
	 */
	modifier notNull(address _address) {
		require(_address != 0);
		_;
	}
	
	/**
	 * @dev Allows to add a new owner. Transaction has to be sent by an owner.
	 * @param _owner Address of new owner.
	 */
	function addOwner(address _owner)
	public
	onlyOwner
	ownerDoesNotExist(_owner)
	notNull(_owner)
	{
		isOwner[_owner] = true;
		owners.push(_owner);
		emit OwnerAddition(_owner);
	}
	
	/**
	 * @dev Allows to remove an owner. Transaction has to be sent by wallet.
	 * @param _owner Address of owner.
	 */
	function removeOwner(address _owner)
	public
	onlyOwner
	ownerExists(_owner)
	{
		isOwner[_owner] = false;
		for (uint i = 0; i < owners.length - 1; i++)
			if (owners[i] == _owner) {
				owners[i] = owners[owners.length - 1];
				break;
			}
		owners.length -= 1;
		emit OwnerRemoval(_owner);
	}
	
}