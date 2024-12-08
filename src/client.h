//--------------------------------------------------------------------------------
// AUTHOR: Hayden NeSmith
//
// DESCRIPTION: 
//      This is file defines the Client class to be implemented by client.cpp.
//      It is to be used in conjunction with GDExtension for the game Tag!
//      Royale made in Godot 4.3.
//--------------------------------------------------------------------------------

#pragma once

#include <iostream>
#include <csignal>
#include <cstring>
#include <thread>
#include <atomic>
#include <shared_mutex>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/classes/label.hpp>

#ifdef _WIN32
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #pragma comment(lib, "Ws2_32.lib")
#else
    #include <netinet/in.h>
    #include <sys/socket.h>
    #include <arpa/inet.h>
    #include <unistd.h>
#endif

using namespace godot;

//--------------------------------------------------------------------------------
// Client Class

class Client : public Node {

//--------------------------------------------------------------------------------
// Private Methods and Variables

    // Register class as Node in Godot
    GDCLASS(Client, Node);

    // Socket Data
    int clientSocket;
    int PORT = 2395;
    sockaddr_in serverAddr;

    // Atomics
    std::atomic<int> clientId;
    std::atomic<int> clientCount;
    std::atomic<int> it;
    std::atomic<int> exploded;
    std::atomic<int> winner;
    std::atomic<int> startGame;

    // Mutex Lock
    mutable std::shared_mutex mtex;

    // For Signal Handler
    static Client* instance;

    // Other Variables
    Label* client_waiting_label; 
    float windmillRotation;

    // Position and Rotation Vectors
    std::vector<Vector3> clientRot;
    std::vector<Vector3> clientPos;

    // Private initialize function
    void initialize(const String& server_address, int port);

//--------------------------------------------------------------------------------
// Protected Methods and Variables

protected:

    // Needed to directly use methods in Godot
    static void _bind_methods();

//--------------------------------------------------------------------------------
// Public Methods and Variables

public:

    // Constructor
    Client();

    // Desctructor
    ~Client();

    // Server Communication Methods
    void connect_to_server(const String& server_address, int port);
    void disconnect();
    void send_message(const String& message);
    void receive_messages();

    // Getters
    int getIt() const;
    int getStartGame() const;
    int getExploded() const;
    int getWinner() const;
    int getClientId() const;
    int getClientCount() const;
    Vector3 getClientPosition(int client) const;
    Vector3 getClientRotation(int client) const;
    float getWindmillRotation() const;

    // Setters
    void setLabel(Label* clientLabel);
    void setIt(int client);
    void setStartGame(int val);
    void setExploded(int id);
    void setWinner(int id);
    void setClientId(int id);
    void setClientPosition(int client, float x, float y, float z);
    void setClientRotation(int client, float x, float y, float z);
    void setClientCount(int count);
    void setWindmillRotation(float rot);

    // Signal Handler
    static void signalHandler(int sigNum);
};