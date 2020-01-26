#include <assertions-test/test.h>
#include <string>
#include <bash/shell.h>

using namespace std;
using namespace std::chrono_literals;

begin_tests {
	test_suite("when executing scripts in shell") {
		test_case("should return correct exit status") {
			bash::shell shell;

			shell.exec("exit 15");

			this_thread::sleep_for(100ms);
			assert(shell.exit_status(), ==, 15);
		};

		test_case("should return the correct stdout output") {
			bash::shell shell;

			shell.exec(R"(echo "hello world")");
			shell.exec("exit 0");

			std::string script_output;

			this_thread::sleep_for(100ms);
			getline(shell.get_stdout(), script_output);

			assert(script_output, ==, "hello world");
		};
	}

	test_suite("when communicating variables") {
		test_case("should be able to write values to shell") {
			bash::shell shell;
			std::string cpp_str("test");

			shell.setvar("cpp_str", cpp_str);
			shell.exec(R"(
				if [ "$cpp_str" == "test" ]; then
					exit 5
				fi
				exit 2
			)");

			this_thread::sleep_for(100ms);
			auto variable_written = (shell.exit_status() == 5);

			assert(variable_written, ==, true);
		};

		test_case("should be able to read values from shell") {
			bash::shell shell;

			shell.exec("bash_str='test'");

			auto bash_str = shell.getvar("bash_str");

			assert(bash_str.get(), ==, "test");
		};
	}
} end_tests;

