cmake_minimum_required(VERSION 3.3)
project(ECE449)

# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall")

set(HEADER_FILES
        src/definitions.h
        src/LexToken.h
        src/SyntaxWire.h
        src/SyntaxPin.h
        src/SyntaxComponent.h
        src/SyntaxModule.h
        src/syntax.h
        src/lex.h
        src/SimNet.h
        src/SimPin.h
        src/SimComponent.h
        src/SimNetList.h
        src/netlist.h
        src/NetListBuilder.h
        src/Simulation.h
        src/Logic.h
        )

set(SOURCE_FILES
        src/LexToken.cpp
        src/SyntaxWire.cpp
        src/SyntaxPin.cpp
        src/SyntaxComponent.cpp
        src/SyntaxModule.cpp
        src/syntax.cpp
        src/lex.cpp
        src/main.cpp
        src/SimNet.cpp
        src/SimPin.cpp
        src/SimComponent.cpp
        src/SimNetList.cpp
        src/netlist.cpp
        src/NetListBuilder.cpp
        src/Simulation.cpp
        src/Logic.cpp
        )

add_executable(ECE449 ${HEADER_FILES} ${SOURCE_FILES})