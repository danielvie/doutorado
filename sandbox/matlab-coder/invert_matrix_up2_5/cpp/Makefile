# CONFIGURANDO FLAGS COMPILADOR
CXX           = g++
CC            = gcc

INCLUDE       = -Isrc -Ilib -Iinclude
DECLARE       = -D__USE_MINGW_ANSI_STDIO=1 \
				-DMODEL=fun_invert_matrix_up2_5

CFLAGS	      = -O0 -g -Wall ${INCLUDE} ${DECLARE}
CXXFLAGS	  = -O0 -g -Wall ${INCLUDE} ${DECLARE}
LDFLAGS 	  = 

# DEFININDO NOME LIB 'python' E 'exe'
app           = main.exe

# BREAKLINE CONSTANT
ifeq (${OS},Windows_NT)
break_line = \\\\\\n
else
break_line = \\\\n
endif

# LENDO ARQUIVOS
src           = $(wildcard src/*.c*)
lib           = $(wildcard lib/*.c*)

# AJUSTANDO 'src' E 'obj'
obj           = $(addsuffix .o,$(basename $(src:src/%=obj/%)))
obj          += $(addsuffix .o,$(basename $(lib:lib/%=obj/%)))

# LEIS DE COMPILACAO
all: r

r: run

p: 
	@echo -----------------------------
	@echo ${src}
	@echo -----------------------------
	@echo ${obj}
	@echo -----------------------------

# AJUSTANDO FLAGS 'python'
lib: ${pyd}

# COMPILACAO 'app {exe}'
${app}: ${obj}
	$(CXX) -o ${app} ${obj}

# ESCREVENDO '*.o' EM 'obj'
obj/%.o : src/%.cpp
	$(CXX) ${CXXFLAGS} -o $@ -c $<

obj/%.o : lib/%.cpp
	$(CXX) ${CXXFLAGS} -o $@ -c $<

# MONITORANDO ALTERACOES '.h' IMPORTANTES
# obj/teste.o : src/teste.h

# INICIALIZANDO PASTAS
init: create_folders
init: create_main

i: init

f: create_folders

m: create_main

create_folders:
	mkdir obj src include lib

create_main:
	printf "#include <iostream>\n\n" > src/main.cpp
	printf "int main(int argc, char const *argv[])\n" >> src/main.cpp
	printf "{\n" >> src/main.cpp
	printf "	std::cout << \"-----------------------------------------${break_line}\";\n" >> src/main.cpp
	printf "	std::cout << \"hello${break_line}\";\n" >> src/main.cpp
	printf "	return 0;\n" >> src/main.cpp
	printf "}" >> src/main.cpp

# EXECURANDO 'exe'
run: ${app}
	${app}

# LIMPANDO OBJETOS
clean: 
	rm obj/*