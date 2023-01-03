import 'dart:io';

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

      }
    });
    return declarations;
  }
