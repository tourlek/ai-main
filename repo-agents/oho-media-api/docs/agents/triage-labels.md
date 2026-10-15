# Triage Labels

The skills speak in terms of five canonical triage roles. In this repo they are **not ClickUp tags** (the user cannot add tags). Record the role as a comment in the ClickUp task's **Activity**:

```
[triage] <role>
<one-line reason>
```

| Role in mattpocock/skills | Activity comment             | Meaning                                  |
| ------------------------- | ---------------------------- | ---------------------------------------- |
| `needs-triage`            | `[triage] needs-triage`      | Maintainer needs to evaluate this issue  |
| `needs-info`              | `[triage] needs-info`        | Waiting on reporter for more information |
| `ready-for-agent`         | `[triage] ready-for-agent`   | Fully specified, ready for an AFK agent  |
| `ready-for-human`         | `[triage] ready-for-human`   | Requires human implementation            |
| `wontfix`                 | `[triage] wontfix`           | Will not be actioned                     |

The latest `[triage]` comment on the card is the current state. When a skill says "apply label X" or "remove label X", post a new `[triage]` comment instead. If no ClickUp tool is available, write it to `.scratch/<oho-id>/activity.md` for Hub to post.
