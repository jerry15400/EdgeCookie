AR     ?= ar
LLC    ?= llc
CLANG  ?= clang
CC     ?= gcc

# Configure paths of locally built dependencies
LIB_DIR := ./xdp-tools/lib
LIBXDP_DIR := $(LIB_DIR)/libxdp
LIBXDP_SOURCES = $(wildcard $(LIBXDP_DIR)/*.[ch] $(LIBXDP_DIR)/*.in)
OBJECT_LIBXDP := $(LIBXDP_DIR)/libxdp.a
LIBXDP_INCLUDE_DIR := $(LIB_DIR)/../headers
LIBBPF_DIR := $(LIB_DIR)/libbpf/src
LIBBPF_SOURCES = $(wildcard $(LIBBPF_DIR)/*.[ch])
OBJECT_LIBBPF := $(LIBBPF_DIR)/libbpf.a
LIBBPF_INCLUDE_DIR := $(LIBBPF_DIR)/root/usr/include


# Allows to pass additional cflags from the make command
override CFLAGS += -I./src -I./headers -I$(LIBXDP_INCLUDE_DIR) -I$(EXAMPLES_DIR) \
				   -I$(LIBBPF_INCLUDE_DIR) -I./examples/common -O3 -flto -march=native  -fomit-frame-pointer


DEBUG_CFLAGS := -DDEBUG
# Configure library paths
XSKNF_DIR    := ./src
XSKNF_H      := $(XSKNF_DIR)/xsknf.h
XSKNF_C      := $(XSKNF_DIR)/xsknf.c
XSKNF_O      := ${XSKNF_C:.c=.o}
XSKNF_TARGET := $(XSKNF_DIR)/libxsknf.a

EXAMPLES := htscookie/switch_agent		\
			htscookie/server_in			\
			htscookie/server_en			\
			htscookie/client_in			\
			htscookie/client_en			\
			smartcookie/switch_agent 	\
			smartcookie/server_in		\
			smartcookie/server_en		\
			# lbfw/lbfw					\
			# test_memory/test_memory


EXAMPLES_DIR     := ./examples
EXAMPLES_TARGETS := $(addprefix $(EXAMPLES_DIR)/,$(EXAMPLES))
EXAMPLES_USER	 := $(addsuffix _user.o,$(EXAMPLES_TARGETS))
EXAMPLES_KERN    := $(addsuffix _kern.o,$(EXAMPLES_TARGETS))
EXAMPLES_LD      := -L./src/ -lxsknf -L$(LIBXDP_DIR) -l:libxdp.a \
					-L$(LIBBPF_DIR) -l:libbpf.a -lelf -lz -lpthread -lmnl
EXAMPLES_COMMON  := $(EXAMPLES_DIR)/common/statistics.o \
					$(EXAMPLES_DIR)/common/utils.o \
					$(EXAMPLES_DIR)/common/khashmap.o\
					$(EXAMPLES_DIR)/common/crc32.o\
					$(EXAMPLES_DIR)/common/fnv.o\
					$(EXAMPLES_DIR)/common/haraka.o\
					$(EXAMPLES_DIR)/common/murmur.o\
					$(EXAMPLES_DIR)/common/timeit.o\
					$(EXAMPLES_DIR)/common/timestamp.o\
					$(EXAMPLES_DIR)/common/csum.o\
					$(EXAMPLES_DIR)/common/bloom.o\
					$(EXAMPLES_DIR)/common/bitutil.o\
					$(EXAMPLES_DIR)/common/hashf.o
					

EXAMPLES_COMMON_TEST  := 	$(EXAMPLES_DIR)/common/haraka.o\
							$(EXAMPLES_DIR)/common/murmur.o\
							$(EXAMPLES_DIR)/common/fnv.o\
							$(EXAMPLES_DIR)/common/crc32.o



.PHONY: update_submodules clean $(CLANG) $(LLC)

all: llvm-check update_submodules $(XSKNF_TARGET) $(EXAMPLES_TARGETS) test


update_submodules:
	git submodule update --init --recursive



clean:
	# $(MAKE) -C ./xdp-tools clean
	$(RM) $(XSKNF_O)
	$(RM) $(XSKNF_TARGET)
	$(RM) $(EXAMPLES_USER)
	$(RM) $(EXAMPLES_TARGETS)
	$(RM) $(EXAMPLES_KERN)
	$(RM) $(EXAMPLES_COMMON)
	
	$(RM) ./examples/htscookie/test

llvm-check: $(CLANG) $(LLC)
	@for TOOL in $^ ; do \
		if [ ! $$(command -v $${TOOL} 2>/dev/null) ]; then \
			echo "*** ERROR: Cannot find tool $${TOOL}" ;\
			exit 1; \
		else true; fi; \
	done

$(OBJECT_LIBBPF): update_submodules $(LIBBPF_SOURCES)
	$(MAKE) -C $(LIB_DIR) libbpf

$(OBJECT_LIBXDP): update_submodules $(LIBXDP_SOURCES)
	$(MAKE) -C ./xdp-tools libxdp

$(XSKNF_O): $(XSKNF_C) $(XSKNF_H) $(OBJECT_LIBXDP) $(OBJECT_LIBBPF)

$(XSKNF_TARGET): $(XSKNF_O)
	$(AR) r -o $@ $(XSKNF_O)

$(EXAMPLES_KERN): %_kern.o: %_kern.c %.h $(OBJECT_LIBBPF) ./examples/htscookie/server.h ./examples/smartcookie/server.h 
	$(CLANG) -S \
		-target bpf \
		-Wall \
		-Wno-unused-value \
		-Wno-pointer-sign \
		-Wno-compare-distinct-pointer-types \
		-Werror \
		$(CFLAGS) \
		-emit-llvm -c -g -o ${@:.o=.ll} $<
	$(LLC) -march=bpf  -filetype=obj -o $@ ${@:.o=.ll}
	$(RM) ${@:.o=.ll}

# Too lazy to set .o rule, so remove user.o every time, it will recompile for every make command.
$(EXAMPLES_TARGETS): %: %_user.o %_kern.o %.h $(EXAMPLES_COMMON) $(XSKNF_TARGET) $(EXAMPLES_DIR)/common/address.h
	$(CC) $@_user.o $(EXAMPLES_COMMON) -o $@ $(EXAMPLES_LD) $(CFLAGS) -funroll-all-loops
	rm $@_user.o

test: ./examples/htscookie/test.c $(EXAMPLES_COMMON)
	$(CC) ./examples/htscookie/test.c $(EXAMPLES_COMMON_TEST) -o ./examples/htscookie/test $(CFLAGS) -funroll-all-loops
