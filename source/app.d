import std.stdio;
import std.getopt;
import std.socket : SocketOSException;

import mcrcon : MCRconClient, ConnectionClosedException;
import rl : readLine;

const string DESCRIPTION = "mcrcon-d: A simple MCRcon client.";

struct Configuration
{
	string host = "localhost";
	ushort port = 25_575;
	string password;
}

struct ParseOptionsResult
{
	Configuration config;
	bool quit;
}

ParseOptionsResult parseArgs(ref string[] args)
{
	Configuration config;

	auto opts = getopt(args,
		std.getopt.config.caseSensitive,
		"H|host", "Server address, default: localhost", &config.host,
		"P|port", "Port, default: 25575", &config.port,
		std.getopt.config.required,
		"p|password", "RCON Password", &config.password);

	if (opts.helpWanted)
	{
		defaultGetoptPrinter(DESCRIPTION, opts.options);
		return ParseOptionsResult(config, true);
	}

	return ParseOptionsResult(config, false);
}

int main(string[] argv)
{
	Configuration config;

	try
	{
		auto parseResult = parseArgs(argv);
		if (parseResult.quit)
			return 0;

		config = parseResult.config;
	}
	catch (Exception ex)
	{
		writeln(ex.message, ". Use --help or -h for help.");
		return 1;
	}

	try
	{
		auto rcon = new MCRconClient(config.host, config.port);
		if (!rcon.login(config.password))
		{
			stderr.writeln("failed to authenticate to RCON, wrong password?");
			return 1;
		}

		writeln("Authenticated. Type :exit or press Ctrl-C | Ctrl-D to exit.");

		while (true)
		{
			auto input = readLine("> ");

			if (input is null || input == ":exit")
				break;
			else if (input.length <= 0)
				continue;

			string response = rcon.sendCommand(input);
			if (response.length > 1)
				writeln(response);
		}
	}
	catch (ConnectionClosedException ex)
	{
		stderr.writeln("Connection to host was closed.");
		return 1;
	}
	catch (SocketOSException ex)
	{
		stderr.writeln("Failed to connect to ", config.host, ":", config.port, ".");
		return 1;
	}

	return 0;
}
