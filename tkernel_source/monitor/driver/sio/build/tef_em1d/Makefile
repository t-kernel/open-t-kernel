#
# ----------------------------------------------------------------------
#     T-Kernel 2.0 Software Package
#
#     Copyright 2011 by Ken Sakamura.
#     This software is distributed under the latest version of T-License 2.x.
# ----------------------------------------------------------------------
#
#     Released by T-Engine Forum(http://www.t-engine.org/) at 2011/05/17.
#     Modified by T-Engine Forum at 2012/11/07.
#     Modified by T-Engine Forum at 2013/02/20.
#     Modified by TRON Forum(http://www.tron.org/) at 2015/06/01.
#
# ----------------------------------------------------------------------
#

#	T-Monitor : sio (em1d)

MACHINE = em1d
TETYPE = tef

SRC_SYSDEP = imx28x.c

# ----------------------------------------------------------------------------

DEPS = Dependencies
DEPENDENCIES_OUTPUT := $(DEPS)

include $(BD)/etc/makerules

TMONITOR_INSTALLDIR = $(BD)/monitor/bin/$(TETYPE)_$(MACHINE)

HEADER = $(BD)/include $(BD)/monitor/include

# ----------------------------------------------------------------------------

TARGET = sio

S = ../../src

VPATH = $(S)
HEADER += $(S)

SRC =
SRC += $(SRC_SYSDEP)

OBJ = $(addsuffix .o, $(basename $(SRC)))

CFLAGS += $(CFLAGS_WARNING)

# ----------------------------------------------------------------------------

.PHONY: all clean install

ALL = $(TARGET).o

all: $(ALL)

$(TARGET).o: $(OBJ)
	$(LINK_R.o) $^ $(OUTPUT_OPTION)

clean:
	$(RM) $(OBJ) $(ALL) $(DEPS)

install: $(addprefix $(TMONITOR_INSTALLDIR)/, $(ALL))

$(TMONITOR_INSTALLDIR)/%: %
	$(BD)/etc/backup_copy -t -d !OLD $< $(TMONITOR_INSTALLDIR)

ifdef DEPENDENCIES_OUTPUT
  $(DEPS): ; touch $(DEPS)
else
  $(DEPS): $(SRC) ; $(MAKEDEPS) $@ $?
endif
-include $(DEPS)
