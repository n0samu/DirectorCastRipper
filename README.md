# Director Cast Ripper
Director Cast Ripper exports code, assets, and information from Macromedia / Adobe Director files, including standard and compressed (Shockwave) movies and casts. It features both a friendly graphical interface and a command-line interface. Created with Director itself, its functionality is implemented using a variety of built-in functions and third-party Xtras.

## Download
[Download Director Cast Ripper from the Releases page](https://github.com/n0samu/DirectorCastRipper/releases/latest).

Two variants are offered: one built with Director MX 2004 (10) and one built with Director 12. The most important difference is that the Director 12 build supports exporting Shockwave 3D cast members, while the Director 10 build does not. But the Director 10 build may be more compatible with older files, so it is also worth trying.

## Supported Member Types
The following table lists member types that Director Cast Ripper can export, along with file formats that it can save them to.

| Member Types        | File formats   |
| ------------------- | -------------- |
| Lingo code          | LS             |
| Bitmap, Picture     | PNG, BMP       |
| Sound               | WAV            |
| Flash, Vector shape | SWF            |
| Shockwave 3D        | W3D            | 
| Text                | HTML, RTF, TXT | 
| Field               | TXT            |

## Other Features
Director Cast Ripper exports information about movies and cast members into CSV spreadsheets. When adding and removing files, it allows multiselection of files using Shift-click or Ctrl-click. Files can also be added by dragging them into the window. All of its functionality is also accessible via the command line; run `DirectorCastRipper.exe --help` for details. Director Cast Ripper can also integrate with [ProjectorRays](https://github.com/ProjectorRays/ProjectorRays); just download the EXE file and place it in Cast Ripper's `Tools` folder.

Although Cast Ripper runs within the Director Player, it disables scripting for all loaded movies, preventing their code from interfering with the export process. But the Director Player still attempts to load any cast files, linked cast members, and Xtras that each movie depends on. Therefore when exporting it is best to keep movies in their original folders and to copy any required Xtras into Cast Ripper's Xtras folder, otherwise error dialogs may pop up during the export process. If you are using Cast Ripper to process many files and don't know what Xtras they may need, Cast Ripper provides an option to auto-dismiss the error dialogs, preventing the export process from stalling.

## Screenshots

| Options | In progress |
| ------- | ----------- |
| ![options](https://github.com/n0samu/DirectorCastRipper/assets/12380876/40e35490-13ea-444f-be6f-d0b21977efea) | ![inprogress](https://github.com/n0samu/DirectorCastRipper/assets/12380876/1535ffc0-8163-422c-932b-7abb70b1a37a) |

## Credits
Director Cast Ripper uses several third-party Xtras which are listed below.
- Sharp Software's [Sharp Image Export Xtra](http://web.archive.org/web/20041009161548/http://sharp-software.com/products/index.htm#sharpexport) and Valentin's [MP3 Xtra](https://valentin.dasdeck.com/xtras/mp3_xtra/win/) and [swfExport Xtra](https://valentin.dasdeck.com/xtras/swfexport_xtra/win/) provide core file export functionality.
- Kent Kersten's [FileXtra4](http://web.archive.org/web/20040803131759/http://www.kblab.net/xtras/FileXtra4/index.html) handles files and folders, while Magic Modules' [Buddy API](http://mods.com.au/) provides file and folder selection dialogs and other useful functions.
- Valentin's [Console Xtra](https://valentin.dasdeck.com/xtras/console_xtra/win/) and [CommandLine Xtra](https://valentin.dasdeck.com/xtras/commandline_xtra/win/) provide command line functionality.
- Valentin's [Msg Xtra](https://valentin.dasdeck.com/xtras/msg_xtra/win/) provides functionality for the auto-dismiss feature.
- Valentin's [Drop Xtra](https://valentin.dasdeck.com/xtras/drop_xtra/win/) allows drag & drop file and folder selection.
- Tomysshadow's [MoaProperties Xtra](https://github.com/tomysshadow/MoaProperties-Xtra/) provides access to movie metadata that is otherwise inaccessible from Lingo.

Special thanks to [Tomysshadow](https://github.com/tomysshadow/) for his extensive help and guidance throughout the development process, and to [Valentin](https://valentin.dasdeck.com/) for developing so many great and useful Xtras!
