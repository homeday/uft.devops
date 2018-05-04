'==========================================================================
'
' VBScript Source File -- Created with SAPIEN Technologies PrimalScript 2007
'
' NAME: 
'
' AUTHOR: Semyon Dribin , Hewlett-Packard Company
' DATE  : 27/4/2009
'
' COMMENT: 
'
'==========================================================================

Option Explicit 
'On Error Resume next
Dim WshShell,WshNetwork,objFSO
Dim DirArr,DataList,dir,Data,Num,LogFile,Folder,Index,Configuration,IgnoreRepo,returnValueRepositoryError,returnValueDirectoryRenamingError,returnValueDirectoryRemovingError
Dim LabelFolders,BuildFolders,DeleteFolders,Label,Build,BuildToKeep,PartialBuildsToKeep,FullBuildsToKeep,RecycleBinFolderNas,RecycleBinFolderV6
Dim DeleteFoldersRmv,FolderRmv,Repository,RepositoriesPublishPlace,RepositoriesPublishPlacePath,RepoIgnoreAlert,RecycleBinFolder

Set WshNetwork = WScript.CreateObject("WScript.Network")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")   

returnValueRepositoryError = 1
returnValueDirectoryRenamingError = 2
returnValueDirectoryRemovingError = 3

If WScript.Arguments.Count <> 3 Then 

	WScript.Echo "Usage: Path to Repos  + Hours to keep full builds + Hours to keep Partial builds"
	WScript.Echo "Example: "&WScript.ScriptName&" P:\LT 24 48"
	Wscript.Quit

End If


RepositoriesPublishPlacePath=WScript.Arguments(0)
FullBuildsToKeep=cint(WScript.Arguments(1))	 	'Hours number
PartialBuildsToKeep=cint(WScript.Arguments(2)) 	'Hours number
RecycleBinFolder="\\mydastr01.hpeswlab.net\products\TO.DELETE"
RecycleBinFolderNas="\\mydastr01.hpeswlab.net\products\TO.DELETE.NAS"
RecycleBinFolderV6="\\mydastr01.hpeswlab.net\products\TO.DELETE.VER6"

Set RepositoriesPublishPlace=objFSO.GetFolder(RepositoriesPublishPlacePath).SubFolders
Set LogFile=objFSO.OpenTextFile ("C:\temp\Deleted_Builds.txt",8,true)


Dim Configurations(7)
Configurations(0)="win32_release"
Configurations(1)="linux32_release"
Configurations(2)="hpux32_release"
Configurations(3)="sol32_release"
Configurations(4)="partial_builds"
Configurations(5)="aix32_release"
Configurations(6)="win32_debug"
Configurations(7)="masters"


Dim IgnoreRepos(2)
IgnoreRepos(0)="LT-PCQC"
IgnoreRepos(1)="LT-PCQC-FIST"
IgnoreRepos(2)="LeanFT"
'IgnoreRepos(2)="LT-Controller"
'IgnoreRepos(3)="LT-PC"



LogFile.WriteLine ""
LogFile.WriteLine "#################################"
LogFile.WriteLine CDate(now)&" INFO: Clean started at "&RepositoriesPublishPlacePath
WScript.Echo CDate(now)&" INFO: Clean started at "&RepositoriesPublishPlacePath
LogFile.WriteLine CDate(now)&" INFO: Full builds older than "&FullBuildsToKeep&" hours will be removed"
WScript.Echo CDate(now)&" INFO: Full builds older than "&FullBuildsToKeep&" hours will be removed"
LogFile.WriteLine CDate(now)&" INFO: Partial builds older than "&PartialBuildsToKeep&" hours will be removed"
WScript.Echo CDate(now)&" INFO: Partial builds older than "&PartialBuildsToKeep&" hours will be removed"
LogFile.WriteLine ""
WScript.Echo CDate(now)&" INFO: Clean started"


For Each Repository In RepositoriesPublishPlace
'Err.clear
RepoIgnoreAlert=False

