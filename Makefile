CC	?= cc
set-user-alarm: set-user-alarm.c
	$(CC) ${CFLAGS} ${LDFLAGS} -o set-user-alarm set-user-alarm.c

check: set-user-alarm.c
	gcc -o out.o -c -fanalyzer -Werror -Wall -Wextra set-user-alarm.c
	rm out.o
	scan-build clang -o out.o -c -Werror -Wall -Wextra set-user-alarm.c # may add -Weverything
	rm out.o


install: set-user-alarm
	ls -lah ${DESTDIR}
	install -D -o root -g root -m 644 system-wake-up.service ${DESTDIR}/lib/systemd/system/system-wake-up.service
	install -D -o root -g root -m 644 system-wake-up.timer ${DESTDIR}/lib/systemd/system/system-wake-up.timer
	install -D -o root -g root -m 4755 set-user-alarm ${DESTDIR}/usr/bin/set-user-alarm
	install -D -o root -g root -m 755 wake-mobile ${DESTDIR}/usr/bin/wake-mobile
	install -D -o root -g root -m 644 wake-mobile.ui ${DESTDIR}/usr/share/wake-mobile/wake-mobile.ui
	install -D -o root -g root -m 644 org.gnome.gitlab.kailueke.WakeMobile.desktop ${DESTDIR}/usr/share/applications/org.gnome.gitlab.kailueke.WakeMobile.desktop
	install -D -o root -g root -m 644 org.gnome.gitlab.kailueke.WakeMobile.service ${DESTDIR}/usr/share/dbus-1/services/org.gnome.gitlab.kailueke.WakeMobile.service
	install -D -o root -g root -m 644 org.gnome.gitlab.kailueke.WakeMobile.svg ${DESTDIR}/usr/share/icons/hicolor/scalable/apps/org.gnome.gitlab.kailueke.WakeMobile.svg

uninstall:
	rm /lib/systemd/system/system-wake-up.service
	rm /lib/systemd/system/system-wake-up.timer
	rm /lib/systemd/system/timers.target.wants/system-wake-up.timer
	rm /usr/bin/set-user-alarm
	rm /usr/bin/wake-mobile
	rm /usr/share/applications/org.gnome.gitlab.kailueke.WakeMobile.desktop
	rm /usr/share/dbus-1/services/org.gnome.gitlab.kailueke.WakeMobile.service
	rm /usr/share/icons/hicolor/scalable/apps/org.gnome.gitlab.kailueke.WakeMobile.svg

clean:
	rm -f set-user-alarm

install-deb: set-user-alarm
	checkinstall "--requires=systemd, pulseaudio-utils, gnome-session-canberra, libglib2.0-bin, python3-psutil, python3-gi, gir1.2-glib-2.0, gir1.2-gtk-3.0" --pkgname=wake-mobile --pkglicense=GPL-2+ --nodoc --pkgversion=1.7 --pkgrelease=0 --include=listfile --deldesc=yes --backup=no -y
