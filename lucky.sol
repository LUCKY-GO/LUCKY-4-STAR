pragma solidity ^0.4.25;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

library Utils {

    function bytes32ToString(bytes32 x) internal pure returns (string) {
        uint charCount = 0;
        bytes memory bytesString = new bytes(32);
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            } else if (charCount != 0) {
                break;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];

        }
        return string(bytesStringTrimmed);
    }

    function _stringToBytes(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function _stringEq(string a, string b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return _stringToBytes(a) == _stringToBytes(b);
        }
    }


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;

    }
}

contract SeroInterface {

    bytes32 private topic_sero_issueToken = 0x3be6bf24d822bcd6f6348f6f5a5c2d3108f04991ee63e80cde49a8c4746a0ef3;
    bytes32 private topic_sero_balanceOf = 0xcf19eb4256453a4e30b6a06d651f1970c223fb6bd1826a28ed861f0e602db9b8;
    bytes32 private topic_sero_send = 0x868bd6629e7c2e3d2ccf7b9968fad79b448e7a2bfb3ee20ed1acbc695c3c8b23;
    bytes32 private topic_sero_currency = 0x7c98e64bd943448b4e24ef8c2cdec7b8b1275970cfe10daf2a9bfa4b04dce905;

    function sero_msg_currency() internal returns (string) {
        bytes memory tmp = new bytes(32);
        bytes32 b32;
        assembly {
            log1(tmp, 0x20, sload(topic_sero_currency_slot))
            b32 := mload(tmp)
        }
        return Utils.bytes32ToString(b32);
    }

    function sero_issueToken(uint256 _total, string memory _currency) internal returns (bool success){
        bytes memory temp = new bytes(64);
        assembly {
            mstore(temp, _currency)
            mstore(add(temp, 0x20), _total)
            log1(temp, 0x40, sload(topic_sero_issueToken_slot))
            success := mload(add(temp, 0x20))
        }
        return;
    }

    function sero_balanceOf(string memory _currency) internal view returns (uint256 amount){
        bytes memory temp = new bytes(32);
        assembly {
            mstore(temp, _currency)
            log1(temp, 0x20, sload(topic_sero_balanceOf_slot))
            amount := mload(temp)
        }
        return;
    }

    function sero_send_token(address _receiver, string memory _currency, uint256 _amount) internal returns (bool success){
        return sero_send(_receiver, _currency, _amount, "", 0);
    }

    function sero_send(address _receiver, string memory _currency, uint256 _amount, string memory _category, bytes32 _ticket) internal returns (bool success){
        bytes memory temp = new bytes(160);
        assembly {
            mstore(temp, _receiver)
            mstore(add(temp, 0x20), _currency)
            mstore(add(temp, 0x40), _amount)
            mstore(add(temp, 0x60), _category)
            mstore(add(temp, 0x80), _ticket)
            log1(temp, 0xa0, sload(topic_sero_send_slot))
            success := mload(add(temp, 0x80))
        }
        return;
    }

}

contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract LUCKY is SeroInterface, Ownable {

    using SafeMath for uint256;
    using Utils for Utils;

    string private constant SERO_CURRENCY = "SERO";
    string private constant TOKEN_CURRENCY = "LUCKY";

    uint256 private _totalSupply = 1e27;
    uint256 private allIncome;

    bool private isSell = true;
    bool private canPlay = true;
    bool private canPlayByLucky = false;

    address private marketAddr;
    address private luckyAddr;

    mapping(uint256 => Player) public betsMap;

    uint256 private index;

    struct Player {
        uint256 investTimestamp;
        byte investCode_1;
        byte investCode_2;
        byte investCode_3;
        byte investCode_4;
        address investAddress;
        uint256 curBlockNumber;
    }

    constructor(address _marketAddr, address _luckyAddr) public payable {
        require(sero_issueToken(_totalSupply, TOKEN_CURRENCY));
        require(sero_send_token(_luckyAddr, TOKEN_CURRENCY, 9e26));
        marketAddr = _marketAddr;
        luckyAddr = _luckyAddr;
    }

    function getAllIncome() public view returns (uint256) {
        return allIncome;
    }

    function getCurrentIndex() public view returns (uint256) {
        return index;
    }

    function symbol() public pure returns (string memory) {
        return TOKEN_CURRENCY;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOfSero() internal view returns (uint256){
        return sero_balanceOf(SERO_CURRENCY);
    }

    function balanceOfToken() public view returns (uint256 amount) {
        return sero_balanceOf(TOKEN_CURRENCY);
    }

    function setMarketAddr(address addr) public onlyOwner {
        marketAddr = addr;
    }

    function setLuckyAddr(address addr) public onlyOwner {
        luckyAddr = addr;
    }

    function setSell(bool flag) public onlyOwner {
        isSell = flag;
    }

    function conversionRate() public view returns (uint256, uint256) {

        if (allIncome < 1e23) {
            return (1e18, 1e20);
        }
        if (allIncome < 2e23) {
            return (1e18, 9e19);
        }
        if (allIncome < 3e23) {
            return (1e18, 8e19);
        }
        if (allIncome < 4e23) {
            return (1e18, 7e19);
        }
        if (allIncome < 5e23) {
            return (1e18, 6e19);
        }
        return (1e18, 5e19);

    }

    function seroToLucky(uint256 value) internal view returns (uint256) {
        uint256 r1;
        uint256 r2;
        (r1, r2) = conversionRate();
        return value.mul(r2) / r1;
    }

    function transferSero(address _to, uint256 _value) public onlyOwner {
        require(sero_balanceOf(SERO_CURRENCY) >= _value);
        require(sero_send_token(_to,SERO_CURRENCY,_value));

    }

    function transferToken(address _to, uint256 _value) public onlyOwner {
        require(sero_balanceOf(TOKEN_CURRENCY) >= _value);
        require(sero_send(_to, TOKEN_CURRENCY, _value, "", 0));
    }

    function enableCanPlay() public onlyOwner{
        require(!canPlay);
        canPlay = true;
    }

    function disableCanPlay() public onlyOwner{
        require(canPlay);
        canPlay = false;
    }

    function enableCanPlayByLucky() public onlyOwner{
        require(!canPlayByLucky);
        canPlayByLucky = true;
    }

    function disableCanPlayByLucky() public onlyOwner{
        require(canPlayByLucky);
        canPlayByLucky = false;
    }


    function insertBets(uint256 loopTimes, bytes memory _investNum, address _addr) private {
        uint256 j =0;
        for (uint256 i = 0; i < loopTimes; i++) {
            betsMap[index].investTimestamp = now;
            betsMap[index].investCode_1 = _investNum[j];
            betsMap[index].investCode_2 = _investNum[j+1];
            betsMap[index].investCode_3 = _investNum[j+2];
            betsMap[index].investCode_4 = _investNum[j+3];
            betsMap[index].investAddress = _addr;
            betsMap[index].curBlockNumber = block.number;
            index+=1;
            j+=4;
        }
    }


    function bet(string investNum) public payable returns (bool){
        require(canPlay);
        require(Utils._stringEq(SERO_CURRENCY, sero_msg_currency()));
        require(!Utils.isContract(msg.sender));
        require(msg.value >= 1e18 && msg.value <= 1e20);
        uint256 loopTimes = msg.value.div(1e18);
        bytes memory bytesInvestNum = bytes(investNum);
        require(loopTimes == bytesInvestNum.length.div(4));
        require(loopTimes <= 100);
        insertBets(loopTimes, bytesInvestNum, msg.sender);
        uint256 fee = msg.value.div(10);
        require(sero_send_token(luckyAddr, SERO_CURRENCY, fee));
        require(sero_send_token(marketAddr, SERO_CURRENCY, msg.value.sub(fee)));
        return true;
    }

    function betByLucky(string investNum) public payable returns (bool){
        require(canPlayByLucky);
        require(Utils._stringEq(TOKEN_CURRENCY, sero_msg_currency()));
        require(!Utils.isContract(msg.sender));
        require(msg.value >= 1e19 && msg.value <= 1e21);
        uint256 loopTimes = msg.value.div(1e19);
        bytes memory bytesInvestNum = bytes(investNum);
        require(loopTimes == bytesInvestNum.length.div(4));
        require(loopTimes <= 100);
        insertBets(loopTimes, bytesInvestNum, msg.sender);
        uint256 fee = msg.value.div(10);
        require(sero_send_token(luckyAddr, TOKEN_CURRENCY, fee));
        require(sero_send_token(marketAddr, TOKEN_CURRENCY, msg.value.sub(fee)));
        return true;
    }

    function buyLucky() public payable returns (uint256 luckyAmount) {
        require(isSell);
        require(Utils._stringEq(SERO_CURRENCY, sero_msg_currency()));

        uint256 amount = msg.value;
        if (msg.value > 1e23) {
            amount = 1e23;
            require(sero_send_token(msg.sender, SERO_CURRENCY, msg.value.sub(amount)));
        }

        luckyAmount = seroToLucky(amount);
        allIncome = allIncome.add(amount);
        require(sero_send_token(luckyAddr, SERO_CURRENCY, amount));
        require(sero_send_token(msg.sender, TOKEN_CURRENCY, luckyAmount));
        if(allIncome >= 5e23){
            canPlayByLucky = true;
        }
        return luckyAmount;
    }


}

