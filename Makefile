# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2021-2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk

PKG_NAME:=rkbin
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://github.com/sbwml/rkbin
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2023-08-17
PKG_SOURCE_VERSION:=1a417bbf7d05c3491ee9613be12a9905fbb8ccb7
PKG_MIRROR_HASH:=458301399fd5c64bc491cce6ea3cdd4c5ec29aae5b8e613d539feb03b74981a7
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_DATE).tar.gz

include $(INCLUDE_DIR)/package.mk
include ./atf-version.mk

define Trusted-Firmware-A/Default
  NAME:=Rockchip $(1)
  BUILD_TARGET:=rockchip
endef

define Trusted-Firmware-A/rk3328
  BUILD_SUBTARGET:=armv8
  ATF:=rk33/$(RK3328_ATF)
  DDR:=rk33/$(RK3328_DDR)
  LOADER:=rk33/$(RK3328_LOADER)
endef

define Trusted-Firmware-A/rk3399
  BUILD_SUBTARGET:=armv8
  ATF:=rk33/$(RK3399_ATF)
  DDR:=rk33/$(RK3399_DDR)
  LOADER:=rk33/$(RK3399_LOADER)
endef

define Trusted-Firmware-A/rk3568
  BUILD_SUBTARGET:=armv8
  ATF:=rk35/$(RK3568_ATF)
  DDR:=rk35/$(RK3568_DDR)
endef

define Trusted-Firmware-A/rk3588
  BUILD_SUBTARGET:=armv8
  ATF:=rk35/$(RK3588_ATF)
  DDR:=rk35/$(RK3588_DDR)
endef

TFA_TARGETS:= \
	rk3328 \
	rk3399 \
	rk3568 \
	rk3588

define Build/Compile
	# This comment is the workaround for "extraneous 'endif'" error
ifneq ($(filter rk33%,$(BUILD_VARIANT)),)
	( \
		pushd $(PKG_BUILD_DIR) ; \
		$(SED) 's,$$$$(PKG_BUILD_DIR),$(PKG_BUILD_DIR),g' trust.ini ; \
		$(SED) 's,$$$$(VARIANT),$(BUILD_VARIANT),g' trust.ini ; \
		./tools/mkimage -n $(BUILD_VARIANT) -T rksd -d bin/$(DDR) \
			$(BUILD_VARIANT)-idbloader.bin ; \
		cat bin/$(LOADER) >> $(BUILD_VARIANT)-idbloader.bin ; \
		./tools/trust_merger --replace bl31.elf bin/$(ATF) trust.ini ; \
		popd ; \
	)
endif
endef

define Package/trusted-firmware-a/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)

	$(CP) $(PKG_BUILD_DIR)/bin/$(ATF) $(STAGING_DIR_IMAGE)/
ifneq ($(filter rk33%,$(BUILD_VARIANT)),)
	$(CP) $(PKG_BUILD_DIR)/tools/loaderimage $(STAGING_DIR_IMAGE)/
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)-idbloader.bin $(STAGING_DIR_IMAGE)/
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)-trust.bin $(STAGING_DIR_IMAGE)/
else ifneq ($(filter rk35%,$(BUILD_VARIANT)),)
	$(CP) $(PKG_BUILD_DIR)/bin/$(DDR) $(STAGING_DIR_IMAGE)/
endif
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
