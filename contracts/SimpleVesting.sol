pragma solidity ^0.4.21;

import "./util/DestroyableMultiOwner.sol";
import "./math/SafeMath.sol";
import "./util/Destroyable.sol";

interface Token {
	function transfer(address _to, uint256 _value) external;
	
	function balanceOf(address who) view external returns (uint256);
}

contract SimpleVesting is DestroyableMultiOwner{
	using SafeMath for uint256;
	
	event Released(address _beneficiary, uint256 _amount);
	event Revoked(address _beneficiary, uint256 _amount);
	event NewBeneficiary(address _beneficiary);
	
	// beneficiary of tokens
	struct Beneficiary {
		string description;
		uint256 vested;
		uint256 releaseAt;
		bool released;
		bool isBeneficiary;
	}
	
	mapping(address => Beneficiary) public beneficiaries;
	address[] public addresses;
	Token public token;
	uint256 public actualVested;
	uint256 public totalVested;
	uint256 public totalReleased;
	
	/*
     *  Modifiers
     */
	modifier isNotBeneficiary(address _beneficiary) {
		require(!beneficiaries[_beneficiary].isBeneficiary);
		_;
	}
	modifier isBeneficiary(address _beneficiary) {
		require(beneficiaries[_beneficiary].isBeneficiary);
		_;
	}
	
	/**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until _start + _duration. By then all
     * of the balance will have vested.
     * @param _token address of the token of vested tokens
     */
	constructor (address _token) public {
		require(_token != address(0));
		token = Token(_token);
	}
	
	function() payable public {
		release(msg.sender);
	}
	
	/**
     * @notice Transfers vested tokens to beneficiary (alternative to fallback function).
     */
	function release() public {
		release(msg.sender);
	}
	
	/**
     * @notice Transfers vested tokens to beneficiary.
     * @param _beneficiary Beneficiary address
     */
	function release(address _beneficiary) private
	isBeneficiary(_beneficiary)
	{
		Beneficiary storage beneficiary = beneficiaries[_beneficiary];
		
		require(now>=beneficiary.releaseAt);
		
		uint256 vested = beneficiary.vested;
		
		token.transfer(_beneficiary, vested);
		
		beneficiary.released = true;
		beneficiary.isBeneficiary = false;
		
		actualVested = actualVested.sub(vested);
		totalReleased = totalReleased.add(vested);
		
		emit Released(_beneficiary, vested);
	}
	
	/**
	 * @notice Allows the owner to transfers vested tokens to beneficiary.
	 * @param _beneficiary Beneficiary address
	 */
	function releaseTo(address _beneficiary) public onlyOwner {
		release(_beneficiary);
	}
	
	/**
     * @dev Add new beneficiary to start vesting
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _vested MTC of the vesting in wei
     * @param _releaseAt time in seconds which the tokens will vest
     * @param _description description of the vesting
     */
	function addBeneficiary(address _beneficiary, uint256 _vested, uint256 _releaseAt, string _description)
	onlyOwner
	isNotBeneficiary(_beneficiary)
	public {
		require(_beneficiary != address(0));
		require(token.balanceOf(this) >= actualVested.add(_vested));
		beneficiaries[_beneficiary] = Beneficiary({
			description: _description,
			vested: _vested,
			releaseAt: _releaseAt,
			released: false,
			isBeneficiary: false
			});
		totalVested = totalVested.add(_vested);
		actualVested = actualVested.add(_vested);
		addresses.push(_beneficiary);
		emit NewBeneficiary(_beneficiary);
	}
	
	/**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param _beneficiary Beneficiary address
     */
	function revoke(address _beneficiary) public
	onlyOwner
	isNotBeneficiary(_beneficiary){
		Beneficiary storage beneficiary = beneficiaries[_beneficiary];
		
		uint256 vested = beneficiary.vested;
		
		token.transfer(owners[0], vested);
		
		actualVested = actualVested.sub(vested);
		
		beneficiary.isBeneficiary = false;
		
		emit Revoked(_beneficiary, vested);
	}
	
	/**
     * @notice Allows the owner to clear the contract. Remain tokens are returned to the owner.
     */
	function clearAll() public onlyOwner {
		
		token.transfer(owners[0], token.balanceOf(this));
		
		for (uint i = 0; i < addresses.length; i++) {
			Beneficiary storage beneficiary = beneficiaries[addresses[i]];
			beneficiary.isBeneficiary = false;
			beneficiary.released = false;
			beneficiary.vested = 0;
			beneficiary.releaseAt = 0;
			beneficiary.description = "";
		}
		addresses.length = 0;
		
	}
	
	/**
     * @dev Get the remain MTC on the contract.
     */
	function Balance() view public returns (uint256) {
		return token.balanceOf(address(this));
	}
	
	/**
	 * @dev Get the numbers of beneficiaries in the vesting contract.
	 */
	function beneficiariesLength() view public returns (uint256) {
		return addresses.length;
	}
	
	/**
	 * @notice Allows the owner to flush the eth.
	 */
	function flushEth() public onlyOwner {
		owners[0].transfer(address(this).balance);
	}
	
	/**
	 * @notice Allows the owner to destroy the contract and return the tokens to the owner.
	 */
	function destroy() public onlyOwner {
		token.transfer(owners[0], token.balanceOf(this));
		selfdestruct(owners[0]);
	}
}
