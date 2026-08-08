include $(TOPDIR)/rules.mk

PKG_NAME:=ufpm
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=Brent Hepburn <brent@hepburn.us>

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ufpm
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Device fingerprinting daemon
  DEPENDS:=+ucode +ucode-mod-fs +ucode-mod-struct +ucode-mod-rtnl +ucode-mod-ubus +ucode-mod-uloop +libubox +unetmsg +uclient-fetch
endef

define Package/ufpm/description
  ufpm identifies connected network devices by matching their MAC address
  against IEEE OUI vendor databases. More specific prefixes score higher
  and the first match in priority order wins.

  This package contains the ufpmd daemon and the uht ucode extension module.
  OUI vendor databases are fetched and compiled at runtime on first boot.
endef

define Package/ufpm/install
	$(INSTALL_DIR) $(1)/usr/lib/ucode $(1)/usr/share/ufpm/db
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/lib/ucode/uht.so $(1)/usr/lib/ucode/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,ufpm))
