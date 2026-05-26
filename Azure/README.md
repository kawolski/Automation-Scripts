!! First login to azure cli or run azLogin.bat before running azure related scripts (Considering az cli is installed on your system).

# azLogin
Provides azure login and subscription selection screen.

# EncryptionAtHost
1. Surfs the selected azure account for vms
2. Lists all VMs with their EncryptionAtHost status
3. Provides option to enable EAH for your selected VM list.

# Ghost DB Detector
### uses powershell 7
1. Surfs the selected azure account for SQL Servers
2. Lists all SQL DBs that are unused for past 30 days
3. Creates csv output file
4. Parallel server execution: Faster for multiple servers
