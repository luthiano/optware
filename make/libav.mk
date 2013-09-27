###########################################################
#
# libav
#
###########################################################

#
# LIBAV_VERSION, LIBAV_SITE and LIBAV_SOURCE define
# the upstream location of the source code for the package.
# LIBAV_DIR is the directory which is created when the source
# archive is unpacked.
# LIBAV_UNZIP is the command used to unzip the source.
# It is usually "zcat" (for .gz) or "bzcat" (for .bz2)
#
# You should change all these variables to suit your package.
# Please make sure that you add a description, and that you
# list all your packages' dependencies, seperated by commas.
# 
# libav-9.9.tar.gz
LIBAV_SITE=http://www.libav.org/releases/
LIBAV_VERSION=9.9
LIBAV_SOURCE=libav-$(LIBAV_VERSION).tar.gz
LIBAV_DIR=libav-$(LIBAV_VERSION)
LIBAV_UNZIP=zcat
LIBAV_MAINTAINER=Luthiano Vasconcelos <optware@luthiano.com>
LIBAV_DESCRIPTION=Libav is a set of portable, functional and high-performance libraries for dealing with multimedia formats of all sorts.
LIBAV_SECTION=media
LIBAV_PRIORITY=optional
LIBAV_DEPENDS=
LIBAV_SUGGESTS=
LIBAV_CONFLICTS=

#
# LIBAV_IPK_VERSION should be incremented when the ipk changes.
#
LIBAV_IPK_VERSION=1

#
# LIBAV_CONFFILES should be a list of user-editable files
#LIBAV_CONFFILES=/opt/etc/libav.conf /opt/etc/init.d/SXXlibav

#
# LIBAV_PATCHES should list any patches, in the the order in
# which they should be applied to the source code.
#
#LIBAV_PATCHES=$(LIBAV_SOURCE_DIR)/configure.patch

#
# If the compilation of the package requires additional
# compilation or linking flags, then list them here.
#
LIBAV_CPPFLAGS=
LIBAV_LDFLAGS=

#
# LIBAV_BUILD_DIR is the directory in which the build is done.
# LIBAV_SOURCE_DIR is the directory which holds all the
# patches and ipkg control files.
# LIBAV_IPK_DIR is the directory in which the ipk is built.
# LIBAV_IPK is the name of the resulting ipk files.
#
# You should not change any of these variables.
#
LIBAV_BUILD_DIR=$(BUILD_DIR)/libav
LIBAV_SOURCE_DIR=$(SOURCE_DIR)/libav
LIBAV_IPK_DIR=$(BUILD_DIR)/libav-$(LIBAV_VERSION)-ipk
LIBAV_IPK=$(BUILD_DIR)/libav_$(LIBAV_VERSION)-$(LIBAV_IPK_VERSION)_$(TARGET_ARCH).ipk

.PHONY: libav-source libav-unpack libav libav-stage libav-ipk libav-clean libav-dirclean libav-check

#
# This is the dependency on the source code.  If the source is missing,
# then it will be fetched from the site using wget.
#
$(DL_DIR)/$(LIBAV_SOURCE):
	$(WGET) -P $(@D) $(LIBAV_SITE)/$(@F) || \
	$(WGET) -P $(@D) $(SOURCES_NLO_SITE)/$(@F)

#
# The source code depends on it existing within the download directory.
# This target will be called by the top level Makefile to download the
# source code's archive (.tar.gz, .bz2, etc.)
#
libav-source: $(DL_DIR)/$(LIBAV_SOURCE) $(LIBAV_PATCHES)

LIBAV_ARCH=$(strip \
	$(if $(filter armeb, $(TARGET_ARCH)), arm, \
	$(TARGET_ARCH)))

