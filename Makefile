set-user-alarm: set-user-alarm.c
	gcc -o set-user-alarm set-user-alarm.c
	sudo chown root:root set-user-alarm
	sudo chmod +s set-user-alarm

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

uninstall:
	sudo rm /lib/systemd/system/system-wake-up.service
	sudo rm /lib/systemd/system/system-wake-up.timer
	sudo rm /lib/systemd/system/timers.target.wants/system-wake-up.timer
	sudo rm /usr/bin/set-user-alarm
	sudo rm /usr/bin/wake-mobile
	sudo rm /usr/share/applications/org.gnome.gitlab.kailueke.WakeMobile.desktop

clean:
	rm -f set-user-alarm

install-deb: set-user-alarm
	sudo checkinstall "--requires=systemd, pulseaudio-utils, gnome-session-canberra" --pkgname=wake-mobile --pkglicense=GPL-2+ --nodoc --pkgversion=1.0 --pkgrelease=1 --include=listfile --deldesc=yes --backup=no -y
