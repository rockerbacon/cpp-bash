#pragma once

#include <string>
#include <future>

namespace unix_socket {
	using namespace std::chrono_literals;
	class client {
		friend void swap(client& a, client& b);

		private:
			std::chrono::milliseconds timeout;
			std::string socket_path;
			int socket_descriptor;

		public:
			client() = default;
			client(const std::string& socket_path);
			~client();

			void connect (const std::string& socket_path, std::chrono::milliseconds timout=5000ms);

			std::future<void> send (const std::string& data);

			const std::string& get_socket_path() const;
	};

	void swap(client& a, client& b);
}

