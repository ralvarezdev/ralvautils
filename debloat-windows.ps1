irm christitus.com/win | iex

# Disable Windows Recall telemetry tracking
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f

# Disable Copilot system hooks
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f

# Stop the background AI Fabric service from starting automatically
sc.config WSAIFabricSvc start= disabled

# Run a deployment cleanup to safely compress and purge these dead system layers
dism /online /cleanup-image /startcomponentcleanup /resetbase