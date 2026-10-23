# Protocol provenance

BudsBridge's Swift implementation was informed by protocol research in
[GalaxyBudsClient](https://github.com/timschneeb/GalaxyBudsClient), copyright Tim
Schneeberger and contributors, licensed under GNU GPL version 3.

Inspected upstream snapshot: `754b6fdfb1c151b022cece775c8aaad4eb185afa`.
The multipoint change was introduced in commit
[`93286175c6e5ebccee81517c8f89c7b7072b5c32`](https://github.com/timschneeb/GalaxyBudsClient/commit/93286175c6e5ebccee81517c8f89c7b7072b5c32).

Key references at the inspected snapshot:

- `GalaxyBudsClient/Platform/MultipointPatcher.cs`
- `GalaxyBudsClient/Message/SppAlternativeMessage.cs`
- `GalaxyBudsClient/Message/SppMessage.cs`
- `GalaxyBudsClient/Message/SppMessageEnums.cs`
- `GalaxyBudsClient/Model/Constants.cs`

This project is distributed under GPL-3.0; see LICENSE. It is an independent,
unofficial prototype and is not affiliated with Samsung.

Samsung's installed Android APK was inspected locally with
[REA](https://github.com/morluto/rea) 6.7.0 and the hash-verified
JADX headless MCP engine 0.7.1. The APK and its decompiled source are not part of
this distribution. Development tools are not bundled in the app.
