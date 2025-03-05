# Solidity

800_6521650645_Lab13

**โครงสร้างโค้ด**

1. การกำหนดตัวแปรหลัก

    reward – จำนวนรางวัลที่สะสมไว้
    
    player_choice – เก็บตัวเลือกของผู้เล่น (0-4)
    
    player_not_played – เช็คว่าผู้เล่นยังไม่ได้เลือก
    
    players – เก็บที่อยู่ของผู้เล่นทั้งสอง
    
    numPlayer – จำนวนผู้เล่นปัจจุบัน
    
    numInput – จำนวนผู้เล่นที่เปิดเผยตัวเลือก
    
    commits – เก็บค่า Commit ของผู้เล่น
    
    revealed – เช็คว่าผู้เล่นเปิดเผยตัวเลือกแล้ว
    
    startTime – เวลาที่เริ่มเกม
    
    allowedAccounts – รายชื่อบัญชีที่ได้รับอนุญาตให้เล่น

2. ฟังก์ชันสำคัญ

    resetGame() - รีเซ็ตสถานะของเกมเพื่อเริ่มรอบใหม่
    
    addPlayer() - ให้ผู้เล่นเข้าร่วมโดยต้องวางเงิน 1 Ether และต้องเป็นบัญชีที่ได้รับอนุญาต
    
    commit(bytes32 dataHash) - ผู้เล่นต้อง Commit ตัวเลือกของตนเองก่อนเปิดเผย
    
    reveal(uint choice, bytes32 randomValue)
    
     - เปิดเผยตัวเลือกของผู้เล่น โดยต้องตรงกับค่าที่ Commit ไว้
    
     - หากเปิดเผยครบ 2 คน จะเรียก _checkWinnerAndPay()
    
    _checkWinnerAndPay()
    
     - ตรวจสอบผู้ชนะและโอนเงินรางวัลให้
    
     - กรณีเสมอ จะแบ่งรางวัลให้ทั้งสองฝ่าย
    
    _isWinner(uint choice1, uint choice2) - ตรวจสอบว่าผู้เล่นที่เลือก choice1 ชนะ choice2 หรือไม่ ตามกติกา RPSLS
    
    isAllowed(address user) - ตรวจสอบว่าบัญชีได้รับอนุญาตให้เล่นหรือไม่
    
    withdraw() - หากไม่มีผู้เล่นครบ 2 คนภายใน 5 นาที ผู้เล่นที่รอสามารถถอนเงินคืนได้

**การทำงานของโค้ด**

1. การเข้าร่วมเกม

    1.ผู้เล่นต้องโอน 1 ETH เพื่อเข้าร่วม
    
    2.รองรับผู้เล่นเพียง 2 คน เท่านั้น
    
    3.ระบบมี บัญชีที่ได้รับอนุญาต เท่านั้นที่สามารถเข้าร่วม
    
    4.ห้ามผู้เล่นคนเดิมเข้าซ้ำในการแข่งขันเดียวกัน

2. การเลือกตัวเลือกแบบ Commit-Reveal

    1.ผู้เล่นส่งค่า commit (keccak256 ของตัวเลือก + ค่าสุ่ม)
    
    2.เมื่อผู้เล่นทั้งสองคน commit แล้ว ต้องใช้ฟังก์ชัน reveal() เพื่อเปิดเผยค่าที่แท้จริง
    
    3.ระบบตรวจสอบความถูกต้องก่อนบันทึกค่าตัวเลือก

3. การตัดสินผู้ชนะ

    1.เมื่อทั้งสองฝ่ายเปิดเผยตัวเลือกแล้ว ระบบเรียก _checkWinnerAndPay()
    
    2.ใช้กฎของเกม RPSLS ในการตัดสินผลแพ้-ชนะ
    
    3.หากมีผู้ชนะ จะได้รับเงินเดิมพันทั้งหมด
    
    4.กรณีเสมอ เงินรางวัลจะถูกแบ่งครึ่งให้ทั้งสองฝ่าย

4. ป้องกันการล็อกเงินในสัญญา

    1.หากมีเพียง 1 คนเข้าร่วม แต่ไม่มีอีกฝ่ายมาเล่นภายใน 5 นาที
    
    2.ผู้เล่นที่รอสามารถเรียก withdraw() เพื่อรับเงินคืน

5. ระบบรีเซ็ตเกม

    1.หลังจากจบแต่ละรอบ ระบบจะเรียก resetGame() เพื่อล้างข้อมูลและเริ่มเกมใหม่

# อธิบายส่วนสำคัญของโค้ด

**1. การป้องกันการล็อกเงินใน Contract**
ปัญหาที่อาจเกิดขึ้นคือมีผู้เล่นเข้ามาวางเงินเดิมพัน แต่ไม่มีผู้เล่นคนที่สองเข้าร่วมหรือผู้เล่นไม่ส่งตัวเลือก ทำให้เงินถูกล็อกไว้ในสัญญาโดยไม่มีใครสามารถถอนออกได้ โค้ดที่ป้องกันปัญหานี้คือ:

    function withdraw() public {
        require(block.timestamp > startTime + 5 minutes, "You have to wait 5 minutes before withdrawing money.");
        payable(players[0]).transfer(1 ether);
        resetGame();
    }

