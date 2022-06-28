#!/bin/bash
service redis-server start
#service nginx start
systemctl enable webchaind
systemctl enable webchain-pool
systemctl enable webchain-pool-api
systemctl enable webchain-pool-unlocker
systemctl enable webchain-pool-payouts
#$HOME/geth --mintme
#systemctl start webchaind
#systemctl start webchain-pool
#systemctl start webchain-pool-api
#systemctl start webchain-pool-unlocker
#systemctl start webchain-pool-payouts
#service webchaind start
#service webchain-pool start
#service webchain-pool-api start
#service webchain-pool-unlocker start
#service webchain-pool-payouts start