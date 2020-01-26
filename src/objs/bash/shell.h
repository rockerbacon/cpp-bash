#pragma once

#include <fstream>
#include <sstream>

namespace bash {
	namespace literals {
		std::stringstream operator"" _bash(const char* literal, size_t length);
	}

	class shell {
		private:
			std::string dir_path;
			std::string isocket_path;
			std::string osocket_path;
			std::string stdout_path;
			std::string stderr_path;
			int exit_status_code;
			pid_t shell_pid;
			int isocket_descriptor;
			int osocket_descriptor;

			void init_server();
			void init_client();
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

			std::string getvar (const std::string& label);
	};
}

