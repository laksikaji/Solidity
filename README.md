Solidity

800_6521650645_Lab13

1. การป้องกันการล็อกเงินใน Contract

ปัญหาที่อาจเกิดขึ้นคือมีผู้เล่นเข้ามาวางเงินเดิมพัน แต่ไม่มีผู้เล่นคนที่สองเข้าร่วมหรือผู้เล่นไม่ส่งตัวเลือก ทำให้เงินถูกล็อกไว้ในสัญญาโดยไม่มีใครสามารถถอนออกได้ โค้ดที่ป้องกันปัญหานี้คือ:

function withdraw() public {
    require(block.timestamp > startTime + 5 minutes, "You have to wait 5 minutes before withdrawing money.");
    payable(players[0]).transfer(1 ether);
    resetGame();
}

การทำงานของโค้ดนี้:

ใช้ block.timestamp เพื่อตรวจสอบว่าเวลาผ่านไป 5 นาทีแล้วหรือยัง

หากไม่มีผู้เล่นคนที่สองเข้ามาภายใน 5 นาที ผู้เล่นคนแรกสามารถเรียกฟังก์ชัน withdraw() เพื่อถอนเงินคืนได้

หลังจากคืนเงินให้ผู้เล่นแล้ว จะเรียก resetGame() เพื่อล้างค่าข้อมูลเกมและเริ่มรอบใหม่

2. การซ่อนตัวเลือก (Choice) และการ Commit

เพื่อป้องกันการใช้ front-running (รู้ตัวเลือกของอีกฝ่ายล่วงหน้าและเลือกชนะได้) เราใช้ commit-reveal scheme โดยให้ผู้เล่นสร้างค่าที่ถูกเข้ารหัสก่อน (commit) แล้วเปิดเผยค่าทีหลัง (reveal)

function commit(bytes32 dataHash) public {
    require(numPlayer == 2, "There must be 2 players first.");
    require(player_not_played[msg.sender], "You have already chosen");
    commits[msg.sender] = dataHash;
    revealed[msg.sender] = false;
}

การทำงานของ commit()

ผู้เล่นต้องมีครบ 2 คนก่อน

ผู้เล่นต้องไม่เคยเลือกมาก่อน

ผู้เล่นส่งค่าที่เข้ารหัส (dataHash) ซึ่งได้จาก keccak256(abi.encodePacked(choice, randomValue))

เก็บค่า commit ไว้ และกำหนดค่า revealed เป็น false

การเข้ารหัสข้อมูลทำให้ไม่มีใครสามารถรู้ว่าอีกฝ่ายเลือกอะไร จนกว่าทั้งสองคนจะเปิดเผยตัวเลือก (reveal)

3. การจัดการกับความล่าช้าเมื่อผู้เล่นไม่ครบทั้งสองคน

หากมีผู้เล่นเข้ามาคนเดียวและรออีกฝ่ายนานเกินไป ระบบต้องมีมาตรการป้องกันไม่ให้เกมติดค้าง

function withdraw() public {
    require(block.timestamp > startTime + 5 minutes, "You have to wait 5 minutes before withdrawing money.");
    payable(players[0]).transfer(1 ether);
    resetGame();
}

การทำงานของโค้ด

หากเวลาผ่านไป 5 นาที (block.timestamp > startTime + 5 minutes) แล้วไม่มีผู้เล่นคนที่สองเข้ามา

ผู้เล่นที่เข้ามาก่อนสามารถถอนเงินออกจาก Contract ได้

หลังจากคืนเงินแล้วจะเรียก resetGame() เพื่อให้สามารถเริ่มเกมใหม่ได้

4. การเปิดเผยตัวเลือก (Reveal) และตัดสินผู้ชนะ

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

การทำงานของ reveal()

ตรวจสอบว่าผู้เล่นเคย commit มาก่อน (require(commits[msg.sender] != 0)).

ตรวจสอบว่ายังไม่เคย reveal มาก่อน (require(!revealed[msg.sender])).

ตรวจสอบว่าค่า choice + randomValue ที่เปิดเผยนั้น ต้องตรงกับค่า commit ที่เคยส่งไปก่อนหน้านี้ (keccak256(abi.encodePacked(choice, randomValue)) == commits[msg.sender]).

บันทึกตัวเลือกของผู้เล่น และกำหนดว่าเปิดเผยแล้ว (revealed[msg.sender] = true).

หากทั้งสองคนเปิดเผยแล้ว (numInput == 2):

เรียก _checkWinnerAndPay() เพื่อตัดสินผู้ชนะ.

รีเซ็ตเกมเพื่อให้เริ่มรอบใหม่.

สรุป

โค้ดนี้ใช้ commit-reveal scheme เพื่อป้องกัน front-running

มีระบบ withdraw() เพื่อให้ผู้เล่นที่รอนานเกินไปสามารถดึงเงินคืนได้

ระบบ reveal() ตรวจสอบความถูกต้องของข้อมูลก่อนตัดสินผู้ชนะ

มีการรีเซ็ตเกมหลังจากรอบสิ้นสุดเพื่อให้สามารถเริ่มใหม่ได้
