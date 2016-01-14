@echo off
rem #=======================================================================#
rem #																		#
rem #	G�n�rateur d'archive Forge - LaunchMyCraft							#
rem #																		#
rem #	Description	: G�n�ration d'une archive Minecraft avec				#
rem #				  Forge pour l'int�gration avec le launcher				#
rem #				  LaunchMyCraft											#
rem #																		#
rem #	Auteur 		: Natinusala / Apokalysme - forum.launchmycraft.fr		#
rem #																		#
rem #	Version		: 2.5													#
rem #																		#
rem #=======================================================================#

rem ----- Cr�ation d'un dossier dans %appdata% pour loguer m�me dans le cas
rem ----- d'une ex�cution depuis l'archive ZIP
if not exist "%appdata%\LaunchMyCraftGenerator\nul" mkdir "%appdata%\LaunchMyCraftGenerator"
set GEN_LOGFILE="%appdata%\LaunchMyCraftGenerator\generator.log"

rem ----- D�but du script
echo == Pr�parateur d'archives Forge pour LaunchMyCraft - Version 2.4 ==
echo == Pr�parateur d'archives Forge pour LaunchMyCraft - Version 2.4 == > %GEN_LOGFILE%

rem ----- V�rification du contenu du dossier courant
echo Dossier courant : %CD%  >> %GEN_LOGFILE%
if not exist generated_files\nul goto ERRORCWD
if not exist output\nul goto ERRORCWD
if not exist tools\nul goto NOTOOLS
if not exist installer.jar goto NOINSTALLER

rem ----- R�cup�ration des versions de Minecraft et de Forge
echo Entrez la version de Minecraft correspondant � Forge : | tools\tee\tee.exe -a %GEN_LOGFILE%
set /p MinecraftName=
echo Valeur entr�e pour Minecraft : %MinecraftName% >> %GEN_LOGFILE%
echo Entrez la version de Forge � installer : | tools\tee\tee.exe -a %GEN_LOGFILE%
set /p ForgeName=
echo Valeur entr�e pour Forge : %ForgeName% >> %GEN_LOGFILE%

rem ----- Nettoyage en cas d'�ni�me ex�cution du programme
echo == Nettoyage des dossiers... | tools\tee\tee.exe -a %GEN_LOGFILE%
cd /d .\generated_files
if %errorlevel% NEQ 0 goto ERRORCWD
for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q || del "%%i" /s/q)
cd..
cd /d .\output
if %errorlevel% NEQ 0 goto ERRORCWD
for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q || del "%%i" /s/q)
cd..

rem ----- Pr�paration des dossiers utilis�s pour la g�n�ration
echo == Pr�paration des dossiers... | tools\tee\tee.exe -a %GEN_LOGFILE%
mkdir ".\output"
mkdir ".\generated_files\mods"
echo Mettez vos mods ici ! >".\generated_files\mods\README.txt"
mkdir ".\generated_files\libraries"
mkdir ".\generated_files\versions\%MinecraftName%\"

rem ----- R�cup�ration dans le dossier d'installation Officiel de Minecraft
echo == Copie du fichier des profils... | tools\tee\tee.exe -a %GEN_LOGFILE%
xcopy /y "%appdata%\.minecraft\launcher_profiles.json" ".\generated_files\*" /Q
echo Copie de Minecraft %MinecraftName%... | tools\tee\tee.exe -a %GEN_LOGFILE%
xcopy /Q "%appdata%\.minecraft\versions\%MinecraftName%" ".\generated_files\versions\%MinecraftName%"

rem ----- Lancement de l'installation de Forge
echo == Ex�cution de l'installateur... | tools\tee\tee.exe -a %GEN_LOGFILE%
echo Installez le client dans le dossier donn� | tools\tee\tee.exe -a %GEN_LOGFILE%
echo Dossier � choisir : | tools\tee\tee.exe -a %GEN_LOGFILE%
echo %CD%\generated_files | tools\tee\tee.exe -a %GEN_LOGFILE%
pause
java -jar installer.jar

rem ----- R�cup�ration du log de Forge dans le log g�n�ral du programme
type installer.jar.log >> %GEN_LOGFILE%
del installer.jar.log /Q

rem ----- Traitement avant cr�ation du ZIP
echo == Finalisation du dossier... | tools\tee\tee.exe -a %GEN_LOGFILE%
for /f "delims=. tokens=1" %%a IN ("%ForgeName%") DO set FMAJOR=%%a
for /f "delims=. tokens=2" %%b IN ("%ForgeName%") DO set fminor=%%b
for /f "delims=. tokens=3" %%c IN ("%ForgeName%") DO set fpatch=%%c

