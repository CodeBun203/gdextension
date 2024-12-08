//--------------------------------------------------------------------------------
// AUTHOR: Hayden NeSmith
//
// DESCRIPTION: 
//      This is file defines the Server class to be implemented by server.cpp.
//      It is to be used in conjunction with GDExtension for the game Tag!
//      Royale made in Godot 4.3.
//--------------------------------------------------------------------------------

#pragma once

#include <iostream>
#include <csignal>
#include <cstring>
#include <vector>
#include <thread>
#include <atomic>
#include <shared_mutex>
#include <algorithm>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>

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
// Server Class

class Server : public Node {

    // Register Class as Node in Godot
    GDCLASS(Server, Node);
    
    // Client Communication Data
    int serverSocket;
    int PORT = 2395;
    std::vector<sockaddr_in> clients;

    // Atomics
    std::atomic<int> clientId;
    std::atomic<int> clientCount;
    std::atomic<int> it;
    std::atomic<int> winner;
    std::atomic<int> exploded;
    std::atomic<int> started;
    std::atomic<bool> running;
    
    // Position and Rotation Vectors
    std::vector<Vector3> clientRot;
    std::vector<Vector3> clientPos;

    // Thread to handle multiple clients
    std::thread serverThread;

    // Mutex Lock
    mutable std::shared_mutex mtex;

    // For Signal Handler
    static Server* instance;

    // Other Variable
    float windmillRotation;

    // Private Method to handle Clients
    void handleClient();

//--------------------------------------------------------------------------------
// Protected Methods and Variables

protected:

    // Needed to use methods directly in Godot
    static void _bind_methods();

//--------------------------------------------------------------------------------
// Public Methods and Variables

public:

    // Constructor
    Server();

    // Destructor
    ~Server();

    // Socket Management Methods
    void start(int port);
    void stop();
    bool compare_sockaddr(const sockaddr_in& lhs, const sockaddr_in& rhs);

    // Getters
    int getClientCount() const;
    int getIt() const;
    int getStart() const;
    int getWinner() const;
    int getExploded() const;
    Vector3 getClientPosition(int client) const;
    Vector3 getClientRotation(int client) const;
    float getWindmillRotation() const;

    // Setters
    void setClientCount(int count);
    void setIt(int Client);
    void setStart(int val);
    void setWinner(int id);
    void setExploded(int client);
    void setClientPosition(int client, float x, float y, float z);
    void setClientRotation(int client, float x, float y, float z);
    void setWindmillRotation(float rot);

    // Signal Handler
    static void signalHandler(int sigNum);

    // Used to start game
    void startGame();
};