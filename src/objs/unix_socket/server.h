#pragma once

#include <cstddef>
#include <string>
#include <future>

namespace unix_socket {
	class server {
		friend void swap(server& a, server& b);

		private:
			std::string socket_path;
			int socket_descriptor;
			size_t buffer_size;
			std::unique_ptr<std::byte> buffer;

		public:
			server(size_t buffer_size=65536);
			server(const std::string& socket_path, size_t buffer_size=65536);
			server(server&& other);
			~server();

			void connect(const std::string& socket_path);
			std::future<std::string> receive();

			const std::string& get_socket_path() const;
	};

	void swap(server& a, server& b);
}

