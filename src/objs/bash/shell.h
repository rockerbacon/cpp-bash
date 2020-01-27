#pragma once

#include <fstream>
#include <sstream>
#include <future>

#include "../unix_socket/server.h"

namespace bash {
	namespace literals {
		std::stringstream operator"" _bash(const char* literal, size_t length);
	}

	class shell {
		private:
			std::string dir_path;
			std::string isocket_path;
			unix_socket::server return_server;
			std::string stdout_path;
			std::string stderr_path;
			int exit_status_code;
			pid_t shell_pid;
			int isocket_descriptor;

			void init_server();
			void init_client();

			void send_to_shell(const std::string& data);
		public:
			shell();
			~shell();

			void exec (std::string command);
			int exit_status () const;

			std::ifstream get_stdout();
			std::ifstream get_stderr();

			template<typename T>
			void setvar (const std::string& label, const T& value) {
				std::stringstream command;
				command << label << "=" << value << std::endl;
				exec(command.str());
			}

			std::future<std::string> getvar (const std::string& label);
	};
}
