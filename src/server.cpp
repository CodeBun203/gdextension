//--------------------------------------------------------------------------------
// AUTHOR: Hayden NeSmith
//
// DESCRIPTION: 
//      This is file serves as the server process used in the game Tag! Royale.
//      It receives connections from client and communicates with them via
//      UDP packets. This file implents the Server class defined in Server.h.
//      It uses GDExtension to allow the Server class to be used in Godot V4.3. 
//--------------------------------------------------------------------------------

#include "server.h"

using namespace godot;

Server* Server::instance = nullptr; // Needed for signalHandler

//--------------------------------------------------------------------------------
// Defines equality between 2 sockaddr_in structs.

bool Server::compare_sockaddr(const sockaddr_in& lhs, const sockaddr_in& rhs) {
    return lhs.sin_family == rhs.sin_family &&
           lhs.sin_addr.s_addr == rhs.sin_addr.s_addr &&
           lhs.sin_port == rhs.sin_port;
}

//--------------------------------------------------------------------------------
// Sends the "Start Game" message to all connected clients.

void Server::startGame() {
    std::string message = "Start Game";
    for (const auto& client : clients) {
        sendto(serverSocket, message.c_str(), message.size(), 0, (struct sockaddr*)&client, sizeof(client));
    }
}

//--------------------------------------------------------------------------------
// This method determines what methods can be used directly in Godot.

void Server::_bind_methods() {
    ClassDB::bind_method(D_METHOD("start", "port"), &Server::start);
    ClassDB::bind_method(D_METHOD("stop"), &Server::stop);
    ClassDB::bind_method(D_METHOD("getClientCount"), &Server::getClientCount);
    ClassDB::bind_method(D_METHOD("setStart", "value"), &Server::setStart);
    ClassDB::bind_method(D_METHOD("getClientPosition", "client"), &Server::getClientPosition);
    ClassDB::bind_method(D_METHOD("getClientRotation", "client"), &Server::getClientRotation);
    ClassDB::bind_method(D_METHOD("setClientPosition", "client"), &Server::setClientPosition);
    ClassDB::bind_method(D_METHOD("setClientRotation", "client"), &Server::setClientRotation);
    ClassDB::bind_method(D_METHOD("setIt", "it"), &Server::setIt);
    ClassDB::bind_method(D_METHOD("setExploded", "exploded"), &Server::setExploded);
    ClassDB::bind_method(D_METHOD("setWinner", "winner"), &Server::setWinner);
    ClassDB::bind_method(D_METHOD("setWindmillRotation"), &Server::setWindmillRotation);
}

//--------------------------------------------------------------------------------
// Signal Handler for errors or early program termination

void Server::signalHandler(int sigNum) {
    std::cout << "Interrupt signal (" << sigNum << ") received.\n";
    if (instance) {
        #ifdef _WIN32
            closesocket(instance->serverSocket);
            WSACleanup();
        #else
            close(instance->serverSocket);
        #endif
    }
    exit(sigNum);
}

//--------------------------------------------------------------------------------
// Default constructor

Server::Server() : clientCount(0), running(false) {
    instance = this;
    clientCount = 1;
    it = -1;
    exploded = -1;
    winner = -1;
    started = 0;
    windmillRotation = 0;
    started = false;
    clientId = 0;
    #ifdef _WIN32
        WSADATA wsaData;
        WSAStartup(MAKEWORD(2, 2), &wsaData);
    #endif
}

//--------------------------------------------------------------------------------
// Destructor

Server::~Server() {
    stop();
    #ifdef _WIN32
        closesocket(serverSocket);
        WSACleanup();
    #else
        close(serverSocket);
    #endif
}

//--------------------------------------------------------------------------------
// Sets up socket and begins accepting clients.

void Server::start(int port) {
    running = true;
    serverSocket = socket(AF_INET, SOCK_DGRAM, 0);

    sockaddr_in serverAddr;
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    serverAddr.sin_port = htons(port);

    bind(serverSocket, (struct sockaddr*)&serverAddr, sizeof(serverAddr));

    serverThread = std::thread(&Server::handleClient, this);
}

//--------------------------------------------------------------------------------
// Stops Server process

void Server::stop() {
    running = false;
    if (serverThread.joinable()) {
        serverThread.join();
    }
}

//--------------------------------------------------------------------------------
// Listens for client messages and responds accordingly. Accepts GET or POST
// requests.

