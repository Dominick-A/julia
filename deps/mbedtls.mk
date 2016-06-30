## mbedtls

MBEDTLS_GIT_URL := git://github.com/ARMmbed/mbedtls.git
MBEDTLS_TAR_URL = https://api.github.com/repos/ARMmbed/mbedtls/tarball/$1
$(eval $(call git-external,mbedtls,MBEDTLS,CMakeLists.txt,build/libmbedtls.$(SHLIB_EXT),$(SRCDIR)/srccache))

MBEDTLS_OBJ_SOURCE := $(BUILDDIR)/$(MBEDTLS_SRC_DIR)/library/libmbedtls.$(SHLIB_EXT) \
			$(BUILDDIR)/$(MBEDTLS_SRC_DIR)/library/libmbedx509.$(SHLIB_EXT) \
			$(BUILDDIR)/$(MBEDTLS_SRC_DIR)/library/libmbedcrypto.$(SHLIB_EXT)
MBEDTLS_OBJ_TARGET := $(build_shlibdir)/libmbedtls.$(SHLIB_EXT) \
			$(build_shlibdir)/libmbedx509.$(SHLIB_EXT) \
			$(build_shlibdir)/libmbedcrypto.$(SHLIB_EXT)

MBEDTLS_OPTS := $(CMAKE_COMMON) -DUSE_SHARED_MBEDTLS_LIBRARY=ON \
		-DENABLE_PROGRAMS=OFF -DENABLE_TESTING=OFF \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo

ifeq ($(OS), WINNT)
MBEDTLS_OPTS += -G"MSYS Makefiles" -DENABLE_ZLIB_SUPPORT=OFF
else
MBEDTLS_OPTS += -DENABLE_ZLIB_SUPPORT=ON -DCMAKE_INSTALL_RPATH=$(build_prefix) -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE
endif

$(BUILDDIR)/$(MBEDTLS_SRC_DIR)/Makefile: $(SRCDIR)/srccache/$(MBEDTLS_SRC_DIR)/CMakeLists.txt
	-cd $(SRCDIR)/srccache/$(MBEDTLS_SRC_DIR) && patch -p0 -f < $(SRCDIR)/patches/mbedtls.patch
	mkdir -p $(dir $@)
	cd $(dir $@) && \
	$(CMAKE) $(dir $<) $(MBEDTLS_OPTS)
	touch -c $@

$(MBEDTLS_OBJ_SOURCE): $(BUILDDIR)/$(MBEDTLS_SRC_DIR)/Makefile
	$(MAKE) -C $(dir $<)
	touch -c $@

$(BUILDDIR)/$(MBEDTLS_SRC_DIR)/checked: $(MBEDTLS_OBJ_SOURCE)
ifeq ($(OS),$(BUILD_OS))
	$(MAKE) -C $(dir $@) test
endif
	echo 1 > $@

$(MBEDTLS_OBJ_TARGET): $(MBEDTLS_OBJ_SOURCE) | $(build_shlibdir)
ifeq ($(OS), WINNT)
	cp $^ $(build_shlibdir)
else
	$(call make-install,$(MBEDTLS_SRC_DIR),)
endif
	touch -c $(MBEDTLS_OBJ_TARGET)

clean-mbedtls:
	-rm -rf $(BUILDDIR)/$(MBEDTLS_SRC_DIR)
	-rm -f $(MBEDTLS_OBJ_TARGET)

get-mbedtls: $(MBEDTLS_SRC_FILE)
configure-mbedtls: $(BUILDDIR)/$(MBEDTLS_SRC_DIR)/Makefile
compile-mbedtls: $(MBEDTLS_OBJ_SOURCE)
check-mbedtls: $(BUILDDIR)/$(MBEDTLS_SRC_DIR)/checked
install-mbedtls: $(MBEDTLS_OBJ_TARGET)
