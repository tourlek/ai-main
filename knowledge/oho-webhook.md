# Repo: oho-webhook

@{{AI_MAIN}}/knowledge/_ohochat-shared.md

## Stack

Node.js webhook ingestion service.

## Notes

- Ingestion path is contract-bound to external senders — validate payload-shape assumptions against real captured payloads before changing parsing.

## Replay

This pipeline acks 200 even when processing fails, so HTTP success is not a result. Measure
terminal state in the datastore before and after, and replay 1-2 events and verify that state
before firing a whole batch — a "success 1,429/1,429" CLI report once meant 26 recovered.
