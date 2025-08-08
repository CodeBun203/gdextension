# Tag! Royale

Welcome to **Tag! Royale**, a multiplayer battle royale tag game built with the Godot Engine. This project features a custom networking backend implemented in C++ using GDExtension for high performance.

## About The Game

Tag! Royale is a fast-paced, last-man-standing tag game. Connect with friends or other players online, run, dodge, and use your wits to avoid being "it". The arena shrinks over time, forcing players closer together for a final, frantic showdown!

## Features

* **Multiplayer Action:** Engage in a chaotic game of tag with multiple players online.
* **Custom Networking:** The networking logic is not built with Godot's high-level networking, but is instead hardcoded using C++ and GDExtension for maximum control and performance.
* **GDExtension Integration:** Demonstrates how to bind powerful C++ libraries to a Godot project.

## Project Structure

This repository contains the core source code for the game and its C++ extension.

* `tag!-royale/`: This folder contains all the Godot project files, scenes, assets, and GDScript code.
* `src/`: This folder contains all the C++ source files for the custom networking GDExtension.
* `SConstruct`: The build configuration file required by SCons to compile the C++ GDExtension.

## Getting Started

This repository **does not** include the full GDExtension wrapper code. To get the project up and running, you need to set up the GDExtension environment first.

1.  **Clone the Godot C++ Template:**
    Start by cloning the official Godot C++ template repository. This contains the necessary boilerplate to link a C++ library with Godot.
    ```bash
    git clone [https://github.com/godotengine/godot-cpp-template.git](https://github.com/godotengine/godot-cpp-template.git)
    ```

2.  **Add Project Files:**
    Copy the `tag!-royale/` folder, the `src/` folder, and the `SConstruct` file from this repository into the root of the `godot-cpp-template` directory you just cloned.

3.  **Compile the Extension:**
    Navigate into the `godot-cpp-template` directory and run the SCons build command. This will compile the C++ code in the `src` folder.
    ```bash
    scons
    ```
    *Note: You may need to specify your target platform (e.g., `scons platform=windows`). Please refer to the official Godot documentation for compiling GDExtensions.*

4.  **Run the Game:**
    Once the extension is successfully compiled, you can open the Godot project by importing the `project.godot` file located inside the `tag!-royale/` folder.

## Resources

If you are new to GDExtension, this introductory video from the official Godot Engine channel is a great place to start:

* **Introduction to GDExtension:** [https://youtu.be/4R0uoBJ5XSk?si=goxgIjFKyKQH1Qo_](https://youtu.be/4R0uoBJ5XSk?si=goxgIjFKyKQH1Qo_)

---

Thank you for checking out Tag! Royale. Happy coding!
