import std.stdio;
import std.getopt;
import std.socket : SocketOSException;
import std.string : strip;

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

void iteractiveMode(ref MCRconClient rcon)
{
	writeln("Authenticated. Type :exit or press Ctrl-C | Ctrl-D to exit.");

	while (rcon.alive)
	{
		auto input = readLine("> ");

		if (input is null || input == ":exit")
			break;
		else if (input.length <= 0)
			continue;

		input = input.strip();

		string response = rcon.sendCommand(input);
		if (response.length > 1)
			writeln(response);

		if (input == "stop")
			break;
	}
}

void cliCommandMode(ref MCRconClient rcon, ref string[] args)
{
	foreach (arg; args)
	{
		string response = rcon.sendCommand(arg);
		if (response.length > 1)
			writeln(response);
	}
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

	auto argsRest = argv[1 .. $];

	try
	{
		auto rcon = new MCRconClient(config.host, config.port);
		if (!rcon.login(config.password))
		{
			stderr.writeln("failed to authenticate to RCON, wrong password?");
			return 1;
		}

		if (argsRest.length == 0)
			iteractiveMode(rcon);
		else
			cliCommandMode(rcon, argsRest);
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
