# GitLab MR Description Template

Use this as the default pattern. Remove sections that do not apply unless the repository requires every heading.

```markdown
## Summary

- What changed at the product or system behavior level.
- Why this MR exists, especially if the branch title is not enough.

## Changes

- Main implementation changes grouped by behavior or subsystem.
- Mention important files, modules, endpoints, UI states, jobs, schemas, or configs when useful.
- Keep refactors separate from behavior changes when that helps review.

## Testing

- Commands run, manual flows checked, screenshots reviewed, or API requests verified.
- Use `Not run: <reason>` when no verification was run.

## Risk / Impact

- User-facing impact, compatibility concerns, rollout risk, data risk, permissions risk, or performance risk.
- Mention if the change is low risk and why, but do not over-explain routine changes.

## Rollout / Migration

- Required deploy order, feature flags, environment variables, DB migrations, backfills, cache invalidation, or rollback notes.
- Use `None` only when the repo convention expects an explicit answer.

## Reviewer Notes

- Specific areas reviewers should focus on.
- Open questions, tradeoffs, or assumptions that affect review.
```

## Compact Variant

Use this when the MR is small or the repo prefers short descriptions:

```markdown
## Summary

- ...

## Testing

- ...

## Notes

- Risk, rollout, or reviewer focus if relevant.
```

## Thai Variant

Use this when the user wants Thai output:

```markdown
## Summary

- สรุปว่าปรับ behavior หรือ flow อะไร
- เหตุผลที่ต้องมี MR นี้ ถ้าดูจาก title แล้วยังไม่ชัด

## Changes

- รายการแก้ไขหลัก แยกตาม behavior หรือ subsystem
- ระบุ endpoint, component, module, schema, config หรือ state สำคัญเมื่อจำเป็น

## Testing

- command ที่รัน, flow ที่ลอง, screenshot ที่ตรวจ, หรือ API request ที่ verify
- ถ้าไม่ได้รัน ให้เขียน `Not run: <reason>`

## Risk / Impact

- ผลกระทบกับ user, compatibility, permission, data, performance หรือ rollout

## Rollout / Migration

- deploy order, feature flag, env, migration, backfill, cache invalidation หรือ rollback note

## Reviewer Notes

- จุดที่อยากให้ reviewer ช่วยดูเป็นพิเศษ
- assumption หรือ open question ที่มีผลกับการ review
```
