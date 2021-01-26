set-user-alarm: set-user-alarm.c
	cc -o set-user-alarm set-user-alarm.c
	sudo chown root:root set-user-alarm
	sudo chmod +s set-user-alarm

check: set-user-alarm.c
	gcc -o out.o -c -fanalyzer -Werror -Wall -Wextra set-user-alarm.c
	rm out.o
	scan-build clang -o out.o -c -Werror -Wall -Wextra set-user-alarm.c # may add -Weverything
	rm out.o

install: set-user-alarm
	sudo install -o root -g root -m 644 system-wake-up.service /lib/systemd/system/system-wake-up.service
	sudo install -o root -g root -m 644 system-wake-up.timer /lib/systemd/system/system-wake-up.timer
	sudo ln -fs /lib/systemd/system/system-wake-up.timer /lib/systemd/system/timers.target.wants/system-wake-up.timer
	sudo install -o root -g root -m 755 set-user-alarm /usr/bin/set-user-alarm
	sudo chmod +s /usr/bin/set-user-alarm
	sudo install -o root -g root -m 755 wake-mobile /usr/bin/wake-mobile
	sudo mkdir -p /usr/share/wake-mobile
	sudo install -o root -g root -m 644 wake-mobile.ui /usr/share/wake-mobile/wake-mobile.ui
	sudo install -o root -g root -m 644 org.gnome.gitlab.kailueke.WakeMobile.desktop /usr/share/applications/org.gnome.gitlab.kailueke.WakeMobile.desktop
	sudo install -o root -g root -m 644 org.gnome.gitlab.kailueke.WakeMobile.service /usr/share/dbus-1/services/org.gnome.gitlab.kailueke.WakeMobile.service
	sudo install -o root -g root -m 644 org.gnome.gitlab.kailueke.WakeMobile.svg /usr/share/icons/hicolor/scalable/apps/org.gnome.gitlab.kailueke.WakeMobile.svg

uninstall:
	sudo rm /lib/systemd/system/system-wake-up.service
	sudo rm /lib/systemd/system/system-wake-up.timer
	sudo rm /lib/systemd/system/timers.target.wants/system-wake-up.timer
	sudo rm /usr/bin/set-user-alarm
	sudo rm /usr/bin/wake-mobile
	sudo rm /usr/share/applications/org.gnome.gitlab.kailueke.WakeMobile.desktop
	sudo rm /usr/share/dbus-1/services/org.gnome.gitlab.kailueke.WakeMobile.service
	sudo rm /usr/share/icons/hicolor/scalable/apps/org.gnome.gitlab.kailueke.WakeMobile.svg

clean:
	rm -f set-user-alarm

install-deb: set-user-alarm
	sudo checkinstall "--requires=systemd, pulseaudio-utils, gnome-session-canberra" --pkgname=wake-mobile --pkglicense=GPL-2+ --nodoc --pkgversion=1.3 --pkgrelease=1 --include=listfile --deldesc=yes --backup=no -y