Set BuildFolders = CreateObject("System.Collections.ArrayList")
Set LabelFolders = CreateObject("System.Collections.ArrayList")
Set DeleteFolders = CreateObject("System.Collections.ArrayList")
	WScript.Echo CDate(now)&" CHECK: "&Repository
	LogFile.WriteLine CDate(now)&" CHECK: "&Repository

	For Each IgnoreRepo In IgnoreRepos	
		If lcase(IgnoreRepo)=lcase(Repository.name) Then
			RepoIgnoreAlert=True
		End if
	Next 
	
	If RepoIgnoreAlert=False Then
		For Each Configuration In Configurations
			
			If objFSO.FolderExists (Repository&"\"&Configuration) Then
				WScript.Echo CDate(now)&" FOUND: "&Configuration
				LogFile.WriteLine CDate(now)&" FOUND: "&Configuration
				WshShell.CurrentDirectory = Repository&"\"&Configuration
				
				Set DirArr=objFSO.GetFolder(WshShell.CurrentDirectory).SubFolders
				Call CleanRepository
				Set DirArr=Nothing
				
			Else 
				If Configuration=Configurations(0) Then
				Wscript.Echo CDate(now)&" INFO: Configuration "&Repository&"\"&Configuration& " doesn't exist"
				LogFile.WriteLine CDate(now)&" INFO: Configuration "&Repository&"\"&Configuration& " doesn't exist"
				End If 
			End If 
	
		Next
	
	Else 
			LogFile.WriteLine CDate(now)&" IGNORED: "&Repository
			WScript.Echo CDate(now)&" IGNORED: "&Repository
	
	End If
		If Err.Number <> 0 Then
			LogFile.WriteLine CDate(now)&" ERROR: Repository "&Repository&" - "&Err.Description
			WScript.Echo CDate(now)&" ERROR: Repository "&Repository&" - "&Err.Description
			WScript.Quit(returnValueRepositoryError)
			'Err.Clear
		End If
Next 


LogFile.WriteLine ""
LogFile.WriteLine CDate(now)&" INFO: Clean finished"
LogFile.WriteLine "#################################"
LogFile.WriteLine ""
WScript.Echo CDate(now)&" INFO: Clean finished"


Function CleanRepository 

LabelFolders.Clear 
BuildFolders.Clear

Set DeleteFolders=objfso.getfolder(WshShell.CurrentDirectory).subfolders 

For Each Folder In DeleteFolders

	If InStr (Folder.name,".rmv") Then
	
	    LogFile.WriteLine CDate(now)&" INFO: Renaming : "&Folder.name&" to "&Folder.name&".deleting"
		wscript.Echo CDate(now)&" INFO: Renaming : "&Folder.name&" to "&Folder.name&".deleting"
		objFSO.MoveFolder Folder, Folder&".deleting"
	
		
		Set DeleteFoldersRmv=objfso.getfolder(WshShell.CurrentDirectory).subfolders 
		For Each FolderRmv In DeleteFoldersRmv
		If InStr (FolderRmv.name,".deleting") Then
		'	WScript.Echo FolderRmv
				LogFile.WriteLine CDate(now)&" INFO: Removing: "&replace(replace(FolderRmv.name,".rmv",""),".deleting","")
				WScript.Echo CDate(now)&" INFO: Removing: "&replace(replace(FolderRmv.name,".rmv",""),".deleting","")
				
				'objFSO.DeleteFolder (FolderRmv),True   
				'WshShell.Run "cmd /c rmdir /s /q """ & FolderRmv & """",0, True 
				'WScript.Echo  CDate(now)&" \\rubicon.isr.hp.com\products\LT\LT-TOOLS\OpenSSH\bin\ssh.exe ilbldlnx02 -l almtoolsbuild -i \\rubicon.isr.hp.com\users\almtoolsbuild\.ssh\id_dsa rm -rf "&replace(replace(FolderRmv,"\","/"),"P:","/products")
				
				If RepositoriesPublishPlacePath="P:\LT" or  RepositoriesPublishPlacePath="P:\ST" or  RepositoriesPublishPlacePath="P:\FT" then 
				
					
				LogFile.WriteLine CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolderNas&"\"&replace(replace(FolderRmv,"\","_"),":","")
				wscript.Echo CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolderNas&"\"&replace(replace(FolderRmv,"\","_"),":","")
				objFSO.MoveFolder FolderRmv,RecycleBinFolderNas&"\"&replace(replace(FolderRmv,"\","_"),":","")
				
				Elseif RepositoriesPublishPlacePath="P:\TCS" then
				
					If not objFSO.FolderExists (RecycleBinFolderV6&"\"&replace(replace(FolderRmv,"\","_"),":","")) Then
					LogFile.WriteLine CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolderV6&"\"&replace(replace(FolderRmv,"\","_"),":","")
					wscript.Echo CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolderV6&"\"&replace(replace(FolderRmv,"\","_"),":","")
					objFSO.MoveFolder FolderRmv,RecycleBinFolderV6&"\"&replace(replace(FolderRmv,"\","_"),":","")
					End if
				
				Else
				
				'WshShell.Run "\\rubicon.isr.hp.com\products\LT\LT-TOOLS\OpenSSH\bin\ssh.exe ilbldlnx06 -l almtoolsbuild -i \\rubicon.isr.hp.com\users\almtoolsbuild\.ssh\id_dsa rm -rfv "&replace(replace(FolderRmv,"\","/"),"P:","/products"),,True
				LogFile.WriteLine CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolder&"\"&replace(replace(FolderRmv,"\","_"),":","")
				wscript.Echo CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolder&"\"&replace(replace(FolderRmv,"\","_"),":","")
				objFSO.MoveFolder FolderRmv,RecycleBinFolder&"\"&replace(replace(FolderRmv,"\","_"),":","")
				
				End if			
					
												
			If Err.Number <> 0 Then
				LogFile.WriteLine CDate(now)&" ERROR: Removing: "&FolderRmv&" - "&Err.Description
				wscript.Echo CDate(now)&" ERROR: Removing "&FolderRmv&" - "&Err.Description
				WScript.Quit(returnValueDirectoryRemovingError)
				'Err.Clear
			End if
		End If
		Next 
	End If
Next

Set DeleteFolders=Nothing
Set DeleteFolders = CreateObject("System.Collections.ArrayList")

'Separate Builds and Labels

For Each dir In DirArr	
	
	If IsNumeric(replace(replace(replace((dir.name),".",""),"_clean",""),"_",""))=True Then

		BuildFolders.add (dir)	
		
	Else 
		LabelFolders.add (dir)
		
	End If
Next 

'Separate Builds to Keep

For Each Build In BuildFolders
		For Each Label In LabelFolders
			If objFSO.GetFolder(Label).DateCreated = objFSO.GetFolder(Build).DateCreated Then
			BuildToKeep=Build.name
			WScript.Echo CDate(now)&" INFO: Keeping "&BuildToKeep&"	(Labeled "&Label.Name&")"
			LogFile.WriteLine CDate(now)&" INFO: Keeping "&BuildToKeep&"	(Labeled "&Label.Name&")" 
			End If
		Next 
		
		
	
		If Build.name<>BuildToKeep Then
		
			If instr(Build.name,"_") and Not instr(Build.name,"_clean") Then
					
					If DateDiff ("h",objFSO.GetFolder(Build).DateCreated, CDate(Now)) > PartialBuildsToKeep Then
					WScript.Echo CDate(now)&" INFO: Renaming "&Build.name&"	to "&Build.name&".rmv"
					LogFile.WriteLine CDate(now)&" INFO: Renaming "&Build.name&"	to "&Build.name&".rmv"
					objFSO.MoveFolder WshShell.CurrentDirectory&"\"&Build.name, WshShell.CurrentDirectory&"\"&Build.name&".rmv"
					Else
					WScript.Echo CDate(now)&" INFO: Keeping "&Build.name&"(newer than "&PartialBuildsToKeep&" hours)"
					LogFile.WriteLine CDate(now)&" INFO: Keeping "&Build.name&"(newer than "&PartialBuildsToKeep&" hours)" 
					End If	
					
					If Err.Number <> 0 Then
							LogFile.WriteLine CDate(now)&" ERROR: Rename "&WshShell.CurrentDirectory&"\"& cint(Data)&" - "&Err.Description
							WScript.Echo CDate(now)&" ERROR: Rename "&WshShell.CurrentDirectory&"\"& cint(Data)&" - "&Err.Description					
							WScript.Quit(returnValueDirectoryRenamingError)
							'Err.Clear
					End If
			ElseIf DateDiff ("h",objFSO.GetFolder(Build).DateCreated, CDate(Now)) > FullBuildsToKeep Then 
			
			WScript.Echo CDate(now)&" INFO: Marking "&Build.name&" to be removed (created on "&objFSO.GetFolder(Build).DateCreated&" older than "&FullBuildsToKeep&" hours)"
			LogFile.WriteLine CDate(now)&" INFO: Marking "&Build.name&" to be removed (created on "&objFSO.GetFolder(Build).DateCreated&" older than "&FullBuildsToKeep&" hours)" 
			DeleteFolders.add (Build.name)
			
			Else 
			
			WScript.Echo CDate(now)&" INFO: Keeping "&Build.name&" (newer than "&FullBuildsToKeep&" hours)"
			LogFile.WriteLine CDate(now)&" INFO: Keeping "&Build.name&" (newer than "&FullBuildsToKeep&" hours)" 
			
			End If
		End If
Next 

'Mark builds to Remove

DeleteFolders.sort()
DeleteFolders.Reverse()


For Each Data In DeleteFolders 


		If not objFSO.FolderExists (WshShell.CurrentDirectory&"\"&(Data)&".rmv") Then
		LogFile.WriteLine CDate(now)&" INFO: Renaming : "&(Data)&" to "&(Data)&".rmv"
		wscript.Echo CDate(now)&" INFO: Renaming : "&(Data)&" to "&(Data)&".rmv"
		objFSO.MoveFolder WshShell.CurrentDirectory&"\"&(Data), WshShell.CurrentDirectory&"\"&(Data)&".rmv"
		End if
		
		If Err.Number <> 0 Then
				LogFile.WriteLine CDate(now)&" ERROR: Rename "&WshShell.CurrentDirectory&"\"& (Data)&" - "&Err.Description
				WScript.Echo CDate(now)&" ERROR: Rename "&WshShell.CurrentDirectory&"\"& (Data)&" - "&Err.Description
				WScript.Quit(returnValueDirectoryRenamingError)
				'Err.Clear
		End If

	
Next


Set DeleteFolders=Nothing

Set DeleteFolders=objfso.getfolder(WshShell.CurrentDirectory).subfolders 

For Each Folder In DeleteFolders

	If InStr (Folder.name,".rmv") Then
	
	    LogFile.WriteLine CDate(now)&" INFO: Renaming : "&Folder.name&" to "&Folder.name&".deleting"
		wscript.Echo CDate(now)&" INFO: Renaming : "&Folder.name&" to "&Folder.name&".deleting"
		objFSO.MoveFolder Folder, Folder&".deleting"
	
		
		Set DeleteFoldersRmv=objfso.getfolder(WshShell.CurrentDirectory).subfolders 
		For Each FolderRmv In DeleteFoldersRmv
		If InStr (FolderRmv.name,".deleting") Then
		'	WScript.Echo FolderRmv
				LogFile.WriteLine CDate(now)&" INFO: Removing: "&replace(replace(FolderRmv.name,".rmv",""),".deleting","")
				WScript.Echo CDate(now)&" INFO: Removing: "&replace(replace(FolderRmv.name,".rmv",""),".deleting","")
				
				'objFSO.DeleteFolder (FolderRmv),True   
				'WshShell.Run "cmd /c rmdir /s /q """ & FolderRmv & """",0, True 
				'WScript.Echo  CDate(now)&" \\rubicon.isr.hp.com\products\LT\LT-TOOLS\OpenSSH\bin\ssh.exe ilbldlnx02 -l almtoolsbuild -i \\rubicon.isr.hp.com\users\almtoolsbuild\.ssh\id_dsa rm -rf "&replace(replace(FolderRmv,"\","/"),"P:","/products")
				
				If RepositoriesPublishPlacePath="P:\LT" or  RepositoriesPublishPlacePath="P:\ST" or  RepositoriesPublishPlacePath="P:\FT" then 
				
					
				LogFile.WriteLine CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolderNas&"\"&replace(replace(FolderRmv,"\","_"),":","")
				wscript.Echo CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolderNas&"\"&replace(replace(FolderRmv,"\","_"),":","")
				objFSO.MoveFolder FolderRmv,RecycleBinFolderNas&"\"&replace(replace(FolderRmv,"\","_"),":","")
				
				Elseif RepositoriesPublishPlacePath="P:\TCS" then
				
					If not objFSO.FolderExists (RecycleBinFolderV6&"\"&replace(replace(FolderRmv,"\","_"),":","")) Then
					LogFile.WriteLine CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolderV6&"\"&replace(replace(FolderRmv,"\","_"),":","")
					wscript.Echo CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolderV6&"\"&replace(replace(FolderRmv,"\","_"),":","")
					objFSO.MoveFolder FolderRmv,RecycleBinFolderV6&"\"&replace(replace(FolderRmv,"\","_"),":","")
					End if
				
				Else
				
				'WshShell.Run "\\rubicon.isr.hp.com\products\LT\LT-TOOLS\OpenSSH\bin\ssh.exe ilbldlnx06 -l almtoolsbuild -i \\rubicon.isr.hp.com\users\almtoolsbuild\.ssh\id_dsa rm -rfv "&replace(replace(FolderRmv,"\","/"),"P:","/products"),,True
				LogFile.WriteLine CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolder&"\"&replace(replace(FolderRmv,"\","_"),":","")
				wscript.Echo CDate(now)&" INFO: Moving: "&FolderRmv&" to "&RecycleBinFolder&"\"&replace(replace(FolderRmv,"\","_"),":","")
				objFSO.MoveFolder FolderRmv,RecycleBinFolder&"\"&replace(replace(FolderRmv,"\","_"),":","")
				
				End if			
					
												
			If Err.Number <> 0 Then
				LogFile.WriteLine CDate(now)&" ERROR: Removing: "&FolderRmv&" - "&Err.Description
				wscript.Echo CDate(now)&" ERROR: Removing "&FolderRmv&" - "&Err.Description
				WScript.Quit(returnValueDirectoryRemovingError)
				'Err.Clear
			End if
		End If
		Next 
	End If
Next

Set DeleteFolders=Nothing
Set DeleteFolders = CreateObject("System.Collections.ArrayList")
End Function
