pragma solidity ^0.7.0 < 0.9.0;

interface IUniswapV2Router {
    //Checks the equivalent tokens that can be received as output
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  //Makes the swap between two tokens via WETH since it provides better price
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract SwapToken{
    //Final commission is calculated as currentCommission/COMMISSION_FACTOR
    uint private constant DEFAULT_COMMISSION = 5;
    uint public constant COMMISSION_FACTOR = 100;
    uint public currentCommision ; 
    address owner;
    IUniswapV2Router router;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    

    constructor(){
        owner = msg.sender;
        router = IUniswapV2Router(UNISWAP_ROUTER_ADDRESS);
        currentCommision = DEFAULT_COMMISSION;
    }

    modifier isOwner(){
        require(msg.sender == owner,"Only admin can access this functionality");
        _;
    }

    function getCurrentCommission() external view returns(uint){
        return currentCommision;
    }

    function setCurrentCommission(uint _commission) external isOwner returns(bool){
        currentCommision = _commission;
        return true;
    }

    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        uint amountIn = uint(_amountIn - ((currentCommision/COMMISSION_FACTOR) * _amountIn));
        uint256[] memory amountOutMins = router.getAmountsOut(amountIn, path);
        return amountOutMins[path.length -1];  
    }

    function swapTokens(address _token0, address _token1, uint _amountIn, uint _amountOutMin, address _to) external returns (uint256[] memory amounts){
        IERC20(_token0).transferFrom(msg.sender, address(this), _amountIn);
        //Deduct commission for the swap
        uint amountIn = uint(_amountIn - ((currentCommision/COMMISSION_FACTOR) * _amountIn));
        IERC20(_token0).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
         address[] memory path;
        if (_token0 == WETH || _token1 == WETH) {
        path = new address[](2);
        path[0] = _token0;
        path[1] = _token1;
        } else {
        path = new address[](3);
        path[0] = _token0;
        path[1] = WETH;
        path[2] = _token1;
        } 
        return router.swapExactTokensForTokens(amountIn, _amountOutMin, path, _to, block.timestamp + 10 seconds);   
    }  

}
