// Contains UI elements for the application 

import 'dart:io';
import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

List<String> _fileNames = [];
LinkedHashMap fileContents = LinkedHashMap< String, List<String> >();
int fileIndex = 0;

class DragDropScreen extends StatefulWidget {
  const DragDropScreen({super.key});
  
  @override
  State<DragDropScreen> createState() => _DragDropScreenState();
}

class _DragDropScreenState extends State<DragDropScreen> {

  // Boolean to know when file has entered/exited drop zone
  bool _fileInZone = false;
  Color bgColor = Colors.transparent.withOpacity(0.5);
  String fileName = '';
  late XFile _file;
  List<String> declarationsList = [];
  
  // Read the file line by line and store each line in a List
  List<String> readFile(File file, String fileExtension) {
    
    List<String> declarations = [];
    int line = 0;

    List<String> lines = file.readAsLinesSync();
    lines.forEach((element) {

      // Count the number of lines
      line++;
      
      // Remove all whitespace in line 
      element = element.trim();

      switch(fileExtension) {

        // Support Python
        case ".py": {
          if(element.startsWith("class") || element.startsWith("def")) {
            // If element contains the comment character then move to next iteration
            if(element.startsWith("#")) {
              return;
            }
            declarations.add(line.toString() + ": " + element);
          }
        } break;

        // Support Java
        case ".java": {
          final javaClassRegEx = RegExp(r'(public|protected|private|static|final|abstract)+\s+(class|interface)\s+\w+\s*\{');
          final javaMethodRegEx = RegExp(r'(public|protected|private|static|final|abstract|void|\s) +[\w\<\>\[\],\s]+\s+(\w+) *\([^\)]*\) *(\{?|[^;])');

          // Account for classes being declared with no access modifiers
          if(element.startsWith("class")){
            declarations.add(line.toString() + ": " + element);
          }  

          // Use regex for all general and common cases
          if(javaClassRegEx.hasMatch(element) || javaMethodRegEx.hasMatch(element)) {
            // Account for comments
            if(element.startsWith("//")) {
              return;
            }
            declarations.add(line.toString() + ": " + element);
          }
        } break;

        // Support PHP
        case ".php": {
          if(element.startsWith("class") || element.startsWith("function")) {

            // If element contains the comment character then move to next iteration
              if(element.startsWith("#") || element.startsWith("//")) {
                return;
              }
              declarations.add(line.toString() + ": " + element);
          }
        } break;

        // Support Perl
        case ".pm": {
          if(element.startsWith("package") || element.startsWith("sub")) {
          // If element contains the comment character then move to next iteration
            if(element.startsWith("#")) {
              return;
            }
          declarations.add(line.toString() + ": " + element);
          }
        } break;

        // Support Ruby
        case ".rb": {
          if(element.startsWith("class") || element.contains("Class.new") || element.startsWith("def")) {
          // If element contains the comment character then move to next iteration
          if(element.startsWith("#")) {
            return;
          }
          declarations.add(line.toString() + ": " + element);
          }
        } break;

        // Support GoLang
        case ".go": {
          final goMethodRegex = RegExp(r'/(func)+[\w\]+\s+(\w+) *\([^\)]*\) *(\{?|[^;])');

          // multi line comments: /* */
          if(element.startsWith("//")) {
            return;
          }

          // An alternate to classes in type <name> struct {} 
          if(element.startsWith("type") && element.contains("struct {")) {
            declarations.add(line.toString() + ": " + element);
          }

          // GoLang does not have classes, only functions
          if(goMethodRegex.hasMatch(element)) {
            // Account for comments
            if(element.startsWith("//")) {
              return;
            }
            declarations.add(line.toString() + ": " + element);
          }

        } break;

        // Support C#
        case ".cs": {
        }
      }
    });
    return declarations;
  }

