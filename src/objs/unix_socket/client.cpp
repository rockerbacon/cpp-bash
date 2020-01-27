#include "client.h"

#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>

using namespace std;
using namespace unix_socket;

client::client (const std::string& socket_path) {
	connect(socket_path);
}

client::~client () {
	close(socket_descriptor);
}

void client::connect (const std::string& socket_path_arg, chrono::milliseconds timeout) {
	socket_path = socket_path_arg;

	sockaddr_un address;
	memset(&address, 0, sizeof(address));

	address.sun_family = AF_UNIX;
	strcpy(address.sun_path, socket_path.c_str());

	socket_descriptor = socket(AF_UNIX, SOCK_STREAM, 0);

	int conn_status;
	bool not_connected = true;
	auto connection_begin = chrono::steady_clock::now();
	do {
		conn_status = ::connect(
			socket_descriptor,
			(const sockaddr*)&address,
			sizeof(decltype(address))
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
			default:
				throw system_error(error_code, std::system_category(), "Error starting client");
		} else {
			not_connected = false;
		}
	} while (not_connected);
}

future<void> client::send (const std::string& data) {
	return async(launch::async, [this, data] {
		auto msg_status = ::send(socket_descriptor, data.c_str(), data.size(), MSG_NOSIGNAL);
		if (msg_status == -1)
			throw system_error(errno, system_category(), "Could not send message");
	});
}

const string& client::get_socket_path() const {
	return socket_path;
}

