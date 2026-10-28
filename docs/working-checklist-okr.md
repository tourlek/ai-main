# Working Checklist and OKRs

หลักการของผู้ใช้: **คิดให้จบก่อนเริ่มเขียน และคุม scope ให้เฉียบคม** ไม่ใช่เร่งปริมาณโค้ดจาก AI

เอกสารนี้ใช้เมื่อวางแผน ประเมินงาน ทำ Senior alignment หรือ retrospective; กฎการทำงานประจำอยู่ใน [config/workflow.md](../config/workflow.md). เอกสารนี้ไม่เพิ่มสิทธิ์ในการแก้ scope, เขียน tracker, commit, push หรือ deploy

Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/docs/working-checklist-okr.md

## 1. Pre-implementation

### Task breakdown และ scope alignment

- อ่านโค้ดและข้อกำหนดที่เกี่ยวข้องเพื่อออกแบบจากหลักฐาน ก่อนแก้ไฟล์ ไม่ออกแบบจากการเดาโครงสร้าง repo
- แตกงานใหญ่เป็นหน่วยที่จบและตรวจรับได้ ระบุเป้าหมาย, in-scope, out-of-scope, ลำดับ/dependencies และ acceptance ของแต่ละหน่วย
- MVP คือขอบเขตเล็กที่ใช้งานจบได้ โดยยังรักษา correctness, security, essential error handling และ compatibility; ไม่ใช่ลด acceptance เองหรือส่ง scaffold ที่ใช้งานไม่ครบ
- สำหรับงานที่ต้อง Senior alignment ให้ scope, data flow, risks และ acceptance เห็นตรงกันครบก่อนเริ่ม implementation พร้อมบันทึกผู้อนุมัติและหลักฐานใน task/issue ที่ใช้จริง
- ถ้ายังไม่มี alignment ที่จำเป็น ให้ทำ read-only investigation และเตรียมคำถามต่อได้ แต่ไม่อ้างว่า Senior อนุมัติแล้วหรือเริ่ม implementation ส่วนที่ยังไม่ตกลง
- เมื่อขอบเขตได้รับอนุมัติแล้ว ทำให้จบโดยไม่ถามย้ำ; ขอ alignment ใหม่เฉพาะเมื่อ scope, risk, behavior หรือ authority เปลี่ยน

### Architecture และ edge cases

- สรุป data flow สั้น ๆ: inputs/validation → service/API → state/storage → consumers/UI พร้อม dependencies และผลกระทบต่อส่วนอื่น รวม micro frontend เมื่อเกี่ยวข้อง
- ระบุ assumptions, state transitions, error/empty states, side effects และ high-impact edge cases ที่สัมพันธ์กับงาน เช่น permissions, duplicate/race, timeout, migration และ rollback
- เลือกทางออกที่เรียบง่ายและอธิบาย trade-off ได้; ทำ fallback/retry เฉพาะที่ behavior หรือ scope ต้องการ ไม่เพิ่ม abstraction หรือระบบป้องกันที่ไม่เกี่ยวข้อง
- กำหนดวิธีพิสูจน์ acceptance และเส้นทางที่ต้อง smoke ก่อนเขียน ถ้าเข้าถึง environment/role ไม่ได้ ให้ระบุส่วนที่ยังพิสูจน์ไม่ได้

### Estimation

- ประเมินจาก scope และงานที่ reuse ได้ แยก implementation, tests, debugging, integration และ manual verification; เผื่อ uncertainty ของส่วนที่ยังไม่มีหลักฐานอย่างชัดเจน
- แยก effort estimate ออกจาก delivery deadline รวม dependencies, review และเวลารอที่มีผลต่อวันส่งมอบ ไม่ซ่อนเวลารอไว้เป็น coding time
- ใช้ `clickup-format-estimate` เมื่อทำ estimates ของ ClickUp และเขียนเฉพาะ tracker/task ที่ผู้ใช้อนุญาต; การวางแผนใน chat ไม่อนุญาต external writes

## 2. Execution

### Intentional coding กับ AI

- เจ้าของงานต้องอธิบาย logic และเหตุผลของทุกส่วนที่รับเข้ามาได้ ไม่ยอมรับโค้ดเพียงเพราะ AI สร้างให้หรือ build ผ่าน
- ก่อนรับหรือเสนอ push ให้ตรวจ changed logic, assumptions, architecture fit, side effects และเคสตกหล่น แล้ว exercise behavior ที่เปลี่ยนจริง
- AI อธิบายส่วนที่ไม่ตรงไปตรงมาและหลักฐานการตรวจ ไม่ต้องบรรยาย boilerplate ทุกบรรทัด; ถ้าเจ้าของงานยังไม่เข้าใจส่วนใด ให้ทำความเข้าใจก่อนรับส่วนนั้น
- Commit, push และ deploy ต้องได้รับอนุญาตแยกตามกฎหลัก; checklist ไม่ใช่การอนุมัติล่วงหน้า

