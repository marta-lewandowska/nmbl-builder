# SPDX-License-Identifier: GPLv3
#
# Makefile
# Copyright Peter Jones <pjones@redhat.com>
#

TOPDIR ?= .
include $(TOPDIR)/utils.mk

TARGETS = nmbl-cloud.uki nmbl-megalith.uki nmbl-workstation.uki

all: $(TARGETS)

%.initramfs.img :
	@dracut --verbose --confdir "$*.conf.d/" --no-hostonly --xz \
		$@ $(KVRA)

nmbl-%.uki : %.initramfs.img
	@/usr/lib/systemd/ukify -o "$@" \
		--os-release @/etc/os-release \
		--uname "$(KVRA)" \
		--efi-arch "$(EFI_ARCH)" \
		--stub "/usr/lib/systemd/boot/efi/linux$(EFI_ARCH).efi.stub" \
                "/boot/vmlinuz-$(KVRA)" \
                "$*.initramfs.img"

install : $(TARGETS)
	install -m 0700 -d "$(DESTDIR)$(ESPDIR)"
	install -m 0600 -t "$(DESTDIR)$(ESPDIR)" $(TARGETS)

nmbl-builder-$(VERSION).tar.xz : Makefile
	git archive --format=tar --prefix=nmbl-builder-$(VERSION)/ --add-file utils.mk HEAD | xz > $@

nmbl-builder: nmbl-builder-$(VR).src.rpm

nmbl-builder-$(VR).src.rpm : nmbl-builder.spec nmbl-builder-$(VERSION).tar.xz
	rpmbuild $(RPMBUILD_ARGS) -bs $<

tarball : nmbl-builder-$(VERSION).tar.xz

clean :
	@rm -vf nmbl-builder-$(VERSION).tar.xz

.PHONY: all install clean tarball

# vim:ft=make
