#pragma once

#include <fstream>
#include <sstream>
#include <future>

#include "../unix_socket/server.h"
#include "../unix_socket/client.h"

namespace bash {
	namespace literals {
		std::stringstream operator"" _bash(const char* literal, size_t length);
	}

	class shell {
		private:
			std::string dir_path;
			unix_socket::client client;
			unix_socket::server return_server;
			std::string stdout_path;
			std::string stderr_path;
			int exit_status_code;
			pid_t shell_pid;

			void init_server();
			void init_client();

		public:
			shell();
			~shell();

			std::future<int> exec (const std::string& command);
			int exit_status () const;

			std::ifstream get_stdout();
			std::ifstream get_stderr();

			template<typename T>
			std::future<int> setvar (const std::string& label, const T& value) {
				std::stringstream command;
				command << label << "=" << value;
				return exec(command.str());
			}

			std::future<std::string> getvar (const std::string& label);
	};
}

