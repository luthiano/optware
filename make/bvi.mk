###########################################################
#
# bvi
#
###########################################################

BVI_VERSION=1.3.2
BVI_SITE=http://sourceforge.net/projects/bvi/files/bvi/$(BVI_VERSION)/
BVI_SOURCE=bvi-$(BVI_VERSION).src.tar.gz
BVI_DIR=bvi-$(BVI_VERSION)
BVI_UNZIP=zcat
BVI_MAINTAINER=Luthiano Vasconcelos <optware@luthiano.com>
BVI_DESCRIPTION=The bvi is a display-oriented editor for binary files.
BVI_SECTION=editor
BVI_PRIORITY=optional
BVI_DEPENDS=ncurses
BVI_SUGGESTS=
BVI_CONFLICTS=
BVI_IPK_VERSION=1

#
# BVI_CONFFILES should be a list of user-editable files
#BVI_CONFFILES=/opt/etc/bvi.conf /opt/etc/init.d/SXXbvi

#
# If the compilation of the package requires additional
# compilation or linking flags, then list them here.
#
BVI_CPPFLAGS=-I$(STAGING_INCLUDE_DIR)/ncurses
BVI_LDFLAGS=

#
# BVI_BUILD_DIR is the directory in which the build is done.
# BVI_SOURCE_DIR is the directory which holds all the
# patches and ipkg control files.
# BVI_IPK_DIR is the directory in which the ipk is built.
# BVI_IPK is the name of the resulting ipk files.
#
# You should not change any of these variables.
#
BVI_BUILD_DIR=$(BUILD_DIR)/bvi
BVI_SOURCE_DIR=$(SOURCE_DIR)/bvi
BVI_IPK_DIR=$(BUILD_DIR)/bvi-$(BVI_VERSION)-ipk
BVI_IPK=$(BUILD_DIR)/bvi_$(BVI_VERSION)-$(BVI_IPK_VERSION)_$(TARGET_ARCH).ipk

.PHONY: bvi-source bvi-unpack bvi bvi-stage bvi-ipk bvi-clean bvi-dirclean bvi-check

#
# This is the dependency on the source code.  If the source is missing,
# then it will be fetched from the site using wget.
#
$(DL_DIR)/$(BVI_SOURCE):
	$(WGET) -P $(@D) $(BVI_SITE)/$(@F) || \
	$(WGET) -P $(@D) $(SOURCES_NLO_SITE)/$(@F)

