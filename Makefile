CC= g++ -std=c++0x
OS=linux
MAKE=make
DIR_BUILD=build
INCLUDE= -Iinclude
MACRO=-DDEBUG
EXEC=fhtagn

LOG="Tool   : "${CC}"\r\nMacros : "${MACRO}"\r\nTarget : "${DIR_BUILD}/${EXEC}"\r\n"

main: init
	@clear;clear
	@echo ${LOG}
	@${CC} -g -o ${DIR_BUILD}/${EXEC}				 	\
		src/main.cpp									\
		${DIR_BUILD}/lua.so								\
		${DIR_BUILD}/dice.so							\
		${INCLUDE} ${MACRO};

init: dice.so core.so lua.so file.so
	@if [ ! -d ${DIR_BUILD} ]; then mkdir ${DIR_BUILD}; fi

# Modules
lua.so:
	@${CC} -shared -o ${DIR_BUILD}/lua.so				\
		src/l*.c										\
		src/LuaClass.cpp								\
		${INCLUDE} ${MACRO}

dice.so:
	@${CC} -shared -o ${DIR_BUILD}/dice.so				\
		src/Dice.cpp								   	\
		${INCLUDE} ${MACRO}

core.so:
	@${CC} -shared -o ${DIR_BUILD}/core.so				\
		src/Entity.cpp 									\
		src/TheSim.cpp									\
		${INCLUDE} ${MACRO}

file.so:
	@${CC} -shared -o ${DIR_BUILD}/file.so				\
		src/File.cpp									\
		${INCLUDE} ${MACRO}


# Test
test: dice.so
	@clear
	@if [ ! -d ${DIR_BUILD} ]; then mkdir ${DIR_BUILD}; fi
	@${CC} -g -o ${DIR_BUILD}/test src/test.cpp			\
		${DIR_BUILD}/lua.so								\
		${DIR_BUILD}/dice.so							\
		${DIR_BUILD}/core.so							\
		${INCLUDE} ${MACRO}
	@./${DIR_BUILD}/test

# Clean
clean:
	@clear;clear
	@if [ -d ${DIR_BUILD} ]; then rm -r ${DIR_BUILD}; fi