#
# This target unpacks the source code in the build directory.
# If the source archive is not .tar.gz or .tar.bz2, then you will need
# to change the commands here.  Patches to the source code are also
# applied in this target as required.
#
# This target also configures the build within the build directory.
# Flags such as LDFLAGS and CPPFLAGS should be passed into configure
# and NOT $(MAKE) below.  Passing it to configure causes configure to
# correctly BUILD the Makefile with the right paths, where passing it
# to Make causes it to override the default search paths of the compiler.
#
# If the compilation of the package requires other packages to be staged
# first, then do that first (e.g. "$(MAKE) <bar>-stage <baz>-stage").
#
# If the package uses  GNU libtool, you should invoke $(PATCH_LIBTOOL) as
# shown below to make various patches to it.
#
$(LIBAV_BUILD_DIR)/.configured: $(DL_DIR)/$(LIBAV_SOURCE) $(LIBAV_PATCHES) make/libav.mk
	#$(MAKE) <bar>-stage <baz>-stage
	rm -rf $(BUILD_DIR)/$(LIBAV_DIR) $(@D)
	$(LIBAV_UNZIP) $(DL_DIR)/$(LIBAV_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	if test -n "$(LIBAV_PATCHES)" ; \
		then cat $(LIBAV_PATCHES) | \
		patch -d $(BUILD_DIR)/$(LIBAV_DIR) -p0 ; \
	fi
	if test "$(BUILD_DIR)/$(LIBAV_DIR)" != "$(@D)" ; \
		then mv $(BUILD_DIR)/$(LIBAV_DIR) $(@D) ; \
	fi
	(cd $(@D); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS) $(LIBAV_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(LIBAV_LDFLAGS)" \
		./configure \
		--enable-cross-compile \
		--cross-prefix=$(TARGET_CROSS) \
		--arch=$(LIBAV_ARCH) \
		--target-os=linux \
		$(LIBAV_CONFIG_OPTS) \
		--disable-encoder=snow \
		--disable-decoder=snow \
		--enable-shared \
		--disable-static \
		--enable-gpl \
		--prefix=/opt \
	)
	#$(PATCH_LIBTOOL) $(@D)/libtool
	touch $@

libav-unpack: $(LIBAV_BUILD_DIR)/.configured

#
# This builds the actual binary.
#
$(LIBAV_BUILD_DIR)/.built: $(LIBAV_BUILD_DIR)/.configured
	rm -f $@
	$(MAKE) -C $(@D)
	touch $@

#
# This is the build convenience target.
#
libav: $(LIBAV_BUILD_DIR)/.built

#
# If you are building a library, then you need to stage it too.
#
$(LIBAV_BUILD_DIR)/.staged: $(LIBAV_BUILD_DIR)/.built
	rm -f $@
	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install

	rm -rf $(STAGING_INCLUDE_DIR)/libav
	$(MAKE) -C $(@D) install \
		mandir=$(STAGING_DIR)/opt/man \
		bindir=$(STAGING_DIR)/opt/bin \
		prefix=$(STAGING_DIR)/opt \
		DESTDIR=$(STAGING_DIR)
	install -d $(STAGING_INCLUDE_DIR)/libav
	cp -p	$(STAGING_INCLUDE_DIR)/libavcodec/* \
		$(STAGING_INCLUDE_DIR)/libavformat/* \
		$(STAGING_INCLUDE_DIR)/libavutil/* 
	sed -i -e 's|^prefix=.*|prefix=$(STAGING_PREFIX)|' \
		$(STAGING_LIB_DIR)/pkgconfig/libavcodec.pc \
		$(STAGING_LIB_DIR)/pkgconfig/libavformat.pc \
		$(STAGING_LIB_DIR)/pkgconfig/libavutil.pc 
	touch $@


libav-stage: $(LIBAV_BUILD_DIR)/.staged

#
# This rule creates a control file for ipkg.  It is no longer
# necessary to create a seperate control file under sources/libav
#
$(LIBAV_IPK_DIR)/CONTROL/control:
	@install -d $(@D)
	@rm -f $@
	@echo "Package: libav" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(LIBAV_PRIORITY)" >>$@
	@echo "Section: $(LIBAV_SECTION)" >>$@
	@echo "Version: $(LIBAV_VERSION)-$(LIBAV_IPK_VERSION)" >>$@
	@echo "Maintainer: $(LIBAV_MAINTAINER)" >>$@
	@echo "Source: $(LIBAV_SITE)/$(LIBAV_SOURCE)" >>$@
	@echo "Description: $(LIBAV_DESCRIPTION)" >>$@
	@echo "Depends: $(LIBAV_DEPENDS)" >>$@
	@echo "Suggests: $(LIBAV_SUGGESTS)" >>$@
	@echo "Conflicts: $(LIBAV_CONFLICTS)" >>$@

#
# This builds the IPK file.
#
# Binaries should be installed into $(LIBAV_IPK_DIR)/opt/sbin or $(LIBAV_IPK_DIR)/opt/bin
# (use the location in a well-known Linux distro as a guide for choosing sbin or bin).
# Libraries and include files should be installed into $(LIBAV_IPK_DIR)/opt/{lib,include}
# Configuration files should be installed in $(LIBAV_IPK_DIR)/opt/etc/libav/...
# Documentation files should be installed in $(LIBAV_IPK_DIR)/opt/doc/libav/...
# Daemon startup scripts should be installed in $(LIBAV_IPK_DIR)/opt/etc/init.d/S??libav
#
# You may need to patch your application to make it use these locations.
#
$(LIBAV_IPK): $(LIBAV_BUILD_DIR)/.built
	rm -rf $(LIBAV_IPK_DIR) $(BUILD_DIR)/libav_*_$(TARGET_ARCH).ipk
	$(MAKE) -C $(LIBAV_BUILD_DIR) DESTDIR=$(LIBAV_IPK_DIR) install
#	install -d $(LIBAV_IPK_DIR)/opt/etc/
#	install -m 644 $(LIBAV_SOURCE_DIR)/libav.conf $(LIBAV_IPK_DIR)/opt/etc/libav.conf
#	install -d $(LIBAV_IPK_DIR)/opt/etc/init.d
#	install -m 755 $(LIBAV_SOURCE_DIR)/rc.libav $(LIBAV_IPK_DIR)/opt/etc/init.d/SXXlibav
#	sed -i -e '/^#!/aOPTWARE_TARGET=${OPTWARE_TARGET}' $(LIBAV_IPK_DIR)/opt/etc/init.d/SXXlibav
	$(MAKE) $(LIBAV_IPK_DIR)/CONTROL/control
#	install -m 755 $(LIBAV_SOURCE_DIR)/postinst $(LIBAV_IPK_DIR)/CONTROL/postinst
#	sed -i -e '/^#!/aOPTWARE_TARGET=${OPTWARE_TARGET}' $(LIBAV_IPK_DIR)/CONTROL/postinst
#	install -m 755 $(LIBAV_SOURCE_DIR)/prerm $(LIBAV_IPK_DIR)/CONTROL/prerm
#	sed -i -e '/^#!/aOPTWARE_TARGET=${OPTWARE_TARGET}' $(LIBAV_IPK_DIR)/CONTROL/prerm
#	if test -n "$(UPD-ALT_PREFIX)"; then \
		sed -i -e '/^[ 	]*update-alternatives /s|update-alternatives|$(UPD-ALT_PREFIX)/bin/&|' \
			$(LIBAV_IPK_DIR)/CONTROL/postinst $(LIBAV_IPK_DIR)/CONTROL/prerm; \
	fi
	echo $(LIBAV_CONFFILES) | sed -e 's/ /\n/g' > $(LIBAV_IPK_DIR)/CONTROL/conffiles
	cd $(BUILD_DIR); $(IPKG_BUILD) $(LIBAV_IPK_DIR)
	$(WHAT_TO_DO_WITH_IPK_DIR) $(LIBAV_IPK_DIR)

#
# This is called from the top level makefile to create the IPK file.
#
libav-ipk: $(LIBAV_IPK)

#
# This is called from the top level makefile to clean all of the built files.
#
libav-clean:
	rm -f $(LIBAV_BUILD_DIR)/.built
	-$(MAKE) -C $(LIBAV_BUILD_DIR) clean

#
# This is called from the top level makefile to clean all dynamically created
# directories.
#
libav-dirclean:
	rm -rf $(BUILD_DIR)/$(LIBAV_DIR) $(LIBAV_BUILD_DIR) $(LIBAV_IPK_DIR) $(LIBAV_IPK)
#
#
# Some sanity check for the package.
#
libav-check: $(LIBAV_IPK)
	perl scripts/optware-check-package.pl --target=$(OPTWARE_TARGET) $^
