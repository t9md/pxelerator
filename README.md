What's this?
==================================
Make pxe installation easy.
PXE installation setup is such like prepare multiple co-related files carefully.

It is boring for me, and lead to nightmare to see growing number of machine.

Why? similar software(such as cobbler and foreman) already exist.
=================================================================
Cobbler was difficult for me, and not good for ESXi and Ubuntu(from version 2.X, cobbler quit supporting ubuntu).
I imagine Foreman is good and well designed just because I didn't try it.

Feature
==================================
* snippet in template
* dnsmasq configuratin generation
* generate per host based bootmenu into /tftpboot/pxelinux.cfg/ dir
* on the fly generation of instration instruction(kickstart) with ERB rendering.
* snippet for resusable code in ERB template.

Similar software
----------------------------------
* [Cobbler](https://fedorahosted.org/cobbler/)
* [Foreman](http://theforeman.org/)
