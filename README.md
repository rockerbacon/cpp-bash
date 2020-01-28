# Description
Use bash as an extension language, deeply mixing it into your C++ code.

The [proposed architecture](#architecture) is technology agnostic and can be used to integrate most languages.

This project is managed by the [Assertions C++ Framework](https://github.com/rockerbacon/assertions). If your project also uses assertions, you can import it using the command:
```
./dependencies.sh add git https://github.com/rockerbacon/cpp-bash
```

## Building and testing
Building is done with the provided ```build.sh``` script and testing with the provided ```test.sh``` script. Check out the [Assertions wiki](https://github.com/rockerbacon/assertions/wiki/Project-Management) for more information.

## Learn in Y minutes

```cpp
#include <cpp-bash/bash/shell.h>
#include <iostream>

int main () {
  bash::shell shell; // instantiates a new shell
  // a shell preserves its state until it is terminated/destroyed

  std::future<int> exec_future = shell.exec("internal_variable=5");
  // any valid bash command can be sent for execution by the shell
  // the shell interface is mostly asynchronous

  if (exec_future.get() == 0)
    std::cout << "successful variable initialization" << std::endl;
  // the future holds the shell's exit code
  // if exec doesn't cause the shell to exit the future returns 0

  shell.exec(R"(
    if [ $internal_variable -eq 5 ]; then
      echo "variable was 5"
    fi
  )");  // the shell preserves its state, including all variables previously declared

  std::string internal_variable = shell.getvar("internal_variable").get();
  // variables can be accessed with this asynchronous method
  // since bash is an untyped language everything gets converted to strings

  if (internal_variable == "5") 
    shell.setvar("internal_variable", 3).wait(); 
  // variables in the shell can also be changed
  // the second argument will be cast to a string using std::stringstream::operator<<

  ifstream shell_output = shell.get_stdout();
  cout << shell_output << endl;  // prints "variable was 5"
  shell_output.close();
  // by design, the shell's outputs are redirected to tmp files
  // these files can be opened with get_stdout() and get_stderr()

  int shell_exit_code = shell.exec("exit 2").get();  
  if (shell_exit_code == 2)
    return 0;
  // the shell can be manually terminated using standard bash commands
  // the future will hold the shell's termination
  // trying to use the shell after it has exited is undefined behaviour

  return 1;
}
```

## Architecture
The architecture consists of sending code written in some arbitrary language to a separate process which is capable of interpreting said language, essentially turning it into an [extension language](https://www.gnu.org/software/guile/docs/master/guile-tut.html/What-are-scripting-and-extension-languages.html), even if it's not designed to work as one.

At first this may sound redundant, since one can achieve something similar with a more traditional microservice architecture. There are important differences in this architecture, however:
- The interpreter process is always a child of the main process and, as such, bound to the main process according to the OS's rules;
- Traditional microservice architectures allow for execution of pre-defined routines while this architecture allows for execution of any arbitrary code;
- The existence of another process is transparent to the developer and there's no need for manual management of the processes;
- Processes using traditional microservice architectures have their communication limited to pre-defined contracts while the two environments in this architecture are deeply integrated, making it possible to transmit any arbitrary data between the two;

The architecture has a few essential components:
- `Interpreter`: program capable of interpreting the target language
- `Interpreter Server`: process which receives code over some connection and forwards it to the interpreter
- `Shell`: API and library for managing the interpreter process and its communication with the main process

### Interpreter
For an interpreter to be compatible with this architecture it only needs to be able to receive strings of code from the standard input (_stdin_). Most interpreted languages have one such program, often called an _interactive shell_.

### Interpreter Server
The interpreter server simply receives the strings of code through some connection and pipes them to the _interpreter_, replacing the interpreter's standard input with an interprocess data stream.

For this implementation, [netcat](https://www.computerhope.com/unix/nc.htm) was used to listen to a [Unix Domain Socket](https://en.wikipedia.org/wiki/Unix_domain_socket) with its output piped to `bash`:
```
nc -lU <Unix Domain Socket path> | bash
```

### Shell
The shell is written entirely in C++17 and available in the class `bash::shell`. Instantiating this class causes the process to [fork](https://en.wikipedia.org/wiki/Fork_(system_call)), with the child process now managing the _interpreter_ and _interpreter server_. After instantiation, the shell lives and retains its state until the instance is destroyed or until the shell is terminated by the same means of termination of a standard shell (calling [exit](https://bash.cyberciti.biz/guide/Exit_command) or raising an error, for example).

Most of the methods are asynchronous, to cope with the communication delay and the fact that bash is a lot slower than C++. Even if the interface is asynchronous, commands are guaranteed to execute in the order they're sent as per Unix Domain Socket specifications.

### Caveats
- In order for communication to work both ways the _interpreter_ needs a way to send information to the _shell_ library. In this implementation, the shell library ensures the commands send through `exec` are decorated to include a `nc` execution at the end of every command
- As of now, this implementation does not make use any Unix Socket security features and is vulnerable to [arbitrary code execution](https://en.wikipedia.org/wiki/Arbitrary_code_execution)

