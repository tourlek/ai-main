---
name: financial-doc-system
description: โครงสร้างระบบออกเอกสาร (ใบเสนอราคา/ใบแจ้งหนี้/ใบวางบิล/ใบเสร็จ) ใน ~/financial
metadata: 
  node_type: memory
  type: project
  originSessionId: 1513b538-92c5-4261-9c1f-587d97945f4d
---

`/Users/tualek/financial` คือระบบออกเอกสารธุรกิจส่วนตัวของ user สร้างเมื่อ 11 มิ.ย. 2026 เพื่อแทนการใช้ PEAK ตัวหลักคือ **React 19 + Vite ใน `app/`** (รัน `npm run dev` port 5180 — เครื่องนี้ node default คือ v14 ต้องใช้ PATH จาก `~/.nvm/versions/node/v24.14.0/bin`; `.claude/launch.json` ชี้ vite ผ่าน node24 ตรงๆ แล้ว) เก็บเอกสาร/โปรไฟล์ผู้ขาย/ลูกค้าใน localStorage (key `fin.docs.v1`, `fin.sellers.v1`, `fin.customers.v1`) มีรันเลขอัตโนมัติแบบ PEAK, เครดิต↔วันครบกำหนดคำนวณสองทาง, ออกเอกสารต่อ (invoice→receipt พร้อม reference), สถานะเอกสาร (draft/issued/paid/void) เอกสารมี 9 ประเภทตามชุด PEAK: รายรับ QT/IV/TX/BN/RC/CN/DN, รายจ่าย PO/PV (ใบสำคัญจ่าย = "ทำจ่าย" ที่ user เรียก) /WHT (หนังสือรับรองหัก ณ ที่จ่าย 50 ทวิ — template เฉพาะใน `WhtCertPreview.jsx`) ส่วน `index.html` ที่ root เป็นเวอร์ชันเก่าไฟล์เดียว ใช้คู่ `scripts/build_pdf.py` แปลง `data/*.json` → PDF ผ่าน headless Chrome (replace marker `const PRELOADED_DOC = null;`), `output/` เก็บ PDF

**ข้อมูลธุรกิจ:** ผู้ขายคือ สิทธิพร รอดเกี้ยว (บุคคลธรรมดา เลขภาษี 1409902885424, โทร 0962394225, stp.rodkeaw@gmail.com, บัญชีกสิกร ออมทรัพย์ 0513895984) รับงานถ่ายทำ insert vdo ให้ บริษัท โมชั่นรีช จำกัด (C00007, เลขภาษี 0105568138574) แบรนด์ mistine — ไม่จด VAT (ใช้ "ไม่มี/ยกเว้น") โดนหัก ณ ที่จ่าย 3% เลขเอกสารรูปแบบ PEAK เช่น `IV-20260600002` (IV-ปีเดือน+ลำดับ)

**Layout อ้างอิงจากใบแจ้งหนี้ PEAK** ที่ user เคยใช้ — ถ้าแก้ template ให้คงโครงเดิม (หัวผู้ขาย/meta ขวา, ตาราง 6 คอลัมน์, สรุปขวา+จำนวนเงินตัวอักษรซ้าย, แถวลายเซ็น 5 ช่อง)
