
### Prints when 'some-dataset.csv' file has a number of columns different than 21
`cat some-dataset.csv | awk -F";" '{print NF}' | grep -n -v 21`

### In my opinion, Facebook is one of wrong things on Internet! You should put this rule
```
sudo iptables -A INPUT -s <INTERNAL_NETWORK_IP_FROM_YOUR_MACHINE> -d "facebook.com" -j REJECT && sudo iptables -A OUTPUT -s <INTERNAL_NETWORK_IP_FROM_YOUR_MACHINE> -d "facebook.com" -j REJECT
```
