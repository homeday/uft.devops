REM Script for Disk 1
echo select disk 1 > disk_script.txt
echo attributes disk clear readonly >> disk_script.txt
echo online disk noerr >> disk_script.txt
echo convert mbr >> disk_script.txt
echo create partition primary >> disk_script.txt
echo format quick fs=ntfs label='New_Volume' >> disk_script.txt
echo assign letter='D' >> disk_script.txt

REM Script for Disk 2
echo select disk 2 >> disk_script.txt
echo attributes disk clear readonly >> disk_script.txt
echo online disk noerr >> disk_script.txt
echo convert mbr >> disk_script.txt
echo create partition primary >> disk_script.txt
echo format quick fs=ntfs label='New_Volume' >> disk_script.txt
echo assign letter='E' >> disk_script.txt

REM Run diskpart
"C:\Windows\System32\diskpart.exe" /s disk_script.txt > output.txt
