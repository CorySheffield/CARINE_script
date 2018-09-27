@echo off
title CAIRNE 1.1
echo Running CARINE backup. Please remain nearby for required input...
	setlocal enableextensions disabledelayedexpansion

:ask
	rem  Shows detected disks and prompts user for a selection
	call :showDiskTable
	set /p disk="Which disk are we backing up today?: " || goto :processCancelled

	rem Verifies the user entered a valid disk number
	( echo select disk %disk%
	  echo list disk) | diskpart | find "*" >null ||(
	  echo(
	  echo Not a valid response, please look at the table
	  echo(
	  goto :ask
	)

:ask2
	rem Shows detected partitions and propts user for a selection
	call :showPartitionTable
	set /p partition="Which partition has the user's data?: " || goto :processCancelled

	rem Verifies the user entered a valid partition number
	( echo select disk %disk%
	  echo select partition %partition%
	  echo list partition) | diskpart | find "*" >null ||(
	  echo(
	  echo Not a valid response, please look at the table
	  echo(
	  goto :ask2
	)

:script
	rem Creates a temporary file that contains the commands to be run through diskpart
	set "scriptFile=%temp%\%~nx0.%random%%random%%random%.tmp" 
	> "%scriptFile%" (
		echo SELECT DISK %disk%
		echo SELECT PARTITION %partition%
		echo ASSIGN LETTER="S"
	)
	rem Runs the temporary file that was created in the previous step
	diskpart /s "%scriptFile%"

	set /p machineName="What is the Machine name?(Format: DEPT-SERIAL_DATE): "

	rem Asks the user to select P or T telling the process where to save the WIM
	set /p importance="Does this back up need to go into Permanent or Temporary?(P/T): "
	2>NUL CALL :CASE_%importance% 
	IF ERRORLEVEL 1 CALL :DEFAULT_CASE 


	rem Deletes the temp file
	del /q "%scriptFile%"

	echo(
	echo DONE
	echo(

	set /p x="Check your locations, I did my best!!"

	exit /b 0

rem Runs diskpart and shows the user in a table the available disks
:showDiskTable
    echo =====================================================
    echo list disk | diskpart | find " "
    echo =====================================================
    echo(
    goto :eof

rem Runs diskpart and shows the user in a table the available partitions
:showPartitionTable
    echo =====================================================
    (echo select disk %disk%
    echo list partition) | diskpart | find " "
    echo =====================================================
    echo(
    goto :eof

rem Switch statement for selecting the drive to save the image to
:CASE_P
 	net use y: \\cts-tools-syn2.cts.fsu.edu\CTS-User-Backup\Computer_WIMS\PermanentHold
 	Dism /Capture-Image /ImageFile:y:\%machineName%.wim /CaptureDir:S:\ /Name:"%machineName%"
 	GOTO END_CASE

rem Switch statement for selecting the drive to save the image to
:CASE_T
 	net use u: \\cts-tools-syn2.cts.fsu.edu\CTS-User-Backup\Computer_WIMS\Temp
 	Dism /Capture-Image /ImageFile:u:\%machineName%.wim /CaptureDir:S:\ /Name:"%machineName%"
 	GOTO END_CASE

rem Switch statement for selecting the drive to save the image to
:DEFAULT_CASE
  	ECHO Not an acceptable option, please enter either P or T!
  	GOTO END_CASE

rem Switch statement for ending the switch
:END_CASE 
  	VER > NUL 
  	GOTO :EOF

rem Any point invalid input is recieved this closes the program gracefully
:processCancelled
    echo(
    echo PROCESS CANCELLED
    echo(
    exit /b 1

