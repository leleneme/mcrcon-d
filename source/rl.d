module rl;

import std.string : fromStringz, toStringz;

private:
extern (C)
{
    char* readline(const char*);
    void add_history(const char* string);
}

public:
string readLine(string prompt)
{
    char* buf = readline(prompt.toStringz);
    if (buf is null)
        return null;

    add_history(buf);
    return cast(string) fromStringz(buf);
}
