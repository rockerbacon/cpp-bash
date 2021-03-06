#include "shell.h"
#include "../unix_socket/server.h"

#include <sstream>
#include <cstdio>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/wait.h>

using namespace bash;
using namespace bash::literals;
using namespace std;

void shell::init_server() {
	stringstream cmd_builder;

	cmd_builder
		<< "nc -lU " << dir_path << "/input.sock | bash "
		<< " 1> " << stdout_path
		<< " 2> " << stderr_path
	;

	auto command = cmd_builder.str();
	auto status_code = std::system(command.c_str());
	auto exit_status = 	WEXITSTATUS(status_code);

	try {
		unix_socket::client client(dir_path + "/output.sock");
		client.send(to_string(exit_status));
	} catch (const system_error& error) {
		if (error.code().value() != ETIMEDOUT) throw error;
	}

	_exit(WEXITSTATUS(status_code));
}

void shell::init_client() {
	client.connect(dir_path + "/input.sock");
	return_server.connect(dir_path + "/output.sock");
}

shell::shell() {
	char path_template[] = "/tmp/cpp-bash-XXXXXX";
	dir_path = mkdtemp(path_template);
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
	if (shell_pid != -1)
		kill(shell_pid, SIGTERM);
}

shell::shell(shell&& other) :
	dir_path(other.dir_path),
	client(std::move(other.client)),
	return_server(std::move(other.return_server)),
	stdout_path(other.stdout_path),
	stderr_path(other.stderr_path),
	exit_status_code(other.exit_status_code),
	shell_pid(other.shell_pid)
{
	other.shell_pid = -1;
}

future<int> shell::exec (const string& command) {
	return async(launch::async, [this](string command) {
		command += "\necho -n 0 | nc -U -q 0 " + return_server.get_socket_path() + '\n';
		client.send(command).wait();
		auto exit_status_str = return_server.receive().get();
		return atoi(exit_status_str.c_str());
	}, command);
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
	return async(launch::async, [this, label] {
		client.send(
			"echo -n $" + label +
			" | nc -U -q 0 " + return_server.get_socket_path() +
			'\n'
		).wait();

		return return_server.receive().get();
	});
}

void bash::swap(shell& a, shell& b) {
	using std::swap;
	swap(a.dir_path, b.dir_path);
	swap(a.client, b.client);
	swap(a.return_server, b.return_server);
	swap(a.stdout_path, b.stdout_path);
	swap(a.stderr_path, b.stderr_path);
	swap(a.exit_status_code, b.exit_status_code);
	swap(a.shell_pid, b.shell_pid);
}

shell& shell::operator=(shell&& other) {
	swap(*this, other);
	return *this;
}