echo Version detectee %FMAJOR%-%fminor%-%fpatch% | tools\tee\tee.exe -a %GEN_LOGFILE%

if %FMAJOR% EQU 10 if %fminor% GEQ 13 if %fpatch% GEQ 3 goto P10133
if %FMAJOR% GEQ 11 goto P11XX


rem ----- Cas des versions 10.13.2 et plus anciennes
echo == Forge Version 10.13.2 et plus anciennes | tools\tee\tee.exe -a %GEN_LOGFILE%
del ".\generated_files\versions\%MinecraftName%\%MinecraftName%.json" /Q
copy ".\generated_files\versions\%MinecraftName%-Forge%ForgeName%\%MinecraftName%-Forge%ForgeName%.json" ".\generated_files\versions\%MinecraftName%"
rename ".\generated_files\versions\%MinecraftName%\%MinecraftName%-Forge%ForgeName%.json" "%MinecraftName%.json"
rmdir /s /q ".\generated_files\versions\%MinecraftName%-Forge%ForgeName%"
del ".\generated_files\launcher_profiles.json" /Q
goto ZIP


:P10133
rem ----- Cas des versions 10.13.3 et sup�rieures
echo == Forge Version 10.13.3 et sup�rieures | tools\tee\tee.exe -a %GEN_LOGFILE%
goto CASE1


:P11XX
rem ----- Cas des versions 11.XX et sup�rieures
echo == Forge Version 11.XX et sup�rieures | tools\tee\tee.exe -a %GEN_LOGFILE%
goto CASE1


:CASE1
rem ----- Cas de traitement classique
mkdir ".\generated_files\versions\release"
tools\sed\sed.exe -e "s/id\".*/id\":\ \"release\",/" -i ".\generated_files\versions\%MinecraftName%\%MinecraftName%.json"
move ".\generated_files\versions\%MinecraftName%\%MinecraftName%.json" ".\generated_files\versions\release"
rename ".\generated_files\versions\release\%MinecraftName%.json" "release.json"

rem -- Recuperation du nom du dossier de Forge
for /f "delims=" %%a in ('dir /B ".\generated_files\versions\*-Forge*"') do @set FORGEDIR=%%a
echo ForgeDir : %FORGEDIR% >> %GEN_LOGFILE%
rem -- Recuperation du nom du fichier JSON de Forge
for /f "delims=" %%b in ('dir /B ".\generated_files\versions\%FORGEDIR%\"') do @set FORGEJSON=%%b
echo ForgeJson : %FORGEJSON% >> %GEN_LOGFILE%

copy ".\generated_files\versions\%FORGEDIR%\%FORGEJSON%" ".\generated_files\versions\%MinecraftName%\%MinecraftName%.json"
tools\sed\sed.exe -e "s/id\".*/id\":\ \"%MinecraftName%\",/" -i ".\generated_files\versions\%MinecraftName%\%MinecraftName%.json"
tools\sed\sed.exe -e "s/inheritsFrom.*/inheritsFrom\":\ \"release\",/" -i ".\generated_files\versions\%MinecraftName%\%MinecraftName%.json"
rmdir /s /q ".\generated_files\versions\%FORGEDIR%
del ".\generated_files\launcher_profiles.json" /Q
goto ZIP


:ZIP
echo == Pr�paration de l'archive... | tools\tee\tee.exe -a %GEN_LOGFILE%
cscript //nologo zip.vbs  "%CD%\generated_files\versions" "%CD%\output\%MinecraftName%-forge-%ForgeName%.zip"
cscript //nologo zip.vbs  "%CD%\generated_files\libraries" "%CD%\output\%MinecraftName%-forge-%ForgeName%.zip"
cscript //nologo zip.vbs  "%CD%\generated_files\mods" "%CD%\output\%MinecraftName%-forge-%ForgeName%.zip"

del sed* /Q
echo == Termin� - %MinecraftName%-forge-%ForgeName%.zip cr�� ! | tools\tee\tee.exe -a %GEN_LOGFILE%
goto END

:NOINSTALLER
echo ERREUR - Le fichier installer.jar n'est pas pr�sent dans le dossier >> %GEN_LOGFILE%
goto END

:NOTOOLS
echo ERREUR - Les ne sont pas pr�sents dans le dossier >> %GEN_LOGFILE%
goto END

:ERRORCWD
echo ERREUR - Le programme n'est pas d�compress� ou le lancement n'est pas fait depuis le bon endroit >> %GEN_LOGFILE%
goto END

:END
pause
