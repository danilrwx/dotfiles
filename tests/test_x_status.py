import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

REPO = Path(__file__).resolve().parents[1]


class StatusTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.home = Path(self.directory.name)
        stubs = self.home / 'stubs'
        stubs.mkdir()
        self.result = self.home / 'notification.json'
        scripts = {
            'classical': '''#!/bin/sh
[ "$1" = now ] && [ -n "$NOW_PLAYING" ] && printf '%s\\n' "$NOW_PLAYING"
''',
            'notify-send': '''#!/usr/bin/python3
import json, os, sys
with open(os.environ['NOTIFICATION'], 'a') as f:
    f.write(json.dumps(sys.argv[1:]) + '\\n')
''',
            'bluetoothctl': '''#!/bin/sh
case "$1" in
  devices)
    [ "$SCENARIO" != disconnected ] || exit 0
    printf 'Device AA:BB:CC:DD:EE:FF Headphones\nDevice 11:22:33:44:55:66 Keyboard\n' ;;
  info)
    if [ "$2" = 11:22:33:44:55:66 ]; then
      printf '\tAlias: Keyboard\n\tIcon: input-keyboard\n'
    else
      printf '\tAlias: FreeClip & <2>\n\tIcon: audio-headphones\n'
      [ "$SCENARIO" = unknown ] || printf '\tBattery Percentage: 0x0a (10)\n'
    fi ;;
esac
''',
            'wpctl': '''#!/bin/sh
[ "$SCENARIO" != disconnected ] || exit 1
if [ "$1" = inspect ]; then
  case "$2" in
    @DEFAULT_AUDIO_SINK@)
      echo '  node.description = "Core Ultra Processors (Series 3) HD Audio Speaker"'
      echo '  node.nick = "Speaker"' ;;
    *) echo '  node.description = "Built-in Microphone"' ;;
  esac
  exit
fi
case "$2" in
  @DEFAULT_AUDIO_SINK@) echo 'Volume: 0.60' ;;
  *) echo 'Volume: 0.27 [MUTED]' ;;
esac
''',
            'ip': '''#!/bin/sh
[ "$SCENARIO" != disconnected ] || exit 0
case "$*" in
  *route*) echo 'default via 192.0.2.1 dev wlan0' ;;
  *) echo '2: wlan0 inet 192.0.2.2/24 scope global wlan0' ;;
esac
''',
            'iwctl': "#!/bin/sh\nprintf '    Connected network    Home & <WiFi>                                        \n    RSSI    -64 dBm\n'\n",
            'free': "#!/bin/sh\necho 'Mem: 32768 8192 4096 0 20480 24576'\n",
            'df': "#!/bin/sh\nprintf 'Avail\n666G\n'\n",
            'uptime': "#!/bin/sh\necho 'up 1 day, 2 hours'\n",
            'upower': "#!/bin/sh\necho '    time to empty: 6.7 hours'\n",
            'date': '''#!/usr/bin/python3
from datetime import datetime
import os, sys
print(datetime.fromisoformat(os.environ['TODAY']).strftime(sys.argv[1][1:]))
''',
        }
        for name, content in scripts.items():
            p = stubs / name
            p.write_text(content)
            p.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), PATH=f'{stubs}:/usr/bin:/bin',
                        NOTIFICATION=str(self.result), SCENARIO='connected', NOW_PLAYING='')

    def run_status(self, scenario, today='2026-11-18T21:17:00'):
        self.result.unlink(missing_ok=True)
        result = subprocess.run([str(REPO / 'bin/x-status')],
                                env=dict(self.env, SCENARIO=scenario, TODAY=today),
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        notifications = [json.loads(line) for line in self.result.read_text().splitlines()]
        self.assertEqual(len(notifications), 3)
        self.assertEqual(notifications[0][:2], ['-a', 'x-calendar'])
        self.calendar_body = notifications[0][-1]
        ET.fromstring('<body>' + self.calendar_body + '</body>')
        args = notifications[1]
        self.assertEqual(args[:2], ['-a', 'x-status'])
        clock = notifications[2]
        self.assertEqual(clock[:2], ['-a', 'x-clock'])
        self.assertRegex(clock[-2], r'^\d{2}:\d{2}$')
        self.assertRegex(clock[-1], r'^.+, \d{1,2} .+ \d{4}$')
        ET.fromstring('<body>' + args[-1] + '</body>')
        return args[-1]

    def test_connected_headphone_charge_and_escaped_names(self):
        body = self.run_status('connected')
        self.assertIn('FreeClip &amp; &lt;2&gt; · 10%', body)
        self.assertNotIn('Keyboard', body)
        self.assertIn('<b>Audio</b>\nSpeaker · 60%', body)
        self.assertNotIn('Core Ultra', body)
        self.assertIn('<b>Microphone</b>\nBuilt-in Microphone · off', body)
        self.assertIn('Home &amp; &lt;WiFi&gt; · -64 dBm', body)
        self.assertIn('192.0.2.2', body)
        self.assertIn('8.0 / 32.0 GiB', body)
        self.assertIn('666G free', body)
        self.assertIn('1d 2h', body)
        self.assertNotIn('hours', body)
        headings = re.findall(r'^<b>([^<]+)</b>$', body, re.M)
        self.assertEqual([h for h in headings if h not in ('Battery', 'Brightness')],
                         ['Audio', 'Microphone', 'Headphones', 'Wi-Fi', 'IPv4',
                          'Memory', 'Disk', 'Uptime'])
        self.assertIn('\n\n<b>', body)

    def test_unknown_charge_is_not_reported_as_zero(self):
        body = self.run_status('unknown')
        self.assertIn('FreeClip &amp; &lt;2&gt; · unknown', body)
        self.assertNotIn('10%', body)

    def test_now_playing_is_visible_and_escaped(self):
        self.env['NOW_PLAYING'] = 'Bach & <Orchestra>'
        body = self.run_status('connected')
        self.assertIn('<b>Now playing</b>\nBach &amp; &lt;Orchestra&gt;', body)

    def test_disconnected_network_audio_and_headphones(self):
        body = self.run_status('disconnected')
        self.assertIn('<b>Headphones</b>\ndisconnected', body)
        self.assertIn('<b>Connection</b>\noffline', body)
        self.assertIn('<b>Audio</b>\nunavailable', body)
        self.assertIn('<b>Microphone</b>\nunavailable', body)
        self.assertNotIn('IPv4', body)

    def test_calendar_leap_years_and_today_highlight(self):
        for today, days in [('2024-02-29', 29), ('2100-02-28', 28), ('2026-11-01', 30)]:
            with self.subTest(today=today):
                self.run_status('connected', today)
                root = ET.fromstring('<body>' + self.calendar_body + '</body>')
                calendar = root.find('span')
                highlighted = calendar.findall('span[@background]')
                self.assertEqual(len(highlighted), 1)
                self.assertEqual(int(highlighted[0].text), int(today[-2:]))
                self.assertEqual(highlighted[0].get('background'), '#ffffff')
                lines = ''.join(calendar.itertext()).splitlines()
                self.assertEqual(lines[0].split(), ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
                self.assertTrue(all(len(line) == 28 for line in lines))
                actual_days = list(map(int, re.findall(r'\d+', '\n'.join(lines[1:]))))
                self.assertEqual(actual_days, list(range(1, days + 1)))

    def test_calendar_highlight_follows_light_palette(self):
        theme = self.home / '.config/dotfiles/theme'
        theme.mkdir(parents=True)
        (theme / 'menu.sh').write_text('bg="#f2e8d2"\nfg="#33322e"\n')
        self.run_status('connected')
        root = ET.fromstring('<body>' + self.calendar_body + '</body>')
        highlight = root.find('.//span[@background]')
        self.assertEqual(highlight.get('background'), '#33322e')
        self.assertEqual(highlight.get('foreground'), '#f2e8d2')
