set-user-alarm: set-user-alarm.c
	gcc -o set-user-alarm set-user-alarm.c
	sudo chown root:root set-user-alarm
	sudo chmod +s set-user-alarm

install: set-user-alarm
	sudo install -o root -g root -m 644 system-wake-up.service /etc/systemd/system/system-wake-up.service
	sudo install -o root -g root -m 644 system-wake-up.timer /etc/systemd/system/system-wake-up.timer
	sudo ln -fs /etc/systemd/system/system-wake-up.timer /etc/systemd/system/timers.target.wants/system-wake-up.timer
	sudo install -o root -g root -m 755 set-user-alarm /usr/bin/set-user-alarm
	sudo chmod +s /usr/bin/set-user-alarm
	sudo install -o root -g root -m 755 wake-mobile /usr/bin/wake-mobile
	sudo mkdir -p /usr/share/wake-mobile
	sudo install -o root -g root -m 644 wake-mobile.ui /usr/share/wake-mobile/wake-mobile.ui
	sudo install -o root -g root -m 644 org.gnome.gitlab.kailueke.WakeMobile.desktop /usr/share/applications/org.gnome.gitlab.kailueke.WakeMobile.desktop

uninstall:
	sudo rm /etc/systemd/system/system-wake-up.service
	sudo rm /etc/systemd/system/system-wake-up.timer
	sudo rm /etc/systemd/system/timers.target.wants/system-wake-up.timer
	sudo rm /usr/bin/set-user-alarm
	sudo rm /usr/bin/wake-mobile
	sudo rm /usr/share/applications/org.gnome.gitlab.kailueke.WakeMobile.desktop

clean:
	rm -f set-user-alarm
