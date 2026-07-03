---
name: reference_release_process
description: "ขั้นตอน deploy release สำหรับทุก repo ใน ohochat — version bump, branch strategy, UAT/staging, production via git-flow"
metadata: 
  node_type: memory
  type: reference
  originSessionId: c489e094-1d57-4b40-9b99-a2864b311928
---

## Version Bump (git working directory ต้องสะอาดก่อน)

```bash
npm version patch -m "chore: bump version to %s"  # 1.0.0 → 1.0.1
npm version minor -m "chore: bump version to %s"  # 1.11.0 → 1.12.0
npm version major -m "chore: bump version to %s"  # 1.0.0 → 2.0.0
```

## Release Branch

1. Pull `master` และ `develop`
2. สร้าง branch `release/x.x.x` จาก `master`
3. bump version ตามข้างบน
4. merge `develop` (หรือ branch รวม tickets ของ sprint) เข้า `release/x.x.x`

## UAT / Staging

- สร้าง environment branch จาก `release/x.x.x`:
  - ทั่วไป: `uat`, `staging-1`, `staging-2`, ..., `staging-4`
  - Core API (pre-production): `uat/vx.x.x`, `staging-1/vx.x.x`, ...
- push environment branch → trigger CI/CD pipeline
- ถ้ามีของตามหลัง ให้ merge เข้า `release/x.x.x` แล้ว re-deploy

## Production (git-flow finish)

1. กด finish current (git-flow)
2. **uncheck** `delete branch`
3. ใส่ tag = `vx.x.x`
4. Push tag → trigger CI/CD pipeline
5. Push `master` และ `develop`

**Why:** เป็น process หลักของทุก repo ใน ohochat  
**How to apply:** ใช้เป็น reference ทุกครั้งที่ถามหรือช่วย deploy release
