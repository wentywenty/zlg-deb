KERNEL_REL := $(shell uname -r)

IS_RDK := $(shell which hrut_socuid >/dev/null 2>&1 && echo 1 || echo 0)

ifeq ($(IS_RDK),1)
  KDIR := $(shell if [ -d /usr/src/linux-headers-$(KERNEL_REL) ]; then \
    echo /usr/src/linux-headers-$(KERNEL_REL); \
  else \
    ls -d /usr/src/linux-headers-*rt* 2>/dev/null | head -1; \
  fi)
  $(info RDK X5 detected via hrut_socuid, KDIR=$(KDIR))
else
  KDIR := /lib/modules/$(KERNEL_REL)/build
endif

obj-m := usbcanfd.o

all: module

module:
	@if [ ! -d "$(KDIR)" ]; then \
		echo "ERROR: Kernel headers not found at $(KDIR)" >&2; \
		echo "" >&2; \
		echo "Install the matching kernel headers package, for example:" >&2; \
		echo "  Ubuntu/Debian:   apt install linux-headers-$(KERNEL_REL)" >&2; \
		echo "  RDK X5/Rockchip: apt install linux-headers-current-rockchip-rk3588" >&2; \
		echo "  Or search:       apt search linux-headers | grep $(KERNEL_REL)" >&2; \
		exit 1; \
	fi
	@if [ ! -f "$(KDIR)/scripts/basic/fixdep" ]; then \
		echo "Preparing kernel build tools (make ARCH=arm64 scripts)..." >&2; \
		make -C $(KDIR) ARCH=arm64 scripts; \
	fi
	make -C $(KDIR) M=$(PWD) modules

clean:
	@if [ -d "$(KDIR)" ]; then \
		make -C $(KDIR) M=$(PWD) clean; \
	fi

.PHONY: all module clean