void Server::handleClient() {
    char buffer[1024];
    while (running) {
        sockaddr_in clientAddr;
        socklen_t clientAddrLen = sizeof(clientAddr);
        memset(buffer, 0, sizeof(buffer));
        int len = recvfrom(serverSocket, buffer, sizeof(buffer), 0, (struct sockaddr*)&clientAddr, &clientAddrLen);

        if (len > 0) {
            buffer[len] = '\0';

            // Receiving and returning messages
            String message = String(buffer);
            String rtrnMsg;

            // Booleans 
            bool didWin;
            bool didStart;

            // Split message array
            PackedStringArray msgArr = message.split(" ");

            // Temp vector
            Vector3 tempVec;

            // Handle GET requests
            if (msgArr[0] == "GET") 
            {
                if (msgArr[1] == "Rotation") {
                    tempVec = getClientRotation(msgArr[2].to_int());
                    rtrnMsg = "Rotation " + msgArr[2] + " " + String::num(tempVec.x) + " " + String::num(tempVec.y) + " " + String::num(tempVec.z);
                    sendto(serverSocket, rtrnMsg.utf8().get_data(), rtrnMsg.length(), 0, (struct sockaddr*)&clientAddr, clientAddrLen);
                }
                if (msgArr[1] == "Position") {
                    tempVec = getClientPosition(msgArr[2].to_int());
                    rtrnMsg = "Position " + msgArr[2] + " " + String::num(tempVec.x) + " " + String::num(tempVec.y) + " " + String::num(tempVec.z);
                    sendto(serverSocket, rtrnMsg.utf8().get_data(), rtrnMsg.length(), 0, (struct sockaddr*)&clientAddr, clientAddrLen);
                }
                if (msgArr[1] == "ClientCount") {
                    rtrnMsg = "ClientCount " + String::num(getClientCount());
                    sendto(serverSocket, rtrnMsg.utf8().get_data(), rtrnMsg.length(), 0, (struct sockaddr*)&clientAddr, clientAddrLen);
                }
                if (msgArr[1] == "Winner") {
                    rtrnMsg = "Winner " + String::num(getWinner());
                    sendto(serverSocket, rtrnMsg.utf8().get_data(), rtrnMsg.length(), 0, (struct sockaddr*)&clientAddr, clientAddrLen);
                }
                if (msgArr[1] == "Exploded") {
                    rtrnMsg = "Exploded " + String::num(getExploded());
                    sendto(serverSocket, rtrnMsg.utf8().get_data(), rtrnMsg.length(), 0, (struct sockaddr*)&clientAddr, clientAddrLen);
                }
                if (msgArr[1] == "Start") {
                    rtrnMsg = "Start " + String::num(getStart());
                    sendto(serverSocket, rtrnMsg.utf8().get_data(), rtrnMsg.length(), 0, (struct sockaddr*)&clientAddr, clientAddrLen);
                }
                if (msgArr[1] == "It") {
                    rtrnMsg = "It " + String::num(getIt());
                    sendto(serverSocket, rtrnMsg.utf8().get_data(), rtrnMsg.length(), 0, (struct sockaddr*)&clientAddr, clientAddrLen);
                }
                if (msgArr[1] == "Windmill") {
                    rtrnMsg = "Windmill " + String::num(getWindmillRotation());
                    sendto(serverSocket, rtrnMsg.utf8().get_data(), rtrnMsg.length(), 0, (struct sockaddr*)&clientAddr, clientAddrLen);
                }
            }

            // Handle POST requests
            if (msgArr[0] == "POST") {
                if (msgArr[1] == "Rotation") {
                    if (msgArr[2].to_int() != clientId) {
                        setClientRotation(msgArr[2].to_int(), msgArr[3].to_float(), msgArr[4].to_float(), msgArr[5].to_float());
                    }
                }
                if (msgArr[1] == "Position") {
                    if (msgArr[2].to_int() != clientId) {
                        setClientPosition(msgArr[2].to_int(), msgArr[3].to_float(), msgArr[4].to_float(), msgArr[5].to_float());
                    }
                }
                if (msgArr[1] == "Register") {
                    std::cout << "Client Connected" << std::endl;
                    clients.push_back(clientAddr);
                    rtrnMsg = "Register " + String::num(getClientCount());
                    sendto(serverSocket, rtrnMsg.utf8().get_data(), rtrnMsg.length(), 0, (struct sockaddr*)&clientAddr, clientAddrLen);
                    setClientCount(getClientCount() + 1);
                }
                if (msgArr[1] == "Disconnect") {
                    std::cout << "Client Disconnected" << std::endl;
                    auto it = std::find_if(clients.begin(), clients.end(), [&](const sockaddr_in& client) {
                        return compare_sockaddr(clientAddr, client);
                    });
                    if (it != clients.end()) {
                        clients.erase(it);
                        setClientCount(getClientCount() - 1);
                    }
                }
            }
        }
    }
}

// Getters

Vector3 Server::getClientRotation(int client) const {
    std::shared_lock<std::shared_mutex> lock(mtex);
    return clientRot[client];
}

Vector3 Server::getClientPosition(int client) const {
    std::shared_lock<std::shared_mutex> lock(mtex);
    return clientPos[client];
}

int Server::getWinner() const {
    return winner.load();
}

int Server::getIt() const {
    return it.load();
}

int Server::getClientCount() const {
    return clientCount.load();
}

int Server::getStart() const {
    return started.load();
}

int Server::getExploded() const {
    return exploded.load();
}

float Server::getWindmillRotation() const {
    return windmillRotation;
}

// Setters

void Server::setClientRotation(int client, float x, float y, float z) {
    std::shared_lock<std::shared_mutex> lock(mtex);
    clientRot[client] = Vector3(x, y, z);
}

void Server::setClientPosition(int client, float x, float y, float z) {
    std::shared_lock<std::shared_mutex> lock(mtex);
    clientPos[client] = Vector3(x, y, z);
}

void Server::setWinner(int client) {
    winner = client;
}

void Server::setIt(int client) {
    it = client;
}

void Server::setClientCount(int count) {
    clientCount = count;
}

void Server::setStart(int val) {
    started = val;
    if (val == 1) {
        clientPos.resize(clientCount);
        clientRot.resize(clientCount);
    }
}

void Server::setExploded(int client) {
    exploded = client;
}

void Server::setWindmillRotation(float rot) {
    windmillRotation = rot;
}