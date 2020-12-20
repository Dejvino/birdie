#!/usr/bin/env python3

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gio, GLib
import os, sys, signal

from subprocess import check_output

os.chdir(os.path.dirname(sys.argv[0]))
UI_FILE = "wake-mobile.ui"
LICENSE = Gtk.License.GPL_3_0
VERSION = "0.1"

startmsg = "Wake your device and issue an alarm"

class WakeMobile(Gtk.Application):
  alarm_set = False
  alarm_pid = 0

  def __init__(self):
    Gtk.Application.__init__(self)

  def do_startup(self):
    Gtk.Application.do_startup(self)

  def do_activate(self):
    self.builder = Gtk.Builder()
    self.builder.add_from_file(UI_FILE)
    self.builder.connect_signals(self)
    self.lefttime = self.builder.get_object("lefttime")
    self.hour = self.builder.get_object("hour")
    self.minute = self.builder.get_object("minute")
    self.second = self.builder.get_object("second")
    self.volumescale = self.builder.get_object("volume")
    self.volumeoption = self.builder.get_object("volumecheck")
    self.window = self.builder.get_object("appwindow")
    self.window.set_application(self)
    self.errorlabel = self.builder.get_object("error")
    self.errorlabel.set_label(startmsg)
    self.setwakebutton = self.builder.get_object("setwake")
    self.cancelbutton = self.builder.get_object("cancel")
    self.snoozebutton = self.builder.get_object("snooze")
    self.window.show_all()
    # TODO: read timer from systemd file(s) and set app state from it
    self.update()
    GLib.timeout_add_seconds(1, self.updater)

  def updater(self):
    self.update()
    if not self.alarm_set or (self.alarmtime.difference(GLib.DateTime.new_now_local()) > 0):
        return True
    self.alarm_set = False
    self.snoozebutton.set_sensitive(True)
    try:
      if self.volumeoption.get_active():
        check_output(["pactl", "set-sink-mute", "0", "0"])
        check_output(["pactl", "set-sink-volume", "0", str(int(self.volumescale.get_value()))+ "%"])
      self.alarm_pid, _, _, _ = GLib.spawn_async(["canberra-gtk-play", "-i", "alarm-clock-elapsed", "-l", "999999999"], standard_output=-1, standard_input=-1, standard_error=-1)
      self.errorlabel.set_label("<span color='orange'>Wake up!</span>")
      self.lefttime.set_label("No time left")
    except:
      self.errorlabel.set_label("<span color='red'>Error issuing alarm</span>")
    return True

  def set_alarm(self):
    self.alarm_set = True
    self.window.set_sensitive(False)
    self.disable_elements(True)
    try: # TODO: use pkexec to write out a user unit and a system unit
      output = str(check_output(["echo", str(self.alarmtime.to_unix()) ]),'utf8').replace('\n','')
      self.errorlabel.set_label("Alarm is set")
    except:
      self.errorlabel.set_markup("<span color='red'>Error setting wake time</span>")
    self.window.set_sensitive(True)
    self.update()

  def snooze_clicked(self, button):
    self.alarmtime = GLib.DateTime.new_now_local().add_minutes(3)
    self.hour.set_value(self.alarmtime.get_hour())
    self.minute.set_value(self.alarmtime.get_minute())
    self.second.set_value(self.alarmtime.get_second())
    self.end_alarm()
    self.set_alarm()

  def end_alarm(self):
    if self.alarm_pid != 0:
      os.kill(self.alarm_pid, signal.SIGTERM)
      self.alarm_pid = 0

  def stop_clicked(self, button):
    self.disable_elements(False)
    self.alarm_set = False
    self.errorlabel.set_label(startmsg)
    self.end_alarm()
    self.update()

  def set_wake_clicked(self, button):
    self.alarmtime = self.calc_wakeup_time()
    self.set_alarm()

  def disable_elements(self, val):
    self.setwakebutton.set_sensitive(not val)
    self.cancelbutton.set_sensitive(val)
    self.snoozebutton.set_sensitive(False)
    self.volumeoption.set_sensitive(not val)
    self.volumescale.set_sensitive(not val)
    self.hour.set_sensitive(not val)
    self.minute.set_sensitive(not val)
    self.second.set_sensitive(not val)

  def on_volumecheck_toggled(self, volumecheckelem):
    self.volumescale.set_sensitive(volumecheckelem.get_active())

  def on_volume_changed(self, volumeadjustment):
    self.volumescale.set_fill_level(volumeadjustment.get_value())

  def on_window_destroy(self, window):
    self.end_alarm()
    self.quit()

  def quit_cb(self, action, parameter):
    self.on_window_destroy(self.window)

  def calc_wakeup_time(self):
    hour = int(self.hour.get_value())
    minute = int(self.minute.get_value())
    second = int(self.second.get_value())
    tn = GLib.DateTime.new_now_local()
    wtime = GLib.DateTime.new_local(tn.get_year(), tn.get_month(), tn.get_day_of_month(), hour, minute, second)
    if wtime.difference(tn) < 0:
      wtime = wtime.add_days(1)
    if wtime.difference(tn) < 0:
      raise Exception("Something went wrong with the time calculation: This should never happen!")
    return wtime

  def update(self):
    tn = GLib.DateTime.new_now_local()
    wtime = self.calc_wakeup_time()
    total_sec_left = int(wtime.difference(tn)/1000/1000)
    sec_left = str(int(total_sec_left % 60))
    min_left = str((int(total_sec_left/60) % 60))
    hours_left = str(int(total_sec_left/60/60))
    label = hours_left + ":" + min_left + ":" + sec_left + " left"
    if self.alarm_pid != 0:
      pass
    elif self.alarm_set:
      self.lefttime.set_label("<span color='orange'>" + label + "</span>")
    else:
      self.lefttime.set_label(label)


if __name__ == "__main__":
  check_output(["pactl", "--version"])
  check_output(["canberra-gtk-play", "--version"]) # Debian package: gnome-session-canberra
  check_output(["pkexec", "--version"])
  app = WakeMobile()
  exit_status = app.run(sys.argv)
  sys.exit(exit_status)
