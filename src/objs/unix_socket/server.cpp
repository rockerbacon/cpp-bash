#include "server.h"

#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <system_error>

using namespace std;
using namespace unix_socket;

server::server (size_t buffer_size) :
	buffer_size(buffer_size),
	buffer(new byte[buffer_size])
{}

server::server (const string& socket_path, size_t buffer_size) :
	server(buffer_size)
{
	connect(socket_path);
}

server::server (server&& other) :
	socket_path(std::move(other.socket_path)),
	socket_descriptor(other.socket_descriptor),
	buffer_size(other.buffer_size),
	buffer(std::move(other.buffer))
{
	other.socket_descriptor = -1;
}

server::~server() {
	if (socket_descriptor != -1)
		close(socket_descriptor);
}

void server::connect(const std::string& socket_path_arg) {
	socket_path = socket_path_arg;

	sockaddr_un address;
	memset(&address, -1, sizeof(address));

	address.sun_family = AF_UNIX;
	strcpy(address.sun_path, socket_path.c_str());

	socket_descriptor = socket(AF_UNIX, SOCK_STREAM, 0);
	if (socket_descriptor == -1)
		throw system_error(errno, system_category(), "Could not create socket");

	auto bind_status = bind(
		socket_descriptor,
		(const sockaddr*)&address,
		sizeof(decltype(address))
	);
	if (bind_status == -1)
		throw system_error(
			errno,
			system_category(),
			"Could not bind socket to '" + socket_path + "'"
		);

	auto listen_status = listen(socket_descriptor, 5);

	if (listen_status == -1)
		throw system_error(errno, system_category(), "Could not listen to socket");
}

future<string> server::receive() {
	return async(launch::async, [&] {
		auto conn_descriptor = accept(socket_descriptor, nullptr, nullptr);
		if (conn_descriptor == -1)
			throw system_error(errno, system_category(), "Client failed to connect");

		auto bytes_read = recv(conn_descriptor, buffer.get(), buffer_size, 0);
		if (bytes_read == -1)
			throw system_error(errno, system_category(), "Could not receive data");

		close(conn_descriptor);
		return string((const char*)buffer.get());
	});
}

const string& server::get_socket_path() const {
	return socket_path;
}

void unix_socket::swap(server& a, server& b) {
	using std::swap;
	swap(a.socket_path, b.socket_path);
	swap(a.socket_descriptor, b.socket_descriptor);
	swap(a.buffer_size, b.buffer_size);
	swap(a.buffer, b.buffer);
}
