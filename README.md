# digsite:53
digsite:53 is an extremely simple DNS (Domain Name Service) server written in [Ruby](https://www.ruby-lang.org/en/). It currently only supports `A` and `AAAA` records and is created solely for educational purposes.

The goal of this project is to create a simple configurable DNS server that can be used to browse the Internet using a Web browser.

## Quick start
1. Download the [Ruby interpreter](https://www.ruby-lang.org/en/downloads/) for your OS
2. Run `$ ruby src/main.rb`
3. The DNS server will be started on `localhost:6969`

## TODO
- [ ] Configuration
  - [ ] Set server adress and port
  - [ ] Configure custom DNS entries as a key value map
  - [ ] Change DNS fallthrough server
- [ ] Fallthrough to an actual DNS server/source (like [1.1.1.1](https://1.1.1.1))
- [ ] Other record types

## FAQ
### 1. Where does the name `digsite:53` come from?
From here: 

![Image](https://i.imgur.com/uRfZp6L.png)

...and 53 is the default DNS port
