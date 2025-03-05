# Solidity
800_6521650645_Lab13

**1. โค้ดที่ป้องกันการล็อกเงินไว้ใน Contract**
ปัญหาที่อาจเกิดขึ้นคือมีผู้เล่นเข้ามาลงเงิน แต่ไม่มีผู้เล่นคนที่สองเข้าร่วมหรือผู้เล่นไม่ส่งตัวเลือก ทำให้เงินถูกล็อกไว้ในสัญญาโดยไม่มีใครสามารถถอนออกได้ โค้ดที่ป้องกันปัญหานี้คือ:

function withdraw() public {
        require(block.timestamp > startTime + 5 minutes, "You have to wait 5 minutes before withdrawing money.");
        payable(players[0]).transfer(1 ether);
        resetGame();
    }
**การทำงานของโค้ดนี้:**
1.ใช้ block.timestamp เพื่อตรวจสอบว่าเวลาผ่านไป 5 นาทีแล้วหรือยัง
2.หากไม่มีผู้เล่นคนที่สองภายใน 5 นาที ผู้เล่นคนแรกสามารถเรียกฟังก์ชัน withdraw() เพื่อถอนเงินคืนได้
3.หลังจากคืนเงินให้ผู้เล่นแล้ว จะเรียก resetGame() เพื่อล้างค่าข้อมูลเกมและเริ่มรอบใหม่

**2. โค้ดส่วนที่ทำการซ่อน Choice และ Commit**
เพื่อป้องกันการใช้ front-running (รู้ตัวเลือกของอีกฝ่ายล่วงหน้าและเลือกชนะได้) เราใช้ commit-reveal scheme โดยให้ผู้เล่นสร้างค่าที่ถูกเข้ารหัสก่อน (commit) แล้วเปิดเผยค่าทีหลัง (reveal)

function commit(bytes32 dataHash) public {
        require(numPlayer == 2, "There must be 2 players first.");
        require(player_not_played[msg.sender], "You have already chosen");
        commits[msg.sender] = dataHash;
        revealed[msg.sender] = false;
    }

**การทำงานของ commit()**
1.ผู้เล่นต้องมีครบ 2 คนก่อน
2.ผู้เล่นต้องไม่เคยเลือกมาก่อน
3.ผู้เล่นส่งค่าที่เข้ารหัส (dataHash) ซึ่งได้จาก keccak256(abi.encodePacked(choice, randomValue))
4.เก็บค่า commit ไว้ และกำหนดค่า revealed เป็น false

การเข้ารหัสข้อมูลทำให้ไม่มีใครสามารถรู้ว่าอีกฝ่ายเลือกอะไร จนกว่าทั้งสองคนจะเปิดเผยตัวเลือก (reveal)

**3. โค้ดส่วนที่จัดการกับความล่าช้าเมื่อผู้เล่นไม่ครบทั้งสองคนเสียที**
กรณีที่ผู้เล่นเข้ามาเพียงคนเดียวและอีกคนไม่มาซักที ระบบต้องมีมาตรการป้องกันไม่ให้เกมติดค้าง

function withdraw() public {
        require(block.timestamp > startTime + 5 minutes, "You have to wait 5 minutes before withdrawing money.");
        payable(players[0]).transfer(1 ether);
        resetGame();
    }

**การทำงานของโค้ด**
1.ถ้าเวลาผ่านไป 5 นาที (block.timestamp > startTime + 5 minutes) แล้วไม่มีผู้เล่นคนที่สองเข้ามา
2.ผู้เล่นที่เข้ามาก่อนสามารถถอนเงินออกจาก Contract ได้
3.หลังจากคืนเงินแล้วจะเรียก resetGame() เพื่อให้สามารถเริ่มเกมใหม่ได้

**4. โค้ดส่วนทำการ Reveal และตัดสินผู้ชนะ**
เมื่อทั้งสองฝ่ายได้ commit ไว้แล้ว ผู้เล่นต้องเปิดเผยตัวเลือก (reveal) โดยต้องมีหลักฐานว่าสิ่งที่เปิดเผยตรงกับสิ่งที่ commit ไว้ก่อนหน้านี้

function reveal(uint choice, bytes32 randomValue) public {
        require(commits[msg.sender] != 0, "Must commit first");
        require(!revealed[msg.sender], "You have revealed your options.");
        require(keccak256(abi.encodePacked(choice, randomValue)) == commits[msg.sender], "Data does not match commit");
        require(choice >= 0 && choice <= 4, "Incorrect option");
        player_choice[msg.sender] = choice;
        revealed[msg.sender] = true;
        numInput++;
        
        if (numInput == 2) {
            _checkWinnerAndPay(); // ตรวจสอบผู้ชนะและจ่ายเงินรางวัล
            resetGame(); // รีเซ็ตเกม
        }
    }
    
**การทำงานของ reveal()**
1.ตรวจสอบว่าผู้เล่นเคย commit มาก่อน (require(commits[msg.sender] != 0))
2.ตรวจสอบว่ายังไม่เคย reveal มาก่อน (require(!revealed[msg.sender]))
3.ตรวจสอบว่าค่า choice + randomValue ที่เปิดเผยนั้น ต้องตรงกับค่า commit ที่เคยส่งไปก่อนหน้านี้ (keccak256(abi.encodePacked(choice, randomValue)) == commits[msg.sender])
4.บันทึกตัวเลือกของผู้เล่น และกำหนดว่าเปิดเผยแล้ว (revealed[msg.sender] = true)
5.หากทั้งสองคนเปิดเผยแล้ว (numInput == 2):
  5.1.เรียก _checkWinnerAndPay() เพื่อตัดสินผู้ชนะ
  5.2.รีเซ็ตเกมเพื่อให้เริ่มรอบใหม่
