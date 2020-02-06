#include <assertions-test/test.h>
#include <string>
#include <bash/shell.h>

using namespace std;
using namespace std::chrono_literals;

begin_tests {
	test_suite("when executing scripts in shell") {
		test_case("should return correct exit status on abnormal termination") {
			bash::shell shell;

			auto command_future = shell.exec("exit 15");

			assert(command_future.get(), ==, 15);
		};

		test_case("should return exit status 0 on normal termination") {
			bash::shell shell;

			auto command_future = shell.exec("echo hello");

			assert(command_future.get(), ==, 0);
		};

		test_case("should be able to execute multiple commands") {
			bash::shell shell;

			auto cmd1_future = shell.exec("echo hi");
			auto cmd2_future = shell.exec("echo hello");

			assert(cmd1_future.get(), ==, 0);
			assert(cmd2_future.get(), ==, 0);
		};

		test_case("should return the correct stdout output") {
			bash::shell shell;

			shell.exec(R"(echo "hello world")").wait();

			std::string script_output;
			getline(shell.get_stdout(), script_output);

			assert(script_output, ==, "hello world");
		};
	}

	test_suite("when communicating variables") {
		test_case("should be able to write values to shell") {
			bash::shell shell;
			std::string cpp_str("test");

			shell.setvar("cpp_str", cpp_str).wait();
			auto variable_read = shell.exec(R"(
				if [ "$cpp_str" == "test" ]; then
					exit 1
				fi
				exit 0
			)");

			assert(variable_read.get(), ==, 1);
		};

		test_case("should be able to read values from shell") {
			bash::shell shell;

			shell.exec("bash_str='test'").wait();

			auto bash_str = shell.getvar("bash_str");

			assert(bash_str.get(), ==, "test");
		};
	}

	test_suite("when move-constructing a shell") {
		test_case("shell should be movable") {
			bash::shell shellA;
			bash::shell shellB(std::move(shellA));
		};

		test_case("shell should retain state after being moved") {
			bash::shell shellA;
			shellA.exec("varA=test").wait();
			bash::shell shellB(std::move(shellA));
			auto varA = shellB.getvar("varA").get();
			assert(varA, ==, "test");
		};

		test_case("shell should be swappable") {
			bash::shell shellA;
			bash::shell shellB;

			shellA.exec("var=a").wait();
			shellB.exec("var=b").wait();

			swap(shellB, shellA);

			auto varA = shellA.getvar("var").get();
			auto varB = shellB.getvar("var").get();

			assert(varA, ==, "b");
			assert(varB, ==, "a");

		};

		test_case("shell should be move assignable") {
			bash::shell shellA;
			bash::shell shellB;

			shellA.exec("var=a").wait();

			shellB = std::move(shellA);

			auto var = shellB.getvar("var").get();

			assert(var, ==, "a");
		};
	}
} end_tests;

