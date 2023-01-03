## methodsList

## Table of Contents

<!-- no toc -->
- [About](#about)
- [Usage](#usage)
- [File Description and Dependencies](#file-description-and-dependencies)

## About 

methodsList is an app in development which, in essence, lets you drag and drop a
source code file and the app shows a list of all classes and methods within that source code. Currently the app supports Object Oriented Programming (OOP) languages.

The app is developed fully with Flutter (Dart), with the help of some [external libraries](#file-description-and-dependencies). 

The app is expected to be ready for downloads by February 2023, for MacOS.

![App Demo](https://i.imgur.com/sbb3fwR.gif)

The list of supported languages are:
1. Java
2. Python
3. PHP
4. Perl
5. Ruby
6. GoLang

## Usage

Using the app is simple, the user only needs to drag and drop the source code
inside the window, and the app will return a list of all classes and methods from that source code, and also the lines in which they occur. 

## File Description and Dependencies

| File Name | Description                                 |
|-----------|---------------------------------------------|
| main.dart | Initializes app and calls main_screen.dart |
| main_screen.dart | Creates home screen and calls drag_drop.dart to get a list of all classes and methods in a source code file as soon as it is dropped in the window. <br /> <br /> Dependencies: <br /> 1. macos_ui <br /> 2. desktop_drop <br /> 3. cross_file <br /> 4. scrollable_positioned_list
|drag_drop.dart | Reads through the source code file and pulls out a list of all classes and methods within it, and returns it. 
