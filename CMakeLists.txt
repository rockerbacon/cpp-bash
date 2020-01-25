cmake_minimum_required(VERSION 3.10)

project("assertions" CXX)
enable_testing()
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_CXX_STANDARD 17)
set(BUILD_STATIC_LIBRARY OFF)
set(BUILD_SHARED_LIBRARY OFF)

set(tests_src_dir "tests")
set(objs_src_dir "src/objs")
set(programs_src_dir "src/main")

set(external_include_dir "external_dependencies/include")
set(external_lib_dir "external_dependencies/lib")
set(external_objs_dir "external_dependencies/objs")
set(external_local_objs_dir "external_dependencies/local_objs")

set_property(GLOBAL PROPERTY TARGET_MESSAGES OFF)

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" OR
    "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")

	set(CMAKE_CXX_FLAGS "-fdiagnostics-color=always -Wall -Wextra")

elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")

	set(CMAKE_CXX_FLAGS "/W4 /EHsc")

endif()

include_directories(${external_include_dir})
include_directories(${external_objs_dir})
include_directories(${external_local_objs_dir})

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY release/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY release/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY release/bin)

file(GLOB_RECURSE external_libraries FOLLOW_SYMLINKS "${external_lib_dir}/*.*")
find_package(Threads)

file(GLOB_RECURSE objs_src_files "${objs_src_dir}/*.cpp")
foreach(obj_src_file  ${objs_src_files})
	string(REGEX REPLACE "(^(.*/)*${objs_src_dir}/)|(\.cpp)" "" obj_binary ${obj_src_file})
	string(REGEX REPLACE "/" "_" obj_binary ${obj_binary})
	string(APPEND obj_binary ".o")
	add_library(${obj_binary} OBJECT ${obj_src_file})
	list(APPEND all_obj_binaries $<TARGET_OBJECTS:${obj_binary}>)
endforeach()

file(GLOB_RECURSE objs_src_files FOLLOW_SYMLINKS "${external_objs_dir}/*.cpp")
message(STATUS ${objs_src_files})
foreach(obj_src_file  ${objs_src_files})
	string(REGEX REPLACE "(^(.*/)*${external_objs_dir}/)|(\.cpp)" "" obj_binary ${obj_src_file})
	string(REGEX REPLACE "/" "_" obj_binary ${obj_binary})
	string(PREPEND obj_binary "external_")
	string(APPEND obj_binary ".o")
	add_library(${obj_binary} OBJECT ${obj_src_file})
	list(APPEND all_obj_binaries $<TARGET_OBJECTS:${obj_binary}>)
endforeach()

file(GLOB_RECURSE objs_src_files FOLLOW_SYMLINKS "${external_local_objs_dir}/*.cpp")
message(STATUS ${objs_src_files})
foreach(obj_src_file  ${objs_src_files})
	string(REGEX REPLACE "(^(.*/)*${external_objs_dir}/)|(\.cpp)" "" obj_binary ${obj_src_file})
	string(REGEX REPLACE "/" "_" obj_binary ${obj_binary})
	string(PREPEND obj_binary "external_local_")
	string(APPEND obj_binary ".o")
	add_library(${obj_binary} OBJECT ${obj_src_file})
	list(APPEND all_obj_binaries $<TARGET_OBJECTS:${obj_binary}>)
endforeach()

file(GLOB_RECURSE tests_src_files "${tests_src_dir}/*.cpp")
foreach(test_src_file ${tests_src_files})
	string(REGEX REPLACE "(^(.*/)*${tests_src_dir}/)|(.cpp)" "" test_binary ${test_src_file})
	string(REGEX REPLACE "/" "_" test_binary ${test_binary})
	string(PREPEND test_binary "tests_")
	add_executable(${test_binary} ${test_src_file} ${all_obj_binaries})
	set_target_properties(${test_binary}
		PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY "tests"
	)
	target_include_directories(${test_binary} PRIVATE ${objs_src_dir})
	target_link_libraries(${test_binary} ${external_libraries} Threads::Threads)
	add_test(NAME ${test_binary} COMMAND ${test_binary})
endforeach()

file(GLOB_RECURSE programs_src_files "${programs_src_dir}/*.cpp")
foreach(program_src_file ${programs_src_files})
	string(REGEX REPLACE "(^(.*/)*${programs_src_dir}/)|(.cpp)" "" program_binary ${program_src_file})
	string(REGEX REPLACE "/" "_" program_binary ${program_binary})
	add_executable(${program_binary} ${program_src_file} ${all_obj_binaries})
	target_include_directories(${program_binary} PRIVATE ${objs_src_dir})
	target_link_libraries(${program_binary} ${external_libraries} Threads::Threads)
endforeach()

if (${BUILD_STATIC_LIBRARY})
	add_library(${PROJECT_NAME} STATIC ${all_obj_binaries})
endif()
if (${BUILD_SHARED_LIBRARY})
	add_library(${PROJECT_NAME} SHARED ${all_obj_binaries})
endif()

if (${BUILD_STATIC_LIBRARY} OR ${BUILD_SHARED_LIBRARY})
	file (
		COPY ${objs_src_dir}/
		DESTINATION release/include
		FILES_MATCHING PATTERN "*.h"
	)
endif()

