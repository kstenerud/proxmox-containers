Windows VM Tips
===============

Key Management Services (KMS)
-----------------------------

KMS Keys: https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys

Example (Windows 10 Pro, activated on server with DNS name "kms")

```powershell
slmgr /upk
slmgr /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX
slmgr /skms kms
slmgr /ato
```

Tweaks
------

## WinUtil

Github: https://github.com/ChrisTitusTech/winutil

Run in Powershell as Administrator:

```powershell
irm https://christitus.com/win | iex
```

### Running WinUtil as an admin script:

* Make a shortcut of `your-winutil-script.ps1`
* Right-click the shortcut
* Select `Properties`
* Select the `Shortcut` tab
* Prefix the `Target` field with `powershell.exe -ExecutionPolicy Bypass -f`
* Click `Advanced`
* Select `Run as administrator`

## O&O ShutUp 10++

Current config: [ooshutup10.cfg](ooshutup10.cfg)
