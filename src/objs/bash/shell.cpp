#include "shell.h"

#include <sstream>
#include <cstdio>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <thread>

using namespace bash;
using namespace bash::literals;
using namespace std;

void shell::init_server() {
	stringstream cmd_builder;

	cmd_builder
		<< "nc -lU " << isocket_path << " | bash"
		<< " 1> " << stdout_path
		<< " 2> " << stderr_path
	;

	auto command = cmd_builder.str();
	auto status_code = std::system(command.c_str());
	_exit(WEXITSTATUS(status_code));
}

void shell::init_client() {
	const auto timeout = 5000ms;

	sockaddr_un isocket_address;
	memset(&isocket_address, 0, sizeof(isocket_address));

	isocket_address.sun_family = AF_UNIX;
	strcpy(isocket_address.sun_path, isocket_path.c_str());

	isocket_descriptor = socket(AF_UNIX, SOCK_STREAM, 0);

	int conn_status;
	bool retry = true;
	auto connection_begin = chrono::steady_clock::now();
	do {
		conn_status = connect(
			isocket_descriptor,
			(const sockaddr*)&isocket_address,
			sizeof(decltype(isocket_address))
		);

		auto error_code = errno;
		if (conn_status == -1) switch (error_code) {
			case ECONNREFUSED:
			case EADDRNOTAVAIL:
			case ENOENT:
				if (chrono::steady_clock::now() - connection_begin > timeout) {
					error_code = ETIMEDOUT;
					[[fallthrough]];
				} else {
					break;
				}
			default: {
				kill(shell_pid, SIGTERM);
				throw system_error(error_code, std::system_category(), "Error starting client");
			}
		} else {
			retry = false;
		}

	} while (retry);

	sockaddr_un osocket_address;
	memset(&osocket_address, 0, sizeof(osocket_address));

	osocket_address.sun_family = AF_UNIX;
	strcpy(osocket_address.sun_path, osocket_path.c_str());

	osocket_descriptor = socket(AF_UNIX, SOCK_STREAM, 0);

	bind(
		osocket_descriptor,
		(const sockaddr*)&osocket_address,
		sizeof(decltype(osocket_address))
	);

	auto listen_status = listen(osocket_descriptor, 5);

	if (listen_status == -1) {
		kill(shell_pid, SIGTERM);
		throw system_error(errno, std::system_category(), "Error creating shell output");
	}
}

void shell::send_to_shell(const std::string& data) {
	auto send_status = send(isocket_descriptor, data.c_str(), data.size(), MSG_NOSIGNAL);
	if (send_status == -1)
		throw system_error(errno, std::system_category(), "Error sending data to shell");
}

shell::shell() {
	char path_template[] = "/tmp/cpp-bash-XXXXXX";
	dir_path = mkdtemp(path_template);
	isocket_path = dir_path + "/input.sock";
	osocket_path = dir_path + "/output.sock";
	stdout_path = dir_path + "/stdout.out";
	stderr_path = dir_path + "/stderr.out";

	shell_pid = fork();

	if (shell_pid == 0) {
		init_server();
	} else {
		init_client();
	}
}

shell::~shell() {
	close(isocket_descriptor);
	close(osocket_descriptor);
	kill(shell_pid, SIGTERM);
}

void shell::exec (std::string command) {
	command += '\n';
	send_to_shell(command);
}

int shell::exit_status () const {
	int status_code;
	int exit_status_code = -1;

	waitpid(shell_pid, &status_code, 1);

	if (WIFEXITED(status_code)) {
		exit_status_code = WEXITSTATUS(status_code);
	}

	return exit_status_code;
}

ifstream shell::get_stdout() {
	return ifstream(stdout_path);
}

ifstream shell::get_stderr() {
	return ifstream(stderr_path);
}

future<string> shell::getvar (const string& label) {
	return async(launch::async, [&] {
		auto command = "echo -n $" + label + " | nc -U -q 0 " + osocket_path;
		exec(command);

		auto output_descriptor = accept(osocket_descriptor, nullptr, nullptr);

		char buffer[1024];
		auto bytes_read = recv(output_descriptor, buffer, sizeof(buffer)/sizeof(char), 0);

		if (bytes_read == -1)
			throw system_error(errno, system_category(), "Error reading variable value");

		return string(buffer);
	});
}

