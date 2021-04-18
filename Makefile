CC	?= cc
APP_NAME=birdie
APP_ID=com.github.dejvino.birdie

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
	install -D -o root -g root -m 4755 set-user-alarm ${DESTDIR}/usr/lib/${APP_NAME}/libexec/set-user-alarm
	install -D -o root -g root -m 755 play-alarm-sound ${DESTDIR}/usr/lib/${APP_NAME}/libexec/play-alarm-sound
	install -D -o root -g root -m 755 ${APP_NAME} ${DESTDIR}/usr/bin/${APP_NAME}
	install -D -o root -g root -m 644 app.ui ${DESTDIR}/usr/share/${APP_NAME}/app.ui
	install -D -o root -g root -m 644 splashes.ogg ${DESTDIR}/usr/share/${APP_NAME}/splashes.ogg
	install -D -o root -g root -m 644 ${APP_ID}.desktop ${DESTDIR}/usr/share/applications/${APP_ID}.desktop
	install -D -o root -g root -m 644 ${APP_ID}.service ${DESTDIR}/usr/share/dbus-1/services/${APP_ID}.service
	install -D -o root -g root -m 644 ${APP_ID}.svg ${DESTDIR}/usr/share/icons/hicolor/scalable/apps/${APP_ID}.svg
	touch ${DESTDIR}/usr/share/icons/hicolor
	gtk-update-icon-cache

uninstall:
	rm /lib/systemd/system/system-wake-up.service
	rm /lib/systemd/system/system-wake-up.timer
	rm /lib/systemd/system/timers.target.wants/system-wake-up.timer
	rm /usr/bin/set-user-alarm
	rm /usr/bin/${APP_NAME}
	rm -rf /usr/lib/${APP_NAME}
	rm -rf /usr/share/${APP_NAME}
	rm /usr/share/applications/${APP_ID}.desktop
	rm /usr/share/dbus-1/services/${APP_ID}.service
	rm /usr/share/icons/hicolor/scalable/apps/${APP_ID}.svg

clean:
	rm -f set-user-alarm

install-deb: set-user-alarm
	checkinstall "--requires=systemd, pulseaudio-utils, gnome-session-canberra, libglib2.0-bin, python3-psutil, python3-gi, gir1.2-glib-2.0, gir1.2-gtk-3.0" --pkgname=${APP_NAME} --pkglicense=GPL-2+ --nodoc --pkgversion=1.7 --pkgrelease=0 --include=listfile --deldesc=yes --backup=no -y
