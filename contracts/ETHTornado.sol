// https://binancecash.io
/*
* d888888P                                           dP              a88888b.                   dP
*    88                                              88             d8'   `88                   88
*    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
*    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
*    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
*    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
* ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
*/

pragma solidity 0.5.17;

import "./Tornado.sol";

  interface PancakeSwapRouter {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
  }
  interface IBEP20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function burn(uint256 amount) external returns (bool);
  }

contract ETHTornado is Tornado {
  bool public buyTokensWithFee;
  IBEP20 public token;
  uint public protocolFee;
  PancakeSwapRouter public pancakeRouter;
  address[] public path;
  address payable public governance;

  modifier onlyGovernance {
    require(msg.sender == governance, "Only governance can call this function.");
    _;
  }

  constructor(
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address _operator
  ) Tornado(_verifier, _denomination, _merkleTreeHeight, _operator) public {
    governance = address(uint160(_operator)); // Type cast to payable type
    protocolFee = 1;
  }

  function _processDeposit() internal {
    require(msg.value == denomination, "Please send `mixDenomination` ETH along with transaction");
  }

  function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) internal {
    // sanity checks
    require(msg.value == 0, "Message value is supposed to be zero for ETH instance");
    require(_refund == 0, "Refund value is supposed to be zero for ETH instance");
    uint _protocolFee = 0;
    if (protocolFee > 0) {
      _protocolFee = denomination / (100 / protocolFee);
      if (buyTokensWithFee) {
        uint[] memory amounts = pancakeRouter.swapExactETHForTokens.value(_protocolFee)(0, path, address(this), block.timestamp+86400);   // Simply swap the protocol fee for tokens
        token.burn(amounts[amounts.length - 1]);    // Burn the swapped tokens
      } else {
        governance.call.value(_protocolFee)("");    // Otherwise, the protocol fee is transferred to governance
      }
    }
    require(denomination > _fee + _protocolFee, "Denomination must be greater than the relayer fee plus protocol fee, otherwise the recipient will not receive anything.");
    (bool success, ) = _recipient.call.value(denomination - _fee - _protocolFee)("");
    require(success, "payment to _recipient did not go thru");
    if (_fee > 0) {
      (success, ) = _relayer.call.value(_fee)("");
      require(success, "payment to _relayer did not go thru");
    }
  }

  function updateFee(uint _newFee) external onlyGovernance {
    require(_newFee <= 5, "The protocol fee cannot be greater than 5%");
    protocolFee = _newFee;
  }

  function updateBuyTokensWithFee() external onlyGovernance {
    buyTokensWithFee = !buyTokensWithFee;
  }

  function updateToken(address _newToken) external onlyGovernance {
    token = IBEP20(_newToken);
  }

  function updatePancakeRouter(address _newPancakeRouter) external onlyGovernance {
    pancakeRouter = PancakeSwapRouter(_newPancakeRouter);
  }

  function updatePath(address path0, address path1) external onlyGovernance {
    if (path.length == 0 || path.length == 1) {
      path.push(address(0));
      path.push(address(0));
    }
    path[0] = path0;
    path[1] = path1;
  }

  function updateGovernance(address payable _newGovernance) external onlyGovernance {
    governance = _newGovernance;
  }
}
