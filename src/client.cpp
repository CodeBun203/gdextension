//--------------------------------------------------------------------------------
// AUTHOR: Hayden NeSmith
//
// DESCRIPTION: 
//      This is file serves as the client process used in the game Tag! Royale.
//      It sets up a connection with a server and communicates with it via
//      UDP packets. This file implents the Client class defined in Client.h.
//      It uses GDExtension to allow the Client class to be used in Godot V4.3. 
//--------------------------------------------------------------------------------

#include "client.h"

using namespace godot;

Client* Client::instance = nullptr; // Needed for signalHandler

//--------------------------------------------------------------------------------
// This function determines what methods can be used directly in Godot.

void Client::_bind_methods() {
    ClassDB::bind_method(D_METHOD("connect_to_server", "server_address", "port"), &Client::connect_to_server);
    ClassDB::bind_method(D_METHOD("send_message", "message"), &Client::send_message);
    ClassDB::bind_method(D_METHOD("initialize", "server_address", "port"), &Client::initialize);
    ClassDB::bind_method(D_METHOD("disconnect"), &Client::disconnect);
    ClassDB::bind_method(D_METHOD("setLabel", "clientLabel"), &Client::setLabel);
    ClassDB::bind_method(D_METHOD("getStartGame"), &Client::getStartGame);
    ClassDB::bind_method(D_METHOD("getClientCount"), &Client::getClientCount);
    ClassDB::bind_method(D_METHOD("getClientId"), &Client::getClientId);
    ClassDB::bind_method(D_METHOD("getIt"), &Client::getIt);
    ClassDB::bind_method(D_METHOD("getWinner"), &Client::getWinner);
    ClassDB::bind_method(D_METHOD("getExploded"), &Client::getExploded);
    ClassDB::bind_method(D_METHOD("getClientRotation", "client"), &Client::getClientRotation);
    ClassDB::bind_method(D_METHOD("getClientPosition", "client"), &Client::getClientPosition);
    ClassDB::bind_method(D_METHOD("getWindmillRotation"), &Client::getWindmillRotation);
}

//--------------------------------------------------------------------------------
// Signal Handler for errors or early program termination.

void Client::signalHandler(int sigNum) {
    std::cout << "Interrupt signal (" << sigNum << ") received.\n";
    if (instance) {
        instance->disconnect();
    }
    
    exit(sigNum);
}

//--------------------------------------------------------------------------------
// Default Constructor

Client::Client() {
    startGame = 0;
    it = -1;
    exploded = -1;
    winner = -1;
    clientId = -1;
    clientCount = 1;
    windmillRotation = 0;
    instance = this;
    #ifdef _WIN32
        WSADATA wsaData;
        WSAStartup(MAKEWORD(2, 2), &wsaData);
    #endif
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);
}

//--------------------------------------------------------------------------------
// Destructor

Client::~Client() {
    disconnect();
}

//--------------------------------------------------------------------------------
// Function to set up client socket.

void Client::initialize(const String& server_address, int port) {
    clientSocket = socket(AF_INET, SOCK_DGRAM, 0);

    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);

    const char* server_addr = server_address.utf8().get_data();
    inet_pton(AF_INET, server_addr, &serverAddr.sin_addr);
}

//--------------------------------------------------------------------------------
// Function to connect to server.

void Client::connect_to_server(const String& server_address, int port) {
    initialize(server_address, port);
    send_message("POST Register");
    
    // Seperate thread for listening for Server responses
    std::thread(&Client::receive_messages, this).detach();
}

//--------------------------------------------------------------------------------
// Function to disconnect from server.

void Client::disconnect() {
    std::cout << "Disconnecting From Server" << std::endl;
    send_message("POST Disconnect");
    #ifdef _WIN32
        closesocket(clientSocket);
        WSACleanup();
    #else
        close(clientSocket);
    #endif
}

//--------------------------------------------------------------------------------
// Function to send messages to server.