  void showAboutAppDialog(BuildContext context) {
    showMacosAlertDialog(
      context: context, 
      builder: (_) => MacosAlertDialog(
        appIcon:Image(image: AssetImage('assets/images/appLogo.png')), 
        title: Text('methods_list',
          style: MacosTheme.of(context).typography.headline,
          ), 
        message: Text('Drag and drop a source code file, and get a list of classes and methods from that file',
        style: MacosTheme.of(context).typography.headline,
        ), 
        primaryButton: PushButton(
          buttonSize: ButtonSize.large,
          child: Text('Dismiss'),
          onPressed: (() => Navigator.of(context, rootNavigator: true).pop())
        )
        ));
  }

  // TODO: Click on the method and take you to that method in default IDE 

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      sidebar: Sidebar(

        // About (the app) button in bottom left
        bottom: MacosListTile(
          leading: MacosIconButton(
            boxConstraints: BoxConstraints(
              minHeight: 30,
              minWidth: 30,
            ),
            icon: MacosIcon(
              CupertinoIcons.info_circle,
            ),
            // On pressed, show a dialog box that gives info about the app
            onPressed: () => showAboutAppDialog(context),
            ),
          title: Text(''),
          ),
        
        // Sidebar that adds new files as when they are dropped in the app
        builder: ((context, scrollController) {
          return SidebarItems(
            items: [
              for(int i = 0; i < _fileNames.length; i++) 
                SidebarItem(label: Text(_fileNames[i]))
            ], 
            // The value in currentIndex determines which file the screen shows. 
            currentIndex: fileIndex,
            onChanged: (i) => setState(() {
              fileIndex = i;
              Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => 
                FileComponentsFromSidebar(declarationsList: fileContents[_fileNames[i]], fileName: _fileNames[i]), 
                transitionDuration: const Duration(seconds: 0)));
            }) 
          );
        }
      ),
      minWidth: 200,
      ),

      child: CupertinoTabView(
        builder: (context) => MacosScaffold(
          toolBar: ToolBar(
            title: Text('methods_list'),
            titleWidth: 200.0,
            leading: null,
          ),

          children: [

            ContentArea(
              builder: (context, dragDrop) => DropTarget( 

                // When file is dropped in zone
                onDragDone: (details) {
                  setState(() {
                _file = details.files[0];
                String _fileExtension = "." + _file.name.split(".")[1].toString();
                fileName = _file.name;

                // Function call to read the file w the corresponding regex
                declarationsList = readFile(File(_file.path), _fileExtension);
                _fileNames.add(fileName);

                // Add fileName-fileComponents to Hashmap
                if(!(fileContents.containsKey(fileName))) {
                  fileContents[fileName] = declarationsList;
                }

                if (fileContents.containsKey(fileName)) {
                  fileContents.update(fileName, (value) => declarationsList);
                }
              
                // Make the transition to next screen from here
                Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => 
                FileComponentsFromDrop(declarationsList: declarationsList, fileName: fileName,), transitionDuration: Duration(seconds: 0)));
                  });
                },

                // When file has entered drop zone
                onDragEntered: (details) {
                  _fileInZone = true;
                  setState(() {
                    bgColor = Colors.transparent.withOpacity(0);
                  });  // Force update all values of the widget
                },

                // When file has exited drop zone
                onDragExited: (details) {
                  _fileInZone = false;
                  setState(() {
                    bgColor = Colors.transparent.withOpacity(0.5);
                  });  // Force update all values of the widget
                },

                child: Container(
                  color: bgColor,

                  // Set dimensions of drag/drop zone to edges of window
                  height: double.infinity,
                  width: double.infinity, 

                  child: Column(

                    // Align Column's children to the center of the screen
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [

                    // Text that says to drag and drop file
                    Text('Drag and drop code file',
                      style: TextStyle(
                      fontFamily: 'SFProDisplay-Regular',
                      fontSize: 15,
                      color: Color.fromARGB(165, 159, 158, 158),
                      letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  )
                )
              ),
            ), 
          ] 
        ),
      )
    );
  }
}  

// call widget build from this class when file is selected from sidebar
class FileComponentsFromSidebar extends StatefulWidget {