การทำงานของโค้ดนี้:

1.ใช้ block.timestamp เพื่อตรวจสอบว่าเวลาผ่านไป 5 นาทีแล้วหรือยัง

2.หากไม่มีผู้เล่นคนที่สองเข้ามาภายใน 5 นาที ผู้เล่นคนแรกสามารถเรียกฟังก์ชัน withdraw() เพื่อถอนเงินคืนได้

3.หลังจากคืนเงินให้ผู้เล่นแล้ว จะเรียก resetGame() เพื่อล้างค่าข้อมูลเกมและเริ่มรอบใหม่

**2. การซ่อนตัวเลือก (Choice) และการ Commit**
เพื่อป้องกันการใช้ front-running (รู้ตัวเลือกของอีกฝ่ายล่วงหน้าและเลือกชนะได้) เราใช้ commit-reveal scheme โดยให้ผู้เล่นสร้างค่าที่ถูกเข้ารหัสก่อน (commit) แล้วเปิดเผยค่าทีหลัง (reveal)

    function commit(bytes32 dataHash) public {
        require(numPlayer == 2, "There must be 2 players first.");
        require(player_not_played[msg.sender], "You have already chosen");
        commits[msg.sender] = dataHash;
        revealed[msg.sender] = false;
    }

การทำงานของ commit()

1.ผู้เล่นต้องมีครบ 2 คนก่อน

2.ผู้เล่นต้องไม่เคยเลือกมาก่อน

3.ผู้เล่นส่งค่าที่เข้ารหัส (dataHash) ซึ่งได้จาก keccak256(abi.encodePacked(choice, randomValue))

4.เก็บค่า commit ไว้ และกำหนดค่า revealed เป็น false

การเข้ารหัสข้อมูลทำให้ไม่มีใครสามารถรู้ว่าอีกฝ่ายเลือกอะไร จนกว่าทั้งสองคนจะเปิดเผยตัวเลือก (reveal)

**3. การจัดการกับความล่าช้าเมื่อผู้เล่นไม่ครบทั้งสองคน**
หากมีผู้เล่นเข้ามาคนเดียวและรออีกฝ่ายนานเกินไป ระบบต้องมีมาตรการป้องกันไม่ให้เกมติดค้าง

    function withdraw() public {
        require(block.timestamp > startTime + 5 minutes, "You have to wait 5 minutes before withdrawing money.");
        payable(players[0]).transfer(1 ether);
        resetGame();
    }

การทำงานของโค้ด

1.หากเวลาผ่านไป 5 นาที (block.timestamp > startTime + 5 minutes) แล้วไม่มีผู้เล่นคนที่สองเข้ามา

2.ผู้เล่นที่เข้ามาก่อนสามารถถอนเงินออกจาก Contract ได้

3.หลังจากคืนเงินแล้วจะเรียก resetGame() เพื่อให้สามารถเริ่มเกมใหม่ได้

**4. การเปิดเผยตัวเลือก (Reveal) และตัดสินผู้ชนะ**
เมื่อทั้งสองฝ่ายได้ commit ไว้แล้ว ผู้เล่นต้องเปิดเผยตัวเลือก (reveal) โดยต้องมีหลักฐานว่าสิ่งที่เปิดเผยตรงกับสิ่งที่ commit ไว้ก่อนหน้านี้:

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

1.ตรวจสอบว่าผู้เล่นเคย commit มาก่อน (require(commits[msg.sender] != 0))

2.ตรวจสอบว่ายังไม่เคย reveal มาก่อน (require(!revealed[msg.sender]))

3.ตรวจสอบว่าค่า choice + randomValue ที่เปิดเผยนั้น ต้องตรงกับค่า commit ที่เคยส่งไปก่อนหน้านี้ (keccak256(abi.encodePacked(choice, randomValue)) == commits[msg.sender])

4.บันทึกตัวเลือกของผู้เล่น และกำหนดว่าเปิดเผยแล้ว (revealed[msg.sender] = true)

5.หากทั้งสองคนเปิดเผยแล้ว

   5.1.เรียก _checkWinnerAndPay() เพื่อตัดสินผู้ชนะ

   5.2.รีเซ็ตเกมเพื่อให้เริ่มรอบใหม่

**สรุป**

-โค้ดนี้ใช้ commit-reveal scheme เพื่อป้องกัน front-running

-มีระบบ withdraw() เพื่อให้ผู้เล่นที่รอนานเกินไปสามารถดึงเงินคืนได้

-ระบบ reveal() ตรวจสอบความถูกต้องของข้อมูลก่อนตัดสินผู้ชนะ

-มีการรีเซ็ตเกมหลังจากรอบสิ้นสุดเพื่อให้สามารถเริ่มใหม่ได้
