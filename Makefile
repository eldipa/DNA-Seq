# If this flag is '0', the output of the make will be small and beautified
# If is '1', the output will show each executed instruction.
export verbose = 0

# If this flag is '1', each instruction is executed using 'time' and after
# its execution, the duration of that execution is showed.
# If it is '0', this is disabled
export timeit = 1

# These are the modules which will be built. Each module represent a directory
# relative to the current directory.
#
# As an example, if the project has four components like:
#  Project
#   - client        The source code to build a client program
#   - client/gui    The separated source with the 'graphical user interface' use by the client
#   - server        The server side
#   - common        The source that is common to the client and the server.
#
# With this layering, the 'SUBMODULES' variable is
#
#  SUBMODULES = common client/gui client server
#
# If you only want to build the sources in the same directory of this makefile
#
#  SUBMODULES = .
#
# Note that the order is important and is honored in the building process.
#
# In each module it MUST exist a 'mconfig' file that define at least the
# TARGET of the module (it can also define more variables that would extend
# or override the defined in this makefile)
#
# You MUST define the target name 'TARGET' used to build the final object.
# This variable can be defined with multiples targets separated by a space
#
# If TARGET is of the form:
#  - lib*.a then the makefile will build a static library archive using ARCHIVE
#  	    and collecting all the *.o object
#
#  - lib*.so the the makefile will build a dynamic library using DYNAMIC
#  	    and collecting all the *.o object
#  - *.make then it is assumed that exists a file with that name an is a makefile with
#           two defined rules 'all' and 'clean'
#
# In other cases, the makefile will build an executable using LINK
# In this case, TARGET MUST BE a name X where the object X.o can be builded (tipically,
# X.c or X.cpp exists)
#
# This is required because the linker must link ONLY ONE target at time and this
# is implemented filter-out the rest of the targets.
# Obviously, X.c/X.cpp must have a 'main' function.
SUBMODULES = .


# Tipical flags used by the compiler
COMPILER = gcc
SRCEXT = .c
STRICT = -Wall -Wextra -pedantic -pedantic-errors -Werror  -std=c99
DEBUG = -ggdb -DDEBUG
OPTIMIZATION = -O0

# More flags
COMPILER_FLAGS = $(STRICT) $(DEBUG) $(OPTIMIZATION)
ARCHIVER_FLAGS = -rc
LINKER_FLAGS =
DYNAMIC_FLAGS =

# This are
# 	- the path to a directory where are the headers files (.h)
# 	- the path and name of each library. The order is very important! Put the more 'high-level' first, then the more 'generic-and-common'.
# 	- the path to a directory where external libraries are.
# 	- the name (no the path) of that libraries.
INCLUDE_PATHS =
LIBRARIES =
EXTERNAL_LIBRARY_PATHS =
EXTERNAL_LIBRARIES =

onsubmodule ?= 0        # do not change this variable
ifeq ($(onsubmodule), 1)
#
# Remember, in each SUBMODULE it MUST exist a 'mconfig' that define at least
# the TARGET.
#
# Optionally it can override or extend the options in this Makefile
#
-include mconfig

# This are the tools used to compile, generate the dependencies, to archive, link and
# delete files.
#
# The '$@' element represent the target object, '$<' is the first dependency element
# and '$^' are the dependencies without duplicated of that rule.
COMPILE = $(TIMEIT) $(COMPILER) -c $(COMPILER_FLAGS) $(patsubst %, -I%, $(INCLUDE_PATHS)) -o $@ $<
DEPEND = $(TIMEIT) $(COMPILER) -MM $(COMPILER_FLAGS) $(patsubst %, -I%, $(INCLUDE_PATHS)) -MF $@ $(subst .deps,$(SRCEXT),$@)
ARCHIVE = $(TIMEIT) ar $(ARCHIVER_FLAGS) $@ $^
LINK = $(TIMEIT) $(COMPILER) $(LINKER_FLAGS) $(patsubst %, -L%, $(EXTERNAL_LIBRARY_PATHS)) -o $@ $@.o $(filter-out $(patsubst %, %.o, $(TARGET)), $^)  $(patsubst %, -l%, $(EXTERNAL_LIBRARIES))
DYNAMIC = $(TIMEIT) $(COMPILER) -shared $(DYNAMIC_FLAGS) -o $@ $^
MAKE_EXTERN = $(TIMEIT) $(SHELL) -c "( $(MAKE) -e --no-print-directory -f $$external $(MAKECMDGOALS) $(PRINT_MAKE_EXTERN_DONE) )"
RM = $(TIMEIT) rm -f

#
# END OF THE CONFIGURATION
#

