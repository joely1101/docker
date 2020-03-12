Script for create new docker os.

1.put dkos file in ~/.local/bin/

2.install bash_complete, apt-get install bash_complete

3.copy dkos.bash_complete to /etc/bash_completion.d/
4.exit shell andlgoin again.

usage:
#dkos create myubuntu-14 ubuntu:18.04

dkos_myubuntu-14 will be created to operate myubuntu-14 os.

#dkos_myubuntu-14 login [ root ]

#dkos_myubuntu-14 save keep-my-ins-in-image - save to image

#dkos_myubuntu-14 del - delete instance.

#dkos_myubuntu-14 sh - exec sh in this OS.



