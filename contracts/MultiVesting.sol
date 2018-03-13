pragma solidity ^0.4.0;

import "./ownership/Ownable.sol";
import "./math/SafeMath.sol";

interface Token {
    function transfer(address _to, uint256 _value) public;

    function balanceOf(address who) public returns (uint256);
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
        bool isBeneficiary;
    }

    event Released(address _beneficiary, uint256 amount);
    event Revoked(address _beneficiary);
    event NewBeneficiary(address _beneficiary);


    mapping(address => Beneficiary) public beneficiaries;
    Token public token;
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

    modifier wasRevoked(address _beneficiary) {
        require(beneficiaries[_beneficiary].revoked);
        _;
    }

    modifier wasNotRevoked(address _beneficiary) {
        require(!beneficiaries[_beneficiary].revoked);
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

    function() payable public {
        release(msg.sender);
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param _beneficiary Beneficiary address
     */
    function release(address _beneficiary) private
    isBeneficiary(_beneficiary)
    wasNotRevoked(_beneficiary)
    {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];

        uint256 unreleased = releasableAmount(_beneficiary);

        require(unreleased > 0);

        beneficiary.released = beneficiary.released.add(unreleased);

        totalReleased.add(unreleased);

        token.transfer(_beneficiary, unreleased);

        Released(_beneficiary, unreleased);
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
     * @param _start time in seconds which the tokens will vest
     * @param _cliff time in seconds of the cliff in which tokens will begin to vest
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _revocable whether the vesting is revocable or not
     */
    function addBeneficiary(address _beneficiary, uint256 _vested, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable)
    onlyOwner()
    public {
        require(_beneficiary != address(0));
        require(_cliff <= _duration);
        require(token.balanceOf(this) > totalVested.sub(totalReleased).add(_vested));
        beneficiaries[_beneficiary] = Beneficiary({
            released : 0,
            vested : _vested,
            start : _start,
            cliff : _cliff,
            duration : _duration,
            revoked : false,
            revocable : _revocable,
            isBeneficiary : true
            });
        totalVested = totalVested.add(_vested);
        NewBeneficiary(_beneficiary);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param _beneficiary Beneficiary address
     */
    function revoke(address _beneficiary) public onlyOwner {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];
        require(beneficiary.revocable);
        require(!beneficiary.revoked);

        uint256 balance = token.balanceOf(this);

        uint256 unreleased = releasableAmount(_beneficiary);
        uint256 refund = balance.sub(unreleased);

        beneficiary.revoked = true;

        token.transfer(owner, refund);

        Revoked(_beneficiary);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param _beneficiary Beneficiary address
     */
    function releasableAmount(address _beneficiary) public view returns (uint256) {
        return vestedAmount(_beneficiary).sub(beneficiaries[_beneficiary].released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param _beneficiary Beneficiary address
     */
    function vestedAmount(address _beneficiary) public view returns (uint256) {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];
        uint256 totalBalance = beneficiary.vested;

        if (now < beneficiary.cliff) {
            return 0;
        } else if (now >= beneficiary.start.add(beneficiary.duration) || beneficiary.revoked) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(beneficiary.start)).div(beneficiary.duration);
        }
    }

}
