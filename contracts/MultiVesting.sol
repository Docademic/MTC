pragma solidity ^0.4.0;

import "../ownership/Ownable.sol";
import "../math/SafeMath.sol";

interface Token {
    function transfer(address _to, uint256 _value) public;
}

contract MultiVesting is Ownable {
    using SafeMath for uint256;

    // beneficiary of tokens
    struct Beneficiary {
        uint256 released;
        uint256 vested;
        uint256 start;
        uint256 cliff;
        uint256 duration;
        bool revoked;
        bool revocable;
    }

    event Released(address _beneficiary, uint256 amount);
    event Revoked(address _beneficiary);
    event NewBeneficiary(address _beneficiary, Beneficiary _data);


    mapping(address => Beneficiary) public beneficiaries;
    mapping(address => bool) public isBeneficiary;
    Token public token;

    /*
     *  Modifiers
     */
    modifier beneficiaryDoesNotExist(address _beneficiary) {
        require(!isBeneficiary[_beneficiary]);
        _;
    }
    modifier beneficiaryExists(address _beneficiary) {
        require(isBeneficiary[_beneficiary]);
        _;
    }

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until _start + _duration. By then all
     * of the balance will have vested.
     * @param _token address of the token of vested tokens
     */
    function MultiVesting(address _token) public {
        require(_token != address(0));
        token = Token(_token);
    }

    /**
     * @dev Add new beneficiary to start vesting
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _start time in seconds which the tokens will vest
     * @param _cliff time in seconds of the cliff in which tokens will begin to vest
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _revocable whether the vesting is revocable or not
     */
    function addBeneficiary(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable)
    onlyOwner()
    public {
        require(_beneficiary != address(0));
        require(_cliff <= _duration);
        beneficiaries[_beneficiary] = Beneficiary({
            released : 0,
            vested : 0,
            start : _start,
            cliff : _cliff,
            duration : _duration,
            revoked : false,
            revocable : _revocable
            });
        NewBeneficiary(_beneficiary, beneficiaries[_beneficiary]);
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release() public {
        uint256 unreleased = releasableAmount(token);

        require(unreleased > 0);

        released[token] = released[token].add(unreleased);

        token.safeTransfer(beneficiary, unreleased);

        Released(unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param token ERC20 token which is being vested
     */
    function revoke(address _beneficiary) public onlyOwner {
        require(revocable);
        require(!revoked[token]);

        uint256 balance = token.balanceOf(this);

        uint256 unreleased = releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        revoked[token] = true;

        token.safeTransfer(owner, refund);

        Revoked();
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param token ERC20 token which is being vested
     */
    function releasableAmount(address _beneficiary) public view returns (uint256) {
        return vestedAmount(token).sub(released[token]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    function vestedAmount(address _beneficiary) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);

        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration) || revoked[token]) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(start)).div(duration);
        }
    }

}