ifeq ($(verbose), 0)
   PRINT_COMPILE = @printf "\033[35m  %-$(ALIGN)s \033[0m" "Compiling $<" ;
   PRINT_DEPEND = @printf "\033[32;2m  %-$(ALIGN)s \033[0m" "Dependencies of $(subst .deps,$(SRCEXT),$@)" ;
   PRINT_ARCHIVE = @printf "\033[36;1m  %-$(ALIGN)s \033[0m" "Archiving into $@" ;
   PRINT_LINK = @printf "\033[36;1m  %-$(ALIGN)s \033[0m" "Linking into $@" ;
   PRINT_DYNAMIC = @printf "\033[36;1m  %-$(ALIGN)s \033[0m" "Building shared library $@" ;
   PRINT_MAKE_EXTERN = printf "\033[36;3m    %s\033[36;1m %-$(ALIGN)s \033[0m" "Invoking" "make $(MAKECMDGOALS) $$external..." ; echo "" ;
   PRINT_RM_DEPS = @printf "\033[31m  %-$(ALIGN)s \033[0m" "Removing dependencies" ;
   PRINT_RM_OBJECTS = @printf "\033[31m  %-$(ALIGN)s \033[0m" "Removing objects" ;
   PRINT_RM_TARGET = @printf "\033[31m  %-$(ALIGN)s \033[0m" "Removing target" ;
   PRINT_MAKE_EXTERN_DONE = && printf \"\033[36;3m  %-$(ALIGN)s \033[0m\" \"  Done\"
endif

SRC = $(wildcard *$(SRCEXT))
OBJ = $(SRC:$(SRCEXT)=.o)
DEPS = $(SRC:$(SRCEXT)=.deps)

.PHONY: all clean depclean mostlyclean e1

$(SRCEXT).o:
	$(PRINT_COMPILE) $(COMPILE) $(NL)

ifndef TARGET
e1:
	$(PRINT_ERROR) "The 'TARGET' must be defined (in the Makeconfig file)"
endif


all: $(DEPS) $(filter lib%.a,$(TARGET)) $(filter lib%.so,$(TARGET)) $(filter-out lib%.a lib%.so %.make,$(TARGET))
	@for external in $(filter %.make,$(TARGET)) ; do $(PRINT_MAKE_EXTERN) $(MAKE_EXTERN) $(NL) ; done


$(filter lib%.a,$(TARGET)): $(OBJ)
	$(PRINT_ARCHIVE) $(ARCHIVE) $(NL)

$(filter lib%.so,$(TARGET)): $(OBJ)
	$(PRINT_DYNAMIC) $(DYNAMIC) $(NL)

$(filter-out lib%.a lib%.so %.make,$(TARGET)): $(OBJ) $(LIBRARIES)
	$(PRINT_LINK) $(LINK) $(NL)


$(DEPS):
	$(PRINT_DEPEND) $(DEPEND) $(NL)

depclean:
	$(PRINT_RM_DEPS) $(RM) $(DEPS) $(NL)

mostlyclean: depclean
	$(PRINT_RM_OBJECTS) $(RM) $(OBJ)  $(NL)

clean: mostlyclean
	$(PRINT_RM_TARGET) $(RM) $(filter-out %.make, $(TARGET))  $(NL)
	@for external in $(filter %.make,$(TARGET)) ; do $(PRINT_MAKE_EXTERN) $(MAKE_EXTERN) ; done

# This will include in this Makefile all the "sub makefiles" with the depenencies loaded
# Only if not is a "clean" rule (eg. "make clean" or "make depclean")
ifneq (clean,$(findstring clean,$(MAKECMDGOALS)))
-include $(DEPS)
endif

else # EOF of onsubmodule ------------------

ifeq ($(verbose), 0)
   ifeq ($(timeit), 1)
      export TIMEIT = time -f "%E"
   else
      export NL = ; echo ""
   endif

   export ALIGN = 65

   MAKECALL = onsubmodule=1 $(MAKE) -e --no-print-directory -f - -C $@ $(filter-out $@, $(MAKECMDGOALS)) < Makefile
   PRINT_ENTERMAKECALL = @printf "\033[34m%s\n\033[0m" "Entering $@" ;
   PRINT_LEAVEMAKECALL = ; printf "\033[34m%s\n\033[0m" "Leaving $@" ;
   export PRINT_ERROR = @printf "\033[31m%s\n\033[0m"
else
   MAKECALL = onsubmodule=1 $(MAKE) -e -f - -C $@ $(MAKECMDGOALS) < Makefile
   export PRINT_ERROR = @echo
endif


.PHONY: all clean depclean mostlyclean e1 $(SUBMODULES)

ifndef SUBMODULES
e1:
	$(PRINT_ERROR) "The 'SUBMODULES' must be defined (in the Makefile file)"
endif

TOEXECUTE = $(filter $(SUBMODULES), $(MAKECMDGOALS))
ifeq "$(strip $(TOEXECUTE))" ""
  TOEXECUTE = $(SUBMODULES)
endif

all: $(TOEXECUTE)

depclean: $(TOEXECUTE)

clean: $(TOEXECUTE)

mostlyclean: $(TOEXECUTE)

$(TOEXECUTE):
	$(PRINT_ENTERMAKECALL) $(MAKECALL) $(PRINT_LEAVEMAKECALL)

#
# Quick reference
#
# "$@" is the name of the target
# "$?" stores the list of dependents more recent than the target (i.e., those that have changed since the last time make was invoked for the given target).
# "$^" gives you all dependencies of a target (recents or not than the target), without duplicates
# "$+" is like $^, but it keeps duplicates and gives you the entire list of dependencies in the order they appear.
# "$<" only the first dependency
#
# blue: red_unmodified green_modified_recently red_unmodified:
# 	echo $@		# blue
# 	echo $?		# green_modified_recently
# 	echo $^		# red_unmodified green_modified_recently
# 	echo $+		# red_unmodified green_modified_recently red_unmodified
# 	echo $<		# red_unmodified

endif
