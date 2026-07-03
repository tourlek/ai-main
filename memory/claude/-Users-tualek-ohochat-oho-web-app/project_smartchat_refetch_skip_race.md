---
name: Smartchat refetch skip race (fixed)
description: Retry refetch in useSmartchatRoomList.ts used to send non-zero $skip and return empty data — fixed by passing explicit skip override through fetchContactList
type: project
originSessionId: b2ad092b-8d69-4fd4-9a21-10ae2c5f5320
---
Bug in `pages/business/_biz_id/smartchat/composables/useSmartchatRoomList.ts` on branch `fix/tk-4241-chat-list-search-sorting` (fixed 2026-05-15): the retry path in `onContactProfileSaved` sometimes sent `$skip=N` (e.g. 2) instead of `$skip=0`, so the just-edited contact never appeared.

**Root cause race**: wrapper called `resetChatListState()` (skip=0, is_no_more_data=false) then `await nextTick()`. Flipping `is_no_more_data` re-shows the loader in `components/Smartchat/RoomList.vue`, IntersectionObserver fires `roomsScroll` (300ms debounce) → `loadMoreRooms` commits `setContactListSkip` (which sets `state.contact_list.skip = data.length`). When the wrapper's `fetchContactList` later built params via `getContactParams`, it read the now-mutated skip from store.

**Why:** `setContactListSkip` mutation is intentionally `skip = data.length` for "load next page" pagination semantics. The race only matters because the refetch path was sharing the same store field for its "first page" intent.

**How to apply:** Fix is in place — `FetchOptions.skip?: number` flows through `loadSearchContactList` → `fetchContactList`, which overrides `params.$skip` after `getContactParams`. The wrapper passes `skip: 0` explicitly. If extending more refetch paths in this file, prefer passing `skip` explicitly rather than relying on store state, to avoid the same race.
