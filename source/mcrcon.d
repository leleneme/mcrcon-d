module mcrcon;

import std.socket;
import std.bitmanip : littleEndianToNative, nativeToLittleEndian;
import std.exception : enforce;
import std.datetime : dur;
import std.typecons : Nullable;
import std.sumtype : SumType;

struct Packet
{
    int ident;
    int kind;
    ubyte[] payload;
}

class ConnectionClosedException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

class MCRconClient
{
private:
    TcpSocket socket;
    bool connected = false;
    bool loggedIn = false;

public:
    this(string host, ushort port)
    {
        socket = new TcpSocket();

        socket.setOption(SocketOptionLevel.SOCKET,
            SocketOption.RCVTIMEO, dur!"seconds"(10));

        socket.connect(new InternetAddress(host, port));
        connected = true;
    }

    MCRconClient opCall()
    {
        return this;
    }

    bool login(string password)
    {
        if (loggedIn)
            return true;
        if (!connected)
            return false;

        sendPacket(Packet(0, 3, cast(ubyte[]) password.dup));
        auto packet = receivePacket();
        loggedIn = packet.ident == 0;

        return loggedIn;
    }

    string sendCommand(string text)
    {
        if (!socket.isAlive() || !connected)
        {
            throw new Exception("Socket is not alive");
        }

        sendPacket(Packet(0, 2, cast(ubyte[]) dup(text)));
        sendPacket(Packet(1, 0, cast(ubyte[]) ""));

        ubyte[] response;
        while (true)
        {
            auto packet = receivePacket();
            if (packet.ident != 0)
                break;
            response ~= packet.payload;
        }

        auto decoded = cast(string) idup(response);
        return decoded;
    }

    void close()
    {
        if (connected && socket.isAlive())
        {
            socket.close();
            connected = false;
            loggedIn = false;
        }
    }

    ~this()
    {
        close();
    }

private:
    bool tryDecodePacket(ubyte[] data, ref Packet packet, ref size_t neededBytes, ref ubyte[] remaining)
    {
        if (data.length < 14)
        {
            neededBytes = 14;
            return false;
        }

        int length = littleEndianToNative!int(data[0 .. 4]) + 4;
        if (data.length < length)
        {
            neededBytes = length;
            return false;
        }

        int ident = littleEndianToNative!int(data[4 .. 8]);
        int kind = littleEndianToNative!int(data[8 .. 12]);
        auto payload = data[12 .. length - 2];
        auto padding = data[length - 2 .. length];

        enforce(padding == [0, 0], "Invalid packet padding");

        packet = Packet(ident, kind, payload);
        remaining = data[length .. $];
        return true;
    }

    ubyte[] encodePacket(Packet packet)
    {
        auto data = nativeToLittleEndian(packet.ident)
            ~ nativeToLittleEndian(
                packet.kind)
            ~ packet.payload
            ~ cast(ubyte[])[0, 0];

        auto lenBytes = nativeToLittleEndian(cast(int) data.length);
        return lenBytes ~ data;
    }

    Packet receivePacket()
    {
        ubyte[] data;
        while (true)
        {
            Packet packet;
            size_t neededBytes;
            ubyte[] remaining;

            if (tryDecodePacket(data, packet, neededBytes, remaining))
                return packet;

            while (data.length < neededBytes)
            {
                auto buf = new ubyte[](neededBytes - data.length);
                auto got = socket.receive(buf);
                if (got <= 0)
                {
                    throw new ConnectionClosedException("Connection closed.");
                }

                data ~= buf[0 .. got];
            }
        }
    }

    void sendPacket(Packet packet)
    {
        socket.send(encodePacket(packet));
    }
}
