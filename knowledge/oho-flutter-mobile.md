# Repo: oho-flutter-mobile

@{{AI_MAIN}}/knowledge/_ohochat-shared.md

## Stack

Flutter mobile app.

## Notes

- Shares the OHO domain (Smartchat, JERA) with the web app but has its own UI contracts — don't port web behavior assumptions blindly.

## OTA releases

A green CI build is not a delivered patch. Shorebird promotes to a track — read the publish
job trace for the track/promotion step and confirm in the delivery console (or the app's own
telemetry) before attributing an incident to a build. Patches can also ship manually outside
CI, so CI history alone neither convicts nor clears a release.
