// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RPSLS {
    uint public reward; // จำนวนรางวัลที่สะสมไว้
    mapping (address => uint) public player_choice; // เก็บตัวเลือกของผู้เล่น (0 - Rock, 1 - Paper, 2 - Scissors, 3 - Lizard, 4 - Spock)
    mapping(address => bool) public player_not_played; // เช็คว่าผู้เล่นยังไม่ได้เลือกหรือไม่
    address[] public players; // เก็บที่อยู่ของผู้เล่น

    uint public numPlayer; // จำนวนผู้เล่นที่เข้าร่วมเกม
    uint public numInput; // จำนวนผู้เล่นที่ส่งค่าเข้ามา
    mapping(address => bytes32) public commits; // เก็บค่า commit ของผู้เล่น
    mapping(address => bool) public revealed; // เช็คว่าผู้เล่นเปิดเผยตัวเลือกแล้วหรือไม่
    uint public startTime; // เวลาที่เริ่มเกม
    address[] public allowedAccounts = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    constructor() {
        resetGame(); // เรียกฟังก์ชัน resetGame() เพื่อล้างค่าทุกอย่างเมื่อเริ่มต้น
    }

    function resetGame() private {
        numPlayer = 0; // รีเซ็ตจำนวนผู้เล่น
        numInput = 0; // รีเซ็ตจำนวนผู้ที่ส่งค่าเข้ามา
        reward = 0; // รีเซ็ตเงินรางวัล
        delete players; // ล้างข้อมูลผู้เล่น
        startTime = block.timestamp; // กำหนดเวลาเริ่มเกมใหม่
    }

    function addPlayer() public payable {
        require(numPlayer < 2, "The players are all there."); // ตรวจสอบว่ามีผู้เล่นน้อยกว่า 2 คน
        require(isAllowed(msg.sender), "This account is not authorized."); // ตรวจสอบว่าบัญชีได้รับอนุญาตให้เล่น
        if (numPlayer > 0) {
            require(msg.sender != players[0], "Do not allow the same player to re-enter."); // ป้องกันผู้เล่นคนเดิมเข้าซ้ำ
        }
        require(msg.value == 1 ether, "You must deposit 1 ether."); // ตรวจสอบว่าผู้เล่นวางเงิน 1 ether
        reward += msg.value; // เพิ่มเงินรางวัล
        player_not_played[msg.sender] = true; // กำหนดว่าผู้เล่นยังไม่ได้เล่น
        players.push(msg.sender); // เพิ่มที่อยู่ของผู้เล่น
        numPlayer++; // เพิ่มจำนวนผู้เล่น
    }

    function commit(bytes32 dataHash) public {
        require(numPlayer == 2, "There must be 2 players first."); // ตรวจสอบว่ามีผู้เล่นครบ 2 คนก่อน
        require(player_not_played[msg.sender], "You have already chosen"); // ตรวจสอบว่าผู้เล่นยังไม่ได้เลือกมาก่อน
        commits[msg.sender] = dataHash; // เก็บค่า commit
        revealed[msg.sender] = false; // กำหนดว่ายังไม่ได้เปิดเผยค่า
    }

    function reveal(uint choice, bytes32 randomValue) public {
        require(commits[msg.sender] != 0, "Must commit first"); // ตรวจสอบว่าผู้เล่นเคย commit มาก่อน
        require(!revealed[msg.sender], "You have revealed your options."); // ตรวจสอบว่าผู้เล่นยังไม่ได้เปิดเผยมาก่อน
        require(keccak256(abi.encodePacked(choice, randomValue)) == commits[msg.sender], "Data does not match commit"); // ตรวจสอบความถูกต้องของการ commit
        require(choice >= 0 && choice <= 4, "Incorrect option"); // ตรวจสอบว่าตัวเลือกอยู่ในช่วงที่กำหนด
        player_choice[msg.sender] = choice; // เก็บตัวเลือกของผู้เล่น
        revealed[msg.sender] = true; // กำหนดว่าผู้เล่นเปิดเผยตัวเลือกแล้ว
        numInput++; // เพิ่มจำนวนผู้ที่ส่งค่าเข้ามา
        
        if (numInput == 2) {
            _checkWinnerAndPay(); // ตรวจสอบผู้ชนะและจ่ายเงินรางวัล
            resetGame(); // รีเซ็ตเกม
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]]; // ดึงตัวเลือกของผู้เล่น 1
        uint p1Choice = player_choice[players[1]]; // ดึงตัวเลือกของผู้เล่น 2
        address payable account0 = payable(players[0]); // กำหนดบัญชีของผู้เล่น 1
        address payable account1 = payable(players[1]); // กำหนดบัญชีของผู้เล่น 2

        if (_isWinner(p0Choice, p1Choice)) {
            account0.transfer(reward); // ผู้เล่น 1 ชนะ รับเงินรางวัลทั้งหมด
        } else if (_isWinner(p1Choice, p0Choice)) {
            account1.transfer(reward); // ผู้เล่น 2 ชนะ รับเงินรางวัลทั้งหมด
        } else {
            account0.transfer(reward / 2); // กรณีเสมอ แบ่งเงินรางวัลครึ่งหนึ่งให้ทั้งสองฝ่าย
            account1.transfer(reward / 2);
        }
    }

    function _isWinner(uint choice1, uint choice2) private pure returns (bool) {
        return (
            (choice1 == 0 && (choice2 == 2 || choice2 == 3)) || // Rock ชนะ Scissors, Lizard
            (choice1 == 1 && (choice2 == 0 || choice2 == 4)) || // Paper ชนะ Rock, Spock
            (choice1 == 2 && (choice2 == 1 || choice2 == 3)) || // Scissors ชนะ Paper, Lizard
            (choice1 == 3 && (choice2 == 1 || choice2 == 4)) || // Lizard ชนะ Paper, Spock
            (choice1 == 4 && (choice2 == 0 || choice2 == 2))    // Spock ชนะ Rock, Scissors
        );
    }

    function isAllowed(address user) private view returns (bool) {
        for (uint i = 0; i < allowedAccounts.length; i++) {
            if (allowedAccounts[i] == user) {
                return true; // ตรวจสอบว่าบัญชีอยู่ในรายชื่อที่อนุญาต
            }
        }
        return false;
    }

    function withdraw() public {
        require(block.timestamp > startTime + 5 minutes, "You have to wait 5 minutes before withdrawing money."); // รอ 5 นาทีเพื่อให้สามารถถอนเงินได้
        payable(players[0]).transfer(1 ether); // คืนเงินให้ผู้เล่นที่ลงเงินไป
        resetGame(); // รีเซ็ตเกม
    }
}