  FileComponentsFromSidebar({Key? key, required this.declarationsList, required this.fileName});

  final List<String> declarationsList;
  final String fileName;
  
  
  @override
  State<FileComponentsFromSidebar> createState() => _FileComponentsFromSidebarState();
}

class _FileComponentsFromSidebarState extends State<FileComponentsFromSidebar> {

  // Controller to scroll or jump to a particular item
  final ItemScrollController itemScrollController = ItemScrollController();

  // Listener to report position of items when the list is scrolled
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  _DragDropScreenState obj = _DragDropScreenState();

  @override
   Widget build(BuildContext context) {
    return MacosWindow(
      sidebar: Sidebar(

        // About (the app) button in bottom left
        bottom: MacosListTile(
          leading: MacosIconButton(
            boxConstraints: BoxConstraints(
              minHeight: 30,
              minWidth: 30,
            ),
            icon: MacosIcon(
              CupertinoIcons.info_circle,
            ),
            // On pressed, show a dialog box that gives info about the app
            onPressed: () => obj.showAboutAppDialog(context),
            ),
          title: Text(''),
          ),
        
        // Sidebar that adds new files as when they are dropped in the app
        builder: ((context, scrollController) {
          return SidebarItems(
            items: [
              for(int i = 0; i < _fileNames.length; i++) 
                SidebarItem(label: Text(_fileNames[i]))
            ], 
            // The value in currentIndex determines which file the screen shows. 
            currentIndex: fileIndex,
            onChanged: (i) => setState(() {
              fileIndex = i;
              Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => 
                FileComponentsFromSidebar(declarationsList: fileContents[_fileNames[i]], fileName: _fileNames[i]), 
                transitionDuration: const Duration(seconds: 0)));
            }) 
          );
        }
      ),
      minWidth: 200,
      ),
    
    
    child: MacosScaffold(
      toolBar: ToolBar(
        title: Text(widget.fileName),
        titleWidth: 200.0,
        // actions: [
        //   const ToolBarSpacer(),
        //   ToolBarIconButton(
        //     label: "About",
        //     icon: const MacosIcon(
        //       CupertinoIcons.info_circle,
        //     ),
        //     onPressed: () => debugPrint("Info button clicked"),
        //     showLabel: true
        //   )
        // ],
      ),
      children: [
        ContentArea(
          builder: (context, dragDrop) => ScrollablePositionedList.builder(
            itemCount: widget.declarationsList.length, 
            itemBuilder: ((context, index) => Text(widget.declarationsList[index]+"\n",
            style: TextStyle(
              fontFamily: 'SFProDisplay-Regular',
              fontSize: 12.5,
              color: const Color(0xffffffff),
              letterSpacing: 1.5,
              ),
            )),
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
          )
        )
      ],
    )
    );
  }
}


// Call the widget build from this class when file is dropped
class FileComponentsFromDrop extends StatefulWidget {
  FileComponentsFromDrop({Key? key, required this.declarationsList, required this.fileName});

  final List<String> declarationsList;
  final String fileName;

  @override
  State<FileComponentsFromDrop> createState() => _FileComponentsFromDropState();
}

class _FileComponentsFromDropState extends State<FileComponentsFromDrop> {

  // Controller to scroll or jump to a particular item
  final ItemScrollController itemScrollController = ItemScrollController();

  // Listener to report position of items when the list is scrolled
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  @override
  Widget build(BuildContext context) {  
    return MacosScaffold(
      toolBar: ToolBar(
        title: Text(widget.fileName),
        titleWidth: 200.0,
      ),
      children: [
        ContentArea(
          builder: (context, dragDrop) => ScrollablePositionedList.builder(
            itemCount: widget.declarationsList.length, 
            itemBuilder: ((context, index) => Text(widget.declarationsList[index]+"\n",
            style: TextStyle(
              fontFamily: 'SFProDisplay-Regular',
              fontSize: 12.5,
              color: const Color(0xffffffff),
              letterSpacing: 1.5,
              ),
            )),
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
          )
        )
      ],
    );
  }
}