void Client::send_message(const String& message) {
    sendto(clientSocket, message.utf8().get_data(), message.length(), 0, (struct sockaddr*)&serverAddr, sizeof(serverAddr));
}

//--------------------------------------------------------------------------------
// Function to receive responses from server.

void Client::receive_messages() {
    char buffer[1024];
    while (true) {
        memset(buffer, 0, sizeof(buffer));
        int len = recvfrom(clientSocket, buffer, sizeof(buffer), 0, nullptr, nullptr);
        if (len > 0) {
            buffer[len] = '\0';

            // Received message
            String message = String(buffer);
            
            // Split message
            PackedStringArray msgArr = message.split(" ");
            
            if (msgArr[0] == "Register") {
                std::cout << "Accepted by server" << std::endl;
                setClientId(msgArr[1].to_int());
            }
            if (msgArr[0] == "Position") {
                if (msgArr[1].to_int() != getClientId()) {
                    setClientPosition(msgArr[1].to_int(), msgArr[2].to_float(), msgArr[3].to_float(), msgArr[4].to_float());
                }
            }
            if (msgArr[0] == "Rotation") {
                if (msgArr[1].to_int() != getClientId()) {
                    setClientRotation(msgArr[1].to_int(), msgArr[2].to_float(), msgArr[3].to_float(), msgArr[4].to_float());
                }
            }
            if (msgArr[0] == "ClientCount") {
                setClientCount(msgArr[1].to_int());
                if (client_waiting_label) {
                    client_waiting_label->call_deferred("set_text", "Lobby " + String::num(getClientCount()));
                }
            }
            if (msgArr[0] == "Winner") {
                setWinner(msgArr[1].to_int());
            }
            if (msgArr[0] == "Exploded") {
                setExploded(msgArr[1].to_int());
            }
            if (msgArr[0] == "Start") {
                setStartGame(msgArr[1].to_int());
            }
            if (msgArr[0] == "It") {
                setIt(msgArr[1].to_int());
            }
            if (msgArr[0] == "Windmill") {
                setWindmillRotation(msgArr[1].to_float());
            }
        }
    }
}

//--------------------------------------------------------------------------------
// Getters

int Client::getWinner() const {
    return winner.load();
}

int Client::getClientId() const {
    return clientId.load();
}

Vector3 Client::getClientPosition(int client) const {
    std::shared_lock<std::shared_mutex> lock(mtex);
    return clientPos[client];
}

Vector3 Client::getClientRotation(int client) const {
    std::shared_lock<std::shared_mutex> lock(mtex);
    return clientRot[client];
}

int Client::getExploded() const {
    return exploded.load();
}

int Client::getClientCount() const {
    return clientCount.load();
}

int Client::getIt() const {
    return it.load();
}

int Client::getStartGame() const {
    return startGame;
}

float Client::getWindmillRotation() const {
    return windmillRotation;
}

//--------------------------------------------------------------------------------
// Setters

void Client::setWinner(int client) {
    winner = client;
}

void Client::setClientId(int id) {
    clientId = id;
}

void Client::setClientPosition(int client, float x, float y, float z) {
    std::shared_lock<std::shared_mutex> lock(mtex);
    clientPos[client] = Vector3(x, y, z);
}

void Client::setClientRotation(int client, float x, float y, float z) {
    std::shared_lock<std::shared_mutex> lock(mtex);
    clientRot[client] = Vector3(x, y, z);
}

void Client::setExploded(int client) {
    exploded = client;
}

void Client::setClientCount(int count) {
    clientCount = count;
}

void Client::setIt(int client) {
    it = client;
}

void Client::setStartGame(int val) {
    startGame = val;
    if (val == 1) {
        clientPos.resize(clientCount);
        clientRot.resize(clientCount);
    }
}

void Client::setWindmillRotation(float rot) {
    windmillRotation = rot;
}

void Client::setLabel(Label* clientLabel) {
    client_waiting_label = clientLabel;
}
