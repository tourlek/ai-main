---
name: new-files-must-be-ts
description: "New source files (incl. ones dispatched to cursor) must be .ts, and check what can be checked (gcloud, repo config) before asking the user"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 00424bd1-3b48-447d-9b19-2412171607c1
  modified: 2026-10-19T05:56:16.129Z
---

ไฟล์ใหม่ทุกไฟล์ต้องเป็น `.ts` เสมอ แม้โฟลเดอร์รอบๆ จะเป็น `.js` เช่น `src/hooks/` ใน oho-api; ใส่ข้อนี้ใน brief ที่ส่ง cursor ทุกครั้ง (Allowed files ระบุนามสกุล `.ts`).

อะไรที่เช็คเองได้ (gcloud read-only, repo config, grep) ให้เช็คก่อน ไม่ใช่ถาม user หรือโยนให้ทีมเช็ค

**Why:** OHO-7084 ตัวรวม `update-contact-block-status.js` ถูกสร้างเป็น .js ทั้งที่ CLAUDE.md ของ repo บอก prefer .ts และผมถามว่า "ใครเช็ค GCP alert" ทั้งที่ gcloud ใช้ได้

**How to apply:** ก่อนเขียน brief เปิด CLAUDE.md ของ repo เช็กกฎภาษา/นามสกุล; ก่อนบอกว่า "ตรวจไม่ได้" ลอง gcloud (`gcloud logging metrics list`, `gcloud logging read`, `gcloud monitoring policies list`, project oho-platform) ก่อน. Related: [[reference_gcp_logging_console]].
