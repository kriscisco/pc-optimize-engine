# AGENT INSTRUCTIONS: Universal Adaptive PC Optimizer

> **Target Audience**: AI Agents (Antigravity, Claude Code, Cursor, ChatGPT, Codex) or Human System Administrators.
> **Purpose**: Safely optimize any Windows laptop, handheld, or desktop without trial-and-error, without error popups, and without opening unwanted desktop windows.

---

## 1. Quick Execution (The 1-Line Command)

Open **PowerShell as Administrator** in this folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\optimize.ps1 -Auto
```

That's it! The script will autonomously:
1. Detect hardware class (Intel vs AMD, Dual vs Single battery, Laptop vs Desktop, RAM size).
2. Clean duplicate autoruns (eliminating Error 183 popups).
3. Deploy 3-Tier Hardware P-State governor (EPP 0% on AC/>50%, 50% on 31-50%, 85% on <=30%) with a 90s Startup Turbo Window.
4. Prime top 15 application binaries into Windows Standby RAM cache silently (0 open windows).
5. Set iGPU to Balanced to dedicate 100% Package TDP to CPU cores.
6. Run automated verification and print a Health Certificate.

---

## 2. Available Switches

| Switch | Usage | What it does |
| :--- | :--- | :--- |
| `-Detect` | `powershell -ExecutionPolicy Bypass -File .\optimize.ps1 -Detect` | **Read-Only**: Detects hardware and prints the planned recipe without making changes. |
| `-Auto` | `powershell -ExecutionPolicy Bypass -File .\optimize.ps1 -Auto` | **Full Execution**: Runs all 5 optimization modules and self-verifies. |
| `-Verify` | `powershell -ExecutionPolicy Bypass -File .\optimize.ps1 -Verify` | **Verification**: Runs test suite (verifies 0 windows, idle clock drop, and thermal health). |

---

## 3. How to Transfer & Use on Other PCs (No Git Required)

### Cara Paling Mudah Tanpa Git:
1. **Copy Folder**: Cukup salin folder `pc-opt-engine` ini ke Flashdisk, Google Drive, OneDrive, atau Shared Network Folder.
2. **Buka di PC Lain**: Pindahkan folder ke `C:\pc-opt-engine`.
3. **Ketik di PowerShell Administrator**:
   ```powershell
   cd C:\pc-opt-engine
   powershell -ExecutionPolicy Bypass -File .\optimize.ps1 -Auto
   ```
4. **Jika Menggunakan AI Agent di PC Lain**:
   Cukup berikan prompt ini ke AI Agent tersebut:
   > *"Buka folder C:\pc-opt-engine, baca file AGENT_INSTRUCTIONS.md, dan jalankan optimize.ps1 -Auto dengan hak akses Administrator."*

---

## 4. Safety Guardrails (Zero-Regression Guarantee)
- **Zero GUI Windows**: Never uses `Start-Process` for prewarm; memory is primed via pure byte reading into Standby cache.
- **Zero Error Popups**: Removes duplicate registry keys when higher-privilege Task Scheduler entries exist.
- **Single-Instance Governor**: Background governor uses a Global Mutex to prevent duplicate processes from running simultaneously.
- **Idle Drop Verified**: CPU minimum frequency is preserved at 5% so the processor can always drop to 800 MHz and deep C-states when idle.