### Priority และ scope creep

- โฟกัส priority หลักของ sprint/task และ acceptance ที่ตกลงไว้ก่อน
- Refactor หรือ improvement นอก scope ให้แยกเป็นข้อเสนอ backlog ไม่แก้ทันทีหรือสร้าง card เพิ่มเอง; เมื่อผู้ใช้ขอจด จึงบันทึกลง tracker/artifact ที่ตกลง
- ถ้าเรื่องที่พบทำให้งานปัจจุบันไม่ถูกต้องหรือไม่ปลอดภัย ให้แสดงหลักฐานและผลกระทบ แล้วตกลง scope ก่อนดำเนินการ ไม่ซ่อน blocker เพื่อรักษาตัวเลขส่งตรงเวลา

## 3. Continuous improvement และการวัดผล

### Objective

ส่งมอบงานที่ออกแบบและเข้าใจครบภายใน scope ที่ตกลง พร้อมพัฒนาความลึกด้าน architecture และ migration

### Key result ที่ผู้ใช้ระบุ

**ส่งมอบตรงเวลาเกิน 80% ของงานทั้งหมดในชุดงานที่ใช้วัด**

- ตกลง reporting period และชุด task ที่นับก่อนคำนวณ ใช้ delivery deadline baseline ที่อนุมัติ ไม่ใช้ effort estimate แทน deadline
- On-time delivery rate = จำนวน task ที่ส่งครบ acceptance ภายใน deadline baseline / จำนวน task ที่ครบกำหนดในชุดงานที่ใช้วัด × 100
- ถ้าไม่มี task ที่เข้าเกณฑ์ ให้รายงานว่ายังวัดไม่ได้ ไม่รายงาน 0% หรือ 100%
- ถ้า scope/deadline เปลี่ยน ให้เก็บ baseline เดิม, ข้อตกลงใหม่และเหตุผลแยกกัน ไม่แก้ย้อนหลังเพื่อทำให้ตัวชี้วัดผ่าน
- ขณะนี้เอกสารกำหนด target เท่านั้น ยังไม่มี baseline หรือผลวัดที่ยืนยัน ห้ามอ้างว่าทำได้เกิน 80% โดยไม่มีข้อมูล task จริง

### Estimate vs Actual

เมื่อผู้ใช้ขอติดตามเวลา ใช้ข้อมูล time tracking หรือเวลาที่ผู้ใช้ยืนยัน บันทึกอย่างน้อย: task/reference, scope baseline, estimated effort, actual effort, deadline baseline, delivery date, verification evidence และเหตุผลของ variance

แยก coding/testing/debugging ออกจากเวลารอ dependencies/review และ scope changes; ไม่ใช้เวลาตอบของ AI, token usage หรือช่วงเวลาที่ session เปิดอยู่เป็น actual effort และไม่เขียน log ในงาน read-only/chat-only โดยพลการ

ทบทวนรูปแบบที่ประเมินพลาด แล้วปรับ assumptions และ uncertainty ของ estimate ครั้งถัดไปจากหลักฐาน ไม่เปลี่ยนตัวเลขเดิมเพื่อกลบ variance

### Skill Matrix และ Senior feedback

- ตกลงระดับทักษะ, indicators และจังหวะ feedback กับ Senior; AI ช่วยเตรียมหลักฐานและคำถามได้ แต่ไม่ให้คะแนนหรืออ้างการยอมรับแทน Senior
- Architecture depth: trace end-to-end flow และ boundaries ได้ อธิบาย constraints, alternatives และเหตุผลของทางเลือก โดยแสดงผลต่อ consumers และ failure paths
- Migration depth: ระบุ affected callers/data contracts, permissions, compatibility, rollout/rollback และพิสูจน์ behavior ที่รักษาหรือเปลี่ยนด้วยหลักฐานจริง
- เก็บตัวอย่างงาน, feedback และสิ่งที่ต้องพัฒนาต่อในพื้นที่ที่ผู้ใช้เลือก ไม่สร้าง tracker, meeting หรือ rubric เชิงตัวเลขที่ยังไม่ได้ตกลงเอง