#
# The source code depends on it existing within the download directory.
# This target will be called by the top level Makefile to download the
# source code's archive (.tar.gz, .bz2, etc.)
#
bvi-source: $(DL_DIR)/$(BVI_SOURCE) $(BVI_PATCHES)

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
$(BVI_BUILD_DIR)/.configured: $(DL_DIR)/$(BVI_SOURCE) $(BVI_PATCHES) make/bvi.mk
	$(MAKE) ncurses-stage
	rm -rf $(BUILD_DIR)/$(BVI_DIR) $(@D)
	$(BVI_UNZIP) $(DL_DIR)/$(BVI_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	if test -n "$(BVI_PATCHES)" ; \
		then cat $(BVI_PATCHES) | \
		patch -d $(BUILD_DIR)/$(BVI_DIR) -p0 ; \
	fi
	if test "$(BUILD_DIR)/$(BVI_DIR)" != "$(@D)" ; \
		then mv $(BUILD_DIR)/$(BVI_DIR) $(@D) ; \
	fi
	(cd $(@D); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS) $(BVI_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(BVI_LDFLAGS)" \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=/opt \
		--disable-nls \
		--disable-static \
	)
#	$(PATCH_LIBTOOL) $(@D)/libtool
	touch $@

bvi-unpack: $(BVI_BUILD_DIR)/.configured

#
# This builds the actual binary.
#
$(BVI_BUILD_DIR)/.built: $(BVI_BUILD_DIR)/.configured
	rm -f $@
	$(MAKE) -C $(@D) \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS) $(BVI_CPPFLAGS)" \
		OPTS="$(STAGING_CPPFLAGS) $(BVI_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(BVI_LDFLAGS)" \
		LIBS=-lncurses \
		$(BVI_MAKE_OPTS) \
		;
	touch $@

#
# This is the build convenience target.
#
bvi: $(BVI_BUILD_DIR)/.built

#
# If you are building a library, then you need to stage it too.
#
#$(BVI_BUILD_DIR)/.staged: $(BVI_BUILD_DIR)/.built
#	rm -f $@
#	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install
#	touch $@
#
#bvi-stage: $(BVI_BUILD_DIR)/.staged

#
# This rule creates a control file for ipkg.  It is no longer
# necessary to create a seperate control file under sources/bvi
#
$(BVI_IPK_DIR)/CONTROL/control:
	@install -d $(@D)
	@rm -f $@
	@echo "Package: bvi" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(BVI_PRIORITY)" >>$@
	@echo "Section: $(BVI_SECTION)" >>$@
	@echo "Version: $(BVI_VERSION)-$(BVI_IPK_VERSION)" >>$@
	@echo "Maintainer: $(BVI_MAINTAINER)" >>$@
	@echo "Source: $(BVI_SITE)/$(BVI_SOURCE)" >>$@
	@echo "Description: $(BVI_DESCRIPTION)" >>$@
	@echo "Depends: $(BVI_DEPENDS)" >>$@
	@echo "Suggests: $(BVI_SUGGESTS)" >>$@
	@echo "Conflicts: $(BVI_CONFLICTS)" >>$@

#
# This builds the IPK file.
#
# Binaries should be installed into $(BVI_IPK_DIR)/opt/sbin or $(BVI_IPK_DIR)/opt/bin
# (use the location in a well-known Linux distro as a guide for choosing sbin or bin).
# Libraries and include files should be installed into $(BVI_IPK_DIR)/opt/{lib,include}
# Configuration files should be installed in $(BVI_IPK_DIR)/opt/etc/bvi/...
# Documentation files should be installed in $(BVI_IPK_DIR)/opt/doc/bvi/...
# Daemon startup scripts should be installed in $(BVI_IPK_DIR)/opt/etc/init.d/S??bvi
#
# You may need to patch your application to make it use these locations.
#
$(BVI_IPK): $(BVI_BUILD_DIR)/.built
	rm -rf $(BVI_IPK_DIR) $(BUILD_DIR)/bvi_*_$(TARGET_ARCH).ipk
	$(MAKE) -C $(BVI_BUILD_DIR) DESTDIR=$(BVI_IPK_DIR) 
#	install -d $(BVI_IPK_DIR)/opt/etc/
#	install -m 644 $(BVI_SOURCE_DIR)/bvi.conf $(BVI_IPK_DIR)/opt/etc/bvi.conf
#	install -d $(BVI_IPK_DIR)/opt/etc/init.d
#	install -m 755 $(BVI_SOURCE_DIR)/rc.bvi $(BVI_IPK_DIR)/opt/etc/init.d/SXXbvi
#	sed -i -e '/^#!/aOPTWARE_TARGET=${OPTWARE_TARGET}' $(BVI_IPK_DIR)/opt/etc/init.d/SXXbvi
	$(MAKE) $(BVI_IPK_DIR)/CONTROL/control
#	install -m 755 $(BVI_SOURCE_DIR)/postinst $(BVI_IPK_DIR)/CONTROL/postinst
#	sed -i -e '/^#!/aOPTWARE_TARGET=${OPTWARE_TARGET}' $(BVI_IPK_DIR)/CONTROL/postinst
#	install -m 755 $(BVI_SOURCE_DIR)/prerm $(BVI_IPK_DIR)/CONTROL/prerm
#	sed -i -e '/^#!/aOPTWARE_TARGET=${OPTWARE_TARGET}' $(BVI_IPK_DIR)/CONTROL/prerm
#	if test -n "$(UPD-ALT_PREFIX)"; then \
		sed -i -e '/^[ 	]*update-alternatives /s|update-alternatives|$(UPD-ALT_PREFIX)/bin/&|' \
			$(BVI_IPK_DIR)/CONTROL/postinst $(BVI_IPK_DIR)/CONTROL/prerm; \
	fi
	echo $(BVI_CONFFILES) | sed -e 's/ /\n/g' > $(BVI_IPK_DIR)/CONTROL/conffiles
	cd $(BUILD_DIR); $(IPKG_BUILD) $(BVI_IPK_DIR)
	$(WHAT_TO_DO_WITH_IPK_DIR) $(BVI_IPK_DIR)

#
# This is called from the top level makefile to create the IPK file.
#
bvi-ipk: $(BVI_IPK)

#
# This is called from the top level makefile to clean all of the built files.
#
bvi-clean:
	rm -f $(BVI_BUILD_DIR)/.built
	-$(MAKE) -C $(BVI_BUILD_DIR) clean

#
# This is called from the top level makefile to clean all dynamically created
# directories.
#
bvi-dirclean:
	rm -rf $(BUILD_DIR)/$(BVI_DIR) $(BVI_BUILD_DIR) $(BVI_IPK_DIR) $(BVI_IPK)
#
#
# Some sanity check for the package.
#
bvi-check: $(BVI_IPK)
	perl scripts/optware-check-package.pl --target=$(OPTWARE_TARGET) $^
