# Director Cast Ripper
Director Cast Ripper exports assets and information from Macromedia / Adobe Director files, including standard and compressed (Shockwave) movies and casts. It features both a friendly graphical interface and a command-line interface. Created with Director itself, its functionality is implemented using a variety of built-in functions and third-party Xtras.

## Download
[Download Director Cast Ripper from the Releases page](https://github.com/n0samu/DirectorCastRipper/releases/latest).

Two variants are offered: one built with Director MX 2004 (10) and one built with Director 12. The most important difference is that the Director 12 build supports exporting Shockwave 3D cast members, while the Director 10 build does not. But the Director 10 build may be more compatible with older files, so it is also worth trying.

## Screenshot
![options](https://github.com/user-attachments/assets/c377f5b9-b69f-4cba-9051-f8d1b9354621)

## Supported Member Types
The following table lists member types that Director Cast Ripper can export, along with file formats that it can save them to.

| Member Types        | File formats   |
| ------------------- | -------------- |
| Bitmap, Picture     | PNG, BMP       |
| Sound               | WAV            |
| Flash, Vector shape | SWF            |
| Shockwave 3D        | W3D            | 
| Text                | HTML, RTF, TXT | 
| Field               | TXT            |

## Other Features
Director Cast Ripper exports information about movies and cast members into CSV spreadsheets. When adding and removing files, it allows multiselection of files using Shift-click or Ctrl-click. Files can also be added by dragging them into the window. All of its functionality is also accessible via the command line; run `DirectorCastRipper.exe --help` for details. Director Cast Ripper can also integrate with [ProjectorRays](https://github.com/ProjectorRays/ProjectorRays); just download the EXE file and place it in Cast Ripper's `Tools` folder.

Although Cast Ripper runs within the Director Player, it disables scripting for all loaded movies, preventing their code from interfering with the export process. But the Director Player still attempts to load any cast files, linked cast members, and Xtras that each movie depends on. Therefore when exporting it is best to keep movies in their original folders and to copy any required Xtras into Cast Ripper's Xtras folder, otherwise error dialogs may pop up during the export process. If you are using Cast Ripper to process many files and don't know what Xtras they may need, Cast Ripper provides an option to auto-dismiss the error dialogs, preventing the export process from stalling.

## Building
If you want to modify and build Director Cast Ripper yourself, here are the steps to do so:
1. Install Director MX 2004 and Director 12. Install the Director 10.1 and 10.1.1 updates.
    - Contact me privately if you need help installing Director.
2. Clone this repository into a new folder.
3. Copy the Xtras folder from the D10 variant of Cast Ripper into the repository folder.
4. Open `DirectorCastRipper.dir` in Director MX 2004 and hit File => Publish.
5. To build the D12 variant, just repeat the above steps using Director 12 and the D12 Xtras folder.
   - Note: When you open DirectorCastRipper.dir in Director 12, it will make you upgrade the project. After publishing with Director 12, you can restore the original DirectorCastRipper.dir file to continue editing in Director MX 2004. Projects cannot be downgraded, so don't edit the file in Director 12 unless you're okay with losing the ability to publish D10 variants.
#### Building with a custom application name
Director applications always have a default name of "Adobe Projector" or "Macromedia Projector". This application name is shown in some places such as Task Manager or the "Open With..." menu (if you associate files with the application). To change the application name and other metadata of executables published with Director, you'll need to edit Director's Projec32.skl file using Visual Studio:
1. Install Visual Studio. (NOT Visual Studio Code)
2. Make a copy of the `Projec32.skl` file from Director's main installation folder. Change the file extension to `.exe` so Visual Studio can recognize it.
3. Open the .exe file in Visual Studio. Expand the Version subtree and change the FileDescription to `Director Cast Ripper` (or any name you like).
4. Rename the file back to `Projec32.skl` and place it in Director's installation folder. From now on, when you publish projectors from that copy of Director, they will have the custom name you set.

## Credits
Director Cast Ripper uses several third-party Xtras which are listed below.
- Sharp Software's [Sharp Image Export Xtra](http://web.archive.org/web/20041009161548/http://sharp-software.com/products/index.htm#sharpexport) and Valentin's [MP3 Xtra](https://valentin.dasdeck.com/xtras/mp3_xtra/win/) and [swfExport Xtra](https://valentin.dasdeck.com/xtras/swfexport_xtra/win/) provide core file export functionality.
- Kent Kersten's [FileXtra4](http://web.archive.org/web/20040803131759/http://www.kblab.net/xtras/FileXtra4/index.html) handles files and folders, while Magic Modules' [Buddy API](http://mods.com.au/) provides file and folder selection dialogs and other useful functions.
- Valentin's [Console Xtra](https://valentin.dasdeck.com/xtras/console_xtra/win/) and [CommandLine Xtra](https://valentin.dasdeck.com/xtras/commandline_xtra/win/) provide command line functionality.
- Valentin's [Msg Xtra](https://valentin.dasdeck.com/xtras/msg_xtra/win/) provides functionality for the auto-dismiss feature.
- Valentin's [Drop Xtra](https://valentin.dasdeck.com/xtras/drop_xtra/win/) allows drag & drop file and folder selection.
- Tomysshadow's [MoaProperties Xtra](https://github.com/tomysshadow/MoaProperties-Xtra/) provides access to movie metadata that is otherwise inaccessible from Lingo.

Special thanks to [Tomysshadow](https://github.com/tomysshadow/) for his extensive help and guidance throughout the development process, and to [Valentin](https://valentin.dasdeck.com/) for developing so many great and useful Xtras!
