// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.10;

import "../token/SafeERC20.sol";
import "../libraries/CoreLibrary.sol";
import "../libraries/EthAddressLib.sol";
import "./aave-protocol/ATokenMock.sol";
import "./AbstractProvider.sol";
import "./aave-protocol/IAaveLendingPool.sol";
import "./aave-protocol/ILendingPoolCore.sol";



contract AaveProvider is AbstractProvider {
  using SafeERC20 for ERC20;
  address private lendingPoolAddress;
  AToken private aToken;

  // address private lendingPoolCoreAddress;

  constructor(address _lendingPoolAddress, address _aTokenAddress)
    public
  {
    lendingPoolAddress = _lendingPoolAddress;
    aToken = AToken(_aTokenAddress);
    // lendingPoolCoreAddress = _lendingPoolCoreAddress;
  }

  // Deposit money to provider pool
  function deposit(address _reserve, uint256 _amount) public override payable {
    getLendingPool().deposit(_reserve, _amount, 0);

    super.deposit(_reserve, _amount);
  }

  function redeemUnderlying(
    address _reserve,
    address payable _user,
    uint256 _amount
  ) public virtual override {


    aToken.redeem(_amount);
    bool transferResult = ERC20(_reserve).transfer(_user, _amount);
    require(transferResult == true, "Can't transfer undelyying asset");

    // getLendingPool().redeemUnderlying(_reserve, _user, _amount, 0);
    super.redeemUnderlying(_reserve, _user, _amount);
  }


 /**
    * @dev transfers to the user a specific amount from the reserve.
    * @param _reserve the address of the reserve where the transfer is happening
    * @param _user the address of the user receiving the transfer
    * @param _amount the amount being transferred
    **/
    function transferToUser(address _reserve, address payable _user, uint256 _amount)
        internal
    {
        if (_reserve != EthAddressLib.ethAddress()) {
            ERC20(_reserve).safeTransfer(_user, _amount);
        } else {
            //solium-disable-next-line
            (bool result, ) = _user.call.value(_amount).gas(50000)("");
            require(result, "Transfer of ETH failed");
        }
    }



  function getReserves() external override returns (address[] memory) {
    return getLendingPool().getReserves();
  }

  function getLendingPool() internal view returns (IAaveLendingPool) {
    return IAaveLendingPool(lendingPoolAddress);
  }

  // function getLendingPoolCore() internal view returns (ILendingPoolCore) {
  //     return ILendingPoolCore(lendingPoolCoreAddress);
  // }

  function getReserveData(address _reserveAddress)
    external
    override
    view
    returns (
      uint256 totalLiquidity,
      uint256 availableLiquidity,
      uint256 totalBorrowsVariable,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 utilizationRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      address aTokenAddress,
      uint40 lastUpdateTimestamp
    )
  {
    // (
    //     totalLiquidity,
    //     availableLiquidity,
    //     ,
    //     totalBorrowsVariable,
    //     liquidityRate,
    //     variableBorrowRate,
    //     ,
    //     ,
    //     utilizationRate,
    //     liquidityIndex,
    //     variableBorrowIndex,
    //     aTokenAddress,
    //     lastUpdateTimestamp
    // ) = getLendingPool().getReserveData(_reserveAddress);
  }

  function getReserveLiquidityRate(address _reserveAddress)
    external
    override
    view
    returns (uint256 liquidityRate)
  {
    (, , , , liquidityRate, , , , , , , , ) = getLendingPool().getReserveData(
      _reserveAddress
    );
  }

  function getReserveBorrowRate(address _reserveAddress)
    external
    override
    view
    returns (uint256 variableBorrowRate)
  {
    (, , , , , variableBorrowRate, , , , , , , ) = getLendingPool()
      .getReserveData(_reserveAddress);
  }
}
