# 👉 0G MONITOR BLOCK AUTO RESTART


copy and paste into your terminal :

clone
```bash
git clone https://github.com/rokipdj88/0gmonitor.git
cd 0gmonitor
```

copy to system
```
sudo cp 0gmonitor.sh /usr/local/bin/monitor_zgs.sh
sudo chmod +x /usr/local/bin/monitor_zgs.sh
```

create service systemd
```
sudo nano /etc/systemd/system/monitor-zgs.service

```

paste

change to your token bot & chat id

```
[Unit]
Description=Monitor 0G Storage Node Service
After=network.target

[Service]
ExecStart=/usr/local/bin/monitor_zgs.sh
Restart=always
User=root
Environment=BOT_TOKEN=isi_token_telegram
Environment=CHAT_ID=isi_chat_id
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

```

run & activate service
```
sudo systemctl daemon-reload
sudo systemctl enable monitor-zgs
sudo systemctl start monitor-zgs

```
Chcek log realtime
```
journalctl -fu monitor-zgs
```
uninstall & delete service
```
sudo systemctl stop monitor-zgs
sudo systemctl disable monitor-zgs
sudo rm /etc/systemd/system/monitor-zgs.service
sudo rm /usr/local/bin/monitor_zgs.sh
sudo systemctl daemon-reexec
```





# 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check [issues page](https://github.com/yourusername/0gmonitor/issues) if you want to contribute.


Enjoy using the Automation installation! If you have any questions or run into any issues, please don't hesitate to reach out or open an issue on GitHub.! ✨
