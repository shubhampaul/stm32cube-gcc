# STM32 Makefile for GNU toolchain and openocd
#
# This Makefile fetches the Cube firmware package from ST's' website.
# This includes: CMSIS, STM32 HAL, BSPs, USB drivers and examples.
#
# Usage:
#	make cube		Download and unzip Cube firmware
#	make program		Flash the board with OpenOCD
#	make openocd		Start OpenOCD
#	make debug		Start GDB and attach to OpenOCD
#	make dirs		Create subdirs like obj, dep, ..
#	make template		Prepare a simple example project in this dir
#
# Copyright	2015 Steffen Vogel
# License	http://www.gnu.org/licenses/gpl.txt GNU Public License
# Author	Steffen Vogel <post@steffenvogel.de>
# Link		http://www.steffenvogel.de
#
# edited for the STM32F4-Discovery

#Username
USERNAME=$(shell whoami)

# A name common to all output files (elf, map, hex, bin, lst)
TARGET     = demo

# Take a look into $(CUBE_DIR)/Drivers/BSP for available BSPs
# name needed in upper case and lower case
BOARD      = STM32F429I-Discovery
BOARD_UC   = STM32F429I-Discovery
BOARD_LC   = stm32f429i_discovery
BSP_BASE   = $(BOARD_LC)

OCDFLAGS   = -f board/stm32f4discovery.cfg
GDBFLAGS   =

#EXAMPLE   = Templates
EXAMPLE    = Applications/Display/LTDC_Paint

# MCU family and type in various capitalizations o_O
MCU_FAMILY = stm32f4xx
MCU_LC     = stm32f429xx
MCU_MC     = STM32F429xx
MCU_UC     = STM32F429ZI

# path of the ld-file inside the example directories
LDFILE     = $(EXAMPLE)/SW4STM32/$(BOARD_UC)/$(MCU_UC)Tx_FLASH.ld

#LDFILE     = $(EXAMPLE)/TrueSTUDIO/$(BOARD_UC)/$(MCU_UC)_FLASH.ld

# Your C files from the /src directory
SRCS       = main.c
SRCS      += system_$(MCU_FAMILY).c
SRCS      += stm32f4xx_it.c

# Basic HAL libraries
SRCS      += stm32f4xx_hal_rcc.c stm32f4xx_hal_rcc_ex.c stm32f4xx_hal.c stm32f4xx_hal_hcd.c stm32f4xx_hal_cortex.c stm32f4xx_hal_gpio.c stm32f4xx_hal_pwr_ex.c $(BSP_BASE).c stm32f4xx_ll_usb.c stm32f4xx_hal_ltdc.c stm32f4xx_ll_fmc.c stm32f4xx_hal_dma.c stm32f4xx_hal_spi.c stm32f4xx_hal_i2c.c

#LCD and Touch Hal
SRCS      += $(BSP_BASE)_lcd.c $(BSP_BASE)_ts.c ts_calibration.c

#SDRAM
SRCS      += $(BSP_BASE)_sdram.c stm32f4xx_hal_sdram.c

#BSP Component Drivers
SRCS      += ili9341.c stmpe811.c

#FatFs HAL
SRCS      += ff.c ff_gen_drv.c diskio.c

#USB_Host HAL
SRCS      += usbh_diskio_dma.c usbh_core.c usbh_msc.c usbh_conf.c usbh_pipes.c usbh_ctlreq.c usbh_core.c usbh_ioreq.c usbh_msc_scsi.c usbh_msc_bot.c

#DMA2D HAL
SRCS      += stm32f4xx_hal_dma2d.c

# Directories
OCD_FOL    = /home/$(USERNAME)/workspace/stm/openocd/0.10.0-13
OCD_DIR    = $(OCD_FOL)/scripts

CUBE_DIR   = STM32Cube_FW_F4_V1.25.0

BSP_DIR    		= $(CUBE_DIR)/Drivers/BSP/$(BOARD_UC)
BSP_COMP_DIR            = $(CUBE_DIR)/Drivers/BSP/Components
HAL_DIR    		= $(CUBE_DIR)/Drivers/STM32F4xx_HAL_Driver
CMSIS_DIR  		= $(CUBE_DIR)/Drivers/CMSIS
FATFS_DIR 		= $(CUBE_DIR)/Middlewares/Third_Party/FatFs
USB_HOST_CORE_DIR       = $(CUBE_DIR)/Middlewares/ST/STM32_USB_Host_Library/Core
USB_HOST_MSC_DIR        = $(CUBE_DIR)/Middlewares/ST/STM32_USB_Host_Library/Class/MSC

DEV_DIR    = $(CMSIS_DIR)/Device/ST/STM32F4xx

# that's it, no need to change anything below this line!

###############################################################################
# Toolchain

TOOLCHAIN_DIR  = /home/$(USERNAME)/workspace/stm/toolchain/gcc-arm-embedded/gcc-arm-none-eabi-9-2019-q4-major/bin

PREFIX         = $(TOOLCHAIN_DIR)/arm-none-eabi
CC             = $(PREFIX)-gcc
AR             = $(PREFIX)-ar
OBJCOPY        = $(PREFIX)-objcopy
OBJDUMP        = $(PREFIX)-objdump
SIZE           = $(PREFIX)-size
GDB            = $(PREFIX)-gdb

OCD            = $(OCD_FOL)/bin/openocd

###############################################################################
# Options

# Defines
DEFS       = -D$(MCU_MC) -DUSE_HAL_DRIVER

# Debug specific definitions for semihosting
DEFS       += -DUSE_DBPRINTF

# Include search paths (-I)
INCS       = -Isrc
INCS      += -I$(BSP_DIR)
INCS      += -I$(BSP_COMP_DIR)/ili9341
INCS      += -I$(BSP_COMP_DIR)/stmpe811
INCS      += -I$(CMSIS_DIR)/Include
INCS      += -I$(DEV_DIR)/Include
INCS      += -I$(HAL_DIR)/Inc
INCS      += -I$(EXAMPLE)/Inc
INCS      += -I$(FATFS_DIR)/src
INCS      += -I$(USB_HOST_CORE_DIR)/Inc
INCS      += -I$(USB_HOST_MSC_DIR)/Inc

# Library search paths
LIBS       = -L$(CMSIS_DIR)/Lib/GCC

# Compiler flags
CFLAGS     = -Wall -g -std=c99 -Os
CFLAGS    += -mlittle-endian -mcpu=cortex-m4 -march=armv7e-m -mthumb
CFLAGS    += -mfpu=fpv4-sp-d16 -mfloat-abi=hard
CFLAGS    += -ffunction-sections -fdata-sections
CFLAGS    += $(INCS) $(DEFS)

# Linker flags
LDFLAGS    = -Wl,--gc-sections -Wl,-Map=$(TARGET).map $(LIBS) -T$(MCU_LC).ld

# Enable Semihosting
LDFLAGS   += --specs=rdimon.specs -lc -lrdimon

# Source search paths
VPATH      = ./src
VPATH     += $(BSP_DIR)
VPATH     += $(BSP_COMP_DIR)/ili9341
VPATH     += $(BSP_COMP_DIR)/stmpe811
VPATH     += $(HAL_DIR)/Src
VPATH     += $(DEV_DIR)/Source/
VPATH     += $(FATFS_DIR)/src
VPATH     += $(USB_HOST_CORE_DIR)/Src
VPATH     += $(USB_HOST_MSC_DIR)/Src

OBJS       = $(addprefix obj/,$(SRCS:.c=.o))
DEPS       = $(addprefix dep/,$(SRCS:.c=.d))

# Prettify output
V = 0
ifeq ($V, 0)
	Q = @
	P = > /dev/null
endif

###################################################

.PHONY: all dirs program debug template clean

all: $(TARGET).bin

-include $(DEPS)

dirs: dep obj cube
dep obj src:
	@echo "[MKDIR]   $@"
	$Qmkdir -p $@

obj/%.o : %.c | dirs
	@echo "[CC]      $(notdir $<)"
	$Q$(CC) $(CFLAGS) -c -o $@ $< -MMD -MF dep/$(*F).d

$(TARGET).elf: $(OBJS)
	@echo "[LD]      $(TARGET).elf"
	$Q$(CC) $(CFLAGS) $(LDFLAGS) src/startup_$(MCU_LC).s $^ -o $@
	@echo "[OBJDUMP] $(TARGET).lst"
	$Q$(OBJDUMP) -St $(TARGET).elf >$(TARGET).lst
	@echo "[SIZE]    $(TARGET).elf"
	$(SIZE) $(TARGET).elf

$(TARGET).bin: $(TARGET).elf
	@echo "[OBJCOPY] $(TARGET).bin"
	$Q$(OBJCOPY) -O binary $< $@

openocd:
	$(OCD) -s $(OCD_DIR) $(OCDFLAGS)

program: all
	$(OCD) -s $(OCD_DIR) $(OCDFLAGS) -c "program $(TARGET).elf verify reset"

debug:
	@if ! nc -z localhost 3333; then \
		echo "\n\t[Error] OpenOCD is not running! Start it with: 'make openocd'\n"; exit 1; \
	else \
		$(GDB)  -ex "target extended localhost:3333" \
			-ex "monitor arm semihosting enable" \
			-ex "monitor reset halt" \
			-ex "load" \
			-ex "monitor reset init" \
			$(GDBFLAGS) $(TARGET).elf; \
	fi

cube:
	rm -fr $(CUBE_DIR)
	unzip cube.zip
	chmod -R u+w $(CUBE_DIR)

template: cube src
	cp -ri $(CUBE_DIR)/Projects/$(BOARD)/$(EXAMPLE)/Src/* src
	cp -ri $(CUBE_DIR)/Projects/$(BOARD)/$(EXAMPLE)/Inc/* src
	cp -i $(DEV_DIR)/Source/Templates/gcc/startup_$(MCU_LC).s src
	cp -i $(CUBE_DIR)/Projects/$(BOARD)/$(LDFILE) $(MCU_LC).ld

clean:
	@echo "[RM]      $(TARGET).bin"; rm -f $(TARGET).bin
	@echo "[RM]      $(TARGET).elf"; rm -f $(TARGET).elf
	@echo "[RM]      $(TARGET).map"; rm -f $(TARGET).map
	@echo "[RM]      $(TARGET).lst"; rm -f $(TARGET).lst
	@echo "[RMDIR]   dep"          ; rm -fr dep
	@echo "[RMDIR]   obj"          ; rm -fr obj

